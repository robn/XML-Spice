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

=head1 NAME

XML::Spice - makes XML generation taste great!

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

=head2 x

=head1 BUGS AND LIMITATIONS

=head1 DEPENDENCIES

=head1 AUTHOR

Robert Norris <rob@cataclysm.cx>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2009 Robert Norris. This program is free software, you can
redistribute it and/or modify it under the same terms as Perl itself.
