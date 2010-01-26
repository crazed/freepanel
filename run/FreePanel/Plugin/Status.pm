package FreePanel::Plugin::Status;

use strict;
use warnings; 

sub default {
	my ($self, $app) = @_;

	my $tt = $app->{stash}{tt};
	my $param = $app->{req}->parameters;

	my $admin = FreePanel::Admin->new();

	#my $dump = Dumper($admin->getConfigs());

	#my $vars = { hash => $dump };

	#$tt->process('status.tt', $vars, \my $out);

	my $maildb = $admin->getMailDbConfig;
	my $vars = {
		http_service		=> $admin->getHttpService,
		mail_service		=> $admin->getMailService,
		name_service		=> $admin->getNameService,
		debug_level		=> $admin->getDebug,
		log_file		=> $admin->getLogFile,
		vhost_template		=> $admin->getVhostTemplate,
		vhost_dir		=> $admin->getVhostDir,
		inactive_dir		=> $admin->getInactiveDir,
		web_dir			=> $admin->getWebDir,
		http_uid		=> $admin->getHttpUID,
		http_gid		=> $admin->getHttpGID,
		zone_dir		=> $admin->getZoneDir,
		zone_template		=> $admin->getZoneTemplate,
		nsd_config		=> $admin->getNsdConfig,
		mysql_host		=> $maildb->{mysql_host},
		mysql_port		=> $maildb->{mysql_port},
		mysql_user		=> $maildb->{mysql_user},
		mysql_pass		=> $maildb->{mysql_pass},
		mysql_db		=> $maildb->{mysql_db},
		user_table		=> $maildb->{user_table},
		domain_table		=> $maildb->{domain_table},
		alias_table		=> $maildb->{alias_table},
		
	};

	$tt->process('status.tt', $vars, \my $out);
	$admin->logger("Status: site was access :) ZOMG LOGS", $admin->INFO);

	return $out;
		

}

sub go {
	my ($self, $app) = @_;
	my $tt = $app->{stash}{tt};
	my $param = $app->{req}->parameters;

	my $vars = {};

	if (!exists $param->{submit}) {
		default();
	}

	$app->stash(
		config => FreePanel::Config::getConfigs(),
	);

	$tt->process('complete.tt', $vars, \my $out);
}

1;
