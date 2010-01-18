#!/usr/bin/perl
use strict;
use lib '../..';
use FreePanel::Admin::Postfix;
#use Crypt::PasswdMD5 qw(unix_md5_crypt);

my $postfix = new FreePanel::Admin::Postfix();

my $quota_bytes = 1024*1024*10;
my $password = "password";


$postfix->dbConnect();
$postfix->setAliasCols(['address', 'goto']);
$postfix->setDomainCol('domain');
$postfix->setUserCols(['name', 'username', 'quota', 'password']);
$postfix->setEmailIdentifier('username');
$postfix->setAliasTable('alias');
$postfix->setDomainTable('domain');
$postfix->setUserTable('mailbox');
$postfix->setAliasIdentifier('address');

print "Adding domain..............................";
if ($postfix->addDomain('test.net')) {
	print "ok!\n";
} else {
	print "error\n";
}

my $hash = $postfix->hash($password, 'md5crypt');
print "Adding email...............................";
if ($postfix->addUser(['crazed', 'afeid@test.net', $quota_bytes, $hash])) {
	print "ok!\n";
} else {
	print "error\n";
}

print "Adding alias address.......................";
if ($postfix->addAlias('info@test.net', 'afeid@test.net')) {
	print "ok!\n";
} else {
	print "error\n";
}

print "Modifying user.............................";
if ($postfix->modifyUser('afeid@test.net', ['name', 'username'], ['allan', 'crazed@test.net'])) {
	print "ok!\n";
} else {
	print "error\n";
}

print "Modifying alias............................";
if ($postfix->modifyAlias('info@test.net', ['goto'], ['crazed@test.net'])) {
	print "ok!\n";
} else {
	print "error\n";
}

print "Deleting user..............................";
if ($postfix->delUser('crazed@test.net')) {
	print "ok!\n";
} else {
	print "error\n";
}
print "Deleting domain............................";
if ($postfix->delDomain('test.net')) {
	print "ok!\n";
} else {
	print "error\n";
}
print "Deleteing alias............................"; 
if ($postfix->delAlias('info@test.net')) {
	print "ok!\n";
} else {
	print "error\n";
}
