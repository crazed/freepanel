#!/usr/bin/perl
package FreePanel::Validate::HTTP;
use strict;
use warnings;

sub new {
        my $class = shift;
        my $self = {};

        return bless $self, $class;
}

sub is_active {
	my ($self, $domain, $dir) = @_;
	return -e "$dir/$domain";
}

sub is_newWebDir {
	my ($self, $domain, $web_dir) = @_;
	return ! -d "$web_dir/$domain";
}
sub is_validName {
        my ($self, $name) = @_;
        return $name =~ /^([-.a-z0-9]+)$/;
} 
1;
