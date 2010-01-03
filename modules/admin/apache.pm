#!/usr/bin/perl
package admin::apache;
use strict;
use config;
our @ISA = qw(admin::config);
#use Cwd;
#my $cwd = cwd;
#use lib "../config/";
#use config;

###################### Class constructors ###################### 
my $conf;
sub new
{
	my $class = shift;
	my $self = $class->SUPER::new();

	bless $self, $class;

	return $self;
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

	my $uid = $self->getHttpUID();
	my $gid = $self->getHttpGID();
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

sub restart {
	my ($self) = @_;
	print "[*]: Apache is being restarted\n" if $self->getDebug;
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

1;
