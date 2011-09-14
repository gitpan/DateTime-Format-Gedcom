use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
 ($] ge '5.005') ?
 (
  AUTHOR   => 'Ron Savage (ron@savage.net.au)',
  ABSTRACT => 'Parse GEDCOM dates',
    ) : (),
 clean =>
 {
	 FILES => 'blib/* Makefile MANIFEST DateTime-Format-Gedcom-*'
 },
 dist =>
 {
	 COMPRESS => 'gzip',
	 SUFFIX   => 'gz'
 },
 DISTNAME  => 'DateTime-Format-Gedcom',
 NAME      => 'DateTime::Format::Gedcom',
 PL_FILES  => {},
 PREREQ_PM =>
 {
	 DateTime                  => 0.70,
	 DateTime::Format::Natural => 0.90,
	 DateTime::Infinite        => 0.70,
	 Hash::FieldHash           => 0.10,
	 Test::More                => 0.94,
	 Test::Pod                 => 1.44,
	 Try::Tiny                 => 0.11,
 },
 VERSION_FROM => 'lib/DateTime/Format/Gedcom.pm',
);
