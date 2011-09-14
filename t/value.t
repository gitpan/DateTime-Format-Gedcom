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

diag 'Start testing parse_date_value(...)';

my(%value) =
(
en_AU =>
{
		'(Unknown date)' => # Use parse_interpreted_date().
		{
		one           => DateTime::Infinite::Past -> new,
		one_ambiguous => 0,
		one_bc        => 0,
		one_date      => DateTime::Infinite::Past -> new,
		phrase        => 'unknown date',
		prefix        => '',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
		'Abt 1 Jan 2001' => # use parse_approximate_date().
		{
		one           => DateTime -> new(year => 2001, month => 1, day => 1),
		one_ambiguous => 1,
		one_bc        => 0,
		one_date      => DateTime -> new(year => 2001, month => 1, day => 1),
		phrase        => '',
		prefix        => 'abt',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
		'Aft 1 Jan 2001' => # Use parse_date_range().
		{
		one           => DateTime -> new(year => 2001, month => 1, day => 1),
		one_ambiguous => 1,
		one_bc        => 0,
		one_date      => DateTime -> new(year => 2001, month => 1, day => 1),
		phrase        => '',
		prefix        => 'aft',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
		'From 0' => # Use parse_date_period().
		{
		one           => '0000-01-01T00:00:00',
		one_ambiguous => 1,
		one_bc        => 0,
		one_date      => DateTime -> new(year => 1000),
		phrase        => '',
		prefix        => 'from',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
}
);

for my $candidate (sort keys %{$value{$locale} })
{
		$date = $parser -> parse_date_value(date => $candidate);

		$in_string  = join(', ', map{"$_ => '$value{$locale}{$candidate}{$_}'"} sort keys %{$value{$locale}{$candidate} });
		$out_string = join(', ', map{"$_ => '$$date{$_}'"} sort keys %$date);

		if ($parser -> debug)
		{
				diag "In:  $in_string.";
				diag "Out: $out_string";
		}

		ok($in_string eq $out_string, "Testing: $candidate");
}

done_testing;
