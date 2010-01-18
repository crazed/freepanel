#!/usr/bin/perl
package FreePanel::Admin::Nsd;
use FreePanel::Config;
use strict;
use base qw(FreePanel::Config);
sub new
{
	my $class = shift;
	my $self = $class->SUPER::new();
	
	bless $self, $class;

	$self->logger("class: FreePanel::Admin::Nsd object created.", $self->FULL_DEBUG);
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

	open LOG, '>>', $self->getLogFile();
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
	my ($self, $domain, $ip_addr) = @_;
	$self->logger("function: addDomain($domain, $ip_addr) called.", $self->FUNC_CALL);

	# check for errors
	if (checkDomains($self, $domain) != 1) {
		return 0;
	}

	my ($sec, $min, $hour, $mday, $mon, 
		$year, $wday, $yday, $isdst)=localtime(time);
	my $serial = sprintf("%4d%02d%02d00",
		$year+1900,$mon+1,$mday);
	$self->logger("  Serial: $serial\n") if $self->getDebug();	

	# add to nsd.conf
	open (NSD, '>>', $self->getNsdConfig());
	print NSD "zone:\n\t";
	print NSD "name: \"$domain\"\n\t";
	print NSD "zonefile: \"$domain\"\n\t";
	#print NSD "include: ".$self->{include_xfer}."\n\n";

	close NSD;

	$self->logger("added $domain to $self->getNsdConfig.", $self->INFO);

	# create zone file
	open(ZONE, '>', $self->getZoneDir()."/$domain");
	open(ZONE_T, '<', $self->getZoneTemplate());

	while(<ZONE_T>) {
		s/<DOMAIN>/$domain/;
		s/<SERIAL>/$serial/;
		s/<IP_ADDR>/$ip_addr/;
		print ZONE;
	}

	close ZONE_T;
	close ZONE;

	$self->logger("created zone file for $domain. Serial: $serial", $self->INFO);
	
	# log domain as added
	#logIt($self, "$domain added");
	return 1; # success
}
#///////////////////////////////////////////////#
# removeDomain("domain.com")			#
#	returns 1 on success, 0 on fail		#
#///////////////////////////////////////////////#
sub removeDomain {
	my ($self, $domain) = @_;
	$self->logger("function: removeDomain($domain) called.", $self->FUNC_CALL);
	my $start_delete;
	my $end_delete;	

	# open the config file and load to array
	open (NSD, '<', $self->getNsdConfig());
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

		$self->logger("$domain was not found in configuration file ($self->getNsdConfig).", $self->ERROR);
		return 0;
	}

	# undefine the lines to delete
	for my $i ($start_delete .. $end_delete) {
		undef($config[$i]);
	}

	# rewrite the file without the lines that needed to be removed
	open (NSD, '>', $self->getNsdConfig());
	foreach my $line (@config) {
		print NSD $line if $line;
	}
	close NSD; 

	$self->logger("$domain was removed from ". $self->getNsdConfig(), $self->INFO);

	# remove the zone file
	if (-e $self->getZoneDir()."/$domain") {
		unlink($self->getZoneDir()."/$domain");
		$self->logger("$domain zone file was removed.", $self->INFO);
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
	$self->logger("function: checkDomains($domain) called.", $self->FUNC_CALL);
	my $err = 1;

	# domain can only have '-', a-z, 0-9. 
	# must have at least 2 letters for tld
	if ($domain !~ /^([-a-z0-9]+\.[a-z]{2,})/) {
		$self->logger("$domain is not a valid domain.", $self->WARNING);			
		return 0;
	}
	
	# verify the zone doesn't already exist
	if (-e $self->getZoneDir()."/$domain") {
		$self->logger("$domain zone file exists already", $self->WARNING);
		$err = -1;
	}

	# look through the nsd configuration for zone
	# 	name: "domain.com"
	open (NSD, '<', $self->getNsdConfig());
	while (<NSD>) {
		#print $_;
		chomp ($_);
		if ($_ =~ /name\: \"$domain\"/) {
			$self->logger("$domain exists in " . $self->getNsdConfig() . " configuration file", $self->WARNING);
			$err--;
		}	
	}

	return $err;
	
}

sub restart {
	my ($self) = @_;
	$self->logger("function: restart called. (nsd)", $self->FUNC_CALL);
	# restart NSD 
	$self->logger("NSD is being restarted..", $self->INFO);
	return 1;
}
1;
