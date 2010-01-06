#!/usr/bin/perl

use FreePanel;
use lib '../modules/admin';
use control;

my $control = new FreePanel::Control();

my $app = FreePanel->new(
    map => {
        home => {
            plugin => 'Home',
	    methods => [ qw/ default go / ],

        },
        root => {
            plugin => 'Home',
	    methods => [ qw/ default go /],
        },
    },
    control => $control,
);

$app->setup();

