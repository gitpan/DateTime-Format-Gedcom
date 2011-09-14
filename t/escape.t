use strict;
use warnings;

use DateTime;
use DateTime::Infinite;

use Test::More;

BEGIN {use_ok('DateTime::Format::Gedcom');}

my($locale) = 'en_AU';

DateTime -> DefaultLocale($locale);

my($parser) = DateTime::Format::Gedcom -> new(debug => 0);

isa_ok($parser, 'DateTime::Format::Gedcom');

my($date);
my($in_string);
my($out_string);

# Candidate value => Result hashref.

diag 'Start testing parse_approximate_date(...)';

my(%approximate) =
(
en_AU =>
{
		'Abt @#DDutch@ 2 Jan 2001' =>
		{
		one           => DateTime -> new(year => 2001, month => 1, day => 2),
		one_ambiguous => 1,
		one_bc        => 0,
		one_date      => DateTime -> new(year => 2001, month => 1, day => 2),
		phrase        => '',
		prefix        => 'abt',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
		'Est @#DFrench@ 2 Vend 2000' =>
		{
		one           => DateTime -> new(year => 2000, month => 1, day => 2),
		one_ambiguous => 1,
		one_bc        => 0,
		one_date      => DateTime -> new(year => 2000, month => 1, day => 2),
		phrase        => '',
		prefix        => 'est',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
}
);

for my $candidate (sort keys %{$approximate{$locale} })
{
		$date = $parser -> parse_approximate_date(date => $candidate, prefix => ['Abt', 'Cal', 'Est']);

		$in_string  = join(', ', map{"$_ => '$approximate{$locale}{$candidate}{$_}'"} sort keys %{$approximate{$locale}{$candidate} });
		$out_string = join(', ', map{"$_ => '$$date{$_}'"} sort keys %$date);

		if ($parser -> debug)
		{
				diag "In:  $in_string.";
				diag "Out: $out_string";
		}

		ok($in_string eq $out_string, "Testing: $candidate");
}

diag 'Start testing parse_date_period(...)';

my(%duration) =
(
en_AU =>
{
		'From @#DDutch@ 2 Januari 2000' =>
		{
		one           => DateTime -> new(year => 2000, month => 1, day => 2),
		one_ambiguous => 1,
		one_bc        => 0,
		one_date      => DateTime -> new(year => 2000, month => 1, day => 2),
		phrase        => '',
		prefix        => 'from',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
		'From @#DFrench@ 2 VENDEMIAIRE 2000' =>
		{
		one           => DateTime -> new(year => 2000, month => 1, day => 2),
		one_ambiguous => 1,
		one_bc        => 0,
		one_date      => DateTime -> new(year => 2000, month => 1, day => 2),
		phrase        => '',
		prefix        => 'from',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
		'From @#DGregorian@ 2 January 2000' =>
		{
		one           => DateTime -> new(year => 2000, month => 1, day => 2),
		one_ambiguous => 1,
		one_bc        => 0,
		one_date      => DateTime -> new(year => 2000, month => 1, day => 2),
		phrase        => '',
		prefix        => 'from',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
		'From @#DHebrew@ 2 Tishri 2000' =>
		{
		one           => DateTime -> new(year => 2000, month => 1, day => 2),
		one_ambiguous => 1,
		one_bc        => 0,
		one_date      => DateTime -> new(year => 2000, month => 1, day => 2),
		phrase        => '',
		prefix        => 'from',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
		'From @#DJulian@ 2 Jan 2000' =>
		{
		one           => DateTime -> new(year => 2000, month => 1, day => 2),
		one_ambiguous => 1,
		one_bc        => 0,
		one_date      => DateTime -> new(year => 2000, month => 1, day => 2),
		phrase        => '',
		prefix        => 'from',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
}
);

for my $candidate (sort keys %{$duration{$locale} })
{
		$date       = $parser -> parse_date_period(date => $candidate);
		$in_string  = join(', ', map{"$_ => '$duration{$locale}{$candidate}{$_}'"} sort keys %{$duration{$locale}{$candidate} });
		$out_string = join(', ', map{"$_ => '$$date{$_}'"} sort keys %$date);

		if ($parser -> debug)
		{
				diag "In:  $in_string.";
				diag "Out: $out_string";
		}

		ok($in_string eq $out_string, "Testing: $candidate");
}

done_testing;
