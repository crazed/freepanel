#!/usr/bin/perl
use strict;
use warnings;

# welcome to freepanel
use FreePanel;
use FreePanel::Admin::Apache;
use FreePanel::Admin::SSH;

#my $fp = FreePanel->new( );
#print $fp->config;
#my $ref = $fp->get_config();
#$print $ref->{global}{log_file};

my $apache = FreePanel::Admin::Apache->new();
print "Vhost dir: ".$apache->get_vhostdir."\n";
print "Inactive dir: ".$apache->get_inactivedir."\n";
print "Templaate: ".$apache->get_template."\n";
print "Web dir: ".$apache->get_webdir."\n";
print "Web uid: ".$apache->get_uid."\n";
print "Web gid: ".$apache->get_gid."\n";

print "adding a new vhost....";
if (!$apache->add_vhost('example.com')) {
	print "ok!\n";
}
print "removing a vhost......";
if (!$apache->rm_vhost('example.com')) {
	print "ok!\n";
}

print "attempting ssh........";
my $ssh = FreePanel::Admin::SSH->new();
my @array = ( { script => 'touch', args => 'a' }, { script => 'touch', args => 'b' }, { script => 'touch', args => 'c'} );
if (!$ssh->exec_helper('localhost', @array)) {
	print "ok!\n";
}
#my $channel = $ssh->connect('localhost');
#$channel->exec('touch hi');
