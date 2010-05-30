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

my $dd_value;
 
my @values = (
    {   value    => q{S23},
        expected => -23,
        args     => {},
    },
    {   value    => q{S23�30},
        expected => -23.5,
        args     => {},
    },
    {   value    => q{S23�0},
        expected => -23,
        args     => {},
    },
    {   value    => q{S23�60},
        expected => -24,
        args     => {},
    },
    {   value    => q{S23�30'30},
        expected => -23.508333333333333,
        args     => {},
    },
    
    {   value    => q{S23�32'09.567"},
        expected => -23.5359908333333,
        args     => {},
    },
    {   value    => q{S23�32'09.567"},
        expected => -23.5359908333333,
        args     => {is_lat => 1},
    },
    {   value    => q{23�32'09.567"},
        expected => 23.5359908333333,
        args     => {},
    },
    {   value    => q{n23�32'09.567"},
        expected => 23.5359908333333,
        args     => {is_lat => 1},
    },
    {   value    => q{149�23'18.009"E},
        expected => 149.388335833333,
        args     => {},
    },
    {   value    => q{149�23'18.009"E},
        expected => 149.388335833333,
        args     => {is_lon => 1},
    },
    {   value    => q{149�23'18.009"W},
        expected => -149.388335833333,
        args     => {is_lon => 1},
    },

    {   value    => q{east 149�23'18.009},
        expected => 149.388335833333,
        args     => {},
    },
    {   value    => q{east 149�23'18.009},
        expected => 149.388335833333,
        args     => {is_lon => 1},
    },
    {   value    => q{east 149�23'18.009},
        expected => 149.388335833333,
        args     => {irrelevant_arg => 1},
    },
    {   value    => q{149�23'18.009"blurgle},
        expected => 149.388335833333,
        args     => {},
    },
    
);

foreach my $condition (@values) {
    my %cond = %$condition;
    my ($value, $expected, $args) = @cond{qw /value expected args/};
    $dd_value  = dms2dd ({value => $value, %$args});
    my $feedback = "value => $value, " . join q{, }, %$args;
    is ($dd_value, $expected, $feedback);
}

#  no value arg passed
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
    { value => q{S23�32'09.567"},   args => {is_lon => 1}  },
    { value => q{149�23'18.009"E},  args => {is_lat => 1}  },
    { value => q{149�23'18.009"25}, args => {}             },
    { value => q{}                , args => {}             },
    { value => q{"blurgle "}      , args => {}             },
    { value => q{149.25�23'18"}   , args => {}             },
    { value => q{149�23.25'18"}   , args => {}             },
    {   value    => q{W149�23'18.009"E},
        args     => {},
    },
    {   value    => q{W149�23'18.009"W},
        args     => {},
    },

);

foreach my $condition (@croakers) {
    my $value = $condition->{value};
    my $args  = $condition->{args}; 
    my $function_args = {value => $value, %$args};
    $dd_value = eval {
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
