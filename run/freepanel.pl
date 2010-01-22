#!/usr/bin/perl

use strict;
use warnings;

use FreePanel;
use Template;
use FindBin qw($Bin);

my $tt = Template->new({
	INCLUDE_PATH => './templates',
	INTERPOLATE => 1,
}) or die "$Template::ERROR\n";

my $app = FreePanel->new(
    
    PLUGINS => [ @INC, $Bin ],
    
    404     => 'FreePanel::Plugin::My404',
    AUTH    => 'FreePanel::Plugin::MyAuth',

);

my $admin = FreePanel::Admin->new();

$app->stash(
    #config => FreePanel::Config->getConfigs(),
	tt		=> $tt,
	admin		=> $admin,
);

$app->dispatch(

    root => {
        #plugin => 'FreePanel::Plugin::Status',
		plugin => 'FreePanel::Plugin::NewSite',
        methods => [qw/ default go /],
    },
	new => {
		plugin	=> 'FreePanel::Plugin::NewSite',
		methods	=> [qw/ default go /],
	},
	status => {
		plugin => 'FreePanel::Plugin::Status',
		methods => [qw/ default /],
	},
	dns => {
		plugin => 'FreePanel::Plugin::DNS',
		methods => [qw/ default add /],
	},
);
$app->setup;
    
