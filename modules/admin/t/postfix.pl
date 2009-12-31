#!/usr/bin/perl
use strict;
use postfix;
#use Crypt::PasswdMD5 qw(unix_md5_crypt);

my $postfix = new admin::postfix();

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

print "\n[info] adding domain test.net\n";
$postfix->addDomain('test.net');
my $hash = $postfix->hash($password, 'md5crypt');
print "\n[info] adding email: afeid\@test.net, name: crazed, quota: $quota_bytes, hash: $hash\n";
$postfix->addUser(['crazed', 'afeid@test.net', $quota_bytes, $hash]);
print "\n[info] adding alias address: info\@test.net, goto: afeid\@test.net\n";
$postfix->addAlias('info@test.net', 'afeid@test.net');
print "\n[info] modifying user afeid\@test.net. changing name: allan, username: crazed\@test.net\n";
$postfix->modifyUser('afeid@test.net', ['name', 'username'], ['allan', 'crazed@test.net']);
print "\n[info] modifying alias, changing goto: crazed\@test.net\n";
$postfix->modifyAlias('info@test.net', ['goto'], ['crazed@test.net']);
print "\n[info] deleting user crazed\@test.net\n";
$postfix->delUser('crazed@test.net');
print "\n[info] deleting domain test.net\n";
$postfix->delDomain('test.net');
print "\n[info] deleteing alias info\@test.net\n";
$postfix->delAlias('info@test.net');
