#!/usr/bin/perl
use strict;
use lib '..';
use control;

my $control = new FreePanel::Control();
$control->setDebug(0);
my $httpd = $control->getHttpObj();
my $maild = $control->getMailObj();
my $named = $control->getDnsObj();
my $domain="example.com";
print "Adding new domain...................."; 
$named->addDomain($domain);
if ($named->checkDomains($domain) == -2) {
        print "ok!\n"
}
#if (-e $nsd->getZoneDir()."/$domain") {
#       print "ok!\n";
#}
else {
        print "dns conf file: ". $named->getNsdConfig();
        die "error :(\n";
}

print "Removing domain......................";
$named->removeDomain($domain);
if ($named->checkDomains($domain) == 1) {
        print "ok!\n";
}
#if (! -e $nsd->getZoneDir()."/$domain") {
#       print "ok!\n";
#}
else {
        die "error :(\n";
}


print "Adding new site......................";
$httpd->addSite($domain);
if (-e $httpd->getVhostDir()."/$domain") {
        print "ok!\n";
}
else {
        print "error\n";
}

print "Adding new web dir...................";
$httpd->addWebDir($domain);
if (-d $httpd->getWebDir()."/$domain") {
        print "ok!\n";
}
else { 
        die "error\n";
}

print "Disabling site.......................";
$httpd->disableSite($domain);
if (-e $httpd->getInactiveDir()."/$domain") {
        print "ok!\n";
}
else { 
        print "error\n";
}

print "Enabling site........................";
$httpd->enableSite($domain);
if (-e $httpd->getVhostDir()."/$domain") {
        print "ok!\n";
}
else { 
        print "error\n";
}

print "Removing site........................";
$httpd->removeSite($domain);
if (! -e $httpd->getVhostDir()."/$domain") {
        print "ok!\n";
}
else { 
        print "error\n";
}

print "Removing web dir.....................";
$httpd->removeWebDir($domain);
if (! -d $httpd->getWebDir($domain)."/$domain") {
        print "ok!\n";
}
else {
        print "error\n";
}

my $password = "password";
my $hash = $maild->hash($password,'md5crypt');
my $quota = 1024*1024*10; # 10 mb in bytes

$maild->dbConnect();
$maild->setAliasCols(['address', 'goto']);
$maild->setDomainCol('domain');
$maild->setUserCols(['name', 'username', 'quota', 'password']);
$maild->setEmailIdentifier('username');
#$maild->setAliasTable('alias');
#$maild->setDomainTable('domain');
#$maild->setUserTable('mailbox');
$maild->setAliasIdentifier('address');

print "Adding domain........................";
$maild->addDomain($domain);
print "ok!\n";

print "Adding user..........................";
$maild->addUser(['crazed', "afeid\@$domain", $quota, $hash]);
print "ok!\n";

print "Adding alias.........................";
$maild->addAlias('info@'.$domain, 'afeid@'.$domain);
print "ok!\n";

print "Modifying user.......................";
$maild->modifyUser('afeid@'.$domain, ['name', 'username'], ['allan', 'crazed@'.$domain]);
print "ok!\n";

print "Modifying alias......................";
$maild->modifyAlias('info@'.$domain, ['goto'], ['crazed@'.$domain]);
print "ok!\n";

print "Deleting user........................";
$maild->delUser('crazed@'.$domain);
print "ok!\n";

print "Deleting domain......................";
$maild->delDomain($domain);
print "ok!\n";

print "Deleting alias.......................";
$maild->delAlias('info@'.$domain);
print "ok!\n";

print "Add site sub.........................";
if ($control->newSite($domain,"1.1.1.1", "allan feid", "crazed", $quota, $hash)) {
	print "ok!\n";
}
else {
	print "error :(\n";
}

print "Removing site sub....................";
if ($control->removeSite($domain)) {
	print "ok!\n";
}
else {
	print "error :(\n";
}

# should implement this stuff in removeSite()
print "Cleaning up..........................";
$maild->delUser('crazed@'.$domain);
$maild->delAlias('webmaster@'.$domain);
print "ok!\n";

