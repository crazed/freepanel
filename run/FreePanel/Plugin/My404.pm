package FreePanel::Plugin::My404;

use strict;
use warnings;

sub default {

    my ($self,$app) = @_;

    my $tt = $app->{stash}{tt};

    $tt->process('404.tt', '', \my $out) or return $tt->error();

    return $out;
}
1;
