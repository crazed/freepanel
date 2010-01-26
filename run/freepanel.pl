#!/usr/bin/perl

use strict;
use warnings;

use FreePanel;
use Template;

##### CHANGE ME ######################
my $domain = 'example.org';
my $docroot = '/change/this/';
######################################


my $tt = Template->new({
    INCLUDE_PATH => './templates',
    INTERPOLATE  => 1,
}) || die "$Template::ERROR\n";


my $app = FreePanel->new(
    
    PLUGINS => [ @INC, './' ],
    NOLOAD  => [ ],
    404     => 'FreePanel::Plugin::My404', 
    AUTH    => 'FreePanel::Plugin::MyAuth',

);

$app->stash(
    config => FreePanel::Config::Basic->config("./etc/freepanel/freepanel.conf"),
    tt     => $tt,
);

$app->dispatch(

    root => {
        plugin => 'FreePanel::Plugin::Root',
        methods => [qw/ default /],
        session => [qw/ username class /],
    },
    test => {
        plugin => 'FreePanel::Plugin::Test',
        methods => [qw/ default /],
        session => [qw/ username class /],
    },
);
$app->setup(
    session => {
        store => {
            class => 'File',
            args => { dir => './tmp' },
        },
        state => {
            class => 'Cookie',
            args => {
                name => 'FreePanel',
                path => '/',
                domain => $domain,
            },
        }
    },
    static => {
        regexp => qr{^/(robots.txt|favicon.ico|(?:skins|css|js|images)/.+)$},
        docroot => $docroot,
    },
);

    
