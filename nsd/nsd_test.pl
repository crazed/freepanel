#!/usr/bin/perl
use strict;
use Nsd;

my $domain = "example.com";
my $nsd = new DP::Nsd();
$nsd->setDebug(0);

print "Adding new domain.............";
$nsd->addDomain($domain);
if ($nsd->checkDomains($domain) == -2) {
	print "ok!\n"
}
#if (-e $nsd->getZoneDir()."/$domain") {
#	print "ok!\n";
#}
else {
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
