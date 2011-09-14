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
		'Abt 1 Jan 2001' =>
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
		'Abt 4000 BC' =>
		{
		one           => DateTime -> new(year => 4000, month => 1, day => 1),
		one_ambiguous => 1,
		one_bc        => 1,
		one_date      => DateTime -> new(year => 4000, month => 1, day => 1),
		phrase        => '',
		prefix        => 'abt',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
		'Cal 2345 BC' =>
		{
		one           => DateTime -> new(year => 2345, month => 1, day => 1),
		one_ambiguous => 1,
		one_bc        => 1,
		one_date      => DateTime -> new(year => 2345, month => 1, day => 1),
		phrase        => '',
		prefix        => 'cal',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
		'Cal 31 Dec 2000' =>
		{
		one           => DateTime -> new(year => 2000, month => 12, day => 31),
		one_ambiguous => 0,
		one_bc        => 0,
		one_date      => DateTime -> new(year => 2000, month => 12, day => 31),
		phrase        => '',
		prefix        => 'cal',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
		'Est 1 Jan 2001' =>
		{
		one           => DateTime -> new(year => 2001, month => 1, day => 1),
		one_ambiguous => 1,
		one_bc        => 0,
		one_date      => DateTime -> new(year => 2001, month =>  1, day => 1),
		phrase        => '',
		prefix        => 'est',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
		'Est 1234BC' =>
		{
		one           => DateTime -> new(year => 1234, month => 1, day => 1),
		one_ambiguous => 1,
		one_bc        => 1,
		one_date      => DateTime -> new(year => 1234, month => 1, day => 1),
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

my(%period) =
(
en_AU =>
{
		'From 0' =>
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
		'From 0 BC' =>
		{
		one           => '0000-01-01T00:00:00',
		one_ambiguous => 1,
		one_bc        => 1,
		one_date      => DateTime -> new(year => 1000),
		phrase        => '',
		prefix        => 'from',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
		'From 0 to 99' =>
		{
		one           => '0000-01-01T00:00:00',
		one_ambiguous => 1,
		one_bc        => 0,
		one_date      => DateTime -> new(year => 1000),
		phrase        => '',
		prefix        => 'from',
		two           => '0099-01-01T00:00:00',
		two_ambiguous => 1,
		two_bc        => 0,
		two_date      => DateTime -> new(year => 1099),
		},
		'From 1 Jan 2001 to 25 Dec 2002' =>
		{
		one           => DateTime -> new(year => 2001, month => 1, day => 1),
		one_ambiguous => 1,
		one_bc        => 0,
		one_date      => DateTime -> new(year => 2001, month =>  1, day => 1),
		phrase        => '',
		prefix        => 'from',
		two           => DateTime -> new(year => 2002, month => 12, day => 25),
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime -> new(year => 2002, month => 12, day => 25),
		},
		'From 25 Dec 2002 to 1 Jan 2001' => # A retrograde example.
		{
		one           => DateTime -> new(year => 2002, month => 12, day => 25),
		one_ambiguous => 0,
		one_bc        => 0,
		one_date      => DateTime -> new(year => 2002, month => 12, day => 25),
		phrase        => '',
		prefix        => 'from',
		two           => DateTime -> new(year => 2001, month =>  1, day => 1),
		two_ambiguous => 1,
		two_bc        => 0,
		two_date      => DateTime -> new(year => 2001, month => 1, day => 1),
		},
		'From 2011' =>
		{
		one           => DateTime -> new(year => 2011),
		one_ambiguous => 1,
		one_bc        => 0,
		one_date      => DateTime -> new(year => 2011),
		phrase        => '',
		prefix        => 'from',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
		'From 21 Jun 6004BC.' =>
		{
		one           => DateTime -> new(year => 6004, month => 6, day => 21),
		one_ambiguous => 0,
		one_bc        => 1,
		one_date      => DateTime -> new(year => 6004, month => 6, day => 21),
		phrase        => '',
		prefix        => 'from',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
		'From 500B.C.' =>
		{
		one           => '0500-01-01T00:00:00',
		one_ambiguous => 1,
		one_bc        => 1,
		one_date      => DateTime -> new(year => 1500),
		phrase        => '',
		prefix        => 'from',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
		'From 500BC' =>
		{
		one           => '0500-01-01T00:00:00',
		one_ambiguous => 1,
		one_bc        => 1,
		one_date      => DateTime -> new(year => 1500),
		phrase        => '',
		prefix        => 'from',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
		'From 500BC.' =>
		{
		one           => '0500-01-01T00:00:00',
		one_ambiguous => 1,
		one_bc        => 1,
		one_date      => DateTime -> new(year => 1500),
		phrase        => '',
		prefix        => 'from',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
		'From 500BC to 400' =>
		{
		one           => '0500-01-01T00:00:00',
		one_ambiguous => 1,
		one_bc        => 1,
		one_date      => DateTime -> new(year => 1500),
		phrase        => '',
		prefix        => 'from',
		two           => '0400-01-01T00:00:00',
		two_ambiguous => 1,
		two_bc        => 0,
		two_date      => DateTime -> new(year => 1400),
		},
		'From 500BC to 400BC' =>
		{
		one           => '0500-01-01T00:00:00',
		one_ambiguous => 1,
		one_bc        => 1,
		one_date      => DateTime -> new(year => 1500),
		phrase        => '',
		prefix        => 'from',
		two           => '0400-01-01T00:00:00',
		two_ambiguous => 1,
		two_bc        => 1,
		two_date      => DateTime -> new(year => 1400),
		},
		'From Nov 2011 to Dec 2011' =>
		{
		one           => DateTime -> new(year => 2011, month => 11, day => 1),
		one_ambiguous => 1,
		one_bc        => 0,
		one_date      => DateTime -> new(year => 2011, month => 11, day => 1),
		phrase        => '',
		prefix        => 'from',
		two           => DateTime -> new(year => 2011, month => 12, day => 1),
		two_ambiguous => 1,
		two_bc        => 0,
		two_date      => DateTime -> new(year => 2011, month => 12, day => 1),
		},
		'To 2011' =>
		{
		one           => DateTime::Infinite::Past -> new,
		one_ambiguous => 0,
		one_bc        => 0,
		one_date      => DateTime::Infinite::Past -> new,
		phrase        => '',
		prefix        => 'to',
		two           => DateTime -> new(year => 2011),
		two_ambiguous => 1,
		two_bc        => 0,
		two_date      => DateTime -> new(year => 2011),
		},
		'To 500 BC' =>
		{
		one           => DateTime::Infinite::Past -> new,
		one_ambiguous => 0,
		one_bc        => 0,
		one_date      => DateTime::Infinite::Past -> new,
		phrase        => '',
		prefix        => 'to',
		two           => '0500-01-01T00:00:00',
		two_ambiguous => 1,
		two_bc        => 1,
		two_date      => DateTime -> new(year => 1500),
		},
}
);

for my $candidate (sort keys %{$period{$locale} })
{
		$date       = $parser -> parse_date_period(date => $candidate);
		$in_string  = join(', ', map{"$_ => '$period{$locale}{$candidate}{$_}'"} sort keys %{$period{$locale}{$candidate} });
		$out_string = join(', ', map{"$_ => '$$date{$_}'"} sort keys %$date);

		if ($parser -> debug)
		{
				diag "In:  $in_string.";
				diag "Out: $out_string";
		}

		ok($in_string eq $out_string, "Testing: $candidate");
}

diag 'Start testing parse_date_range(...)';

my(%range) =
(
en_AU =>
{
		'Aft 1 Jan 2001' =>
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
		'Aft 4000 BC' =>
		{
		one           => DateTime -> new(year => 4000, month => 1, day => 1),
		one_ambiguous => 1,
		one_bc        => 1,
		one_date      => DateTime -> new(year => 4000, month => 1, day => 1),
		phrase        => '',
		prefix        => 'aft',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
		'Bef 2345 BC' =>
		{
		one           => DateTime -> new(year => 2345, month => 1, day => 1),
		one_ambiguous => 1,
		one_bc        => 1,
		one_date      => DateTime -> new(year => 2345, month => 1, day => 1),
		phrase        => '',
		prefix        => 'bef',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
		'Bef 31 Dec 2000' =>
		{
		one           => DateTime -> new(year => 2000, month => 12, day => 31),
		one_ambiguous => 0,
		one_bc        => 0,
		one_date      => DateTime -> new(year => 2000, month => 12, day => 31),
		phrase        => '',
		prefix        => 'bef',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
		'Bet 1 Jan 2001 and 25 Dec 2002' =>
		{
		one           => DateTime -> new(year => 2001, month => 1, day => 1),
		one_ambiguous => 1,
		one_bc        => 0,
		one_date      => DateTime -> new(year => 2001, month =>  1, day => 1),
		phrase        => '',
		prefix        => 'bet',
		two           => DateTime -> new(year => 2002, month => 12, day => 25),
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime -> new(year => 2002, month => 12, day => 25),
		},
		'Bet 1234BC and 5678' =>
		{
		one           => DateTime -> new(year => 1234, month => 1, day => 1),
		one_ambiguous => 1,
		one_bc        => 1,
		one_date      => DateTime -> new(year => 1234, month => 1, day => 1),
		phrase        => '',
		prefix        => 'bet',
		two           => DateTime -> new(year => 5678, month => 1, day => 1),
		two_ambiguous => 1,
		two_bc        => 0,
		two_date      => DateTime -> new(year => 5678, month => 1, day => 1),
		},
		'Bet Nov 2011 and Dec 2011' =>
		{
		one           => DateTime -> new(year => 2011, month => 11, day => 1),
		one_ambiguous => 1,
		one_bc        => 0,
		one_date      => DateTime -> new(year => 2011, month => 11, day => 1),
		phrase        => '',
		prefix        => 'bet',
		two           => DateTime -> new(year => 2011, month => 12, day => 1),
		two_ambiguous => 1,
		two_bc        => 0,
		two_date      => DateTime -> new(year => 2011, month => 12, day => 1),
		},
}
);

for my $candidate (sort keys %{$range{$locale} })
{
		$date = $parser -> parse_date_range(date => $candidate, from_to => [ ['Aft', 'Bef', 'Bet'] , 'And']);

		$in_string  = join(', ', map{"$_ => '$range{$locale}{$candidate}{$_}'"} sort keys %{$range{$locale}{$candidate} });
		$out_string = join(', ', map{"$_ => '$$date{$_}'"} sort keys %$date);

		if ($parser -> debug)
		{
				diag "In:  $in_string.";
				diag "Out: $out_string";
		}

		ok($in_string eq $out_string, "Testing: $candidate");
}

diag 'Start testing parse_datetime(...)';

my(%datetime) =
(
en_AU =>
{
		'21 Jun 1950' =>
		{
		one           => DateTime -> new(year => 1950, month => 6, day => 21),
		one_ambiguous => 0,
		one_bc        => 0,
		one_date      => DateTime -> new(year => 1950, month => 6, day => 21),
		phrase        => '',
		prefix        => '',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
}
);

for my $candidate (sort keys %{$datetime{$locale} })
{
		$date = $parser -> parse_datetime($candidate);

		$in_string  = join(', ', map{"$_ => '$datetime{$locale}{$candidate}{$_}'"} sort keys %{$datetime{$locale}{$candidate} });
		$out_string = join(', ', map{"$_ => '$$date{$_}'"} sort keys %$date);

		if ($parser -> debug)
		{
				diag "In:  $in_string.";
				diag "Out: $out_string";
		}

		ok($in_string eq $out_string, "Testing: $candidate");
}

diag 'Start testing parse_interpreted_date(...)';

my(%interpreted) =
(
en_AU =>
{
		'(Unknown date)' =>
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
		'Int 1 Jan 2001' =>
		{
		one           => DateTime -> new(year => 2001, month => 1, day => 1),
		one_ambiguous => 1,
		one_bc        => 0,
		one_date      => DateTime -> new(year => 2001, month => 1, day => 1),
		phrase        => '',
		prefix        => 'int',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
		'int 4000 BC (more or less)' =>
		{
		one           => DateTime -> new(year => 4000, month => 1, day => 1),
		one_ambiguous => 1,
		one_bc        => 1,
		one_date      => DateTime -> new(year => 4000, month => 1, day => 1),
		phrase        => 'more or less',
		prefix        => 'int',
		two           => DateTime::Infinite::Future -> new,
		two_ambiguous => 0,
		two_bc        => 0,
		two_date      => DateTime::Infinite::Future -> new,
		},
}
);

for my $candidate (sort keys %{$interpreted{$locale} })
{
		$date = $parser -> parse_interpreted_date(date => $candidate, prefix => 'Int');

		$in_string  = join(', ', map{"$_ => '$interpreted{$locale}{$candidate}{$_}'"} sort keys %{$interpreted{$locale}{$candidate} });
		$out_string = join(', ', map{"$_ => '$$date{$_}'"} sort keys %$date);

		if ($parser -> debug)
		{
				diag "In:  $in_string.";
				diag "Out: $out_string";
		}

		ok($in_string eq $out_string, "Testing: $candidate");
}

done_testing;
