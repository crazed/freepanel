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

$app->stash(
    #config => FreePanel::Config->getConfigs(),
	tt		=> $tt,
);

$app->dispatch(

    root => {
        plugin => 'FreePanel::Plugin::Status',
        methods => [qw/ default /],
    },
);
$app->setup;
    
