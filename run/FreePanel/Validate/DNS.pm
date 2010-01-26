#!/usr/bin/perl
package FreePanel::Validate::DNS;
use strict;
use warnings;

#######################################
# Validate
#
# Purpose: provide common validation
# sub routines for DNS related things
#######################################

sub new {
	my $class = shift;
	my $self = {};

	return bless $self, $class;
}

sub is_validDomain {
	my ($self, $domain) = @_;

	# domain can only have '-', a-z, 0-9
	# must have at least 2 letters for tld
	return $domain =~ /^([-a-z0-9]+\.[a-z]{2,})/;
}

sub is_newZoneFile {
	my ($self, $domain, $zone_dir) = @_;
	return ! -e "$zone_dir/$domain";
}

sub is_validName {
        my ($self, $name) = @_;
        return $name =~ /^([-@.a-z0-9]+)$/;
}

sub is_validHost {
        my ($self, $host) = @_;
        return $host =~ /^(\d+)(\.\d+){3}$/;
}

sub checkDnsConfig {
	my ($self, $domain, $config_file) = @_;

	open my $fh, '<', $config_file;

	while (<$fh>) {
		chomp($_);
		if ($_ =~ /name\: \"$domain\"/) {
			return 0;
		}
	}

	return 1;
}
1;
