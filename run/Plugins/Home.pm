package Home;
use strict;
use warnings;
use lib '../modules/admin';
use control;

sub default {
	my ($self,$app) = @_;
	my $control = $app->{app}{control};
	my $vars = {
		name => "Mike",
		debt => "a million dollars",
		deadline => "NOW",
		dns => $control->getNameService(),
		mail => $control->getMailService(),
		http => $control->getHttpService(),
		debug => $control->getDebug(),
		vhost_dir => $control->getVhostDir(),
		vhost_template => $control->getVhostTemplate(),
	};

	$app->{tt}->process('home.tt',$vars,\my $out);
	
	return $out;
}

sub go {
	my ($self, $app) = @_;

	# grab the form variables
	my $params = $app->{req}->parameters;
	#my $control = new FreePanel::Control();
	my $control = $app->{app}{control};
	
	# run some validation tests
	if (validateForm($self, $params)) {

		# needed params:
		# 	domain
		# 	ip_addr
		#	full name
		#	user
		#	hashed password
		my $hash = $control->getMailObj()->hash($params->{password},'md5crypt');

		$control->newSite(
			$params->{domain},
			$params->{ip_addr},
			$params->{full_name},
			$params->{user},
			$hash);

		# display some info user
		$app->{tt}->process('example.tt',$params, \my $out);
		return $out;
	}

	return 1;
	
}

sub validateForm {
	my ($self, $vars) = @_;

	return 1;
}

1;
