package Home;

sub run {
    my ($self,$app) = @_;
    my $vars = {
        name => "Mike",
        debt => "a million dollars",
        deadline => "NOW",
    };

    $app->{tt}->process('home.tt',$vars,\my $out);

    return $out;
}

sub foo {
    my ($self,$app) = @_;

    # retrieve GET or POST parameters
    my $param = $app->{req}->parameters;


    # the <form> is blank, so return the foo.tt template, without
    # any variables to display.. because they are none
    if (!exists $param->{firstname} or !exists $param->{lastname}) {
        my $vars = {
            name => "Mike",
        };
        $app->{tt}->process('foo.tt',$vars, \my $out);
        return $out;
    }

    # we got to here because the <form> was processed with input
    # variables. So now return the foo_done.tt template, and
    # use the variables we retrieved from the form.
    else {
        my $vars = {
            name => "Mike",
            username => $param->{firstname},
            lastname => $param->{lastname},
        };
        $app->{tt}->process('foo_done.tt',$vars, \my $out);
        return $out;
    }
}
1;
