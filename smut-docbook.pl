#! /usr/bin/perl -Tw
# smut-docbook (simply marked up text --> DocBook XML)
# (c) 2002-2008 Reuben Thomas (rrt@sc3d.org,  http://rrt.sc3d.org/)
# Distributed under the GNU General Public License

# FIXME: Need to generate <artheader> to make a valid article

require 5.8.4;

use strict;
use warnings;

use Perl6::Slurp;

use lib ".";
use Smutx;


# Output routines

my %output =
  (
   open => sub {"<" . $_[0] . ">"},
   close => sub {"</" . $_[0] . ">"},

   emphasis => sub {"<emphasis>" . $_[0] . "<\/emphasis>"},
   bold => sub {"<emphasis role=\"bold\">" . $_[0] . "<\/emphasis>"},
   typewriter => sub {"<literal>" . $_[0] . "<\/literal>"},

   sectlevel1 => sub {"sect1"},
   sect1title => sub {"<title>" . $_[0] . "<\/title>"},
   sectlevel2 => sub {"sect2"},
   sect2title => sub {"<title>" . $_[0] . "<\/title>"},
   sectlevel3 => sub {"sect3"},
   sect3title => sub {"<title>" . $_[0] . "<\/title>"},
   sectlevel4 => sub {"sect4"},
   sect4title => sub {"<title>" . $_[0] . "<\/title>"},
   leadingspcae => sub {" " x $_[0]},

   descriptionlist => sub {"variablelist"},
   opendescriptionlistitem => sub {"<varlistentry>"},
   closedescriptionlistitem => sub {"</varlistentry>"},
   describeditem => sub {"<term>" . $_[0] . "</term>"},
   itemizedlist => sub {"itemizedlist"},
   openitemizedlistitem => sub {"<listitem>"},
   closeitemizedlistitem => sub {"</listitem>"},
   orderedlist => sub {"orderedlist"},
   openorderedlistitem => sub {"<listitem>"},
   closeorderedlistitem => sub {"</listitem>"},

   openpara => sub {"<para>"},
   closepara => sub {"</para>"},
   linebreak => sub {"<br />\n"}, # FIXME: how to do this in DocBook?

   notinpara => sub {$_[0] =~ m/^<\/?sect/},

   preamble => sub {
     return <<"EOF";
<?xml version='1.0'?>
<!DOCTYPE book PUBLIC "-//OASIS//DTD Simplified DocBook XML V1.0//EN"
               "http://www.oasis-open.org/docbook/xml/simple/1.0/sdocbook.dtd">
<article>
EOF
   },
   postamble => sub {"</article>"},

   image => sub {
     my ($image, $alt, $width, $height) = @_;
     my $ret = "<imagedata fileref=\"$image\" ";
     $ret .= "width=\"$width\" " if defined $width;
     $ret .= "height=\"$height\" " if defined $height;
     $ret .= "/>";
     return $ret;
   },

   hyperlink => sub {
     my ($url, $desc) = @_;
     $desc ||= $url;
     return "<ulink url=\"$url\">$desc</ulink>";
   },

   # Escape characters that need it and process \ source escapes
   escape => sub {
     my ($text) = @_;
     $text =~ s/\\(.)/"&#" . (ord $1) . ";"/ge; # \ escapes the next character
     $text =~ s/&(?!#?[\pN\pL_]+;)/&amp;/g; # escape ampersands (but not in entities)
     $text =~ s/</&lt\;/g;      # escape <
     $text =~ s/>/&gt\;/g;      # escape >
     return $text;
   },
  );

# Render text
my ($file, $page, $serverurl, $baseurl, $root) = @ARGV;
$file = decode_utf8($file);
$page = decode_utf8($page);
$baseurl = decode_utf8($baseurl);
$root = decode_utf8($root);
binmode(STDOUT, ":utf8");
my ($text);
if ($file eq "-") {
  $text = slurp '<:crlf:utf8', \*STDIN;
} else {
  $text = slurp '<:crlf:utf8', $file || "";
}
print Smutx::smutx($text, \%output, $page, $serverurl, $baseurl, $root);
