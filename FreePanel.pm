#!/usr/bin/perl
package FreePanel;
use strict;
use warnings;
use Config::General;
use Sys::Syslog qw/ :DEFAULT setlogsock /;

# When calling the logger function, you should supply one of these levels
#  example: $self->logger("hi", $self->FULL_DEBUG);
use constant {
	# httpd related errors
	VHOST_EXISTS	=> 100,
	VHOST_NOEXIST	=> 101,
	WEBDIR_EXISTS	=> 102,
	WEBDIR_NOEXIST	=> 103,

	# ssh related errors
	SSH_FAIL	=> 200,

	# log levels
        FULL_DEBUG      => 10,
        VARIABLE        => 7,
        DB_QUERY        => 6,
        FUNC_CALL       => 5,
	WEB		=> 4,
        INFO            => 3,
        WARNING         => 2,
        ERROR           => 1,
};

### Constructor
sub new {
        my $class = shift;
        my $self = {
                config_file     => '/usr/local/freepanel/etc/freepanel.conf',
        };

	if (! -e $self->{config_file}) {
		die "FATAL: Configuration file $self->{config_file} does not exist.\n";
	}

	my $conf = Config::General->new($self->{config_file});
	$self->{_conf} = { $conf->getall() };

        bless $self, $class;
        return $self;
}

### Global methods
sub logger {
	my ($self, $msg, $log_level) = @_;
	my $level_name;
	
	if ($self->get_debug < $log_level) {
		return 1;
	}

	if ($log_level == 1) {
		$level_name = "err";
	}
	elsif ($log_level == 2) {
		$level_name = "warn";
	}
	elsif ($log_level == 3) {
		$level_name = "info";
	}
	elsif ($log_level == 4) {
		$level_name = "info";
	}
	else {
		$level_name = "debug";
	}

	openlog 'FreePanel', '', 'user';
	syslog $level_name, $msg;

	# old code for logging directly to a file
	#my ($sec, $min, $hour, $mday, $mon, 
	#	$year, $wday, $yday, $isdst) = localtime(time);

	#my $ts = sprintf("%02d-%02d-%4d %02d:%02d:%02d",
	#	$mon+1, $mday, $year+1900, $hour, $min, $sec);

	#open my $log, '>>', $self->get_logfile or die "FATAL: $!";
	#print $log "$ts :: [ $level_name ] $msg\n";
	#close $log;

	return 0;
}

### Accessors 
sub get_http {
	my $self = shift;
	return $self->{_conf}->{global}{http};
}
sub get_mail {
	my $self = shift;
	return $self->{_conf}->{global}{mail};
}
sub get_dns { 
	my $self = shift;
	return $self->{_conf}->{global}{dns};
}
sub get_debug {
	my $self = shift;
	return $self->{_conf}->{global}{debug};
}

# this is kinda deprecated, will leave it around for now
# reason: now using syslog
sub get_logfile {
	my $self = shift;
	return $self->{_conf}->{global}{log_file};
}

1;
