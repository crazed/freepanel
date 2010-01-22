package FreePanel::Plugin::NewSite;
use strict;
use warnings;

sub default {
	my ($self, $app) = @_;
	my $tt = $app->{stash}{tt};

	my $param = $app->{req}->parameters;

	my $admin = FreePanel::Admin->new();

	my $vars = {};
	$tt->process('add_client.tt', $vars, \my $out);
	return $out;
}
sub go {
	my ($self, $app) = @_;
	my $tt = $app->{stash}{tt};
	my $param = $app->{req}->parameters;

	my $vars = {
		first_name 	=> $param->{first_name},
		last_name	=> $param->{last_name},
		email		=> $param->{email},
		domain		=> $param->{domain},
		user		=> $param->{account},
		password	=> $param->{password},
		access		=> $param->{access},
	};

	$tt->process('print_vals.tt', $vars, \my $o);
	return $o;
}
1;
