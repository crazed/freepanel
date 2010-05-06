#!/usr/bin/perl
package FreePanel::Admin::Apache;
use base qw/FreePanel/;

### Constructor
sub new {
	my $class = shift;
	my $self = $class->SUPER::new();

	bless $self, $class;
	return $self;
}

### General Methods
sub add_vhost {
	my ($self, $domain, $ip_addr) = @_;
	if ($self->is_active($domain)) {
		$self->logger("vhost config already exists for $domain.", $self->ERROR);
		return $self->VHOST_EXISTS;
	}

	open my $template, '<', $self->get_template or die $!;
	my @template = <$template>;
	close $template;

	if ($ip_addr) {
		open my $new_vhost, '>', $self->get_inactivedir."/$domain" or die $1;
		foreach my $line (@template) {
			$line =~ s/<DOMAIN>/$domain/;
			$line =~ s/<IP_ADDR>/$ip_addr/;
			print $new_vhost $line;
		}
		close $new_vhost;
	}
	else {
		open my $new_vhost, '>', $self->get_inactivedir."/$domain" or die $1;
		foreach my $line (@template) {
			$line =~ s/<DOMAIN>/$domain/;
			$line =~ s/<IP_ADDR>/\*/;
			print $new_vhost $line;
		}
		close $new_vhost;
	}

	$self->logger("added new vhost for $domain.", $self->INFO);
	return 0;
}

sub add_alias {
	my ($self, $domain) = @_;

	if (!$self->is_active($domain)) {
		$self->logger("$domain configuration does not exist or is inactive.", $self->ERROR);
		return $self->VHOST_NOEXIST;
	}

	my $alias = '';
	while (@_) {
		my $other_alias = shift;
		$alias = "$alias $other_alias";
	}

	$alias =~ s/\s+$//; # remove trailing space if any

	open my $vhost, '<', $self->get_vhostdir."/$domain" or die "FATAL: $!";
	my @config = <$vhost>;
	close $vhost;
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

	# in case no ServerAlias exists, add one
	if (!$alias_line) {
		my $server_alias = "ServerAlias $alias\n";
		splice @config, $server_line, 0, $server_alias; 
	}
	open $vhost, '>', $self->get_vhostdir."/$domain" or die "FATAL: $!";
	foreach my $line (@config) {
		print $vhost $line;
	}
	close $vhost;

	return 0;
}

sub add_webdir {
	my ($self, $domain) = @_;

	if (!$self->is_newdir($domain)) {
		$self->logger("web directory already exists for $domain.", $self->ERROR);
		return $self->WEBDIR_EXISTS;
	}

	my $uid = $self->get_uid;
	my $gid = $self->get_gid;
	my $base_dir = $self->get_webdir."/$domain";
	my @dirs = ($base_dir, "$base_dir/web");

	for my $dir (@dirs) {
		mkdir $dir, 0755;
	}
	chown $uid, $gid, @dirs;

	$self->logger("added new webdir for $domain.", $self->INFO);
	return 0;
}

sub rm_vhost {
	my ($self, $domain) = @_;

	if ($self->is_active($domain)) {
		unlink $self->get_vhostdir."/$domain";
		$self->logger("removed vhost configuration for $domain.", $self->INFO);
		return 0;
	}

	$self->logger("no vhost configuration exists for $domain while trying to remove one.", $self->ERROR);
	return $self->VHOST_NOEXIST;
}

sub rm_webdir {
	my ($self, $domain) = @_;

	my $web_dir = $self->get_webdir;
	if (!$self->is_newdir($domain)) {
		system 'rm', '-rf', "$web_dir/$domain";
		$self->logger("removed webdir for $domain.", $self->INFO);
		return 0;
	}

	$self->logger("no web dir exists for $domain while trying to remove one.", $self->ERROR);
	return $self->WEBDIR_NOEXIST;
}

sub enable_site {
	my ($self, $domain) = @_;

	if ($self->is_active($domain)) {
		$self->logger("vhost configuration for $domain is already enabled.", $self->ERROR);
		return $self->VHOST_EXISTS;
	}

	if (!$self->is_inactive($domain)) {
		$self->logger("vhost does not exist for $domain while trying to enable.", $self->ERROR);
		return $self->VHOST_NOEXIST;
	}

	system 'mv', $self->get_inactivedir."/$domain", $self->get_vhostdir."/$domain";
	$self->logger("enabled vhost configuration for $domain.", $self->INFO);
	return 0;
}
sub disable_site {
	my ($self, $domain) = @_;

	if (!$self->is_active($domain)) {
		$self->logger("no configuration file for $domain found while trying to disable.", $self->ERROR);
		return $self->VHOST_NOEXIST
	}
	system 'mv', $self->get_vhostdir."/$domain", $self->get_inactivedir."/$domain";
}

sub restart {
	my $self = shift;
	$self->logger("Apache is being restarted (not really implemented yet).", $self->INFO);
	return 0;
}

### Validation Methods
sub is_inactive {
	my ($self, $domain) = @_;
	return -e $self->get_inactivedir . "/$domain";
}
sub is_active {
	my ($self, $domain) = @_;
	return -e $self->get_vhostdir . "/$domain";
}
sub is_newdir {
	my ($self, $domain) = @_;
	return ! -d $self->get_webdir . "/$domain";
}

### Accessors
sub get_vhostdir {
	my $self = shift;
	return $self->{_conf}->{apache}{vhost_dir};
}
sub get_template {
	my $self = shift;
	return $self->{_conf}->{apache}{vhost_template};
}
sub get_inactivedir {
	my $self = shift;
	return $self->{_conf}->{apache}{inactive_dir};
}
sub get_webdir {
	my $self = shift;
	return $self->{_conf}->{apache}{web_dir};
}
sub get_uid {
	my $self = shift;
	return $self->{_conf}->{apache}{http_uid};
}
sub get_gid {
	my $self = shift;
	return $self->{_conf}->{apache}{http_gid};
}

1;
