#!/usr/bin/perl
package FreePanel::Admin::SSH;
use base qw/FreePanel/;
use Net::SSH2;

#### Constructor
sub new {
	my $class = shift;
	my $self = $class->SUPER::new();

	bless $self, $class;
	return $self;
}
### General Methods

# exec_helper needs more error checking!
sub exec_helper {
	my $self = shift;
	my $host = shift;

	# tried to use $chan->shell but was crashing...
	foreach my $helper (@_) {
		my $c = $self->get_channel($host);
		my $script = $self->get_helperdir($host)."/".$helper->{script};
		my $args = $helper->{args};
		$c->blocking(0); # this fixes a weird bug where Net::SSH2 hung on a RHEL box
		$c->exec("$script $args");
		while (<$c>) { print };
		if ($c->exit_status) {
			$self->logger("'$script $args' failed to run on $host\n", $self->ERROR);
			return $self->SSH_FAIL;
		}
		$self->logger("'$script $args' executed on $host.", $self->FULL_DEBUG);
	}

	return 0;

}

sub cluster_push {
	my $self = shift;
	my $clname = shift;
	my $errors = 0; 

	my @helpers = @_;
	my @hosts = $self->get_cluster($clname);
	foreach my $host (@hosts) {
	#	if ($host eq 'localhost') {
			# TODO: implement code for when it is localhost.. 
			# - screw ssh to localhost that's dumb
			# - would be nice if it didn't resort to running the helper scripts
	#		next;
	#	}
		if ($self->exec_helper($host, @helpers)) {
			$errors++;
		}
	}
	return $errors;
}

### Accessor methods

# TODO: error checking
sub get_cluster {
	my ($self, $cluster) = @_;
	return split /,/, $self->{_conf}->{clusters}{$cluster};
}

sub get_channel {
        my ($self, $host) = @_;

        my $pub = $self->get_pubkey($host);
        my $priv = $self->get_privkey($host);
        my $user = $self->get_user($host);

	if ($pub == $self->CONFIG_MISSING || $priv == $self->CONFIG_MISSING || $user == $self->CONFIG_MISSING) {
		return $self->CONFIG_MISSING;
	}
	if ($pub == $self->CONFIG_INVALID || $priv == $self->CONFIG_INVALID || $user == $self->CONFIG_INVALID) {
		return $self->CONFIG_INVALID;
	}

        my $ssh = Net::SSH2->new();
        $ssh->connect($host) or die $!;

        if ($ssh->auth_publickey($user, $pub, $priv)) {
		$self->logger("successfully opened ssh connection to $host.", $self->FULL_DEBUG);
                return $ssh->channel();
        }
	$self->logger("error while trying to connect to $host.", $self->ERROR);
        return $self->SSH_FAIL;

}

sub get_helperdir {
	my ($self, $host) = @_;
	if (!$self->{_conf}->{ssh}{$host}{helpers}) {
		$self->logger("SSH config: no helperdir set for $host!", $self->ERROR);
		return $self->CONFIG_MISSING;
	}
	return $self->{_conf}->{ssh}{$host}{helpers};
}
sub get_pubkey {
	my ($self, $host) = @_;
	my $key = $self->{_conf}->{ssh}{$host}{pub_key};
        if (!$key) {
                $self->logger("SSH config: no pub_key set for $host!", $self->ERROR);
                return $self->CONFIG_MISSING;
        }
	if (! -e $key) {
		$self->logger("SSH config: public key '$key' does not exist!", $self->ERROR);
		return $self->CONFIG_INVALID;
	}
	return $key;
}

sub get_privkey {
	my ($self, $host) = @_;
	my $key = $self->{_conf}->{ssh}{$host}{priv_key};
        if (!$key) {
                $self->logger("SSH config: no priv_key set for $host!", $self->ERROR);
                return $self->CONFIG_MISSING;
        }
	if (! -e $key) {
		$self->logger("SSH config: private key '$key' does not exist!", $self->ERROR);
		return $self->CONFIG_INVALID;
	}
	return $key;
}

sub get_user {
	my ($self, $host) = @_;
        if (!$self->{_conf}->{ssh}{$host}{user}) {
                $self->logger("SSH config: no user set for $host!", $self->ERROR);
                return $self->CONFIG_MISSING;
        }
	return $self->{_conf}->{ssh}{$host}{user};
}
1;
