package FreePanel::Plugin::Root;

use strict;
use warnings;

sub default {
    my ($self,$app) = @_;

    my $tt = $app->{stash}{tt};

    my $vars = {};
    
    $vars->{vars} = FreePanel::Base::Misc->getvars($app);


    $tt->process('index.tt',$vars,\my $out) or return $tt->error();

    return $out;
}
1;
