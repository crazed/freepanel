#!/usr/bin/perl
package FreePanel::Config;
use strict;
use Config::General;

my %configs;
###################### Constants ###############################
## log levels, used by log()
use constant {
        FULL_DEBUG      => 10,
        VARIABLE        => 7,
        DB_QUERY        => 6,
        FUNC_CALL       => 5,
	WEB		=> 4,
        INFO            => 3,
        WARNING         => 2,
        ERROR           => 1,
};

sub new
{
	my $class = shift;
	my $self = { 
		config_file	=> '/etc/freepanel/freepanel.conf',
	};

	%configs = getConfigs($self->{config_file});

	bless $self, $class;
	return $self;
}
sub logger {
        my ($self, $msg, $log_level) = @_;
        my $level_name;
	my $log_file = $self->getLogFile;
	my $dbg_level = $self->getDebug;

        if ($dbg_level < $log_level) {
                return 0;
        }

        if ($log_level == 1) {
                $level_name = "ERROR";
        }
        elsif ($log_level == 2) {
                $level_name = "WARNING";
        }
        elsif ($log_level == 3) {
                $level_name = "INFO";
        }
	elsif ($log_level == 4) {
		$level_name = "WEB";
	}
        else {
                $level_name = "DEBUG";
        }

        my ($sec, $min, $hour, $mday, $mon, 
                $year, $wday, $yday, $isdst)=localtime(time);

        my $timestamp = sprintf("%02d-%02d-%4d %02d:%02d:%02d",
                $mon+1,$mday,$year+1900,$hour,$min,$sec);

        # print out the log
        open LOG, ">>", $log_file or die "FATAL: $!\n";
        print LOG "$timestamp :: [ $level_name ] $msg\n";
        close LOG;
}

sub getHttpService {
	my ($self) = @_;
	return %configs->{global}{http};
}
sub getMailService {
	my ($self) = @_;
	return %configs->{global}{mail};
}
sub getNameService {
	my ($self) = @_;
	return %configs->{global}{dns};
}

sub getDebug {
	my ($self) = @_;
	return %configs->{global}{debug};
}

sub setDebug {
	my ($self, $value) = @_;
	%configs->{global}{debug} = $value;
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

sub getZoneDir {
	my ($self) = @_;
	return %configs->{nsd}{zones_dir};
}
sub getZoneTemplate {
	my ($self) = @_;
	return %configs->{nsd}{zone_template};
}

sub getNsdConfig {
	my ($self) = @_;
	return %configs->{nsd}{nsd_config};
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
