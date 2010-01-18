#!/usr/bin/perl
package FreePanel::Log;
use strict;
use warnings;

use constant {
	FULL_DEBUG	=> 10,
	VARIABLE	=> 6,
	DB_QUERY	=> 5,
	FUNC_CALL	=> 4,
	INFO		=> 3,
	WARNING		=> 2,
	ERROR		=> 1,
};

sub logger {
	my ($self, $log_file, $msg, $dbg_level, $log_level) = @_;
	my $level_name;

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
1;
