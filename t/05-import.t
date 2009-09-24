#!perl -T

use warnings;
use strict;

use Test::More tests => 9;


# deliberately don't import
BEGIN {
    require XML::Spice;
}


# no args pulls in x() and nothing more
package noargs;

import XML::Spice;

main::ok(__PACKAGE__->can("x"), "x() should be imported by default");


# create some generators, these shouldn't bring in x()
package nox;

import XML::Spice qw(foo bar baz);

main::ok(__PACKAGE__->can("foo"), "foo() should be imported");
main::ok(__PACKAGE__->can("bar"), "bar() should be imported");
main::ok(__PACKAGE__->can("baz"), "baz() should be imported");
main::ok(!__PACKAGE__->can("x"), "x() should not be imported when tags are explicitly asked for");


# create some generators with alternate names
package alternates;

import XML::Spice qw(foo=bar baz=quux);

main::ok(__PACKAGE__->can("foo"), "foo() should be imported");
main::ok(!__PACKAGE__->can("bar"), "bar() should not be imported");
main::ok(__PACKAGE__->can("foo"), "baz() should be imported");
main::ok(!__PACKAGE__->can("quux"), "quux() should not be imported");
