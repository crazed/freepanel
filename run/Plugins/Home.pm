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

1
