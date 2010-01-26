package FreePanel::Base::Misc;

use strict;
use warnings;


sub getvars {

    my ($self,$app) = @_;

    my $vars = {
        session => $app->{req}->session->as_hashref,
        param   => $app->{req}->parameters,
        config  => $app->{stash}{config},
    };
    return $vars;
}
1;
        
