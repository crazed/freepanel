#!/usr/bin/perl
use strict;
use lib '../..';
use FreePanel::Admin::Nsd;

my $domain = "example.com";
my $nsd = new FreePanel::Admin::Nsd();
#$nsd->setDebug(0);

print "Adding new domain.............";
$nsd->addDomain($domain);
if ($nsd->checkDomains($domain) == -2) {
	print "ok!\n"
}
#if (-e $nsd->getZoneDir()."/$domain") {
#	print "ok!\n";
#}
else {
	print "nsd conf file: ". $nsd->getNsdConfig();
	die "error :(\n";
}

print "Removing domain...............";
$nsd->removeDomain($domain);
if ($nsd->checkDomains($domain) == 1) {
	print "ok!\n";
}
#if (! -e $nsd->getZoneDir()."/$domain") {
#	print "ok!\n";
#}
else {
	die "error :(\n";
}
