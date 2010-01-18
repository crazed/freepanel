#!/usr/bin/perl
package FreePanel::Admin;
use strict;
use FreePanel::Config;
use FreePanel::Admin::Apache;
use FreePanel::Admin::Nsd;
use FreePanel::Admin::Postfix;
use base qw(FreePanel::Config);

sub new { 
	my $class = shift;
	my $self = $class->SUPER::new();

	bless $self, $class;

	$self->{http_obj} = $self->newHttpObj();
	$self->{mail_obj} = $self->newMailObj();
	$self->{dns_obj} = $self->newDnsObj();

	return $self;
}

# newSite($domain, $ip_addr,$full_name, $user, $hash) 
sub newSite {
	my ($self, $domain, $ip_addr, $full_name, $user, $hash) = @_;
	my $user_email = $user.'@'.$domain;

	# setup service objects
	my $http = $self->getHttpObj();
	my $dns = $self->getDnsObj();
	my $mail = $self->getMailObj();

	$mail->dbConnect();
	$mail->setAliasCols(['address', 'goto']);
	$mail->setDomainCol('domain');
	$mail->setUserCols(['name', 'username', 'quota', 'password']);
	$mail->setEmailIdentifier('username');
	$mail->setAliasIdentifier('address');

	# add new items to each service
	$http->addSite($domain,$ip_addr);
	$http->addWebDir($domain);
	$dns->addDomain($domain,$ip_addr);
	$mail->addDomain($domain);
	$mail->addUser([$full_name, $user_email, 1024*10248*10, $hash]);	
	$mail->addAlias('webmaster@'.$domain, $user_email);

	# restart each service (not implemented yet)
	$http->restart();
	$dns->restart(); 
	$mail->restart();
	return 1;
}
sub removeSite {
	my ($self, $domain) = @_;

	# setup service objects

        my $http = $self->getHttpObj();
        my $dns = $self->getDnsObj();
        my $mail = $self->getMailObj();

        $mail->dbConnect();
        $mail->setAliasCols(['address', 'goto']);
        $mail->setDomainCol('domain');
        $mail->setUserCols(['name', 'username', 'quota', 'password']);
        $mail->setEmailIdentifier('username');
        $mail->setAliasIdentifier('address');

	# remove items from each service
	$http->removeSite($domain);
	$http->removeWebDir($domain);
	$mail->delDomain($domain);
	$dns->removeDomain($domain);
	return 1;
}

sub getHttpObj {
	my ($self) = @_;
	$self->{http_obj}->setDebug($self->getDebug());
	return $self->{http_obj};
}
sub getMailObj {
	my ($self) = @_;
	$self->{mail_obj}->setDebug($self->getDebug());
	return $self->{mail_obj};
}
sub getDnsObj {
	my ($self) = @_;
	$self->{dns_obj}->setDebug($self->getDebug());
	return $self->{dns_obj};
}
sub newHttpObj {
	my ($self) = @_;
	my $type = $self->getHttpService();
	my $obj;

	if ($type eq "apache") {
		$obj = new FreePanel::Admin::Apache();
		return $obj;
	}
	return 0;
}
sub newMailObj {
	my ($self) = @_;
	my $type = $self->getMailService();
	my $obj;
	
	if ($type eq "postfix") {
		$obj = new FreePanel::Admin::Postfix();
		return $obj;
	}
	return 0;
}
sub newDnsObj {
	my ($self) = @_;
	my $type = $self->getNameService();
	my $obj;
	
	if ($type eq "nsd") {
		$obj = new FreePanel::Admin::Nsd();
		return $obj;
	}
	return 0;
}
1;
