# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Geo-Converter-dms2dd.t'

#########################

use strict;
use warnings;
use English qw { -no_match_vars };

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;

BEGIN { use_ok('Geo::Converter::dms2dd') };

use Geo::Converter::dms2dd qw {dms2dd};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $dms_coord;
my $dd_coord;
 
my @coords = (
    
    {   coord    => q{S23},
        expected => -23,
        args     => {},
    },
    {   coord    => q{S23°30},
        expected => -23.5,
        args     => {},
    },
    {   coord    => q{S23°0},
        expected => -23,
        args     => {},
    },
    {   coord    => q{S23°60},
        expected => -24,
        args     => {},
    },
    {   coord    => q{S23°30'30},
        expected => -23.508333333333333,
        args     => {},
    },
    
    {   coord    => q{S23°32'09.567"},
        expected => -23.5359908333333,
        args     => {},
    },
    {   coord    => q{S23°32'09.567"},
        expected => -23.5359908333333,
        args     => {is_lat => 1},
    },
    {   coord    => q{23°32'09.567"},
        expected => 23.5359908333333,
        args     => {},
    },
    {   coord    => q{n23°32'09.567"},
        expected => 23.5359908333333,
        args     => {is_lat => 1},
    },
    {   coord    => q{149°23'18.009"E},
        expected => 149.388335833333,
        args     => {},
    },
    {   coord    => q{149°23'18.009"E},
        expected => 149.388335833333,
        args     => {is_lon => 1},
    },
    {   coord    => q{149°23'18.009"W},
        expected => -149.388335833333,
        args     => {is_lon => 1},
    },

    {   coord    => q{east 149°23'18.009},
        expected => 149.388335833333,
        args     => {},
    },
    {   coord    => q{east 149°23'18.009},
        expected => 149.388335833333,
        args     => {is_lon => 1},
    },
    {   coord    => q{east 149°23'18.009},
        expected => 149.388335833333,
        args     => {irrelevant_arg => 1},
    },
    {   coord    => q{149°23'18.009"blurgle},
        expected => 149.388335833333,
        args     => {},
    },
    
);

foreach my $condition (@coords) {
    my %cond = %$condition;
    my ($value, $expected, $args) = @cond{qw /coord expected args/};
    $dd_coord  = dms2dd ({coord => $value, %$args});
    my $feedback = "coord => $value, " . join q{, }, %$args;
    is ($dd_coord, $expected, $feedback);
}

#  no coord arg passed
my $result = eval {
    dms2dd ();
};
my $error = $EVAL_ERROR;
my $text = '';
if ($error =~ /(^.+?)\n/) {
    $text = $1;
}
ok (defined $error, "Trapped error: $text");


#  The following all croak with warnings,
my @croakers = (
    { coord => q{S23°32'09.567"},   args => {is_lon => 1}  },
    { coord => q{149°23'18.009"E},  args => {is_lat => 1}  },
    { coord => q{149°23'18.009"25}, args => {}             },
    { coord => q{}                , args => {}             },
    { coord => q{"blurgle "}      , args => {}             },
    { coord => q{149.25°23'18"}   , args => {}             },
    { coord => q{149°23.25'18"}   , args => {}             },
    {   coord    => q{W149°23'18.009"E},
        args     => {},
    },
    {   coord    => q{W149°23'18.009"W},
        args     => {},
    },

);

foreach my $condition (@croakers) {
    my $value = $condition->{coord};
    my $args  = $condition->{args}; 
    my $function_args = {coord => $value, %$args};
    $dd_coord = eval {
        dms2dd ($function_args)
    };
    my $error = $EVAL_ERROR;

    my $text = '';
    if ($error =~ /(^.+?)\n/) {
        $text = $1;
    }

    ok ($error, "Trapped error: $text");
}

done_testing();
