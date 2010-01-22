#!/usr/bin/perl
use strict;
use lib '../..';
use FreePanel::Admin::Nsd;

my $domain = "example.com";
my $nsd = new FreePanel::Admin::Nsd();
$nsd->setDebug(3);


print "Deleting an MX record.........";
if ($nsd->delMX($domain, "smtp.google.com")) {
	print "ok!\n";
} else {
	print "error\n";
}
exit();

print "Adding a TXT record...........";
if ($nsd->addTXT($domain, "@", "spf=waht?")) {
	print "ok!\n";
} else {
	print "error\n";
}

print "Deleting a TXT record.........";
if ($nsd->delTXT($domain, "spf=waht?")) {
	print "ok!\n";
} else {
	print "error\n";
}

print "Removing domain...............";
$nsd->removeDomain($domain);
if ($nsd->checkZone($domain) == 1) {
	print "ok!\n";
}
#if (! -e $nsd->getZoneDir()."/$domain") {
#	print "ok!\n";
#}
else {
	die "error :(\n";
}
