package FreePanel::Plugin::Test;

use strict;
use warnings;


sub default {

    my ($self,$app) = @_;

    my $tt = $app->{stash}{tt};

    my $vars = {
        vars => FreePanel::Base::Misc->getvars($app),
    };

    $tt->process('test.tt', $vars, \my $out) or return $tt->error();

    return $out;
}
1;
