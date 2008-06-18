#!perl -T

use warnings;
use strict;

use Test::More;
use XML::Spice;

eval "use Test::XML";
if ($@) {
    plan skip_all => "Test::XML required for coderef tests";
}
else {
    plan "no_plan";
}

is_xml(x("foo", "bar", x("what", "lol")),
       x("foo", undef, "bar", x("what", "lol", ""), undef),
        "undefs and empty strings are silently ignored");
