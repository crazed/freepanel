#!/usr/bin/perl
package FreePanel::Admin::Nsd;
use FreePanel::Config;
use DNS::ZoneParse;
use FreePanel::Validate::DNS;
use strict;
use warnings;
use base qw(FreePanel::Config);
sub new
{
	my $class = shift;
	my $self = $class->SUPER::new();
	
	bless $self, $class;
	$self->setValidateObj(FreePanel::Validate::DNS->new);

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
	print LOG "$log\n";
	close LOG;

}
#///////////////////////////////////////////////#
# addDomain("domain.com")			#
#	returns 1 on success, 0 on fail		#
#///////////////////////////////////////////////#
sub addZone {
	my ($self, $domain, $ip_addr) = @_;
	$self->logger("function: addDomain($domain, $ip_addr) called.", $self->FUNC_CALL);

	# check for errors
	my $check = $self->getValidateObj();

	if (!$check->is_validDomain($domain)) {
		$self->logger("$domain is not a valid domain name.", $self->ERROR);
		return 0;
	}

	if (!$check->is_newZoneFile($domain, $self->getZoneDir)) {
		$self->logger("$domain already exists in ".$self->getZoneDir, $self->ERROR);
		return 0;
	}

	if (!$check->checkDnsConfig($domain, $self->getNsdConfig)) {
		$self->logger("$domain already exists in ".$self->getNsdConfig, $self->ERROR);
		return 0;
	}

	## deprecated code
	#if (checkZone($self, $domain) != 1) {
	#	return 0;
	#}

	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)=localtime(time);
	my $serial = sprintf("%4d%02d%02d00",
		$year+1900,$mon+1,$mday);

	# add to nsd.conf
	open my $fh, '>>', $self->getNsdConfig() 
		or die "FATAL: ".$self->getNsdConfig.": $!";
	print $fh "zone:\n\t";
	print $fh "name: \"$domain\"\n\t";
	print $fh "zonefile: \"$domain\"\n";
	#print $fh "include: ".$self->{include_xfer}."\n\n";

	close $fh;

	$self->logger("added $domain to ".$self->getNsdConfig.".", $self->INFO);

	# create zone file
	open ZONE, '>', $self->getZoneDir()."/$domain" 
		or die "FATAL: ".$self->getZoneDir()."/$domain: $!";
	open my $zone_t, '<', $self->getZoneTemplate()
		or die "FATAL: ".$self->getZoneTemplate().": $!";

	while(<$zone_t>) {
		s/<DOMAIN>/$domain/;
		s/<SERIAL>/$serial/;
		s/<IP_ADDR>/$ip_addr/;
		print ZONE;
	}

	close $zone_t;
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
	open NSD, '<', $self->getNsdConfig()
		or die "FATAL: ".$self->getNsdConfig().": $!";

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

		$self->logger("$domain was not found in configuration file (".$self->getNsdConfig.".).", $self->ERROR);
		return 0;
	}

	# undefine the lines to delete
	for my $i ($start_delete .. $end_delete) {
		undef($config[$i]);
	}

	# rewrite the file without the lines that needed to be removed
        open NSD, '>', $self->getNsdConfig()
                or die "FATAL: ".$self->getNsdConfig().": $!";

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
sub delA {
	my ($self, $domain, $name) = @_;
	$self->logger("function: delA($domain, $name)", $self->FUNC_CALL);

	# check that zone file exists
	my $check = $self->getValidateObj();
	if ($check->is_newZoneFile($domain, $self->getZoneDir)) {
		$self->logger("zone file for $domain does not exist.", $self->ERROR);
		return 0;
	}

	## deprecated code
	#if (!$self->checkZone($domain)) {
	#	return 0;
	#}

	# set the zone file name
	my $zonedb = $self->getZoneDir."/$domain";

	# find $name in the zone file and remove it
	my $zonefile = DNS::ZoneParse->new($zonedb);
	my $a_records = $zonefile->a();

	for my $i (0 .. $#$a_records) {
		if (@$a_records[$i]->{name} eq $name) {
			delete @$a_records[$i];
		}
	}

	$zonefile->new_serial();

	open my $fh, '>', $zonedb or die "FATAL: $zonedb: $!";
	print $fh $zonefile->output();
	close $fh;

	$self->logger("A record for $name deleted from $domain.", $self->INFO);

	return 1;
}
	
	
sub addA {
        my ($self, $domain, $name, $host) = @_;
	$self->logger("function: addA($domain, $name, $host)", $self->FUNC_CALL);

	# check if zone file even exists
	my $check = $self->getValidateObj();
        if ($check->is_newZoneFile($domain, $self->getZoneDir)) {
                $self->logger("zone file for $domain does not exist.", $self->ERROR);
                return 0;
        }

	if (!$check->is_validName($name)) {
		$self->logger("$name is not a valid name for DNS", $self->ERROR);
		return 0;
	}

	if (!$check->is_validHost($host)) {
		$self->logger("$host is not a valid host for an A record.", $self->ERROR);
		return 0;
	}


	## deprecated code
	#if (!$self->checkZone($domain)) {
	#	return 0;
	#}

	# make sure $name is valid and $host is a valid ip
	#if (!$self->validateName($name)) {
	#	$self->logger("$name is not a valid name for DNS", $self->VARIABLE);
	#	return 0;
	#}

	#if (!$self->validateHost($host)) {
	#	$self->logger("$host is not a valid IP address", $self->VARIABLE);
	#	return 0;
	#}

        my $zonedb = $self->getZoneDir."/$domain";

        my $zonefile = DNS::ZoneParse->new($zonedb);
        my $a_records = $zonefile->a();

        push (@$a_records, {
                name    => $name,
                class   => 'IN',
                host    => $host,
        });

        $zonefile->new_serial();

        open my $fh, '>', $zonedb or die "FATAL: $zonedb: $!";
        print $fh $zonefile->output();
        close $fh;

	$self->logger("$name IN AN $host added to $domain.", $self->INFO);

        return 1;
}

sub addMX {
        my ($self, $domain, $name, $host, $priority) = @_;
	$self->logger("function: addMX($domain, $name, $host, $priority)", $self->FUNC_CALL);

	# check zone file even exists
	my $check = $self->getValidateObj();
        if ($check->is_newZoneFile($domain, $self->getZoneDir)) {
                $self->logger("zone file for $domain does not exist.", $self->ERROR);
                return 0;
        }

	if (!$check->is_validName($name)) {
		$self->logger("$name is not a valid name for DNS", $self->ERROR);
		return 0;
	}

	if (!$check->is_validName($host)) {
		$self->logger("$host is not a valid host for an MX record.", $self->ERROR);
		return 0;
	}


	## deprecated code
	#if (!$self->checkZone($domain)) {
	#	return 0;
	#}

	# mx records don't use IP addresses, both must be names
        #if (!$self->validateName($name) or !$self->validateName($host)) {
        #        $self->logger("$name is not a valid name for DNS", $self->VARIABLE);
        #        return 0; 
        #}

        my $zonedb = $self->getZoneDir."/$domain";

        my $zonefile = DNS::ZoneParse->new($zonedb);
        my $mx_records = $zonefile->mx();

	# need some validation for $name and $host
	# checkHost(), checkName() ?, useful in all record subs

        push (@$mx_records, {
                host            => $host,
                priority        => $priority,
                name            => $name,
        });

        $zonefile->new_serial();

        open my $fh, '>', $zonedb or die "FATAL: $zonedb: $!";
        print $fh $zonefile->output();
        close $fh;

	$self->logger("$name IN MX $priority $host added to $domain.", $self->INFO);

        return 1;
}

sub delMX {
	my ($self, $domain, $host) = @_;
	$self->logger("function: delMX($domain, $host)", $self->FUNC_CALL);

	# check if the zone file exists
        my $check = $self->getValidateObj();
        if ($check->is_newZoneFile($domain, $self->getZoneDir)) {
                $self->logger("zone file for $domain does not exist.", $self->ERROR);
                return 0;
        }

	## depcrecated code
	#if (!$self->checkZone($domain)) {
	#	return 0;
	#}

	# set the zone file name
	my $zonedb = $self->getZoneDir."/$domain";

	# find $host in zone file and remove it
	my $zonefile = DNS::ZoneParse->new($zonedb);
	my $mx_records = $zonefile->mx();

	for my $i (0 .. $#$mx_records) {
		if (@$mx_records[$i]->{host} eq $host) {
			delete @$mx_records[$i];
		}
	}

	$zonefile->new_serial();

	open my $fh, '>', $zonedb or die "FATAL: $zonedb: $!";
	print $fh $zonefile->output();
	close $fh;

	$self->logger("MX record for $host delete from $domain.", $self->INFO);

	return 1;

}

sub delTXT {
	my ($self, $domain, $text) = @_;
	$self->logger("function: delTXT($domain, $text)", $self->FUNC_CALL);

	# check if the zone file exists
        my $check = $self->getValidateObj();
        if ($check->is_newZoneFile($domain, $self->getZoneDir)) {
                $self->logger("zone file for $domain does not exist.", $self->ERROR);
                return 0;
        }

	## deprecated code
	#if (!$self->checkZone($domain)) {
	#	return 0;
	#}

	# set the zone file name
	my $zonedb = $self->getZoneDir."/$domain";

	# find $text in zone file and remove it
	my $zonefile = DNS::ZoneParse->new($zonedb);
	my $txt_records = $zonefile->txt();

	for my $i (0 .. $#$txt_records) {
		if (@$txt_records[$i]->{text} eq $text) {
			delete @$txt_records[$i];
		}
	}

	$zonefile->new_serial();

	open my $fh, '>', $zonedb or die "FATAL: $zonedb: $!";
	print $fh $zonefile->output();
	close $fh;

	$self->logger("TXT record for $text delete from $domain.", $self->INFO);

	return 1;

}

sub addTXT {
        my ($self, $domain, $name, $text) = @_;
	$self->logger("function: addTXT($domain, $name, $text)", $self->FUNC_CALL);

	# check if zone file even exists
        my $check = $self->getValidateObj();
        if ($check->is_newZoneFile($domain, $self->getZoneDir)) {
                $self->logger("zone file for $domain does not exist.", $self->ERROR);
                return 0;
        }

	if (!$check->is_validName($name)) {
		$self->logger("$name is not a valid name for DNS", $self->ERROR);
		return 0;
	}

	## deprecated code
	#if (!$self->checkZone($domain)) {
	#	return 0;
	#}

	#if (!$self->validateName($name)) {
	#	$self->logger("$name is not a valid name for DNS", $self->VARIABLE);
	#	return 0;
	#}

        my $zonedb = $self->getZoneDir."/$domain";

        my $zonefile = DNS::ZoneParse->new($zonedb);
        my $txt_records = $zonefile->txt();

        push (@$txt_records, {
                name    => $name,
                class   => 'IN',
                text    => $text,
        });

	$zonefile->new_serial();

	open my $fh, '>', $zonedb or die "FATA: $zonedb: $!";
	print $fh $zonefile->output();
	close $fh;

	$self->logger("$name IN TXT $text added to $domain.", $self->INFO);

        return 1;
}

#sub validateName {
#	my ($self, $name) = @_;
#	return $name =~ /^([-@.a-z0-9]+)$/;
#}
#sub validateHost {
#	my ($self, $host) = @_;
#	return $host =~ /^(\d+)(\.\d+){3}$/;
#}


#///////////////////////////////////////////////#
# checkZone("domain.com")			#
#	returns 1 on success, 0 on fail		#
#///////////////////////////////////////////////#
	## possible outcomes:
	# 	1, domain is fine to create
	#	0, missing from config file
	#	-1, zone file does not exist
	#	-2, zone file and config file missing

sub checkZone {
	my ($self, $domain) = @_;
	$self->logger("function: checkZone($domain) called.", $self->FUNC_CALL);
	my $err = 1;

	# domain can only have '-', a-z, 0-9. 
	# must have at least 2 letters for tld
	if ($domain !~ /^([-a-z0-9]+\.[a-z]{2,})/) {
		$self->logger("$domain is not a valid domain.", $self->ERROR);			
		return 0;
	}
	
	# verify the zone doesn't already exist
	if (-e $self->getZoneDir()."/$domain") {
		$self->logger("$domain zone file exists already", $self->FULL_DEBUG);
		$err = -1;
	}

	# look through the nsd configuration for zone
	# 	name: "domain.com"
	open (NSD, '<', $self->getNsdConfig());
	while (<NSD>) {
		#print $_;
		chomp ($_);
		if ($_ =~ /name\: \"$domain\"/) {
			$self->logger("$domain exists in " . $self->getNsdConfig() . " configuration file", $self->FULL_DEBUG);
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

sub setValidateObj {
	my ($self, $obj) = @_;
	$self->logger("function: setValidateObj($obj)", $self->FUNC_CALL);

	$self->{validate} = $obj;
	return 1;	
}

sub getValidateObj {
	my ($self) = @_;
	return $self->{validate};
}
1;
