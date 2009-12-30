#!/usr/bin/perl
package DP::Postfix;
use strict;
use DBI;
use Crypt::PasswdMD5 qw(unix_md5_crypt);
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
{ my ($self) = @_;
	# connect the database

	my $dbh = DBI->connect("DBI:mysql:database=$self->{mysql_db};host=$self->{mysql_host}",
		"$self->{mysql_user}", "$self->{mysql_pass}",
		{'RaiseError' => $self->{debug} } )

		or die("[error] unable to connect database\n");

	$self->{_dbh} = $dbh;
	return $self->{_dbh};
}
sub new
{
	my $class = shift;
	my $self = {
		config_file	=> '/etc/freepanel/freepanel.conf'
	};

	# load the config vars
	getConfiguration($self);

	# ~ bless the code ~
	bless $self, $class;
	return $self;
}

sub getConfiguration
{
	my ($self) = @_;
	print "my config is ".$self->{config_file}."\n";
	open (CONF, '<', $self->{config_file}) or die ("ERR: ".$self->{config_file}." file is missing.\n");
	my $line;
        my @configs = ("mysql_host", "mysql_port", "mysql_user", "mysql_pass",
                        "mysql_db", "user_table", "domain_table", "alias_table", "debug");

	while (<CONF>) {
		my $line = $_;

		chomp($line);

		if ($line =~ /^\#./) {
			# line is comment skip it
			next;
		}
	
		my @split = split(/=/, $line);

		for my $config (@configs) {
			if ($split[0] =~ /^$config$/) {
				$self->{$config} = $split[1];
			}
		}	
	}

        if ($self->{debug}) {
                print "[DEBUG] configurations loaded:\n";
                for my $config (@configs) {
                        print "\t$config=".$self->{$config}."\n"
                }
        }

	close CONF;

	return 1;
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

sub setAliasCols
{
	my ($self, $columns) = @_;
	$self->{_aliasCols} = \@$columns if $columns;
	return $self->{_aliasCols};
}
sub setAliasIdentifier
{
	my ($self, $column) = @_;
	$self->{_aliasCol} = $column if $column;
	return $self->{_aliasCol};
}
sub setDomainCol
{
	my ($self, $column) = @_;
	$self->{_domainCol} = $column if $column;
	return $self->{_domainCol};
}
sub setEmailIdentifier
{
	my ($self, $column) = @_;
	$self->{_emailCol} = $column if $column;
	return $self->{_emailCol};
}
sub setUserCols
{
	my ($self, $columns) = @_;
	$self->{_userCols} = \@$columns if $columns;
	return $self->{_userCol};
}
sub setAliasTable
{
	my ($self, $table) = @_;
	$self->{alias_table} = $table if $table;
	return $self->{alias_table};
} 
sub setDomainTable
{
	my ($self, $table) = @_;
	$self->{domain_table} = $table if $table;
	return $self->{domain_table};
} 
sub setUserTable
{
	my ($self, $table) = @_;
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

	my @vals = ($source, $destination);
	my @cols = $self->{_aliasCols};
	my @email_prts = split(/@/, $source);
	if (!$email_prts[1]) {
		die("[error] $source is not a valid email\n");
	}

	if (!checkRecordExists($self, $self->{domain_table}, $self->{_domainCol}, $email_prts[1])) {
		die("[error] $email_prts[1] is not a valid domain for this server\n");
	}

	if (!checkRecordExists($self, $self->{user_table}, $self->{_emailCol}, $destination)) {
		die("[error] destination address ($destination) does not exist");
	}
	
	insertRecord($self, $self->{alias_table}, $self->{_aliasCols}, \@vals)
		or die("[error] failure adding alias $source\n");
}
sub addDomain
{
	# arguments to take
	my ($self, $domain) = @_;

	my @vals = ($domain);
	my @cols = ($self->{_domainCol});

	if (checkRecordExists($self, $self->{domain_table}, $self->{_domainCol}, $domain)) {
		die("[error] $domain already exists\n");
	}

	insertRecord($self, $self->{domain_table}, \@cols, \@vals)
		or die("[error] failure adding domain $domain\n");	
}
sub addUser
{
	# arguments
	my ($self, $values) = @_;
	
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
		die("[error] no email address supplied\n");
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
		die("[error] $email_prts[1] is not a valid domain for this server\n");
	}
	
	insertRecord($self, $self->{user_table}, $self->{_userCols}, $values) 
		or die("[error] failure adding user $email_addr\n");
}
sub modifyUser
{
	# arguments to take
	my ($self, $email_addr, $columns, $values) = @_;
	my $selector = $self->{_emailCol};
	updateRecord($self, $self->{user_table}, $selector, $email_addr, $columns, $values)
		or die("[error] failure to modify $email_addr\n");
}
sub delUser
{
	#arguments
	my ($self, $email_addr) = @_;
	deleteRecord($self, $self->{user_table}, $self->{_emailCol}, $email_addr)
		or die("[error] failed to remove $email_addr\n");
}
sub delDomain
{
	my ($self, $domain) = @_;
	deleteRecord($self, $self->{domain_table}, $self->{_domainCol}, $domain)
		or die("[error] failed to remove $domain\n");
}

sub delAlias
{
	my ($self, $alias) = @_;
	deleteRecord($self, $self->{alias_table}, $self->{_aliasCol}, $alias)
		or die("[error] failed to remove $alias\n");
}

sub modifyAlias
{
	my ($self, $alias, $columns, $values) = @_;
	my $selector = $self->{_aliasCol};

	updateRecord($self, $self->{alias_table}, $selector, $alias, $columns, $values)
		or die("[error] failure to modify $alias\n");
}
sub addForward
{
	my ($self, $source, $destination) = @_;
	my $selector = $self->{_emailCol};

	# make sure domain exists
	my @email_prts = split(/@/, $source);
	my @dst_prts = split(/@/, $source);
	if (!$email_prts[1]) {
		die("[error] $source is not a valid email\n");
	}
	if (!$dst_prts[1]) {
		die("[error] $destination is not a valid email\n");
	}

	if (!checkRecordExists($self, $self->{domain_table}, $self->{_domainCol}, $email_prts[1])) {
		die("[error] $email_prts[1] is not a valid domain for this server\n");
	}

	# check if mailbox exists
	if (checkRecordExists($self, $self->{user_table}, $self->{_emailCol}, $source)) {
		# set activate to 0 for user (stops recieving mail locally)
		deactivateMail($self, $source);
	}

	# add to the alias column
	insertRecord($self, $self->{alias_table}, $self->{_aliasCols}, [$source, $destination])
		or die("[error] failure adding alias $source\n");
}
sub activateMail
{
	my ($self, $email_addr) = @_;
	my $selector = $self->{_emailCol};
	# check if email addr exists in mailbox table
	if (!checkRecordExists($self, $self->{user_table}, $self->{_emailCol}, $email_addr)) {
		die("[error] $email_addr does not exist in the database\n");
	}

	# modify the record
	updateRecord($self, $self->{user_table}, $selector, $email_addr, ['active'], [1])
		or die("[error] failure to activate mailbox for $email_addr\n");	
}
sub deactivateMail
{
	my ($self, $email_addr) = @_;
	my $selector = $self->{_emailCol};
	# check if email addr exists in mailbox table
	if (!checkRecordExists($self, $self->{user_table}, $self->{_emailCol}, $email_addr)) {
		die("[error] $email_addr does not exist in the database\n");
	}

	# modify the record
	updateRecord($self, $self->{user_table}, $selector, $email_addr, ['active'], [0])
		or die("[error] failure to deactivate mailbox for $email_addr\n");	
}
########################### END POSTFIX #################################

#########################################################################
#			Password Hashing				#
#########################################################################
sub hash
{
	my ($self, $password, $type) = @_;
	my $hash;

	if (!$type) {
		die("[error] no type specified for hash()");
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
	print "[query] $query\n" if $self->{debug};

	if ($self->{_dbh}->do($query)) {
		print "[func] deleteRecord() success\n" if $self->{debug};
		return 1;
	}

	print "[func] deleteRecord() fail\n" if $self->{debug};
	return 0;
}

sub updateRecord
{
	#arguments to take
	my ($self, $table, $selector, $id, $columns, $values) = @_;

	my $tmp_string;
	my $update_string;

	# note: $columns, $values should be a ref to arrays
	
	# if the arrays aren't the same amount.. input is fudged throw an error
	if ($#$columns != $#$values) {
		print "[func] modifyRecord() fail :: number of columns supplied does not match number of values\n" if $self->{debug};
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

	print "[query] $query\n" if $self->{debug};

	# run the query
	if ($self->{_dbh}->do($query)) {
		print "[func] updateRecord() success\n" if $self->{debug};
		return 1;	# success
	}

	print "[func] updateRecord() fail\n";
	return 0;		# fail
}

sub insertRecord
{
	# arguments to take
	my ($self, $table, $columns, $values) = @_;

	my $column_string;
	my $value_string;
	my $query;

	# note: $columns, $values should be a ref to arrays
	
	# if the arrays aren't the same amount.. input is fudged throw an error
	if ($#$columns != $#$values) {
		print "[var] \@columns is @{$columns}\n";
		print "[var] \@values is @{$values}\n";
		print "[func] insertRecord() fail :: number of columns supplied does not match number of values\n" if $self->{debug};
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
	print "[query] $query\n";# if $self->{debug};

	# insert the record
	if ($self->{_dbh}->do($query)) {
		print "[func] insertRecord() success\n" if $self->{debug};
		return 1; 	# success
	}

	print "[func] insertRecord() fail\n" if $self->{debug};
	return 0;		# fail

}

sub checkRecordExists
{
	# arguments to take
	my ($self, $table, $column, $value) = @_;

	my $query = sprintf("SELECT COUNT(*) FROM %s WHERE %s = '%s'", $table, $column, $value);
	print "[query] checkign for record.. $query\n" if $self->{debug};
	my $dbh = $self->{_dbh};
	my $sth = $dbh->prepare($query);
	
	$sth->{"mysql_use_result"} = 1;

	if (!$sth) {
		die "Error: " . $dbh->errstr . "\n";
	}
	if (!$sth->execute()) {
		die "Error: " . $dbh->errstr . "\n";
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

1;
