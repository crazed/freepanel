#!/usr/bin/perl
package FreePanel::Admin::NSD;
use strict;
use warnings;
use DNS::ZoneParse;
use base qw/FreePanel/;

### Constructor
sub new {
	my $class = shift;
	my $self = $class->SUPER::new();

	bless $self, $class;
	$self->logger("FreePanel::Admin::NSD object created.", $self->FULL_DEBUG);
	return $self;
}

### General methods
sub add_zone {
	my ($self, $domain, $ip_addr) = @_;

	my $err;
	$err = $self->is_validfqdn($domain);
	if (!$err) {
		$self->logger("$domain is not a valid FQDN.", $self->ERROR);
		return $err;
	}
	$err = $self->is_newzone($domain);
	if ($err) {
		$self->logger("$domain already exists.", $self->ERROR);
		return $err;
	}
	$err = $self->is_validip($ip_addr);
	if (!$err) {
		$self->logger("$ip_addr is not a valid IP address.", $self->ERROR);
		return $err;
	}

	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)=localtime(time);
	my $serial = sprintf("%4d%02d%02d00",$year+1900,$mon+1,$mday);

	# add the domain to our nsd configuration file
	open my $config, '>>', $self->get_nsdconfig or die $!;
	print $config "zone:\n\t";
	print $config "name: \"$domain\"\n\t";
	print $config "zonefile: \"$domain\"\n";
	close $config;

	$self->logger("added $domain to ".$self->get_nsdconfig.".", $self->INFO);

	# open the template and create a new zone file for $domain with $ip_addr	
	open my $new_zone, '>', $self->get_zonedir."/$domain" or die $!;
	open my $template, '<', $self->get_template or die $!;
	my @template = <$template>;
	close $template;
	foreach my $line (@template) {
		$line =~ s/<DOMAIN>/$domain/;
                $line =~ s/<SERIAL>/$serial/;
                $line =~ s/<IP_ADDR>/$ip_addr/;
		print $new_zone $line;
	}
	close $template;

	$self->logger("created zone file for $domain. Serial: $serial", $self->INFO);
	return 0;
}
sub rm_zone {
	my ($self, $domain) = @_;
	my $start_delete;
	my $end_delete;

	# open the config file and load to array
	open my $nsdconfig, '<', $self->get_nsdconfig or die $!;
	my @config = <$nsdconfig>;
	close $nsdconfig;

	# initialize end_delete to be the last index
	$end_delete = $#config;

	# loop array, look for name: "domain.com"
	for my $i (0 .. $#config) {
		if ($config[$i] =~ /name\: \"$domain\"/) {

			# loop backwards from match, find zone: line
			for my $j (reverse 0 .. $i) {
				if ($config[$j] =~ /zone\:/) {
					$start_delete = $j;
					last;
				}
			}
			# loop forward from match to find zone: line
			for my $k ($i .. $#config) {
				if ($config[$k] =~ /zone\:/) {
					$end_delete = $k-1;
					last;
				}
			}
			last;
		}
					
				
	}

	# if neither are defined, no match was found
	if (!defined($start_delete)) {
		$self->logger("$domain was not found in configuration file.", $self->ERROR);
		return $self->CONFIG_NO_EXIST;
	}

	# undefine the lines to delete
	for my $i ($start_delete .. $end_delete) {
		undef($config[$i]);
	}

	# rewrite the file without the lines that needed to be removed
        open NSD, '>', $self->get_nsdconfig or die $!;
	foreach my $line (@config) {
		print NSD $line if $line;
	}
	close NSD; 

	$self->logger("$domain was removed from ". $self->get_nsdconfig.".", $self->INFO);

	# remove the zone file
	if (-e $self->get_zonedir."/$domain") {
		unlink($self->get_zonedir."/$domain");
		$self->logger("$domain zone file was removed.", $self->INFO);
	}
	return 0;
}

### Verification methods

# domain can only have '-', a-z, 0-9
# must have at least 2 letters for tld
sub is_validfqdn {
	my ($self, $domain) = @_;
	return $domain =~ /^[-a-z0-9]+\.[a-z]{2,}$/;
}

# names are valid record types
sub is_validname {
	my ($self, $name) = @_;
	return $name =~ /^[-@.a-z0-9]+$/;
}

sub is_validip {
	my ($self, $ip_addr) = @_;
	return $ip_addr =~ /^(\d+)(\.\d+){3}$/;
}

# check's nsd.conf and zone's directory to verify
# that the domain passed isn't already configured
sub is_newzone {
	my ($self, $domain) = @_;
	my $zone_dir = $self->get_zonedir;
	my $config_file = $self->get_nsdconfig;
	open my $config, '<', $config_file;
	while (<$config>) {
		chomp $_;
		if (/name\: \"$domain\"/) {
			return $self->ZONE_CONFIG_EXISTS;
		}
	}

	if (-e "$zone_dir/$domain") {
		return $self->ZONE_FILE_EXISTS;
	}

	return 0;
}

### Accessor methods
sub get_zonedir {
	my $self = shift;
	return $self->{_conf}->{nsd}{zones_dir};
}
sub get_template {
	my $self = shift;
	return $self->{_conf}->{nsd}{zone_template};
}
sub get_nsdconfig {
	my $self = shift;
	return $self->{_conf}->{nsd}{nsd_config};
}
1;
