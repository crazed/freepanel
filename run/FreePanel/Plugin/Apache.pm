#!/usr/bin/perl
package FreePanel::Plugin::Apache;
use strict;
use warnings;

sub default {
	my ($self, $app) = @_;
	my $tt = $app->{stash}{tt};
	my $vars = {};

	$tt->process('Apache/index.tt', $vars, \my $out);
	return $out;

}

sub add {
	my ($self, $app) = @_;
	my $tt = $app->{stash}{tt};
	my $vars = {};
	my $tt_file = 'Apache/new_vhost.tt';
	my $param = $app->{req}->parameters;

	# check for submit
	if (!$param->{submit}) {
		$tt->process($tt_file, $vars, \my $out);
		return $out;
	}

	# set the submitted vars
	$vars = {
		params	=> $param,
		error	=> {},
	};

        # process the data
        my $http = new FreePanel::Admin::Apache();
        my $check = $http->getValidateObj();


	# check for blank fields
	my $err = 0;

	if (!$param->{owner}) {
		$vars->{error}{owner} = "Owner cannot be blank.";
		$http->logger("$vars->{error}{owner}", $http->WEB);
		$err = 1;
	}
	if (!$param->{servername}) {
		$vars->{error}{servername} = "Domain cannot be blank.";
		$http->logger("$vars->{error}{servername}", $http->WEB);
		$err = 1;
	}
	
	if (!$check->is_validName($param->{servername}) && $param->{servername}) {
		$vars->{error}{servername} = "$param->{servername} is not valid input.";
		$http->logger("$vars->{error}{servername}", $http->WEB);
		$err = 1;
	}

	if ($check->is_active($param->{servername}, $http->getVhostDir()) && $param->{servername}) {
		$vars->{error}{servername} = "$param->{servername} already exists.";
		$http->logger("$vars->{error}{servername}", $http->WEB);
		$err = 1;
	}

	if ($param->{serveralias}) {
		$http->logger("aliases: $param->{serveralias}", $http->WEB);
		my @aliases = split(/ /, $param->{serveralias});
		for my $alias (@aliases) {
			$http->logger("checking '$alias'", $http->WEB);
			if (!$check->is_validName($alias)) {
				$http->logger("$alias is not valid", $http->WEB);
				$vars->{error}{serveralias} = "$alias is not valid input.";
				$err = 1;
			}
		}
	}

	if (!$err) {
		$vars->{message} = "$param->{servername} added successfully!";
		$http->logger("Form completed successfully, $param->{servername}", $http->WEB);
	}

	$tt->process($tt_file, $vars, \my $out);
	return $out;
}
1;
