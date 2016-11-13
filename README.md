[![Build Status](https://secure.travis-ci.org/robn/XML-Spice.png)](http://travis-ci.org/robn/XML-Spice)

# NAME

XML::Spice - generating XML has never been so Perly!

# SYNOPSIS

    use XML::Spice qw(html head title body h1 p a);

    print
        html(
            head(
                title("my great page"),
            ),
            body(
                h1("my great page"),
                p("this is my great page, made with ", 
                  a("spice", { href => "http://en.wikipedia.org/wiki/Spice/" }),
                ),
            ),
        );

# DESCRIPTION

XML::Spice is yet another XML generation module. It tries to take some of the
pain out of generating XML by making it more like Perl.

Unless you've got a really good module for producing XML for your particular
use (like a module for interfacing with a specific web service), you've
probably found that you end up resorting to code like this:

    my $xml = q{<foo><bar><baz /></bar><quux /></foo>};

Of course this works great, and you can't beat it for speed, but it quickly
becomes difficult to work with. Your syntax highlighting probably just
displays it as a giant string. You can't easily see mismatched brackets or
other bugs until your code runs and tries to parse the thing. And, once you
start adding attributes and character data into the mix, it rapidly moves
towards being impossible to read.

Instead of this, you could use XML::Spice and write the same thing in Perl:

    my $xml = foo(bar(baz()), quux());

You'll can add liberal amounts of whitespace to convey structure without it
making your output larger. You get Perl checking to make sure that you haven't
left anything out. You can use all the power of Perl to generate and include
data without having to pepper your code with interpolated strings or
concatenation operators. And you get a guarantee that the XML produced is
valid.

# BASIC USAGE

If you `use` (or `import`) XML::Spice without any arguments, it will export
a single function `x()` into your package. This is the only real function in
XML::Spice, and its used to implement everything else.

`x()` generates a single element, which in turn can contain attributes,
character data, sub-elements (via additional calls to `x()`), and more. The
general format for `x()` is:

    my $xml = x("element", ...);

The first argument is required, and is always the name of the element to
generate. So `x("foo")` produces `<foo/>`.

Generally though, you'll want to use the more readable named functions to do
the work. You get these by providing arguments to XML::Spice when you `use`
it (or call `import`). For example:

    use XML::Spice qw(foo bar baz);

This will export three functions into your package, `foo()`, `bar()` and
`baz()`, and _won't_ import `x()`. Calling these functions produces the
same results as calling `x()` with the name as the first argument, that is:

    my $xml = foo(...);

produces identical results to:

    my $xml = x("foo", ...);

`x()` returns an `XML::Spice::Chunk` object, which when stringified (ie
`print`ed or interpolated into a string) produces the XML of its input.
Generally you won't care, you'll just stringify it and be done with it. There
are however some rather clever things that can be done by having the return
value be an object instead of a normal string; see ["ADVANCED USAGE"](#advanced-usage) for
details.

# ARGUMENTS

`x()` can take zero or more additional arguments. These arguments define what
else gets added to the element. What happens depends on what you pass.

- attributes

    Attributes are added to the element by passing a hash reference, eg:

        img({ src => "hello.jpg" });

    produces:

        <img src='hello.jpg' />

    If you pass multiple hash references, their contents are combined, with the
    value from the last hash passed being used in the case of a conflict.

- sub-elements

    Sub-elements are included in an element by passing the output from another
    call to `x()`, eg:

        foo(bar());

    produces:

        <foo><bar /></foo>

- character data

    Character data is added to the element by passing simple strings, eg:

        p("this is my paragraph");

    produces:

        <p>this is my paragraph</p>

These arguments can be mixed as much as you like, eg:

    p("Visit my ", a({ href => "http://homepage.com/"}, "homepage"), " for more information.");

produces:

    <p>Visit my <a href='http://homepage.com/'>homepage</a> for more information.</p>

Other things can be passed to `x()`; those are described in ["ADVANCED
USAGE"](#advanced-usage).

# ADVANCED USAGE

## Dynamic tree generation

The most important thing to understand about the `XML::Spice::Chunk` objects
returned by `x()` is that they do nothing until they are stringified to
produce XML output. This makes it possible to pass code references or even
other objects to `x()` and have them dynamically generate data to be included
in the produced XML.

If a code reference is passed to `x()`, it is called when the resultant
`XML::Spice::Chunk` is stringified and its output is included at the position
that the code reference was at, eg:

    p("the time is ", sub { scalar localtime });

would produce something like:

    <p>the time is Sat Sep 26 22:32:57 2009</p>

`XML::Spice::Chunk` will recursively evaluate the result from the code
reference until it gets down to basic strings and hash references as described
in ["BASIC USAGE"](#basic-usage). This is great for producing lists of things, eg:

    my $list = ul(sub {
        my @results;
        opendir my $dir, "images";
        push @results, li($_) for grep { m/\.png$/ } readdir $dir;
        closedir $dir;
        return @results;
    });

When `$list` is stringified, the sub will be called and would return a list
of `XML::Spice::Chunk` objects. These in turn will be stringified until
eventually only strings are left and output like the following is produced:

    <ul><li>foo.png</li><li>bar.png</li><li>baz.png</li></ul>

Had the sub itself returned a code reference, then that in turn would have
been called and its output used.

The code reference is called every time the `XML::Spice::Chunk` object is
stringified. If the computed result will not change, consider caching the
result.

To support this, the following things may be passed to `x()` (and thus
returned by code references or objects):

- undef

    If `undef` is passed to `x()`, it is ignored. That is:

        foo("bar", undef, "baz");

    is exactly equivalent to:

        foo("bar", "baz");

    and produces:

        <foo>barbaz</foo>

- array reference

    If an array reference is passed to `x()`, it is flattened. That is:

        foo("bar", [ baz(), "quux" ]);

    is exactly equivalent to:

        foo("bar", baz(), "quux");

    and produces:

        <foo>bar<baz />quux</foo>

## Result cache

A chunk is only evaluated the first time it is stringified. The result is
cached and each subsequent stringification will return the cached result. If
you wanted to reuse a chunk (eg if it has a coderef in it that does a database
lookup), you can call its `forget()` method to remove the cached result. The
next time it is stringified it will be reevaluated from scratch.

# PRETTY PRINTING

`XML::Spice` can produce pretty-printed output. Because the additional
whitespace subtly changes the semantics of the generated XML this is only
intended as a debugging feature. This also disables the result cache.

To use it, you'll need the [XML::Tidy::Tiny](https://metacpan.org/pod/XML::Tidy::Tiny) module installed. Then to enable
it, set (and localise!) `$XML::Spice::PRETTY_PRINT` to a true value before
stringifying a chunk.

# TODO

- Optimised namespace declarations

    If two sub-chunks declare the same namespace, then move the declaration to the
    parent chunk.

# BUGS AND LIMITATIONS

This module guarantees that the XML it produces will be valid and semantically
equivalent to the input you give it, but it makes no guarantees and gives no
control over things like use of entity encoding vs. CDATA sections,
declaration of namespaces and use of prefixes, and so forth. The method used
may change between releases, producing different results. If you require exact
control over the details of the XML produced, then this module is not for you.

# SUPPORT

## Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at [https://github.com/robn/XML-Spice/issues](https://github.com/robn/XML-Spice/issues).
You will be notified automatically of any progress on your issue.

## Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

[https://github.com/robn/XML-Spice](https://github.com/robn/XML-Spice)

    git clone https://github.com/robn/XML-Spice.git

# AUTHORS

- Robert Norris <rob@eatenbyagrue.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2006-2016 by Robert Norris.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
