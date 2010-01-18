#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'FreePanel' );
}

diag( "Testing FreePanel $FreePanel::VERSION, Perl $], $^X" );
