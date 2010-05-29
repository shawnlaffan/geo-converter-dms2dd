#  package to convert degrees minutes seconds coords to decimal degrees
#  also does some simple validation of decimal degree values as a side effect
package Geo::Converter::dms2dd;

use strict;
use warnings;

our $VERSION = '1';

use Carp;

use Readonly;
use Regexp::Common;
use English qw { -no_match_vars };

require Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw( dms2dd );

#############################################################
##  some stuff to handle coords in degrees 

#  some regexes
Readonly my $RE_REAL => qr /$RE{num}{real}/xms;
Readonly my $RE_INT  => qr /$RE{num}{int} /xms;
Readonly my $RE_HEMI => qr {
                            #  the hemisphere if given as text
                            \s*
                            [NESWnesw]
                            \s*
                        }xms;

#  a few constants
Readonly my $MAX_VALID_DD  => 360;
Readonly my $MAX_VALID_LAT => 90;
Readonly my $MAX_VALID_LON => 180;

Readonly my $INVALID_CHAR_CONTEXT => 3;

#  how many numbers we can have in a DMS string
Readonly my $MAX_DMS_NUM_COUNT => 3;

#  convert degrees minutes seconds coords into decimal degrees
#  e.g.;
#  S23�32'09.567"  = -23.5359908333333
#  149�23'18.009"E = 149.388335833333
sub dms2dd {
    my $args = shift;

    my $coord = $args->{coord};
    croak "Argument 'coord' not supplied\n"
      if !defined $coord;

    my $msg_pfx = 'Coord error: ';

    my $first_char_invalid;
    if (not $coord =~ m/ \A [\s0-9NEWSnews+-] /xms) {
        $first_char_invalid = substr $coord, 0, $INVALID_CHAR_CONTEXT;
    }

    croak $msg_pfx . "Invalid string at start of coord: $coord\n"
      if defined $first_char_invalid;

    my @nums = eval {
        _dms2dd_extract_nums ( { coord => $coord } );
    };
    croak $EVAL_ERROR if ($EVAL_ERROR);

    my $deg = $nums[0];
    my $min = $nums[1];
    my $sec = $nums[2];

    my $hemi = eval {
        _dms2dd_extract_hemisphere (
            { coord => $coord },
        );
    };
    croak $EVAL_ERROR if $EVAL_ERROR;

    my $multiplier = 1;
    if ($hemi =~ / [SsWw-] /xms) {
        $multiplier = -1;
    }

    #  now apply the defaults
    #  $deg is +ve, as hemispheres are handled separately
    $deg = abs ($deg) || 0;
    $min = $min || 0;
    $sec = $sec || 0;

    my $dd = $multiplier
            * (   $deg
                + $min / 60
                + $sec / 3600
              );

    my $valid = eval {
        _dms2dd_validate_dd_coord ( {
            %{$args},
            coord       => $dd,
            hemisphere  => $hemi,
        } );
    };
    croak $EVAL_ERROR if $EVAL_ERROR;

    #my $res = join (q{ }, $coord, $dd, $multiplier, $hemi, @nums) . "\n";

    return $dd;
}

#  are the numbers we extracted OK?
#  must find three or fewer of which only the last can be decimal 
sub _dms2dd_extract_nums {
    my $args = shift;

    my $coord = $args->{coord};

    my @nums = $coord =~ m/$RE_REAL/gxms;
    my $deg = $nums[0];
    my $min = $nums[1];
    my $sec = $nums[2];

    #  some verification
    my $msg;

    if (! defined $deg) {
        $msg = 'No numeric values in string';
    }
    elsif (scalar @nums > $MAX_DMS_NUM_COUNT) {
        $msg = 'Too many numbers in string';
    }

    if (defined $sec) {
        if ($min !~ / \A $RE_INT \z/xms) {
            $msg = 'Seconds value given, but minutes value is floating point';
        }
        elsif ($sec < 0 || $sec > 60) {
            $msg = 'Seconds value is out of range';
        }
    }
    
    if (defined $min) {
        if ($deg !~ / \A $RE_INT \z/xms) {
            $msg = 'Minutes value given, but degrees value is floating point';
        }
        elsif ($min < 0 || $min > 60) {
            $msg = 'Minutes value is out of range';
        }
    }

    #  the valid degrees values depend on the hemisphere,
    #  so are trapped elsewhere

    my $msg_pfx     = 'DMS coord error: ';
    my $msg_suffix  = qq{: '$coord'\n};

    croak $msg_pfx . $msg . $msg_suffix
        if $msg;

    return wantarray ? @nums : \@nums;
}

sub _dms2dd_validate_dd_coord {
    my $args = shift;

    my $is_lat = $args->{is_lat};
    my $is_lon = $args->{is_lon};

    my $dd   = $args->{coord};
    my $hemi = $args->{hemisphere};

    my $msg_pfx = 'Coord error: ';
    my $msg;

    #  if we know the hemisphere then check it is in bounds,
    #  otherwise it must be in the interval [-180,360]
    if ($is_lat || $hemi =~ / [SsNn] /xms) {
        if ($is_lon) {
            $msg = "Longitude specified, but latitude found\n"
        }
        elsif (abs ($dd) > $MAX_VALID_LAT) {
            $msg = "Latitude out of bounds: $dd\n"
        }
    }
    elsif ($is_lon || $hemi =~ / [EeWw] /xms) {
        if ($is_lat) {
            $msg = "Latitude specified, but longitude found\n"
        }
        elsif (abs ($dd) > $MAX_VALID_LON) {
            $msg = "Longitude out of bounds: $dd\n"
        }
    }
    elsif ($dd < -180 || $dd > $MAX_VALID_DD) {
        croak "Coord out of bounds\n";
    }
    croak "$msg_pfx $msg" if $msg;

    return 1;
}

sub _dms2dd_extract_hemisphere {
    my $args = shift;

    my $coord = $args->{coord};

    my $hemi;
    #  can start with [NESWnesw-]
    if ($coord =~ m/ \A ( $RE_HEMI | [-] )/xms) {
        $hemi = $1;
    }
    #  cannot end with [-]
    if ($coord =~ m/ ( $RE_HEMI ) \z /xms) {
        my $hemi_end = $1;

        croak "Cannot define hemisphere twice: $coord\n"
          if (defined $hemi && defined $hemi_end);

        $hemi = $hemi_end;
    }
    if (! defined $hemi) {
        $hemi = q{};
    }

    return $hemi;
}


1;


=pod

=head1 NAME

Geo::Converter::dms2dd

=head1 VERSION

1

=head1 SYNOPSIS

 use Geo::Converter::dms2dd qw { dms2dd };

 my $dms_coord;
 my $dd_coord;
 
 $dms_coord = q{S23�32'09.567"};
 $dd_coord  = dms2dd ({coord => $dms_coord});
 print $dms_coord
 #  -23.5359908333333

 $dms_coord = q{149�23'18.009"E};
 $dd_coord  = dms2dd ({coord => $dms_coord});
 print $dd_coord
 #   149.388335833333
 
 $dms_coord = q{east 149�23'18.009};
 $dd_coord  = dms2dd ({coord => $dms_coord});
 print $dd_coord
 #   149.388335833333
 
 
 #  The following all croak with warnings:
 
 $dms_coord = q{S23�32'09.567"};
 $dd_coord  = dms2dd ({coord => $dms_coord, is_lon => 1});
 # Coord error:  Longitude specified, but latitude found

 $dms_coord = q{149�23'18.009"E};
 $dd_coord  = dms2dd ({coord => $dms_coord, is_lat => 1});
 # Coord error:  Latitude out of bounds: 149.388335833333
 
 $dms_coord = q{149�23'18.009"25};  #  extra number
 $dd_coord  = dms2dd ({coord => $dms_coord});
 # DMS coord error: Too many numbers in string: '149�23'18.009"25'


=head1 DESCRIPTION

Use this module to convert a coordinate value in degrees minutes seconds
to decimal degrees.  It exports a single sub C<dms2dd> which will
parse and convert a single value.

A reasonable amount of location information is provided in
degrees/minutes/seconds (DMS) format, for example from Google Earth, GIS packages or
similar.  For example, one might be given a location coordinate for just north east
of Dingo in Queensland, Australia.  Four possible formats are:

 S23�32'09.567", E149�23'18.009"
 23�32'09.567"S, 149�23'18.009"E
 -23 32 9.567,   +149 23 18.009
 -23.535991,     149.388336

The first three coordinates are in degrees/minutes/seconds while the fourth
is in decimal degrees.  The fourth coordinate can be used in numeric
calculations, but the first three must first be converted to decimal degrees.

The conversion process used in dms2dd is pretty generous in what it treats as DMS,
as there is a multitude of variations in punctuation and the like.
Up to three numeric values are extracted and any additional text is largely
ignored unless it specifies the hemisphere.  It croaks if there are four or more values.
If the hemisphere is known or the C<is_lat> or C<is_lon> arguments are specified then
values are validated (e.g. latitudes must be in the interval [-90, 90], 
and longitudes with a hemisphere specified must be within [-180, 180]).  
Otherwise values between [-180, 360] are accepted.  If seconds are specified
and minutes have values after the radix (decimal point) then it croaks
(e.g. 35 26.5' 22").  Likewise, it croaks for cases like (35.2d 26').

Note that this module only works on a single value. 
Call it once each for latitude and longitude values to convert a full coordinate.

=head1 AUTHOR

Shawn Laffan S<(I<shawnlaffan@gmail.com>)>.

=head1 BUGS AND IRRITATIONS

This is part of the Biodiverse project, so
submit bug, fixes and enhancement requests via the bug tracker
at L<http://www.purl.org/biodiverse>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=head1 See also

L<Geo::Coordinates::DecimalDegrees>, although it requires the
degrees, minutes and seconds values to already be parsed from the string.

=cut


