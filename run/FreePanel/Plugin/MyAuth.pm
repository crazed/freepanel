package FreePanel::Plugin::MyAuth;

use warnings;
use strict;

=head1 NAME

FreePanel::Plugin::MyAuth - The great new FreePanel::Plugin::MyAuth!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
use Crypt::PasswdMD5;

sub default {

    my ($self,$app) = @_;

    my $param   = $app->{req}->parameters;
    my $session = $app->{req}->session;

    my $vars = {};


    if (exists $param->{username} or
        exists $param->{username}
    ) {
        my ($username) = ($param->{username} =~ /(\w+)/);
        my ($password) = ($param->{password} =~ /(\S+)/);
        use Config::General;
        my $conf = Config::General->new(-ConfigFile => $app->{stash}{config}{global}{userdb} ) or die($!);
        my %userdb = $conf->getall;
        my $userdb = \%userdb;

        if (exists($userdb->{$username}) ) {

            my $hash  = unix_md5_crypt($password, $userdb->{$username}{password});

            if ($hash eq $userdb->{$username}{password}) {
                #sucees!!!

                $session->set("username",$username);
                $session->set("class", $userdb->{$username}{class});

                $vars->{success} = 'OMGTRUE';
            }
            else {
                $vars->{message} = "Login Failed";
            }
        }
        else {
            $vars->{message} = "Login Failed";
        }
    }

    my $tt = $app->{stash}{tt};
    $tt->process('login.tt', $vars, \my $out)
       || return $tt->error(), "\n";
    return $out;
}


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use FreePanel::Plugin::MyAuth;

    my $foo = FreePanel::Plugin::MyAuth->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 function1

=cut

=head2 function2

=cut


=head1 AUTHOR

Michael Kroher, C<< <mkroher at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-freepanel-plugin-myauth at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FreePanel-Plugin-MyAuth>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FreePanel::Plugin::MyAuth


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FreePanel-Plugin-MyAuth>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FreePanel-Plugin-MyAuth>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FreePanel-Plugin-MyAuth>

=item * Search CPAN

L<http://search.cpan.org/dist/FreePanel-Plugin-MyAuth/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Michael Kroher, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
1;
