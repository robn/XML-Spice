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

is_xml(
    qq(<tag>text</tag>),
    x("tag", sub { "text" }),
    "basic text substitution");

is_xml(
    qq(<tag><sub>thunk</sub></tag>),
    x("tag", sub { x("sub", "thunk") }),
    "tree substitution");

my $count = 0;
sub inc {
    return $count++;
}
is_xml(
    qq(<count><val>0</val><val>1</val><val>2</val></count>),
    x("count", map { x("val", \&inc) } (0..2)),
    "lazy evaluation");
