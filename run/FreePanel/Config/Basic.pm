package FreePanel::Config::Basic;

use warnings;
use strict;

=head1 NAME

FreePanel::Config::Basic - Get config file

my $config = FreePanel::Config::Basic->config;

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


sub config {
    use FindBin::Real;
    my $Bin = FindBin::Real::Bin();
    use Config::General;

    my ($self,$file) = @_; 
    $file ||= "/etc/freepanel/freepanel.conf";

    die $! if (!-e $file);

    my $conf = Config::General->new( -ConfigFile => $file, -SlashIsDirectory => 1 ) or die $!;
    my %config = $conf->getall;
    return \%config;
}

 


=head1 SYNOPSIS

Quick summary of what the module does.


 my $config = FreePanel::Config::Basic->config;

 or
 
 my $config = FreePanel::Config::Basic->config("/path/to/file");

=head1 Description

FreePanel needs a config file. With this module, you will be using a general, 
basic flat file. This module uses Config::General, so whatever formats 
Config::General supports you can use to create you config file.
 


=head1 methods 

=head2 config()

Returns a hash reference.  If no file was specified, it will try to load
./etc/freepanel.conf

=cut


=head2 function2

=cut


=head1 AUTHOR

Michael Kroher, C<< <mkroher at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-freepanel-config-basic at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FreePanel-Config-Basic>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FreePanel::Config::Basic


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FreePanel-Config-Basic>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FreePanel-Config-Basic>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FreePanel-Config-Basic>

=item * Search CPAN

L<http://search.cpan.org/dist/FreePanel-Config-Basic/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Michael Kroher, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of FreePanel::Config::Basic
