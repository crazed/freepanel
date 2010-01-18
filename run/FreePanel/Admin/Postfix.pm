#!/usr/bin/perl
package FreePanel::Admin::Postfix;
use strict;
use DBI;
use Crypt::PasswdMD5 qw(unix_md5_crypt);
use FreePanel::Config;
use base qw(FreePanel::Config);
#########################################################################
#			        DP::Postfix				#
#########################################################################
# Purpose: easy to maintain email accounts for postfix in a mysql DB
#
# Usage:
#
# 1) create the database connection
#	my $postfix = new DP::Postfix(host, port,
#		user, password, database,
#		raiseError, debug);
# 2) set options
#	my @user_cols = ("fname", "email", "quota", "password");
#	$postfix->setUsersCols(@user_col);
# 3) write to database
#	my $hash = md5_hex("password");
#	my $quota_bytes = 1024*1024*10 // 10 MB
#	$postfix->addUser('foo@bar.com', 'Foo Bar', $hash, $quota_bytes);
#
# see: <link> for more info
##########################################################################

##########################################################################
#				Class Constructor	 		 #
##########################################################################
sub dbConnect
{ 
	my ($self) = @_;
	# connect the database

	my $dbh = DBI->connect("DBI:mysql:database=$self->{mysql_db};host=$self->{mysql_host}",
		"$self->{mysql_user}", "$self->{mysql_pass}",
		{'RaiseError' => $self->{debug} } );

	$self->logger("FATAL: unable to connect database", $self->ERROR);

	$self->{_dbh} = $dbh;
	return $self->{_dbh};
}
sub new
{
        my $class = shift;
        my $self = $class->SUPER::new();

	bless $self, $class;
	my $hash = $self->getMailDbConfig();

        # load configuration variables
        while ( my ($key, $value) = each(%$hash) ) {
                $self->{$key} = $value;
        }

	$self->{debug} = $self->getDebug();

        return $self;
}

#########################################################################

#########################################################################
#			     HELPER FUNCTIONS				#
#########################################################################
# setAliasCols(@array)
#	- @array is an array of columns used in the alias mysql table
# setDomainCol($column)
#	- name of the column for the domain table
#	- assumes one column in the table
# setEmailIdentifier($column)
#	- used for checkRecordExists function
#	- this is used for error checking and required
#	- identifies the column emails will be held
# setAliasIdentifier($column)
#	- used for checkRecordExists function
#	- identifies the column to search aliases for 
# setUserCols(@array)
#	- takes an array of columns used in the users table
# setAliasTable($table)
#	- mysql table used for aliases
# setDomainTable($table)
#	- mysql table used for domains
# setUserTable($table)
#	- mysql table used for users
#########################################################################

sub setDebug {
	my ($self, $value) = @_;
	$self->logger("function: setDebug($value)", $self->FUNC_CALL);

	$self->{debug} = $value;
}
sub setAliasCols
{
	my ($self, $columns) = @_;
	$self->logger("function: setAliasCols(@$columns)", $self->FUNC_CALL);
	$self->{_aliasCols} = \@$columns if $columns;
	return $self->{_aliasCols};
}
sub setAliasIdentifier
{
	my ($self, $column) = @_;
	$self->logger("function: setAliasIdentifier($column)", $self->FUNC_CALL);
	$self->{_aliasCol} = $column if $column;
	return $self->{_aliasCol};
}
sub setDomainCol
{
	my ($self, $column) = @_;
	$self->logger("function: setDomainCol($column)", $self->FUNC_CALL);
	$self->{_domainCol} = $column if $column;
	return $self->{_domainCol};
}
sub setEmailIdentifier
{
	my ($self, $column) = @_;
	$self->logger("function: setEmailIdentifier($column)", $self->FUNC_CALL);
	$self->{_emailCol} = $column if $column;
	return $self->{_emailCol};
}
sub setUserCols
{
	my ($self, $columns) = @_;
	$self->logger("function: setUserCols(@$columns)", $self->FUNC_CALL);
	$self->{_userCols} = \@$columns if $columns;
	return $self->{_userCol};
}
sub setAliasTable
{
	my ($self, $table) = @_;
	$self->logger("function: setAliasTable($table)", $self->FUNC_CALL);
	$self->{alias_table} = $table if $table;
	return $self->{alias_table};
} 
sub setDomainTable
{
	my ($self, $table) = @_;
	$self->logger("function: setDomainTable($table)", $self->FUNC_CALL);
	$self->{domain_table} = $table if $table;
	return $self->{domain_table};
} 
sub setUserTable
{
	my ($self, $table) = @_;
	$self->logger("function: setUserTable($table)", $self->FUNC_CALL);
	$self->{user_table} = $table if $table;
	return $self->{user_table};
} 

############################### END HELPERS #############################



#########################################################################
#			    POSTFIX FUNCTIONS				#	
#########################################################################
# usage:
# addAlias($source, $destination)
# addDomain($domain)
# addUser([val1, val2, ... valn])
#	- takes a ref to an array that is same order used for userCols
#	- hash should be md5_hex of password
#	- quota should be passed in bytes
# modifyUser($email_addr, $columns, $values)
#	- columns and values are a reference to an array (ex: \@cols)
#	- see MySQL helpers for more information
# delUser($email)
# delAlias($alias)
# modifyAlias($alias, $columns, $values)
#	- columns and values are a reference to an array (ex: \@col)
# delDomain($domain)
#########################################################################
sub addAlias
{
	# arguments to take
	my ($self, $source, $destination) = @_;
	$self->logger("function: addAlias($source, $destination)", $self->FUNC_CALL);

	my @vals = ($source, $destination);
	my @cols = $self->{_aliasCols};
	my @email_prts = split(/@/, $source);
	if (!$email_prts[1]) {
		$self->logger("$source is not a valid email address.", $self->ERROR);
		return 0;
	}

	if (!checkRecordExists($self, $self->{domain_table}, $self->{_domainCol}, $email_prts[1])) {
		$self->logger("$email_prts[1] is not a valid domain on this server.", $self->ERROR);
		return 0;
	}

	if (!checkRecordExists($self, $self->{user_table}, $self->{_emailCol}, $destination)) {
		$self->logger("destination address ($destination) does not exist.", $self->ERROR);
		return 0;
	}
	
	if (!insertRecord($self, $self->{alias_table}, $self->{_aliasCols}, \@vals)) {
		$self->logger("failure adding alias for $source.", $self->ERROR);
		return 0;
	}
	return 1;
}
sub addDomain
{
	# arguments to take
	my ($self, $domain) = @_;
	$self->logger("function: addDomain($domain)", $self->FUNC_CALL);

	my @vals = ($domain);
	my @cols = ($self->{_domainCol});

	if (checkRecordExists($self, $self->{domain_table}, $self->{_domainCol}, $domain)) {
		$self->logger("$domain already exists in postfix database.", $self->ERROR);
		return 0;
	}

	if (!insertRecord($self, $self->{domain_table}, \@cols, \@vals)) {
		$self->logger("failure while adding $domain to postfix database.", $self->ERROR);
		return 0;
	}

	return 1;
}
sub addUser
{
	# arguments
	my ($self, $values) = @_;
	$self->logger("function: addUser(@$values)", $self->FUNC_CALL);
	
	my $email_addr;
	# find the email address in the array
	foreach my $value (@{$values}) {
		if ($value =~ /^[A-z0-9_\-]+[@][A-z0-9_\-]+([.][A-z0-9_\-]+)+[A-z]{2,4}$/) {
			# $value is an email
			$email_addr = $value;
		}
	}
	
	# if no email was found, throw error
	if (!$email_addr) {
		$self->logger("no email address supplied", $self->ERROR);
		return 0;
	}
	
	# pull out the domain portion
	my @email_prts = split(/@/, $email_addr);

	# test if domain exists in domains table
	my $test = checkRecordExists(
		$self,
		$self->{domain_table}, 
		$self->{_domainCol}, 
		$email_prts[1]
	);

	if (!$test) {
		$self->logger("$email_prts[1] is not a valid domain on this server.", $self->ERROR);
		return 0;
	}
	
	if (!insertRecord($self, $self->{user_table}, $self->{_userCols}, $values)) { 
		$self->logger("failure while adding $email_addr to postfix database.", $self->ERROR);
		return 0;
	}

	return 1;
}
sub modifyUser
{
	# arguments to take
	my ($self, $email_addr, $columns, $values) = @_;
	$self->logger("function: modifyUser($email_addr, @$columns, @$values)", $self->FUNC_CALL);
	my $selector = $self->{_emailCol};
	if (!updateRecord($self, $self->{user_table}, $selector, $email_addr, $columns, $values)) {
		$self->logger("failure to modify $email_addr", $self->ERROR);
		return 0;
	}
	return 1;
}
sub delUser
{
	#arguments
	my ($self, $email_addr) = @_;
	$self->logger("function: delUser($email_addr)", $self->FUNC_CALL);
	if(!deleteRecord($self, $self->{user_table}, $self->{_emailCol}, $email_addr)) {
		$self->logger("failed to remove $email_addr from postfix database.", $self->ERROR);
		return 0;
	}
	return 1;
}
sub delDomain
{
	my ($self, $domain) = @_;
	$self->logger("function: delDomain($domain)", $self->FUNC_CALL);
	if(!deleteRecord($self, $self->{domain_table}, $self->{_domainCol}, $domain)) {
		$self->logger("failed to remove $domain from postfix database.", $self->ERROR);
		return 0;
	}
	return 1;
}

sub delAlias
{
	my ($self, $alias) = @_;
	$self->logger("function: delAlias($alias)", $self->FUNC_CALL);
	if (!deleteRecord($self, $self->{alias_table}, $self->{_aliasCol}, $alias)) {
		$self->logger("failed to remove $alias from postfix database", $self->ERROR);
		return 0;
	}
	return 1;
}

sub modifyAlias
{
	my ($self, $alias, $columns, $values) = @_;
	$self->logger("function: modifyAlias($alias, @$columns, @$values)", $self->FUNC_CALL);
	my $selector = $self->{_aliasCol};

	if (!updateRecord($self, $self->{alias_table}, $selector, $alias, $columns, $values)) {
		$self->logger("failure while modifying $alias", $self->ERROR);
		return 0;
	}
	return 1;
}
sub addForward
{
	my ($self, $source, $destination) = @_;
	$self->logger("function: addForward($source, $destination)", $self->FUNC_CALL);
	my $selector = $self->{_emailCol};

	# make sure domain exists
	my @email_prts = split(/@/, $source);
	my @dst_prts = split(/@/, $source);

	if (!$email_prts[1]) {
		$self->logger("$source is not a valid email", $self->ERROR);
		return 0;
	}
	if (!$dst_prts[1]) {
		$self->logger("$destination is not a valid email", $self->ERROR);
		return 0;
	}

	if (!checkRecordExists($self, $self->{domain_table}, $self->{_domainCol}, $email_prts[1])) {
		$self->logger("$email_prts[1] is not a valid domain on this server.", $self->ERROR);
		return 0;
	}

	# check if mailbox exists
	if (checkRecordExists($self, $self->{user_table}, $self->{_emailCol}, $source)) {
		# set activate to 0 for user (stops recieving mail locally)
		deactivateMail($self, $source);
	}

	# add to the alias column
	if(!insertRecord($self, $self->{alias_table}, $self->{_aliasCols}, [$source, $destination])) {
		$self->logger("failure adding alias $source to the postfix database.", $self->ERROR);
		return 0;
	}
	return 1;
}
sub activateMail
{
	my ($self, $email_addr) = @_;
	$self->logger("function: activiateMail($email_addr)", $self->FUNC_CALL);
	my $selector = $self->{_emailCol};
	# check if email addr exists in mailbox table
	if (!checkRecordExists($self, $self->{user_table}, $self->{_emailCol}, $email_addr)) {
		$self->logger("$email_addr does not exist in the database.", $self->ERROR);
		return 0;
	}

	# modify the record
	if (!updateRecord($self, $self->{user_table}, $selector, $email_addr, ['active'], [1])) {
		$self->logger("failure to activate mailbox for $email_addr", $self->ERROR);
		return 0;
	}
	return 1;
}
sub deactivateMail
{
	my ($self, $email_addr) = @_;
	$self->logger("function: deactivateMail($email_addr)", $self->FUNC_CALL);
	my $selector = $self->{_emailCol};
	# check if email addr exists in mailbox table
	if (!checkRecordExists($self, $self->{user_table}, $self->{_emailCol}, $email_addr)) {
		$self->logger("$email_addr does not exist in the postix database.", $self->ERROR);
		return 0;
	}

	# modify the record
	if (!updateRecord($self, $self->{user_table}, $selector, $email_addr, ['active'], [0])) {
		$self->logger("failure to deactivate mailbox for $email_addr", $self->ERROR);
		return 0;
	}
	return 1;
}
########################### END POSTFIX #################################

#########################################################################
#			Password Hashing				#
#########################################################################
sub hash
{
	my ($self, $password, $type) = @_;
	$self->logger("function: hash($password, $type)", $self->FUNC_CALL);
	my $hash;

	if (!$type) {
		$self->logger("no type specified for password hash", $self->ERROR);
		return 0;
	}	

	if ($type eq 'md5crypt') {
		$hash = md5crypt($password);
	}

	return $hash
}

sub md5crypt {
	my ($password) = @_;

	my $range = 100;
	my $random_number = int(rand($range));
	my $salt = gensalt($random_number);

	my $crypt = unix_md5_crypt($password, $salt);

	return $crypt;	
}

	
sub gensalt {
	my ($count) = @_;

	my @salt = ( '.', '/', 0 .. 9, 'A' .. 'Z', 'a' .. 'z' );
	my $salt;
	for (1..$count) {
		$salt .= (@salt)[rand @salt];
	}
	return $salt;
}
#########################################################################

#########################################################################
#			   MySQL Helpers				#
#########################################################################
# deleteRecord($table, $column, $id)
#   - DELETE FROM $table WHERE $column=[$id|'$id']
#
# updateRecord($table, $selector, $id, \@columns, \@values)
#   - UPDATE $talbe SET @columns[0..n]=$values[0..n] WHERE $selector=[$id|'$id']
#
# insertRecord($table, \@columns, \@values)
#   - INSERT INTO $table (@columns[0], @columns[1]..) VALUES(@values[0], @values[1]..)
#
# checkRecordExists($table, $column, $value)
#   - SELECT COUNT(*) FROM $table WHERE $column = '$value'
#########################################################################
sub deleteRecord
{
	#arguments to take
	my ($self, $table, $column, $id) = @_;
	$self->logger("function: deleteRecord($table, $column, $id)", $self->FUNC_CALL);

	# need a different query if id is an integer
	my $query;

	# if $id is numeric no need for quoting 
	if ($id =~ /^-?\d+$/ ) {
		$query = sprintf("DELETE FROM %s WHERE %s=%s", $table, $column, $id)
	}
	else {
		$query = sprintf("DELETE FROM %s WHERE %s='%s'", $table, $column, $id)
	}

	# debug statement
	$self->logger("query: $query", $self->DB_QUERY);

	if ($self->{_dbh}->do($query)) {
		return 1;
	}

	$self->logger("failed to delete record.", $self->ERROR);
	return 0;
}

sub updateRecord
{
	#arguments to take
	my ($self, $table, $selector, $id, $columns, $values) = @_;
	$self->logger("function: updateRecord($table, $selector, $id, @$columns, @$values)", $self->FUNC_CALL);

	my $tmp_string;
	my $update_string;

	# note: $columns, $values should be a ref to arrays
	
	# if the arrays aren't the same amount.. input is fudged throw an error
	if ($#$columns != $#$values) {
		$self->logger("FATAL: number of columns supplied does not match number of values", $self->ERROR);
		return 0;
	}
	# format the array data correctly
	for (my $i = 0; $i <= $#$columns; $i++) {
		$tmp_string = sprintf("%s='%s'", $columns->[$i], $values->[$i]);
		$update_string = $tmp_string . "," . $update_string;
	}
	# chop off the extra ','
	chop($update_string);	

	# create the query string, need different for number vs other
	my $query; 

	if ($id =~ /^-?\d+$/ ) {
		$query = sprintf("UPDATE %s SET %s WHERE %s=%d", $table, $update_string, $selector, $id);
	}
	else {
		$query = sprintf("UPDATE %s SET %s WHERE %s='%s'", $table, $update_string, $selector, $id);
	}

	$self->logger("query: $query", $self->DB_QUERY);

	# run the query
	if ($self->{_dbh}->do($query)) {
		return 1;	# success
	}

	return 0;		# fail
}

sub insertRecord
{
	# arguments to take
	my ($self, $table, $columns, $values) = @_;
	$self->logger("function: insertRecord($table, @$columns, @$values)", $self->FUNC_CALL);

	my $column_string;
	my $value_string;
	my $query;

	# note: $columns, $values should be a ref to arrays
	
	# if the arrays aren't the same amount.. input is fudged throw an error
	if ($#$columns != $#$values) {
		$self->logger("FATAL: number of columns supplied does not match number of values.", $self->ERROR);
		return 0;
	}
	# format the strings for query usage
	foreach my $column (@{$columns}) {
		$column_string = $column . "," . $column_string;
	}

	foreach my $value (@{$values}) {
		$value_string = "'" . $value . "'," . $value_string;
	}

	# remove extra commas
	chop($value_string);
	chop($column_string);
	
	# setup query
	$query = sprintf("INSERT INTO %s (%s) VALUES(%s)", $table, $column_string, $value_string);

	# debug statements
	$self->logger("query: $query", $self->DB_QUERY);

	# insert the record
	if ($self->{_dbh}->do($query)) {
		return 1; 	# success
	}

	return 0;		# fail

}

sub checkRecordExists
{
	# arguments to take
	my ($self, $table, $column, $value) = @_;

	my $query = sprintf("SELECT COUNT(*) FROM %s WHERE %s = '%s'", $table, $column, $value);
	$self->logger("query: $query", $self->DB_QUERY);
	my $dbh = $self->{_dbh};
	my $sth = $dbh->prepare($query);
	
	$sth->{"mysql_use_result"} = 1;

	if (!$sth) {
		$self->logger("Error: " . $dbh->errstr, $self->ERROR);
		return 0;
	}
	if (!$sth->execute()) {
		$self->logger("Error: " . $dbh->errstr, $self->ERROR);
		return 0;
	}

	# ugly..
	while (my $ref = $sth->fetchrow_arrayref) {
		if ($$ref[0] == 0) {
			return 0;
		}
		else {
			return 1;
		}
	}
}
############################ END MySql ##################################
sub restart
{
	my ($self) = @_;
	$self->logger("Postfix is being restarted", $self->INFO);
	return 1;
}

1;
