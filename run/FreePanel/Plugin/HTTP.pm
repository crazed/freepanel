#!/usr/bin/perl
package FreePanel::Plugin::HTTP;
use strict;
use warnings;

sub default {

}

sub add {
	my ($self, $app) = @_;
	my $tt = $app->{stash}{tt};
	my $vars = {};
	my $tt_file = 'http_addform.tt';
	my $param = $app->{req}->parameters;

	# check for submit
	if (!$param->{submit}) {
		$tt->process($tt_file, $vars, \my $out);
		return $out;
	}

	# set the submitted vars
	$vars->{owner} = $param->{owner};
	$vars->{domain} = $param->{domain};
	$vars->{aliases} = $param->{aliases};

	# check for blank fields
	my $err = 0;

	if (!$param->{owner}) {
		$vars->{error_owner} = "Owner cannot be blank.";
		$err = 1;
	}
	if (!$param->{domain}) {
		$vars->{error_domain} = "Domain cannot be blank.";
		$err = 1;
	}
	
	# process the data
	my $admin = $app->{stash}{admin};
	my $http = $admin->getHttpObj();
	my $check = $http->getValidateObj();

	if (!$check->is_validName($param->{domain}) && $param->{domain}) {
		$vars->{error_domain} = "$param->{domain} is not valid input.";
		$err = 1;
	}

	if ($check->is_active($param->{domain}, $http->getVhostDir()) && $param->{domain}) {
		$vars->{error_domain} = "$param->{domain} already exists.";
		$err = 1;
	}

	if ($param->{aliases}) {
		$admin->logger("aliases: $param->{aliases}", $admin->FULL_DEBUG);
		my @aliases = split(/ /, $param->{aliases});
		for my $alias (@aliases) {
			$admin->logger("checking '$alias'", $admin->FULL_DEBUG);
			if (!$check->is_validName($alias)) {
				$admin->logger("$alias is not valid", $admin->FULL_DEBUG);
				$vars->{error_aliases} = "$alias is not valid input.";
				$err = 1;
			}
		}
	}

	if (!$err) {
		$vars->{message} = "$param->{domain} added successfully!";
	}

	$tt->process($tt_file, $vars, \my $out);
	return $out;
}
1;
