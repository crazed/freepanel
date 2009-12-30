#!/usr/bin/perl
package admin::config;
use strict;
use Config::General;

my %configs;

sub new
{
	my $class = shift;
	my $self = { 
		config_file	=> '/etc/freepanel/freepanel.conf'
	};

	%configs = getConfigs($self->{config_file});

	bless $self, $class;
	return $self;
}

sub getDebug {
	my ($self) = @_;
	return %configs->{global}{debug};
}

sub getLogFile {
	my ($self) = @_;
	return %configs->{global}{log_file};
}
sub getVhostTemplate {
	my ($self) = @_;
	return %configs->{apache}{vhost_template};
}
sub getVhostDir {
	my ($self) = @_;
	return %configs->{apache}{vhost_dir};
}
sub getInactiveDir {
	my ($self) = @_;
	return %configs->{apache}{inactive_dir};
}
sub getWebDir {
	my ($self) = @_;
	return %configs->{apache}{web_dir};
}
sub getHttpUID {
	my ($self) = @_;
	return %configs->{apache}{http_uid};
}
sub getHttpGID {
	my ($self) = @_;
	return %configs->{apache}{http_gid};
}

sub getZonesDir {
	my ($self) = @_;
	return %configs->{nsd}{zones_dir};
}
sub getZoneTemplate {
	my ($self) = @_;
	return %configs->{nsd}{zone_template};
}

sub getDnsConfig {
	my ($self) = @_;
	return %configs->{nsd}{nsd_configs};
}

sub getMailDbConfig {
	my ($self) = @_;
	return %configs->{postfix};
}

sub getConfigs
{
	my ($file) = @_;

	if (! -e $file) {
		die "FATAL: Configuration file $file does not exist.\n";
	}

	my $conf = new Config::General($file);
	my %hash = $conf->getall();
	return %hash;
}	
1;
