#!/usr/bin/perl
use strict;

# test all functions for httpd.pm
use Apache;

my $domain = "example.com";
my $httpd = new admin::apache();
$httpd->setDebug(0);

print "Adding new site.................";
$httpd->addSite($domain);
if (-e $httpd->getVhostDir()."/$domain") {
	print "ok!\n";
}
else {
	print "error\n";
}

print "Adding new web dir..............";
$httpd->addWebDir($domain);
if (-d $httpd->getWebDir()."/$domain") {
	print "ok!\n";
}
else {
	die "error\n";
}

print "Disabling site..................";
$httpd->disableSite($domain);
if (-e $httpd->getInactiveDir()."/$domain") {
	print "ok!\n";
}
else {
	print "error\n";
}

print "Enabling site...................";
$httpd->enableSite($domain);
if (-e $httpd->getVhostDir()."/$domain") {
	print "ok!\n";
}
else {
	print "error\n";
}

print "Removing site...................";
$httpd->removeSite($domain);
if (! -e $httpd->getVhostDir()."/$domain") {
	print "ok!\n";
}
else {
	print "error\n";
}

print "Removing web dir................";
$httpd->removeWebDir($domain);
if (! -d $httpd->getWebDir($domain)."/$domain") {
	print "ok!\n";
}
else {
	print "error\n";
}

		# VALID CONFIGUATION OPTIONS
		# 	vhost_template
		#	vhost_dir
		#	inactive_dir
		#	web_dir
		#	log_file
		#	debug	
