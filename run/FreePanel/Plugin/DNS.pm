#!/usr/bin/perl
package FreePanel::Plugin::DNS;
use strict;
use warnings;

####################################################################
## DNS Plugin
####################################################################
#
# Goals
# 	- allow the following functionality via an html form
# 		* add new zones
# 		* remove zones
# 		* modify zones (adding/removing/modifying records)
#
####################################################################
# Version: 0.01
# Author: Allan Feid
# For use with FreePanel

###################################
# default
# 
# use: display page with options to 
# add new zone, modify zone, 
# or remove zone
###################################
sub default {
	my ($self, $app) = @_;
	my $tt = $app->{stash}{tt};
	my $vars = {};

	$tt->process('dns_default.tt', $vars, \my $out);
	return $out;

}

sub add {
	my ($self, $app) = @_;
	my $tt = $app->{stash}{tt};
	my $vars = {};
	my $param = $app->{req}->parameters;

	# check for submit
	if (!$param->{submit}) {
		$tt->process('dns_addform.tt', $vars, \my $out);
		return $out;
	}
	
	# set the submitted vars
	$vars->{owner} = $param->{owner};
	$vars->{ip_addr} = $param->{ip_addr};
	$vars->{domain} = $param->{domain};

	# check for blank fields
	my $err = 0;
	if (!$param->{owner}) {
		$vars->{error_owner} = "Owner cannot be blank.";
		$err = 1;
	}
	if (!$param->{ip_addr}) {
		$vars->{error_ip} = "IP address cannot be blank.";
		$err = 1;
	}
	if (!$param->{domain}) {
		$vars->{error_domain1} = "Domain cannot be blank.";
		$err = 1;
	}

	# process data
	my $admin = $app->{stash}{admin};
	my $dns = $admin->getDnsObj();
	my $check = $dns->getValidateObj();

	#if (!$dns->checkZone($param->{domain})) {
	if (!$check->is_validDomain($param->{domain}) && $param->{domain}) {
		$vars->{error_domain1} = "$param->{domain} is not a valid domain name.";
		$err = 1;
	}

	if (!$check->is_newZoneFile($param->{domain}, $admin->getZoneDir) && $param->{domain}) {
		$vars->{error_domain2} = "$param->{domain} already has a zone file.";
		$err = 1;
	}

	#if (!$dns->validateHost($param->{ip_addr})) {
	if (!$check->is_validHost($param->{ip_addr}) && $param->{ip_addr}) {
		$vars->{error_ip} = "$param->{ip_addr} is not a valid host address.";
		$err = 1;
	}

	if (!$err) {
		$dns->addZone($param->{domain}, $param->{ip_addr});
		$vars->{message} = "$param->{domain} has been added successfully!";
	}

	$tt->process('dns_addform.tt', $vars, \my $out);
        return $out;


}


1;
