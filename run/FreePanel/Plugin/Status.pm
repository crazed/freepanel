package FreePanel::Plugin::Status;

use strict;
use warnings; 

sub default {
	my ($self, $app) = @_;

	my $tt = $app->{stash}{tt};
	my $param = $app->{req}->parameters;

	my $config = FreePanel::Config->new();

	#my $dump = Dumper($config->getConfigs());

	#my $vars = { hash => $dump };

	#$tt->process('example.tt', $vars, \my $out);

	my $maildb = $config->getMailDbConfig;
	my $vars = {
		http_service		=> $config->getHttpService,
		mail_service		=> $config->getMailService,
		name_service		=> $config->getNameService,
		debug_level			=> $config->getDebug,
		log_file			=> $config->getLogFile,
		vhost_template		=> $config->getVhostTemplate,
		vhost_dir			=> $config->getVhostDir,
		inactive_dir		=> $config->getInactiveDir,
		web_dir				=> $config->getWebDir,
		http_uid			=> $config->getHttpUID,
		http_gid			=> $config->getHttpGID,
		zone_dir			=> $config->getZoneDir,
		zone_template		=> $config->getZoneTemplate,
		nsd_config			=> $config->getNsdConfig,
		mysql_host			=> $maildb->{mysql_host},
		mysql_port			=> $maildb->{mysql_port},
		mysql_user			=> $maildb->{mysql_user},
		mysql_pass			=> $maildb->{mysql_pass},
		mysql_db			=> $maildb->{mysql_db},
		user_table			=> $maildb->{user_table},
		domain_table		=> $maildb->{domain_table},
		alias_table			=> $maildb->{alias_table},
		
	};

	$tt->process('example.tt', $vars, \my $out);
	$config->logger("Status: site was access :) ZOMG LOGS", $config->INFO);

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
