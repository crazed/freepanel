#!/usr/bin/perl
package DP::Nsd;
use strict;
sub new
{
	my $class = shift;
	my $self = { 
		config_file	=> 'domains.conf'
	};

	# load the configuration vars
	open (CONF, '<', $self->{config_file}) or die ("ERR: domains.conf file is missing.\n");
	my $config;
	my @arguments;
	while (<CONF>) {
		$config = $_;

		chomp($config);
		if ($config =~ /^\#./) {
			# line is comment skip it
			next;
		}
	
		@arguments = split(/=/, $config);		
		
		if ($arguments[0] =~ /^zones_dir$/) {
			$self->{zones_dir} = $arguments[1];
			next;
		}

		if ($arguments[0] =~ /^nsd_config$/) {
			$self->{nsd_config} = $arguments[1];
			next;
		}

		if ($arguments[0] =~ /^include_xfer$/) {
			$self->{include_xfer} = $arguments[1];
			next;
		}

		if ($arguments[0] =~ /^log_file$/) {
			$self->{log_file} = $arguments[1];
			next;
		}

		if ($arguments[0] =~ /^debug$/) {
			$self->{debug} = $arguments[1];
			next;
		}
	}
	close CONF;
	

	bless $self, $class;
	return $self;

}
#############
# functions #
#############
#///////////////////////////////////////////////#
# logIt("some text")				#
#	logs "some text" to constant LOG_FILE	#
#///////////////////////////////////////////////#
sub logIt{
	my ($self, $log) = @_;

	my ($sec, $min, $hour, $mday, $mon, 
		$year, $wday, $yday, $isdst)=localtime(time);

	open LOG, '>>', $self->{log_file};
	my $timestamp = sprintf("%02d-%02d-%4d %02d:%02d:%02d",
		$mon+1,$mday,$year+1900,$hour,$min,$sec);
	print LOG "$timestamp :: $log\n";
	close LOG;

}
#///////////////////////////////////////////////#
# addDomain("domain.com")			#
#	returns 1 on success, 0 on fail		#
#///////////////////////////////////////////////#
sub addDomain {
	my ($self, $domain) = @_;

	# check for errors
	if (checkDomains($self, $domain) != 1) {
		return 0;
	}

	my ($sec, $min, $hour, $mday, $mon, 
		$year, $wday, $yday, $isdst)=localtime(time);
	my $serial = sprintf("%4d%02d%02d00",
		$year+1900,$mon+1,$mday);
	print ("[*]:  Serial: $serial\n") if $self->{debug};	

	# add to nsd.conf
	open (NSD, '>>', $self->{nsd_config});
	print "[+]:  Adding $domain to nsd.conf..\n" if $self->{debug};
	print NSD "zone:\n\t";
	print NSD "name: \"$domain\"\n\t";
	print NSD "zonefile: \"$domain\"\n\t";
	print NSD "include: ".$self->{include_xfer}."\n\n";
	close NSD;

	# create zone file
	open(ZONE, '>', $self->{zones_dir}."/$domain");
	open(ZONE_T, '<', $self->{zones_dir}.'/template.zone');
	print "[+]:  Creating zone file $domain..\n" if $self->{debug};
	while(<ZONE_T>) {
		s/<DOMAIN>/$domain/;
		s/<SERIAL>/$serial/;
		print ZONE;
	}
	close ZONE_T;
	close ZONE;
	
	# log domain as added
	logIt($self, "$domain added");
	return 1; # success
}
#///////////////////////////////////////////////#
# removeDomain("domain.com")			#
#	returns 1 on success, 0 on fail		#
#///////////////////////////////////////////////#
sub removeDomain {
	my ($self, $domain) = @_;
	my $start_delete;
	my $end_delete;	

	# open the config file and load to array
	open (NSD, '<', $self->{nsd_config});
	my @config = <NSD>;
	close NSD;

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

		print "[!]:  $domain was not found in configuration file\n";
		return 0;
	}

	# undefine the lines to delete
	for my $i ($start_delete .. $end_delete) {
		undef($config[$i]);
	}

	# rewrite the file without the lines that needed to be removed
	open (NSD, '>', $self->{nsd_config});
	foreach my $line (@config) {
		print NSD $line if $line;
	}
	close NSD;
	print "[-]:  $domain was removed from ". $self->{nsd_config} ."\n" if $self->{debug};

	# remove the zone file
	if (-e $self->{zones_dir}."/$domain") {
		unlink($self->{zones_dir}."/$domain");
		print "[-]:  $domain zone file was removed\n" if $self->{debug};
	}
		

	return 1;
}

#///////////////////////////////////////////////#
# checkDomains("domain.com")			#
#	returns 1 on success, 0 on fail		#
#///////////////////////////////////////////////#
	## possible outcomes:
	# 	1, domain is fine to create
	#	0, missing from config file
	#	-1, zone file does not exist
	#	-2, zone file and config file missing

sub checkDomains {
	my ($self, $domain) = @_;
	my $err = 1;

	# domain can only have '-', a-z, 0-9. 
	# must have at least 2 letters for tld
	if ($domain !~ /^([-a-z0-9]+\.[a-z]{2,})/) {
		print "[!]:  $domain is not a valid domain\n";			
		return 0;
	}
	
	# verify the zone doesn't already exist
	if (-e $self->{zones_dir}."/$domain") {
		print "[!]:  $domain zone file exists already\n" if $self->{debug};		
		$err = -1;
	}

	# look through the nsd configuration for zone
	# 	name: "domain.com"
	open (NSD, '<', $self->{nsd_config});
	while (<NSD>) {
		#print $_;
		chomp ($_);
		if ($_ =~ /name\: \"$domain\"/) {
			print "[!]:  $domain exists in " . $self->{nsd_config} . " configuration file\n" if $self->{debug};
			$err--;
		}	
	}

	return $err;
	
}

sub setDebug {
	my ($self, $value) = @_;
	$self->{debug} = $value;
	return $self->{debug};
}
1;
