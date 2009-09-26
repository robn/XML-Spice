package XML::Spice;

use warnings;
use strict;

use Carp;

our $VERSION = "0.01";

sub import {
    my ($pkg, @args) = @_;

    my $them = caller();

    my $want_x = 1;

    for my $arg (@args) {
        my ($name, $tag);

        if ($arg =~ m/^(\w+)$/) {
            $name = $1;
            $tag = $name;
        }

        elsif ($arg =~ m/^(\w+)=(\w+)$/) {
            $name = $1;
            $tag = $2;
        }

        else {
            croak qq{Unknown option "$arg"};
        }

        if ($name && $tag) {
            $want_x = 0;

            {
                no strict "refs";
                *{$them."::".$name} = sub { x($tag, @_) };
            }
        }
    }

    if ($want_x) {
        no strict "refs";
        *{$them."::x"} = \&x;
    }
}

sub x {
    my ($tag, @args) = @_;

    my $chunk = {
        tag => $tag,
    };
    
    for my $arg (@args) {
        if (ref $arg eq "HASH") {
            $chunk->{attrs} = $arg;
        }

        else {
            push @{$chunk->{sub}}, $arg;
        }
    }

    return bless $chunk, "XML::Spice::Chunk";
}


package # hide from PAUSE
    XML::Spice::Chunk;

use warnings;
use strict;

use overload
    '""' => \&_xml;

sub _xml {
    my ($chunk) = @_;

    if (exists $chunk->{dirty}) {
        delete $chunk->{cached};
        delete $chunk->{dirty};
    }
    
    elsif (exists $chunk->{cached}) {
        return $chunk->{cached};
    }

    my $xml = "<" . $chunk->{tag};

    sub _escape_attr {
        my ($val) = @_;
        $val =~ s/'/&apos;/g;
        return $val;
    }
        

    for my $attr (keys %{$chunk->{attrs}}) {
        $xml .= " $attr='" . _escape_attr($chunk->{attrs}->{$attr}) . "'";
    }
    
    if (!exists $chunk->{sub}) {
        $xml .= "/>";
        $chunk->{cached} = $xml;
        return $xml;
    }

    $xml .= ">";

    sub _escape_cdata {
        my ($val) = @_;
        $val =~ s/&/&amp;/g;
        $val =~ s/</&lt;/g;
        $val =~ s/>/&gt;/g;
        return $val;
    }

    for my $sub (@{$chunk->{sub}}) {
        next if ! defined $sub;

        if(ref $sub eq "CODE") {
            $sub = &{$sub};
        }

        if(ref $sub eq "XML::Spice::Chunk") {
            $xml .= $sub->_xml;
        }

        else {
            next if $sub eq "";
            $xml .= _escape_cdata($sub);
        }
    }

    $xml .= "</" . $chunk->{tag} . ">";

    $chunk->{cached} = $xml;
    return $xml;
}


1;

__END__

=pod

=head1 NAME

XML::Spice - makes generating XML taste great!

=head1 SYNOPSIS

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

=head1 DESCRIPTION

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

=head1 BASIC USAGE

If you C<use> (or C<import>) XML::Spice without any arguments, it will export
a single function C<x()> into your package. This is the only real function in
XML::Spice, and its used to implement everything else.

C<x()> generates a single element, which in turn can contain attributes,
character data, sub-elements (via additional calls to C<x()>), and more. The
general format for C<x()> is:

    my $xml = x("element", ...);

The first argument is required, and is always the name of the element to
generate. So C<x("foo")> produces C<E<lt>foo/E<gt>>.

Generally though, you'll want to use the more readable named functions to do
the work. You get these by providing arguments to XML::Spice when you C<use>
it (or call C<import>). For example:

    use XML::Spice qw(foo bar baz);

This will export three functions into your package, C<foo()>, C<bar()> and
C<baz()>, and I<won't> import C<x()>. Calling these functions produces the
same results as calling C<x()> with the name as the first argument, that is:

    my $xml = foo(...);

produces identical results to:

    my $xml = x("foo", ...);

C<x()> (and variants) returns an C<XML::Spice::Chunk> object, which when
stringified (ie C<print>ed or interpolated into a string) produces the XML of
its input. Generally you won't care, you'll just stringify it and be done with
it. There are however some rather clever things that can be done by having the
return value be an object instead of a normal string; see L</ADVANCED USAGE>
for details.

=head1 ARGUMENTS

C<x()> (or variants) can take zero or more additional arguments. These
arguments define what else gets added to the element. What happens depends on
what you pass.

=over

=item attributes

Attributes are added to the element by passing a hash reference, eg:

    img({ src => "hello.jpg" });

produces:

    <img src='hello.jpg' />

If you pass multiple hash references, their contents are combined, with the
value from the last hash passed being used in the case of a conflict.

=item sub-elements

Sub-elements are included in an element by passing the output from another
call to C<x()> (or variants), eg:

    foo(bar());

produces:

    <foo><bar /></foo>

=item character data

Character data is added to the element by passing simple strings, eg:

    p("this is my paragraph");

produces:

    <p>this is my paragraph</p>

=back

These arguments can be mixed as much as you like, eg:

    p("Visit my ", a({ href => "http://homepage.com/"}, "homepage"), " for more information.");

produces:

    <p>Visit my <a href='http://homepage.com/'>homepage</a> for more information.</p>

Other things can be passed to C<x()> (or variants); those are described in
L</ADVANCED USAGE>.

=head1 ADVANCED USAGE

Advanced usages of C<XML::Spice> mostly centre around the fact that the
C<XML::Spice::Chunk> objects returned by C<x()> do nothing until the object is
stringified to produce XML output. This makes it possible to pass code
references or even other objects to C<x()> and have them dynamically generate
data to be included in the produced XML.

=over

=item code references

If a code reference is passed to C<x()>, it is called when the resultant
C<XML::Spice::Chunk> is stringified and its output is included at the position
that the code reference was at, eg:

    p("the time is ", sub { scalar localtime });

would produce something like:

    <p>the time is Sat Sep 26 22:32:57 2009</p>

C<XML::Spice::Chunk> will recursively evaluate the result from the code
reference until it gets down to basic strings and hash references as described
in L</BASIC USAGE>. This is great for producing lists of things, eg:

    my $list = ul(sub {
        my @results;
        opendir my $dir, "images";
        push @results, li($_) for grep { m/\.png$/ } readdir $dir;
        closedir $dir;
        return @results;
    });

When C<$list> is stringified, the sub will be called and would return a list
of C<XML::Spice::Chunk> objects. These in turn will be stringified until
eventually only strings are left and output like the following is produced:

    <ul><li>foo.png</li><li>bar.png</li><li>baz.png</li></ul>

Had the sub itself returned a code reference, then that in turn would have
been called and its output used.

The code reference is called every time the C<XML::Spice::Chunk> object is
stringified. If the computed result will not change, consider caching the
result.

=item objects

You can pass an arbitrary object to C<x()>. C<XML::Spice::Chunk> will call its
C<xml_spice()> method if it exists and include its output as described above
for code references. If the object does not have a C<xml_spice()> method, it
will be stringified as normal and the result included in the XML as character
data.

=back

To support these, the following things may be passed to C<x()> (and thus
returned by code references or objects):

=over

=item undef

If C<undef> is passed to C<x()>, it is ignored. That is:

    foo("bar", undef, "baz");

is exactly equivalent to:

    foo("bar", "baz");

and produces:

    <foo>barbaz</foo>

=item array reference

If an array reference is passed to C<x()>, it is flattened. That is:

    foo("bar", [ baz(), "quux" ]);

is exactly equivalent to:

    foo("bar", baz(), "quux");

and produces:

    <foo>bar<baz />quux</foo>

=back




=head1 BUGS AND LIMITATIONS

=head1 DEPENDENCIES

=head1 AUTHOR

Robert Norris <rob@cataclysm.cx>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2009 Robert Norris. This program is free software, you can
redistribute it and/or modify it under the same terms as Perl itself.
