package FreePanel;

our $VERSION = '0.01';
use 5.008009;
use strict;
use warnings;
use FindBin qw($Bin);
use Template;
use Module::Find;
use HTTP::Engine;
use HTTP::Engine::Middleware;

sub new {
	my $class = shift;
	my %self = map { $_ } @_;
	bless \%self, $class;

}
sub setup {
	my $self = shift;
	my %args = map { $_ } @_;
	my $args = \%args;

	$self->{tt} = Template->new({
		INCLUDE_PATH => "$Bin/templates",
		INTERPOLATE  => 1,
	}) || die "$Template::ERROR\n";

	#Check the plugins, exit if the map does not match
    setmoduledirs($Bin);
	my @plugins = useall Plugins;
	s/\w+::// for @plugins;
	$self->{plugins} = \@plugins;

	my @errors = $self->map_match( $self->{plugins}, $self->{map} );

	if (@errors) {
		print STDOUT "$_\n" for @errors;
		exit;
	}	
	
	my $mv = HTTP::Engine::Middleware->new({
		method_class => 'HTTP::Engine::Request'
	});
	$mv->install( %{ $args->{middleware} }) if exists $args->{middleware};
	$args->{engine} = $self->defaults;
	$args->{engine}{interface}{request_handler} = $mv->handler( sub { $self->handler(@_) }  );
	my $engine = HTTP::Engine->new( %{ $args->{engine}} );
	$engine->run();
}

sub handler {
	my $self = shift;
	my $req  = shift;
	my $response = HTTP::Engine::Response->new;
	my @path = ($req->path =~ /([a-zA-Z0-9]+)/g);
    my $plugin = lc $path[0];

	$plugin = $self->{map}{$plugin};
	
	my $args = {
		app => $self,
		tt => $self->{tt},
		req => $req,
	};
	my $output;

    $output = ${plugin}->run($args);  
	$response->body($output);
	$response->status(200);
	return $response;
}

sub defaults {
	my $self = shift;
	my $defaults = { 
		interface => {
			module => 'ServerSimple',
			args => {
				host => '127.0.0.1',
				port => '5000',
			}
		}
	};
	return $defaults;
}
			
sub map_match {
	my ($self,$plugins,$map) = @_;
	my @errors;
	for my $each (keys %{$map}) {
		if (!grep($map->{$each} eq $_, @{$plugins} )) {
			push(@errors,qq(Trying to map the URL: "/$each" to plugin: "$map->{$each}", but no such plugin $Bin/Plugins/$map->{$each}.pm) );
		}
	}
	return @errors;
}
	
1;
__END__

=head1 NAME

FreePanel - Perl standalone server to freepanel

=head1 SYNOPSIS

  use Freepanel;
 
  my $app = Freepanel->new($args);
 
  $app->setup($args);
  

=head1 DESCRIPTION

Stub documentation for FreePanel, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

User &, E<lt>mkroher@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by User &

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
