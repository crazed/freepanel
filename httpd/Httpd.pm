#!/usr/bin/perl
package DP::Httpd;
use strict;

###################### Class constructors ###################### 
sub new
{
	my $class = shift;
	my $self = {
		config_file	=> '/etc/freepanel/freepanel.conf'
	};

	# load the configuration vars
	getConfiguration($self);

	bless $self, $class;
	return $self;
}

sub getConfiguration
{
	my ($self) = @_;
	open (CONF, '<', $self->{config_file}) or die ("ERR: ".$self->{config_file}." file is missing.\n");
	my $line;
	my @arguments;

	while (<CONF>) {
		my $line = $_;

		chomp($line);
		if ($line =~ /^\#./) {
			# line is comment skip it
			next;
		}
	
		my @split = split(/=/, $line);

		my @configs = ("vhost_template", "vhost_dir", "inactive_dir", "web_dir", 
			"log_file", "http_uid", "http_gid", "debug");

		for my $config (@configs) {
			if ($split[0] =~ /^$config$/) {
				$self->{$config} = $split[1];
			}
		}	
	}

	if ($self->{debug}) {
		print "[DEBUG] configurations loaded:
	vhost_template=".$self->{vhost_template}."
	vhost_dir=".$self->{vhost_dir}."
	inactive_dir=".$self->{inactive_dir}."
	web_dir=".$self->{web_dir}."
	log_file=".$self->{log_file}."
	http_uid=".$self->{http_uid}."
	http_gid=".$self->{http_gid}."
	debug=1\n";
	}
	close CONF;

	return 1;
}

###################### Main functions ###################### 

sub addSite {
	my ($self, $domain, $ip_addr) = @_;

	# add some sort of error checking function here

	if ($self->checkVhost($domain)) {
		print "[!]: vhost config already exists for $domain.\n";
		return 0;
	}
	my $vhost_dir = $self->getVhostDir();
	my $vhost_templ = $self->getVhostTemplate();

	open (VHOST, '>', $vhost_dir."/$domain");
	open (VHOST_T, '<', $vhost_templ);

	if ($ip_addr) {
		while (<VHOST_T>) {
			s/<DOMAIN>/$domain/;
			s/<IP_ADDR>/$ip_addr/;
			print VHOST;
		}
	}
	else {
		while (<VHOST_T>) {
			s/<DOMAIN>/$domain/;
			s/<IP_ADDR>/\*/;
			print VHOST;
		}
	}

	return 1;
}

sub addWebDir {
	my ($self, $domain) = @_;
	
	if ($self->checkWebDir($domain)) {
		print "[!]: web directory already exists for $domain.\n" if $self->{debug};
		return 0;
	}

	my $uid = $self->getWebDirUID();
	my $gid = $self->getWebDirGID();
	my $base_dir = $self->getWebDir()."/$domain";
	my @dirs = ($base_dir, $base_dir."/web");

	for my $dir (@dirs) {
		mkdir($dir, 0755);
	}

	# set ownership
	chown $uid, $gid, @dirs;
	
	return 1;
}
sub removeSite {
	my ($self, $domain, $remove_dir) = @_;
	my $vhost_dir = $self->getVhostDir();
	my $web_dir = $self->getWebDir();
	my $err = 1;
	# add some sort of error checking function here

	# remove vhost file
	if ($self->checkVhost($domain)) {
		unlink($vhost_dir."/$domain");
		return 1;
	}

	print "[!]: no vhost configuration exists for $domain.\n";
	return 0;
}

sub removeWebDir {
	my ($self, $domain) = @_;
	my $web_dir = $self->getWebDir();

	if ($self->checkWebDir($domain)) {
		system ('rm', '-rf', $web_dir."/$domain");
		return 1;
	}
	print "[!]: no web dir exsists for $domain.\n" if $self->{debug};
	return 0;
}

sub disableSite {
	my ($self, $domain) = @_;
	my $inactive_dir = $self->getInactiveDir();
	my $vhost_dir = $self->getVhostDir();

	if (!$self->checkVhost($domain)) {
		print "[!]: no configuration file for $domain.\n";
		return 0;

	}

	# move from vhost dir to inactive dir
	system ('mv', $vhost_dir."/$domain", $inactive_dir."/$domain");
	
	return 1;
}

sub enableSite {
	my ($self, $domain) = @_;
	my $inactive_dir = $self->getInactiveDir();
	my $vhost_dir = $self->getVhostDir();
	
	if ($self->checkVhost($domain)) {
		print "[!]: site configuration ($domain) is already in proper directory.\n";
		return 0;
	} 

	if (!$self->checkInactive($domain)) {
		print "[!]: $domain does not exist.\n";
		return 0;
	}

	# move from inactive dir to vhost dir
	system ('mv', $inactive_dir."/$domain", $vhost_dir."/$domain");	

	return 1;
}

sub restartApache {
	my ($self) = @_;
	print "[*]: Apache is being restarted\n" if $self->{debug};
	return 1;
}

###################### Check functions ###################### 
sub checkVhost {
	my ($self, $domain) = @_;
	my $vhost_dir = $self->getVhostDir();

	# see if a configuration file exists 

	if (-e $vhost_dir."/$domain") {
		# vhost file exists
		return 1;
	}
	return 0;
}

sub checkInactive {
	my ($self, $domain) = @_;
	my $inactive_dir = $self->getInactiveDir();

	# see if a configuration exists
	if (-e $inactive_dir."/$domain") {
		# vhost file exists
		return 1;
	}

	return 0;
}

sub checkWebDir {
	my ($self, $domain) = @_;
	my $web_dir = $self->getWebDir();

	if (-d $web_dir."/$domain") {
		# web dir exists
		return 1;
	}
	return 0;
}


###################### Set functions ###################### 

sub setDebug {
	my ($self, $value) = @_;
	$self->{debug} = $value;
	return $self;
}

###################### Get functions ###################### 

sub getVhostTemplate {
	my ($self) = @_;

	if (-e $self->{vhost_template}) {
		return $self->{vhost_template};
	}
	die ("[error] vhost_template file does not exist\n");
}

sub getVhostDir {
	my ($self) = @_;

	if (-d $self->{vhost_dir}) {
		return $self->{vhost_dir};
	}
	die ("[error] vhost_dir directory does not exist\n");
}

sub getInactiveDir {
	my ($self) = @_;

	if (-d $self->{inactive_dir}) {
		return $self->{inactive_dir};
	}
	die ("[error] inactive_dir directory does not exist\n");
}

sub getWebDir {
	my ($self) = @_;

	if (-d $self->{web_dir}) {
		return $self->{web_dir};
	}
	die ("[error] web_dir directory does not exist\n");
}

sub getWebDirUID {
	my ($self) = @_;

	if ($self->{http_uid} =~ /^?\d+$/) {
		return $self->{http_uid};
	}
}

sub getWebDirGID {
	my ($self) = @_;

	if ($self->{http_gid} =~ /^?\d+$/) {
		return $self->{http_gid};
	}
}
1;
