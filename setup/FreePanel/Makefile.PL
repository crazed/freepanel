use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'FreePanel',
    AUTHOR              => 'Michael Kroher <mkroher@gmail.com>',
    VERSION_FROM        => 'lib/FreePanel.pm',
    ABSTRACT_FROM       => 'lib/FreePanel.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Web::Light' => 0.01,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'FreePanel-*' },
);
