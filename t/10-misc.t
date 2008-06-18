#!perl -T

use warnings;
use strict;

use Test::More tests => 1;
use Test::XML;
use XML::Spice;

is_xml(x("foo", "bar", x("what", "lol")),
       x("foo", undef, "bar", x("what", "lol", ""), undef),
        "undefs and empty strings are silently ignored");
