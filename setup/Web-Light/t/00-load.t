#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Web::Light' );
}

diag( "Testing Web::Light $Web::Light::VERSION, Perl $], $^X" );
