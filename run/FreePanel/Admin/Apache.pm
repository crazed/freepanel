#!/usr/bin/perl
package FreePanel::Admin::Apache;
use strict;
use warnings;
use Exporter;
use FreePanel::Config;
use FreePanel::Validate::HTTP;
use base qw/ FreePanel::Config /;

###################### Class constructors ###################### 
my $conf;
sub new
{
	my $class = shift;
	my $self = $class->SUPER::new();

	bless $self, $class;
	$self->setValidateObj(FreePanel::Validate::HTTP->new);

	return $self;
}

###################### Main functions ###################### 
sub addServerAlias {
	my ($self, $domain, $alias_array) = @_;

	$self->logger("function: addServerAlias($domain,$alias_array)", $self->FUNC_CALL);
	$self->logger("variable: \@\$alias_array: @$alias_array", $self->VARIABLE);

	# make sure the cofnig file exists
	my $vhost_dir = $self->getVhostDir();
	my $check = $self->getValidateObj();

	if (!$check->is_active($domain, $vhost_dir)) {
	#if (!$self->checkVhost($domain)) {

		$self->logger("$domain configuration does not exist or is inactive.", $self->ERROR);
		return 0;
	}

	my $alias = '';
	foreach my $element (@$alias_array) {
		$alias = "$element $alias";
	}
	$alias =~ s/\s+$//; # remove trailing space if any

	# load the domain config into an array
	open VHOST, '<', $vhost_dir."/$domain" or die "FATAL: $vhost_dir/$domain $!";
	my @config = <VHOST>;
	close VHOST;

	# search for ServerAlias directive
	my $alias_line = 0;
	my $server_line = 1;	# 1 because 0 would be the <VirtualHost *> line
	for my $i (0 .. $#config) { 
		if ($config[$i] =~ /ServerAlias (.+)/) {
			chomp($config[$i]);
			$config[$i] = "$config[$i] $alias\n";
			$alias_line = $i;
		}
		if ($config[$i] =~ /ServerName (.+)/) {
			$server_line = $i;
		}
	}

	# if no ServerAlias, add one after $server_line
	if (!$alias_line) {
		my $server_alias = "ServerAlias $alias\n";
		splice @config, $server_line, 0, $server_alias; 
	}

	$self->logger("variable: \@config: \n@config", $self->VARIABLE);

	# write the config out
	open VHOST, '>', $vhost_dir."/$domain";

	foreach my $line (@config) {
		print VHOST $line;
	}	

	close VHOST;

	return 1;

}

sub addSite {
	my ($self, $domain, $ip_addr) = @_;
	$self->logger("function: addSite($domain, $ip_addr) called.", $self->FUNC_CALL);

        my $vhost_dir = $self->getVhostDir();
        my $vhost_templ = $self->getVhostTemplate();
	my $check = $self->getValidateObj();

	if ($check->is_active($domain, $vhost_dir)) {
	#if ($self->checkVhost($domain)) {
		$self->logger("vhost config already exists for $domain.", $self->ERROR);
		return 0;
	}

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

	close VHOST_T;
	close VHOST;

	return 1;
}

sub addWebDir {
	my ($self, $domain) = @_;
	$self->logger("function: addWebDir($domain)", $self->FUNC_CALL);

	my $check = $self->getValidateObj();
	my $web_dir = $self->getWebDir();
	
	if (!$check->is_newWebDir($domain, $web_dir)) {
	#if ($self->checkWebDir($domain)) {
		$self->logger("web directory already exists for $domain while tryingn to add one.", $self->ERROR);
		return 0;
	}

	my $uid = $self->getHttpUID();
	my $gid = $self->getHttpGID();
	my $base_dir = "$web_dir/$domain";
	my @dirs = ($base_dir, "$base_dir/web");

	for my $dir (@dirs) {
		mkdir($dir, 0755);
	}

	# set ownership
	chown $uid, $gid, @dirs;
	
	return 1;
}
sub removeSite {
	my ($self, $domain) = @_;
	$self->logger("removeSite($domain)", $self->FUNC_CALL);
	my $vhost_dir = $self->getVhostDir();
	my $web_dir = $self->getWebDir();
	my $check = $self->getValidateObj();

	# remove vhost file
	if ($check->is_active($domain, $vhost_dir)) {
	#if ($self->checkVhost($domain)) {
		unlink($vhost_dir."/$domain");
		return 1;
	}

	$self->logger("no vhost configuration exists for $domain while tryig to remove one.", $self->ERROR);
	return 0;
}

sub removeWebDir {
	my ($self, $domain) = @_;
	$self->logger("function: removeWebDir($domain)", $self->FUNC_CALL);
	my $web_dir = $self->getWebDir();
	my $check = $self->getValidateObj();

	if (!$check->is_newWebDir($domain, $web_dir)) {
	#if ($self->checkWebDir($domain)) {
		system ('rm', '-rf', "$web_dir/$domain");
		return 1;
	}
	$self->logger("no web dir exsists for $domain while trying to remove one.", $self->ERROR);
	return 0;
}

sub disableSite {
	my ($self, $domain) = @_;
	$self->logger("function: disableSite($domain)", $self->FUNC_CALL);
	my $inactive_dir = $self->getInactiveDir();
	my $vhost_dir = $self->getVhostDir();
	my $check = $self->getValidateObj();

	if (!$check->is_active($domain, $vhost_dir)) {
	#if (!$self->checkVhost($domain)) {
		$self->logger("no configuration file for $domain found while trying to disable the site.", $self->ERROR);
		return 0;

	}

	# move from vhost dir to inactive dir
	system ('mv', "$vhost_dir/$domain", "$inactive_dir/$domain");
	
	return 1;
}

sub enableSite {
	my ($self, $domain) = @_;
	$self->logger("function: enableSite($domain)", $self->FUNC_CALL);
	my $inactive_dir = $self->getInactiveDir();
	my $vhost_dir = $self->getVhostDir();
	my $check = $self->getValidateObj();
	
	if ($check->is_active($domain, $vhost_dir)) {
	#if ($self->checkVhost($domain)) {
		$self->logger("site configuration file for $domain is already in proper directory.", $self->ERROR);
		return 0;
	} 

	if (!$check->is_active($domain, $inactive_dir)) {
	#if (!$self->checkInactive($domain)) {
		$self->logger("$domain does not exist while trying to enable site.", $self->ERROR);
		return 0;
	}

	# move from inactive dir to vhost dir
	system ('mv', $inactive_dir."/$domain", $vhost_dir."/$domain");	

	return 1;
}

sub restart {
	my ($self) = @_;
	$self->logger("function: restart (apache)", $self->FUNC_CALL);
	$self->logger("Apache is being restarted.", $self->INFO);
	return 1;
}

###################### Check functions ###################### 
sub checkVhost {
	my ($self, $domain) = @_;
	$self->logger("function: checkVhost($domain)", $self->FUNC_CALL);
	my $vhost_dir = $self->getVhostDir();

	# see if a configuration file exists 
	return -e "$vhost_dir/$domain";
}

sub checkInactive {
	my ($self, $domain) = @_;
	$self->logger("function: checkInactive($domain)", $self->FUNC_CALL);
	my $inactive_dir = $self->getInactiveDir();

	# see if a configuration exists
	return -e "$inactive_dir/$domain";
}

sub checkWebDir {
	my ($self, $domain) = @_;
	$self->logger("function: checkWebDir($domain)", $self->FUNC_CALL);
	my $web_dir = $self->getWebDir();

	return -d "$web_dir/$domain";
}

sub setValidateObj {
	my ($self, $obj) = @_;

	$self->{validate} = $obj;
	return 1;
}
sub getValidateObj {
	my ($self) = @_;
	return $self->{validate};
}
1;
