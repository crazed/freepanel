#!/usr/bin/perl
use strict;
use warnings;

# welcome to freepanel
use FreePanel;
use FreePanel::Admin::Apache;

#my $fp = FreePanel->new( );
#print $fp->config;
#my $ref = $fp->get_config();
#$print $ref->{global}{log_file};

my $apache = FreePanel::Admin::Apache->new();
print "Vhost dir: ".$apache->get_vhostdir."\n"
