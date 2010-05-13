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

# TODO: needs more error checking
# - verify keys exist
sub get_channel {
        my ($self, $host) = @_;

        my $pub = $self->get_pubkey($host);
        my $priv = $self->get_privkey($host);
        my $user = $self->get_user($host);

        my $ssh = Net::SSH2->new();
        $ssh->connect($host) or die $!;

        if ($ssh->auth_publickey($user, $pub, $priv)) {
		$self->logger("successfully opened ssh connection to $host.", $self->FULL_DEBUG);
                return $ssh->channel();
        }
	$self->logger("error while trying to connect to $host.", $self->ERROR);
        return $self->SSH_FAIL;

}

# TODO: all of these need more error checking
#  - verify that $host config is set!
sub get_helperdir {
	my ($self, $host) = @_;
	return $self->{_conf}->{ssh}{$host}{helpers};
}
sub get_pubkey {
	my ($self, $host) = @_;
	return $self->{_conf}->{ssh}{$host}{pub_key};
}

sub get_privkey {
	my ($self, $host) = @_;
	return $self->{_conf}->{ssh}{$host}{priv_key};
}

sub get_user {
	my ($self, $host) = @_;
	return $self->{_conf}->{ssh}{$host}{user};
}
1;
