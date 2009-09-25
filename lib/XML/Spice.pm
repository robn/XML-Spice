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

    my $xml = q{<foo><bar><baz/></bar><quux/></foo>};

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

=head1 BASIC OPERATION

If you C<use> (or C<import>) XML::Spice without any arguments, it will export
a single function C<x()> into your package. This is the only real function in
XML::Spice, and its used to implement everything else.

C<x()> generates a single element, which in turn can contain attributes,
character data, sub-elements (via additional calls to C<x()>), and more. The
general format for C<x()> is:

    my $xml = x("element", ...);

The first argument is required, and is always the name of the element to
generate. 





=head2 x

=head1 BUGS AND LIMITATIONS

=head1 DEPENDENCIES

=head1 AUTHOR

Robert Norris <rob@cataclysm.cx>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2009 Robert Norris. This program is free software, you can
redistribute it and/or modify it under the same terms as Perl itself.
