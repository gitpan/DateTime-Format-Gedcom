package DateTime::Format::Gedcom;

use strict;
use warnings;

use DateTime;
use DateTime::Format::Natural;
use DateTime::Infinite;

use Hash::FieldHash ':all';

use Try::Tiny;

fieldhash my %date         => 'date';
fieldhash my %debug        => 'debug';
fieldhash my %formatter    => 'formatter';
fieldhash my %method_index => 'method_index';

our $VERSION = '1.01';

# --------------------------------------------------

sub _init
{
	my($self, $arg)     = @_;
	$$arg{date}         ||= ''; # Caller can set.
	$$arg{debug}        ||= 0;  # Caller can set.
	$$arg{method_index} = 0;    # See parse_date_value.
	$$arg{formatter}    = DateTime::Format::Natural -> new;
	$self               = from_hash($self, $arg);

	return $self;

} # End of _init.

# --------------------------------------------------

sub _init_flags
{
	my($self) = @_;

	my(%flags);

	for my $key (qw/one two/)
	{
		$flags{$key}               = $key eq 'one' ? DateTime::Infinite::Past -> new : DateTime::Infinite::Future -> new;
		$flags{"${key}_ambiguous"} = 0;
		$flags{"${key}_bc"}        = 0;
		$flags{"${key}_date"}      = $flags{$key};
		$flags{phrase}             = '';
		$flags{prefix}             = '';
	}

	return {%flags};

} # End of _init_flags.

# --------------------------------------------------

sub month_names_in_dutch
{
	my($self) = @_;

	return [ [qw/januari februari mart april mei juni juli augustus september october november december/], [qw/jan feb mar apr mei jun jul aug sep oct nov dec/] ];

} # End of month_names_in_dutch.

# --------------------------------------------------

sub month_names_in_french
{
	my($self) = @_;

	return [ [qw/VENDEMIAIRE BRUMAIRE FRIMAIRE NIVOSE PLUVIOSE VENTOSE GERMINAL FLOREAL PRAIRIAL MESSIDOR THERMIDOR FRUCTIDOR JOUR_COMPLEMENTAIRS/],
			 [qw/VEND BRUM FRIM NIVO PLUV VENT GERM FLOR PRAI MESS THER FRUC COMP/] ];

} # End of month_names_in_french.

# --------------------------------------------------

sub month_names_in_gregorian
{
	my($self) = @_;

	return [ [qw/january february march april may june july august september october november december/], [qw/jan feb mar apr may jun jul aug sep oct nov dec/] ];

} # End of month_names_in_gregorian.

# --------------------------------------------------

sub month_names_in_hebrew
{
	my($self) = @_;

	return [ [qw/Tishri Cheshvan Kislev Tevet Shevat Adar Adar Sheni Nisan Iyar Sivan Tammuz Av Elul54/], [qw/TSH CSH KSL TVT SHV ADR ADS NSN IYR SVN TMZ AAV ELL/] ];

} # End of month_names_in_hebrew.

# --------------------------------------------------

sub month_names_in_julian
{
	my($self) = @_;

	return [ [qw/january february march april may june july august september october november december/], [qw/jan feb mar apr may jun jul aug sep oct nov dec/] ];

} # End of month_names_in_julian.

# --------------------------------------------------

sub new
{
	my($class, %arg) = @_;
	my($self)        = bless {}, $class;
	$self            = $self -> _init(\%arg);

	return $self;

}	# End of new.

# --------------------------------------------------

sub parse_approximate_date
{
	my($self, %arg) = @_;
	my($date)       = lc ($arg{date} || $self -> date);
	$date           =~ s/^\s+//;
	$date           =~ s/\s+$//;
	my($prefix)     = $arg{prefix} || ['abt', 'bef', 'bet'];

	# Phase 1: Validate parameters.

	die "No value for the 'date' key"                                      if (length($date) == 0);
	die "The value for the 'prefix' key must be an arrayref of 3 elements" if ( (! ref $prefix) || (ref $prefix ne 'ARRAY') || ($#$prefix != 2) );

	$prefix = [map{lc} @$prefix];

	# Phase 2: Split the date on '-' or spaces, so we can check for prefixes.
	# Expected format is something like 'cal 21 jun 1950'.

	my(@field) = split(/[-\s]+/, $date);

	if ( ($field[0] eq $$prefix[0]) || ($field[0] eq $$prefix[1]) || ($field[0] eq $$prefix[2]) )
	{
		# Do nothing.
	}
	else
	{
		die "The value of the 'date' key - '$date' - must start with one of " . join(', ', @$prefix);
	}

	# Phase 3: Handle the date escape.

	@field = $self -> process_date_escape(@field);

	# We rig the $from_to parameter so the same call works from within parse_date_range() etc.

	return $self -> _parse_1or2_dates([ [$$prefix[0], $$prefix[1], $$prefix[2] ], ''], @field);

} # End of parse_approximate_date.

# --------------------------------------------------

sub parse_date_period
{
	my($self, %arg) = @_;
	my($date)       = lc ($arg{date} || $self -> date);
	$date           =~ s/^\s+//;
	$date           =~ s/\s+$//;
	my($from_to)    = $arg{from_to} || ['from', 'to'];

	# Phase 1: Validate parameters.

	die "No value for the 'date' key"                                       if (length($date) == 0);
	die "The value for the 'from_to' key must be an arrayref of 2 elements" if ( (! ref $from_to) || (ref $from_to ne 'ARRAY') || ($#$from_to != 1) );

	$from_to = [map{lc} @$from_to];

	# Phase 2: Split the date on '-' or spaces, so we can check for 'from' and 'to'.
	# Expected format is something like 'from 21 jun 1950 to 21 jun 2011'.

	my(@field)  = split(/[-\s]+/, $date);
	my($prefix) = '';

	if ($field[0] eq $$from_to[0])
	{
		$prefix = 'one';
	}
	elsif ($field[0] eq $$from_to[1])
	{
		$prefix = 'two';
	}

	if (! $prefix)
	{
		die "The value of the 'date' key - '$date' - must start with '$$from_to[0]' or '$$from_to[1]'";
	}

	# Phase 3: Handle the date escape.

	@field = $self -> process_date_escape(@field);

	# We rig the $from_to parameter so the same call works from within parse_date_range() etc.

	return $self -> _parse_1or2_dates([ [$$from_to[0], $$from_to[0], $$from_to[0] ], $$from_to[1] ], @field);

} # End of parse_date_period.

# --------------------------------------------------

sub parse_date_range
{
	my($self, %arg) = @_;
	my($date)       = lc ($arg{date} || $self -> date);
	$date           =~ s/^\s+//;
	$date           =~ s/\s+$//;
	my($from_to)    = $arg{from_to} || [ ['Aft', 'Bef', 'Bet'], 'And'];

	# Phase 1: Validate parameters.

	die "No value for the 'date' key"                                       if (length($date) == 0);
	die "The value for the 'from_to' key must be an arrayref of 2 elements" if ( (! ref $from_to) || (ref $from_to ne 'ARRAY') || ($#$from_to != 1) );

	$$from_to[0] = [map{lc} @{$$from_to[0]}];
	$$from_to[1] = lc $$from_to[1];

	# Phase 2: Split the date on '-' or spaces, so we can check for ranges.
	# Expected format is something like 'bet 21 jun 1950 and 21 jun 2011'.

	my(@field) = split(/[-\s]+/, $date);

	# This code allows ranges to be:
	# o Legal, with 'Bet 1999 and 2000'.
	# o Illegal, with 'Aft 1999 and 2000' or 'Bef 1999 and 2000'.
	# o Illegal, with 'Bet 1999'.
	# Why? Because we don't care that 'And' is not preceeded by 'Bet', nor that 'Bet' is not followed by 'And'.

	if ( ($field[0] eq $$from_to[0][0]) || ($field[0] eq $$from_to[0][1]) || ($field[0] eq $$from_to[0][2]) )
	{
		# Do nothing.
	}
	else
	{
		die "The value of the 'date' key - '$date' - must start with one of " . join(', ', @{$$from_to[0][0]});
	}

	# Phase 3: Handle the date escape.

	@field = $self -> process_date_escape(@field);

	return $self -> _parse_1or2_dates($from_to, @field);

} # End of parse_date_range.

# --------------------------------------------------

sub parse_date_value
{
	my($self, %arg)  = @_;
	my($index)       = $self -> method_index;
	my(@method_name) = (qw/parse_datetime parse_date_period parse_date_range parse_approximate_date parse_interpreted_date/);

	my($method_name);
	my($result);

	try
	{
		$method_name = $method_name[$index];
		$result      = $index == 0 ? $self -> $method_name($arg{date}) : $self -> $method_name(date => $arg{date});
	}
	catch
	{
		# After the current method dies we try the next in the list.

		$self -> method_index($index + 1);

		die "Unable to parse date '$arg{date}'" if ($self -> method_index > $#method_name);

		$result = $self -> parse_date_value(date => $arg{date});
	};

	# Having succeeded, ensure next parse starts from scratch.

	$self -> method_index(0);

	return $result;

} # End of parse_date_value.

# --------------------------------------------------

sub parse_datetime
{
	my($self, $date) = @_;
	$date            = lc ($date || $self -> date);
	$date            =~ s/^\s+//;
	$date            =~ s/\s+$//;

	die 'No date provided' if (length($date) == 0);

	# We rig the $from_to parameter so the same call works from within parse_date_range() etc.

	return $self -> _parse_1or2_dates([ ['' , '', ''], ''], split(/[-\s]+/, $date) );

} # End of parse_datetime.

# --------------------------------------------------

sub parse_interpreted_date
{
	my($self, %arg) = @_;
	my($date)       = lc ($arg{date} || $self -> date);
	$date           =~ s/^\s+//;
	$date           =~ s/\s+$//;
	my($prefix)     = lc ($arg{prefix} || 'int');

	# Phase 1: Validate parameters.

	die "No value for the 'date' key"   if (length($date) == 0);
	die "No value for the 'prefix' key" if (length($prefix) == 0);

	# Phase 2: Split the date on '-' or spaces, so we can check for prefixes.
	# Expected format is something like 'int 21 jun 1950 (more or less)'.

	my(@field) = split(/[-\s]+/, $date);

	if ( ($field[0] eq $prefix) || ($field[0] =~ /^\(/) )
	{
		# Do nothing.
	}
	else
	{
		die "The value of the 'date' key - '$date' - must start with '$prefix'";
	}

	# Phase 3: Handle the date phrase.
	# Expected formats:
	# o Int 2000 (more or less).
	# o (Unknown).

	my($open_paren)  = index($date, '(');
	my($close_paren) = index($date, ')');
	my($phrase)      = '';

	if ( ($open_paren < 0) && ($close_paren < 0) )
	{
		# Do nothing.
	}
	elsif ( ($open_paren < 0) && ($close_paren >= 0) )
	{
		die "Date - '$date' - missing the '(' before the ')'";
	}
	elsif ( ($open_paren < 0) && ($close_paren >= 0) )
	{
		die "Date - '$date' - missing the ')' after the '('";
	}
	else
	{
		$phrase                             = substr($date, ($open_paren + 1), ($close_paren - $open_paren - 1) );
		my($length)                         = length($phrase) + 2; # + 2 to zap the '(' and ')'.
		substr($date, $open_paren, $length) = '';
		$date                               =~ s/\s+$//; # Zap any spaces before the '(' in 'Int 2000 (Guesswork)'..
		@field                              = split(/[-\s]+/, $date);
	}

	# Special case: '(Unknown date and time)' reduced to ''.

	if ($#field < 0)
	{
		my($flags)      = $self -> _init_flags;
		$$flags{phrase} = $phrase;

		return $flags;
	}

	# Phase 4: Handle the date escape.

	@field = $self -> process_date_escape(@field);

	# We rig the $from_to parameter so the same call works from within parse_date_range() etc.

	my($flags)      = $self -> _parse_1or2_dates([ [$prefix, $prefix, $prefix], ''], @field);
	$$flags{phrase} = $phrase;

	return $flags;

} # End of parse_interpreted_date.

# --------------------------------------------------

sub _parse_1or2_dates
{
	my($self, $from_to, @field) = @_;
	my($flags) = $self -> _init_flags;

	# Phase 1: Check for embedded 'to', as in 'from date.1 to date.2'.

	my(%offset) =
		(
		 one => - 1,
		 two => - 1,
		);

	for my $i (0 .. $#field)
	{
		if ( ($field[$i] eq $$from_to[0][0]) || ($field[$i] eq $$from_to[0][1]) || ($field[$i] eq $$from_to[0][2]) )
		{
			$offset{one} = $i;

			for my $j (0 .. 2)
			{
				$$flags{prefix} = $$from_to[0][$j] if ($field[$i] eq $$from_to[0][$j]);
			}
		}

		if ($field[$i] eq $$from_to[1])
		{	
			$offset{two} = $i;

			if ($offset{one} < 0)
			{
				$$flags{prefix} = $$from_to[1];
			}
		}
	}

	# Phase 2: Search for BC, of which there might be 2.

	my(@offset_of_bc);

	for my $i (0 .. $#field)
	{
		# Note: The field might contain just BC or something like 500BC.

		if ($field[$i] =~ /^(\d*)b\.?c\.?$/)
		{
			# Remove BC. Allow for year 0 with defined().

			if (defined($1) && $1)
			{
				$field[$i] = $1;
			}
			else
			{
				# Save offsets so we can remove BC later.

				push @offset_of_bc, $i;
			}

			# Flag which date is BC. They may both be.

			if ( ($offset{two} < 0) || ($i < $offset{two}) )
			{
				$$flags{one_bc} = 1;
			}
			else
			{
				$$flags{two_bc} = 1;
			}
		}
	}

	# Clean up if there is there a BC or 2.

	if ($#offset_of_bc >= 0)
	{
		# Discard 1st BC.

		splice(@field, $offset_of_bc[0], 1);

		# Is there another BC?

		if ($#offset_of_bc > 0)
		{
			# We use - 1 because of the above splice.

			splice(@field, $offset_of_bc[1] - 1, 1);
		}
	}

	# Phase 3: We have 1 or 2 dates without BCs.
	# We process them separately, so we can determine if they are ambiguous.

	if ($offset{one} >= 0)
	{
		my($end) = $offset{two} >= 0 ? $offset{two} - 1 : $#field;

		$self -> _parse_1_date('one',  $flags, @field[($offset{one} + 1) .. $end]);
	}

	if ($offset{two} >= 0)
	{
		my($start) = $offset{two} >= 0 ? $offset{two} + 1 : 0;

		$self -> _parse_1_date('two', $flags, @field[$start .. $#field]);
	}

	# When called from parse_datetime, there will be just 1 date...

	if ( ($offset{one} < 0) && ($offset{two} < 0) )
	{
		$self -> _parse_1_date('one', $flags, @field);
	}

	return $flags;

} # End of _parse_1or2_dates.

# --------------------------------------------------

sub _parse_1_date
{
	my($self, $which, $flags, @field) = @_;

	# Phase 1: Flag an isolated year or a year with a month.

	$$flags{"${which}_ambiguous"} = $#field < 2 ? 1 : 0;

	# Phase 2: Handle missing data.

	if ($#field == 0)
	{
		# This assumes the year is the last and only input field.

		$field[2] = $field[0];
		$field[1] = 1; # Month.
		$field[0] = 1; # Day.
	}
	elsif ($#field == 1)
	{
		# This assumes the year is the last input field, and the month is first.

		$field[2] = $field[1];
		$field[1] = $field[0]; # Month.
		$field[0] = 1;         # Day.
	}

	# Phase 3: Check that the day and year are numeric.
	# Brute force calls via parse_datetime() will fail this test.

	die "Day - '$field[0]' - and year - '$field[2]' - must be numeric" if ( ($field[0] !~ /^\d+$/) || ($field[2] !~ /^\d+$/) );

	# Phase 4: Hand over analysis to our slave.

	my($four_digit_year) = 1;

	if ($field[2] < 1000)
	{
		# DateTime only accepts 4-digit years :-(.

		$field[2]        += 1000;
		$four_digit_year = 0;
	}

	my($candidate)           = join('-', @field);
	$$flags{"${which}_date"} = $self -> formatter -> parse_datetime($candidate);
	$$flags{$which}          = qq|$$flags{"${which}_date"}|;

	die "Unable to parse date: $candidate" if (! $self -> formatter -> success);

	# Phase 5: Replace leading 1 with 0 if we rigged a 4-digit year.

	substr($$flags{$which}, 0, 1) = '0' if (! $four_digit_year);

	# Phase 6: Check is the day is <= 12, in which case it could be a month.

	$$flags{"${which}_ambiguous"} = 1 if (substr($$flags{$which}, 8, 2) <= '12');

} # End of _parse_1_date.

# --------------------------------------------------

sub process_date_escape
{
	my($self, @field) = @_;

	# Phase 1: Check for a date escape.

	my(%escape) =
		(
		 offset   => -1,
		 language => '',
		);

	for my $i (0 .. $#field)
	{
		if ($field[$i] =~ /@#d(.+)@/)
		{
			$escape{offset}   = $i;
			$escape{language} = $1;

			last;
		}
	}

	# Phase 2: Convert month full names or abbreviations into Gregorian abbreviations,
	# as required by DateTime::Format::Natural.

	 if ($escape{language})
	 {
		 # Remove the date escape expression itself.

		 splice(@field, $escape{offset}, 1);

		 # Build look-up tables.

		 my($gregorian_names) = $self -> month_names_in_gregorian;
		 my($method_name)     = "month_names_in_$escape{language}";

		 my($month_names);

		 if ($self -> can($method_name) )
		 {
			 $month_names = $self -> $method_name;
		 }
		 else
		 {
			 die "Unsupported date escape: $escape{language}";
		 }

		 # Convert escaped names or abbreviations into Gregorian abbreviations.

		 my(%name);

		 @name{map{lc} @{$$month_names[1]} } = @{$$gregorian_names[1]};
		 @name{map{lc} @{$$month_names[0]} } = @{$$gregorian_names[1]};

		 # Replace escaped names or abbreviations with Gregorian abbreviations.

		 for my $i (0 .. $#field)
		 {
			 $field[$i] = $name{$field[$i]} if ($name{$field[$i]});
		 }
	 }

	return @field;

} # End of process_date_escape.

# --------------------------------------------------

1;

=pod

=head1 NAME

L<DateTime::Format::Gedcom> - Parse GEDCOM dates

=head1 Synopsis

	my($parser) = DateTime::Format::Gedcom -> new;

	or, in debug mode, which prints progress reports:

	my($parser) = DateTime::Format::Gedcom -> new(debug => 1);

	# These samples are from t/value.t.

	for my $candidate (
	'(Unknown date)', # Use parse_interpreted_date().
	'Abt 1 Jan 2001', # use parse_approximate_date().
	'Aft 1 Jan 2001', # Use parse_date_range().
	'From 0'          # Use parse_date_period().
	)
	{
		my($hashref) = $parser -> parse_date_value(date => $candidate);
	}

See the L</FAQ>'s first QA for the definition of $hashref.
 
L<DateTime::Format::Gedcom> ships with t/date.t, t/escape.t and t/value.t. You are strongly encouraged to peruse them,
and perhaps to set the debug option in each to see extra progress reports.

=head1 Description

L<DateTime::Format::Gedcom> provides a parser for GEDCOM dates.

See L<the GEDCOM Specification Ged551-5.pdf|http://wiki.webtrees.net/File:Ged551-5.pdf>.

=head1 Installation

Install L<DateTime::Format::Gedcom> as you would for any C<Perl> module:

Run:

	cpanm DateTime::Format::Gedcom

or run:

	sudo cpan DateTime::Format::Gedcom

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($parser) = DateTime::Format::Gedcom -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<DateTime::Format::Gedcom>.

Key-value pairs accepted in the parameter list (see corresponding methods for details [e.g. debug()]):

=over 4

=item o date => $a_string

The string to be parsed.

This string is always converted to lower case before being processed.

Default: ''.

This parameter is optional. It can be supplied to new() or to L<parse_approximate_date([%arg])>, L<parse_date_period([%arg])> or L<parse_date_range([%arg])>.

=item o debug => $Boolean

Turn debugging prints off or on.

Default: 0.

This parameter is optional.

=back

=head1 Methods

=head2 debug([$Boolean])

The [] indicate an optional parameter.

Get or set the debug flag.

=head2 month_names_in_dutch()

Returns an arrayref of 2 arrayrefs, the first being the month names in Dutch and the second being the month abbreviations.

=head2 month_names_in_french()

Returns an arrayref of 2 arrayrefs, the first being the month names in French and the second being the month abbreviations.

This uses the French Republican Calendar.

=head2 month_names_in_gregorian()

Returns an arrayref of 2 arrayrefs, the first being the month names in English and the second being the month abbreviations.

=head2 month_names_in_hebrew()

Returns an arrayref of 2 arrayrefs, the first being the month names in Hebrew and the second being the month abbreviations.

=head2 month_names_in_julian()

Returns an arrayref of 2 arrayrefs, the first being the month names in English and the second being the month abbreviations.

There is no difference between the 2 date escapes @#DGregorian@ and @#DJulian@.

=head2 parse_approximate_date([%arg])

Here, the [] indicate an optional parameter.

Parse the candidate date and return a hashref.

The date is expected to be an approximate date as per p. 45 of L<the GEDCOM Specification Ged551-5.pdf|http://wiki.webtrees.net/File:Ged551-5.pdf>.

Key => value pairs for %arg:

=over 4

=item o date => $a_string

Specify the string to parse.

This parameter is optional.

The candidate can be passed in to new as new(date => $a_string), or into this method as parse_approximate_date(date => $a_string).

The string in parse_approximate_date(date => $a_string) takes precedence over the one in new(date => $range).

This string is always converted to lower case before being processed.

Throw an exception if the string cannot be parsed.

=item o prefix => $arrayref

Specify the case-insensitive words, in your language, which indicate an approximate date.

This lets you specify a candidate as 'Abt 1999', 'Cal 2000' or 'Est 1999', and have the code recognize 'Abt', 'Cal' and 'Est'.

This parameter is optional. If supplied, it must be a 3-element arrayref.

The elements of this arrayref are:

=over 4

=item o A string

Default: 'Abt', for 'About'.

=item o A string

Default: 'Cal', for 'Calculated'.

=item o A string

Default: 'Est', for 'Estimated'.

=back

You must use the abbreviated forms of those words.

Note: These arrayref elements are I<not> the same as used by L<parse_date_period([%arg])> nor as used by L<parse_date_range([%arg])>.

These strings are always converted to lower case before being processed.

=back

The return value is a hashref as described in the L</FAQ>'s first QA.

Since a single date is provided, with 'Abt 1999', 'Cal 1999' or 'Est 2000 BC', the date is stored - in the returned hashref - under the 2 keys 'one' and 'one_date'.
The other date in the hashref ('two', 'two_date') is an object of type L<DateTime::Infinite::Future>.

=head2 parse_date_period([%arg])

Here, the [] indicate an optional parameter.

Parse the candidate period and return a hashref.

The date is expected to be a date period as per p. 46 of L<the GEDCOM Specification Ged551-5.pdf|http://wiki.webtrees.net/File:Ged551-5.pdf>.

Key => value pairs for %arg:

=over 4

=item o date => $a_string

Specify the string to parse.

This parameter is optional.

The candidate period can be passed in to new as new(date => $a_string), or into this method as parse_date_period(date => $a_string).

The string in parse_date_period(date => $a_string) takes precedence over the one in new(date => $a_string).

This string is always converted to lower case before being processed.

Throw an exception if the string cannot be parsed.

=item o from_to => $arrayref

Specify the case-insensitive words, in your language, which indicate a date period.

This lets you specify a period as 'From 1999', 'To 2000' or 'From 1999 to 2000', and have the code recognize 'From' and 'To'.

This parameter is optional. If supplied, it must be a 2-element arrayref.

The 'From' and 'To' strings can be passed in to new as new(from_to => $arrayref), or into this method as parse_date_period(from_to => $arrayref).

The elements of this arrayref are:

=over 4

=item o A string

Default: 'From'.

=item o A string

Default: 'To'.

=back

Note: These arrayref elements are I<not> the same as used by L<parse_approximate_date([%arg])> nor as used by L<parse_date_range([%arg])>.

These strings are always converted to lower case before being processed.

=back

The return value is a hashref as described in the L</FAQ>'s first Q and A.

=head2 parse_date_range([%arg])

Here, the [] indicate an optional parameter.

Parse the candidate range and return a hashref.

The date is expected to be a date range as per p. 47 of L<the GEDCOM Specification Ged551-5.pdf|http://wiki.webtrees.net/File:Ged551-5.pdf>.

Key => value pairs for %arg:

=over 4

=item o date => $a_string

Specify the string to parse.

This parameter is optional.

The candidate range can be passed in to new as new(date => $a_string), or into this method as parse_date_range(date => $a_string).

The string in parse_date_range(date => $a_string) takes precedence over the one in new(date => $range).

This string is always converted to lower case before being processed.

Throw an exception if the string cannot be parsed.

=item o from_to => $arrayref

Specify the case-insensitive words, in your language, which indicate a date range.

This lets you specify a range as 'Bef 1999', 'Aft 2000' or 'Bet 1999 and 2000', and have the code recognize 'Bef', 'Aft', 'Bet' and 'And'.

This parameter is optional. If supplied, it must be a 2-element arrayref.

The elements of this arrayref are:

=over 4

=item o An arrayref

Default: ['Aft', 'Bef', 'Bet'], which stand for 'After', 'Before' and 'Between'.

You must use the abbreviated forms of those words.

=item o A string

Default: 'And'.

=back

Note: These arrayref elements are I<not> the same as used by L<parse_approximate_date([%arg])> nor as used by L<parse_date_period([%arg])>.

These strings are always converted to lower case before being processed.

=back

The return value is a hashref as described in the L</FAQ>'s first Q and A.

When a single date is provided, with 'Aft 1999' or 'Bef 2000 BC', the date is stored - in the returned hashref - under the 2 keys 'one' and 'one_date'.
The other date in the hashref ('two', 'two_date') is an object of type L<DateTime::Infinite::Future>.

=head2 parse_date_value(%arg)

Parse the candidate date using a series of methods, until one succeeds or we run out of methods.

See the definition of date_value on p. 47 of L<the GEDCOM Specification Ged551-5.pdf|http://wiki.webtrees.net/File:Ged551-5.pdf>.

The methods are, in this order:

=over 4

=item o parse_date_period

=item o parse_date_range

=item o parse_approximate_date

=item o parse_interpreted_date

=back

In the hash %arg, only the 'date' key is passed to the named method. In each case, the algorithm I<must> use the default for the other key,
since the name and format of that other key depends on the method.

See t/value.t for details.

Throw an exception if the date cannot be parsed.

=head2 parse_datetime($a_string)

Parse the string and return a hashref as described in the L</FAQ>'s first Q and A.

The date is expected to be an exact date as per p. 45 of L<the GEDCOM Specification Ged551-5.pdf|http://wiki.webtrees.net/File:Ged551-5.pdf>.

The string is mandatory.

Throw an exception if the string cannot be parsed.

=head2 parse_interpreted_date([%arg])

Here, the [] indicate an optional parameter.

Parse the candidate date and return a hashref.

The date is expected to be an interpreted date as per the definition of date_value on p. 47 of L<the GEDCOM Specification Ged551-5.pdf|http://wiki.webtrees.net/File:Ged551-5.pdf>.

Key => value pairs for %arg:

=over 4

=item o date => $a_string

Specify the string to parse.

This parameter is optional.

The candidate can be passed in to new as new(date => $a_string), or into this method as parse_interpreted_date(date => $a_string).

The string in parse_interpreted_date(date => $a_string) takes precedence over the one in new(date => $range).

This string is always converted to lower case before being processed.

Throw an exception if the string cannot be parsed.

=item o prefix => $a_string

Specify a case-insensitive word, in your language, which indicates an interpreted date.

This lets you specify a candidate as 'Int 1999', 'Int 2000 (more or less)' or '(Date not known)', and have the code recognize 'Int'.

This parameter is optional. If supplied, it must be a string meaning 'Int'.

This string is always converted to lower case before being processed.

Default: 'Int'.

=back

The return value is a hashref as described in the L</FAQ>'s first Q and A.

Since a single date is provided, with 'Int 1999' or 'Int 1999 (more or less)', the date is stored - in the returned hashref - under the 2 keys 'one' and 'one_date'.
The other date in the hashref ('two', 'two_date') is an object of type L<DateTime::Infinite::Future>.

Also in the returned hashref, the key 'phrase' will have the value of the text between '(' and ')', if any.

=head2 process_date_escape(@field)

Parse the fields of the date, split on ' ' and '-', and return the fields as an array.

In the process, convert month full names and abbreviations to Gregorian abbreviations, because that's what L<DateTime::Format::Natural> expects.

Languages:

=over 4

=item o Dutch, using the escape @#DDutch#

=item o French, using the escape @#DFrench#

=item o Gregorian, using the escape @#DGregorian#

=item o Hebrew, using the escape @#DHebrew#

=item o Julian, using the escape @#DJulian#

=back

Notes:

=over 4

=item o Escape names (Dutch etc) are case-insensitive

=item o @#DFrench@ is for the French Republican Calendar

=item o @#DJulian@ is treated exactly the same as @#DGregorian@

=item o See t/escape.t for details

=back

=head1 FAQ

=head2 What is the format of the hashref returned by parse_*()?

It has these key => value pairs:

=over 4

=item o one => $first_date_in_range

Returns the first (or only) date as a string, after 'Abt', 'Bef', 'From' or whatever.

This is for cases like '1999' in 'abt 1999', '1999' in 'bef 1999, '1999' in 'from 1999', and for '1999' in 'from 1999 to 2000'.

A missing month defaults to 01. A missing day defaults to 01.

'500BC' will be returned as '0500-01-01', with the 'one_bc' flag set. See also the key 'one_date'.

Default: DateTime::Infinite::Past -> new, which stringifies to '-inf'.

The default value does I<not> set the one_ambiguous and one_bc flags.

=item o one_ambiguous => $Boolean

Returns 1 if the first (or only) date is ambiguous. Possibilities:

=over 4

=item o Only the year is present

=item o Only the year and month are present

=item o The day and month are reversible

This is checked for by testing whether or not the day is <= 12, since in that case it could be a month.

=back

Obviously, the 'one_ambiguous' flag can be set for a date specified in a non-ambiguous way, e.g. 'From 1 Jan 2000',
since the numeric value of the month is 1 and the day is also 1.

Default: 0.

=item o one_bc => $Boolean

Returns 1 if the first date is followed by one of (case-insensitive): 'B.C.', 'BC.' or 'BC'.

In the input, this suffix can be separated from the year by spaces, so both '500BC' and '500 B.C.' are accepted.

Default: 0.

=item o one_date => $a_date_object

This object is of type L<DateTime::Format::Natural>, which will actually be an object of type L<DateTime>.

Warning: Since these objects only accept 4-digit years, any year 0 .. 999 will have 1000 added to it.
Of course, the value for the 'one' key will I<not> have 1000 added it.

This means that if the value of the 'one' key does not match the stringified value of the 'one_date' key
(assuming the latter is not '-inf'), then the year is < 1000.

Alternately, if the stringified value of the 'one_date' key is '-inf', the period supplied did not have a 'From' date.

Default: DateTime::Infinite::Past -> new, which stringifies to '-inf'.

=item o phrase => $string

This holds the text, if any, between '(' and ')' in an interpreted date.

Default: ''.

=item o prefix => $string

Possible values for the prefix:

=over 4

=item o 'abt', given the approximate date 'Abt 1999'

=item o 'aft', given the date range 'Aft 1999'

=item o 'bef', given the date range 'Bef 1999'

=item o 'bet', given the date range 'Bet 1999 and 2000'

=item o 'cal', given the approximate date 'Cal 1999'

=item o 'est', given the approximate date 'Est 1999'

=item o 'from', given the date period 'From 1999' or 'From 1999 to 2000'

=item o 'int', given the interpreted date 'Int 1999 (Guesswork)'

=item o 'phrase', given the date phrase '(Unknown)'

=item o 'to', given the date period 'To 2000'

=back

Default: ''.

=item o two => $second_date_in_range

Returns the second (or only) date as a string, after 'and' in 'bet 1999 and 2000', or 'to' in 'from 1999 to 2000', or '2000' in 'to 2000'.

A missing month defaults to 01. A missing day defaults to 01.

'500BC' will be returned as '0500-01-01', with the 'two_bc' flag set. See also the key 'two_date'.

Default: DateTime::Infinite::Future -> new, which stringifies to 'inf'.

The default value does I<not> set the two_ambiguous and two_bc flags.

=item o two_ambiguous => $Boolean

Returns 1 if the second (or only) date is ambiguous. Possibilities:

=over 4

=item o Only the year is present

=item o Only the year and month are present

=item o The day and month are reversible

This is checked for by testing whether or not the day is <= 12, since in that case it could be a month.

=back

Obviously, the 'two_ambiguous' flag can be set for a date specified in a non-ambiguous way, e.g. 'To 1 Jan 2000',
since the numeric value of the month is 1 and the day is also 1.

Default: 0.

=item o two_bc => $Boolean

Returns 1 if the second date is followed by one of (case-insensitive): 'B.C.', 'BC.' or 'BC'.

In the input, this suffix can be separated from the year by spaces, so both '500BC' and '500 B.C.' are accepted.

Default: 0.

=item o two_date => $a_date_object

This object is of type L<DateTime::Format::Natural>, which will actually be an object of type L<DateTime>.

Warning: Since these objects only accept 4-digit years, any year 0 .. 999 will have 1000 added to it.
Of course, the value for the 'two' key will I<not> have 1000 added it.

This means that if the value of the 'two' key does not match the stringified value of the 'two_date' key
(assuming the latter is not 'inf'), then the year is < 1000.

Alternately, if the stringified value of the 'two_date' key is 'inf', the period supplied did not have a 'To' date.

Default: DateTime::Infinite::Future -> new, which stringifies to 'inf'.

=back

=head2 Why are dates returned as objects of type L<DateTime>?

Because such objects have the sophistication required to handle such a complex topic.

See L<DateTime> and L<http://datetime.perl.org/wiki/datetime/dashboard> for details.

=head2 What happens if parse_date_period() is given a string like 'From 2000 to 1999'?

Then the returned hashref will have:

=over 4

=item o one => '2000-01-01T00:00:00'

=item o two => '1999-01-01T00:00:00'

=back

Clearly then, the code I<does not> reorder the dates.

=head2 Why did you choose L<Hash::FieldHash> over L<Moose>?

My policy is to use the lightweight L<Hash::FieldHash> for stand-alone modules and L<Moose> for applications.

=head1 TODO

=over 4

=item o Handle Gregorian years of the form 1699/00

See p. 65 of L<the GEDCOM Specification Ged551-5.pdf|http://wiki.webtrees.net/File:Ged551-5.pdf>.

=item o Test input file for binary

=item o Test input file for non-ASCII character sets

=item o Test input file for size 0

=item o Tighten validation

=back

=head1 Machine-Readable Change Log

The file CHANGES was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=DateTime::Format::Gedcom>.

=head1 Thanx

Thanx to Eugene van der Pijll, the author of the Gedcom::Date::* modules.

Thanx also to the authors of the DateTime::* family of modules. See L<http://datetime.perl.org/wiki/datetime/dashboard> for details.

=head1 Author

L<DateTime::Format::Gedcom> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
