package Web::Light;

use warnings;
use strict;
our $VERSION = '0.01';
use 5.008009;
use FindBin::Real;
use Module::Find;
use HTTP::Engine;
use HTTP::Engine::Middleware;
use Getopt::Long;


my $Bin = FindBin::Real::Bin();
my $Script = FindBin::Real::Script();
my $debug;
my $create;
my $help;
my $port;
GetOptions ("debug" => \$debug, "create" => \$create, "help" => \$help, "port=i" => \$port);

if ($help) {
    print qq(--debug \t run in debug mode\n);
    print qq(--create \t create local plugin directories and Root.pm\n);
    print qq(--port \t\t specify port\n);
    print qq(--help \t\t this\n);
    exit;
}


sub new {

    my $class = shift;

    die "Subclass Web::Light" if ($class eq __PACKAGE__);

    my %self = map { $_ } @_;

    $self{PLUGINS} ||= \@INC;
    setmoduledirs( @{$self{PLUGINS}} );
    my @plugins = useall $class;
    
    if ($debug) {
        print "[debug] loaded: $_\n" for @plugins;
    }
    $self{plugins} = \@plugins;

    bless \%self, $class;
}

sub stash {

    my $self = shift;
    
    my %stash = map { $_ } @_;

    $self->{stash} = \%stash;

    if ($debug) {

        for my $each (keys %stash) {
            print "[debug] stash: $each => $stash{$each}\n";
        }
    }
} 



sub dispatch {
    my $self = shift;
    
    my $class = ref $self;
    my %dispatch = map { $_ } @_;

    my $allowed = [qw/ plugin methods session /];

    if ( !exists $dispatch{root} ) {
        print STDOUT "[debug] dispatch:  No dispatch set for root, setting to: ${class}::Plugin::Root\n" if $debug;
        
        $dispatch{root}{plugin}  ||= "${class}::Plugin::Root"; # set a default for /
        $dispatch{root}{methods} ||= [ qw/ default /];        # default method


        my $test = "${class}::Plugin::Root";
        if  ( !$test->can('default') )  {
            print "Fatal: either $test doesn't exist,
               or there is no default method.\n Maybe try $Script --create\n";
        }

    }
    $self->{dispatch} = \%dispatch;

    if ($debug) {
        for my $each (keys %dispatch) {
            print "[debug] dispatch: $each => $dispatch{$each}\n";
        }
    }

    my @map_errors = $self->map_match( $self->{plugins}, $self->{dispatch} );

    if (@map_errors) {
        print STDOUT "$_\n" for @map_errors;
        exit;
    }  # wasn't that fun?


    my @method_errors = $self->method_match($self->{dispatch});

    if (@method_errors) {
        print STDOUT "$_\n" for @method_errors;
        exit;
    }

}

sub setup {
    my $self = shift;
    my %args = map { $_ } @_;
    my $args = \%args;


    my $mv = HTTP::Engine::Middleware->new({
        method_class => 'HTTP::Engine::Request'
    });
    
    if (exists $args->{session}) {
        $mv->install('HTTP::Engine::Middleware::HTTPSession' => $args->{session} );
    }
    if (exists $args->{static}) {
        $mv->install('HTTP::Engine::Middleware::Static' => $args->{static} );
    }
    
    #$mv->install( %{ $args->{middleware} }) if exists $args->{middleware};
    $args->{engine} = $self->defaults if !exists $args->{engine};
    $args->{engine}{interface}{request_handler} = $mv->handler( sub { $self->handler(@_) }  );
    my $engine = HTTP::Engine->new( %{ $args->{engine}} );
    $engine->run();
}


sub handler {
    my $self = shift;
    my $req  = shift;

    my $response = HTTP::Engine::Response->new;
    my @path = ($req->path =~ /([a-zA-Z0-9]+)/g);

    # Root.pm from Catalyst .. yeah i know!
    my $plugin = defined($path[0]) ? lc $path[0] : 'root';

    my $sub    = defined($path[1]) ? lc $path[1] : 'default';

    my $output;

    # $args to send to the plugins
    my $args = {
        app   => $self,
        stash => $self->{stash},
        req   => $req,
    };

    # let's check to see if the plugin exists, and/or the method/sub exists too
    if (
        !exists( $self->{dispatch}{$plugin} ) or
        !$self->{dispatch}{$plugin}{plugin}->can($sub) or
        !grep($sub eq $_, @{$self->{dispatch}{$plugin}{methods} } )
    ) {
        # uh oh, time for 404!
        # it's possible to call the method "new" with:  404 => 'MyPlugin404',
        # and in that plugin, there should be a 'default' method. So.. another check!
        my $do404 = $self->{404};
        if (
            !exists( $self->{404} ) or
            !${do404}->can('default')
        ) {
            # fail. set the default 404...
            $output = "404, Sorry :(";
        }
        else {
            # there seems to be a 404 plugin and 'default' method, so do it!
            $output = $self->{404}->default($args);
        }
        $response->body($output);
        $response->status(404);
        return $response;

    }
    else {
        # If we got to this point, everything looks good. 
        # let's send some output from our plugins

        my $Plugin = $self->{dispatch}{$plugin}{plugin};


        # sessions! if session => \@list is supplied for
        # a plugin, we need to see if those session
        # variables are set, if not, force 'Auth' plugin
        if (exists $self->{dispatch}{$plugin}{session}) {

            my $session = $req->session;

            # loop through the session => \@list, check if they
            # are set.
            for my $require (@{ $self->{dispatch}{$plugin}{session} } ) {
                if (!$session->get($require)) {
                    # session variable isn't set, so we have
                    # to force 'Auth' Plugin
                    $Plugin = $self->{AUTH};
                    $sub    = 'default';
                    last;
                }
            }
        }
        $output = ${Plugin}->$sub($args);
        if ($output =~ /^Location:/) {
            $response->headers->header($output);
            $response->status(200);
            return $response;
        }
        else {
            $response->body($output);
            $response->status(200);
            return $response;
        }
    }
}

sub defaults {
        my $self = shift;

        $port ||= 5000;
        my $defaults = {
                interface => {
                        module => 'ServerSimple',
                        args => {
                                host => '127.0.0.1',
                                port => $port,
                        }
                },
                print_banner => "omg hi",

        };
        return $defaults;
}

sub map_match {

    # new( map => { home => { plugin => 'Home' }, } )
    #
    # this method just verifies that
    # there is a loaded plugin for
    # the mapped url: /home

    my ($self,$plugins,$map) = @_;
    my $class = ref $self;
    my @errors;
    for my $each (keys %{$map}) {
        if (!grep($map->{$each}{plugin} eq $_, @{$plugins} )) {
            push(@errors,qq(Trying to map the URL: "/$each" to plugin: "$map->{$each}{plugin}", but no such plugin ) );
        }
    }
   return @errors;
}

sub method_match {

    shift;
    my ($map) = @_;
    my @errors;

    for my $each ( keys %{$map} ) {

        my $plugin = $map->{$each}{plugin};

        for my $method ( @{ $map->{$each}{methods}} ) {
            if (!${plugin}->can($method) ) {
                print "[debug] method_match: $plugin->$method FAILED\n" if $debug;
                push (@errors, qq(You specified method: $method for the plugin: $plugin, but no such method exists) );
            }
            else {
                print "[debug] method_match: $plugin->$method FOUND\n" if $debug;
            }
        }
    }
    return @errors;
}

sub makePluginsDir {
    my ($self,$Bin) = @_;
    die $! if !mkdir("$Bin/Plugins",0755);
    print STDOUT qq(Created ${Bin}/Plugins directory\n);
    return;
}
sub makeRootPM {
    my ($self,$Bin) = @_;
    open (my $fh, ">", "$Bin/Plugins/Root.pm") or die $!;
    print $fh q(package Root;),"\n\n";
    print $fh q(use strict;),"\n", q(use warnings;),"\n\n";
    print $fh q(sub default {),"\n",q(    my ($self,$wf) = @_;),"\n";
    print $fh q(    my $req     = $wf->{req};),"\n";
    print $fh q(    my $param   = $req->parameters;),"\n";
    print $fh q(    my $path    = $req->path;),"\n";
    print $fh q(    # do something with the above,),"\n";
    print $fh q(    # or just a simple Hello World),"\n\n";
    print $fh q(    my $out = "Hello World!";),"\n";
    print $fh q(    return $out;),"\n";
    print $fh q(}),"\n",q(1);
    close $fh;

    print STDOUT qq(Created ${Bin}/Plugins/Root.pm\n);
}
=head1 NAME

Web::Light - Light weight web framework

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Subclass Web::Light

    package MyApp;
    use base qw/ Web::Light /;
    1;

Then later...

    use Mypp;
    my $app = MyApp->new();
    $app->stash();
    $app->dispatch();
    $app->setup();

=head1 Description 

Web::Light is a light-weight web framework.  It's basically just a wrapper around 
HTTP::Engine::Middleware, and does some stuff to handle plugins.  If you are 
looking for a more tested, developed, and supported web framework, consider using Catalyst.

Web::Light by default launches a stand alone web server that you can connect to with your 
browser. Since Web::Light can do whatever HTTP::Engine can, you can specify different 
interfaces like ServerSimple and FastCGI.

=head1 Usage

=head2 new( $args )

Creates a Web::Light instance.

    new(
       PLUGINS => [ @INC, './' ],
    );

Define the location of plugins to load. This just passes a list to Module::Find's 
setmoduledirs() method.

    new(
       404 => 'MyApp::Plugin::My404',
    );

Assign a custom 404 plugin to use.

    new(
       AUTH => 'MyApp::Plugin::MyAuth',
    );

Assign which plugin to use for authentication. See dispatch() on how to 
incorporate authentication.


=head2 dispatch( $args )

Define how URLs get dispatched.

    dispatch(
       root => {
            plugin  => 'MyApp::Plugin::Root',
            methods => [qw/ default hello /],
            session => [],
       },
       home => {
            plugin  => 'MyApp::Plugin::CoolHome,
            methods => [qw/ default /],
            session => [qw/ username /],
       },
    );

The list of methods are the methods that are availabe to the web. 
The above will dispatch http://localhost/hello to the 
'hello' subroutine defined in MyApp::Plugin::Root

If 'session' contains a list, this forces Web::Light to check if
the variables in that list *are* set. If they aren't, the 'AUTH' 
plugin that was defined with new() will be forced.


=head2 stash( $args )

Just a simple hash ref to pass around stuff to your plugins.

    use Template;
    my $tt = Template->new;
    $app->stash(
        tt => $tt,
    );


Then in your plugin..

    package MyApp::Plugin::Cool

    sub default {
        my ($self,$app) = @_;
        my $tt = $app->{stash}{tt};

    }


        
=cut


=head1 AUTHOR

Michael Kroher, C<< <mkroher at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-web-light at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Web-Light>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Web::Light


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Web-Light>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Web-Light>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Web-Light>

=item * Search CPAN

L<http://search.cpan.org/dist/Web-Light/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Michael Kroher, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Web::Light
