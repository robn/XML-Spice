#!perl -T

use warnings;
use strict;

use Test::More tests => 12;


# deliberately don't import
BEGIN {
    require XML::Spice;
}


# no args pulls in x() and nothing more
package noargs;

import XML::Spice;

main::ok(__PACKAGE__->can("x"), "x() should be imported by default");


# expressly don't pull x()
package noimport;

import XML::Spice qw/-nox/;

main::ok(!__PACKAGE__->can("x"), "x() should not be imported when -nox is used");


# create some functions, these shouldn't bring in x()
package custom;

import XML::Spice qw/foo bar baz/;

main::ok(__PACKAGE__->can("foo"), "foo() should be imported");
main::ok(__PACKAGE__->can("bar"), "bar() should be imported");
main::ok(__PACKAGE__->can("baz"), "baz() should be imported");
main::ok(!__PACKAGE__->can("x"), "x() should not be imported when tags are explicitly asked for");


# create stuff and bring in x
package custom::x;

import XML::Spice qw/foo bar baz -x/;

main::ok(__PACKAGE__->can("foo"), "foo() should be imported");
main::ok(__PACKAGE__->can("bar"), "bar() should be imported");
main::ok(__PACKAGE__->can("baz"), "baz() should be imported");
main::ok(__PACKAGE__->can("x"), "x() should be imported when -x is used");


# import x() as something else
package custom::rename;

import XML::Spice qw/-x=xml/;

main::ok(__PACKAGE__->can("xml"), "xml() should be imported when asked for by name");
main::ok(!__PACKAGE__->can("x"), "x() should not be imported when -x gave a name");
