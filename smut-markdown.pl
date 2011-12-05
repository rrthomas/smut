#! /usr/bin/perl
# smut-markdown (simply marked up text --> markdown)
# (c) 2002-2010 Reuben Thomas (rrt@sc3d.org,  http://rrt.sc3d.org/)
# Distributed under the GNU General Public License

require 5.8.4;

use utf8;
use strict;
use warnings;

use Perl6::Slurp;
use CGI qw(:standard unescapeHTML);
use Encode;

use RRT::Misc;
use Smutx;

my %output =
  (
   emphasis => sub {"_" . $_[0] . "_"},
   bold => sub {"**" . $_[0] . "**"},
   typewriter => sub {"`" . $_[0] . "`"},

   # FIXME: Need spurious spaces because input is split after titles have been marked up
   sectlevel1 => sub {""},
   sect1title => sub {h1($_[0])},
   sectlevel2 => sub {""},
   sect2title => sub {h2($_[0])},
   sectlevel3 => sub {""},
   sect3title => sub {h3($_[0])},
   sectlevel4 => sub {""},
   sect4title => sub {h4($_[0])},
   leadingspace => sub {">" x (length $_[0] / 3) . " "},

   descriptionlist => sub {"dl"},
   opendescriptionlistitem => sub {"<dd>"},
   closedescriptionlistitem => sub {"</dd>"},
   describeditem => sub {"<dt>" . $_[0] . "</dt>"},
   itemizedlist => sub {""},
   openitemizedlistitem => sub {"* "},
   closeitemizedlistitem => sub {"\n\n"},
   orderedlist => sub {""},
   openorderedlistitem => sub {"1. "},
   closeorderedlistitem => sub {"\n\n"},

   openpara => sub {"\n"},
   closepara => sub {"\n"},
   linebreak => sub {"  \n"},

   notinpara => sub {0},

   preamble => sub {""},
   postamble => sub {"\n"},

   image => sub {
     my ($image, $alt, $width, $height) = @_;
     $image = url($image) if $image !~ /^http:/;
     $alt ||= "";
     $width = " width=\"$width\"" if $width;
     $height = " height=\"$height\"" if $height;
     $width ||= "";
     $height ||= "";
     return "<img src=\"$image\" alt=\"$alt\"$width$height />";
   },

   hyperlink => sub {
     my ($url, $desc) = @_;
     return "<a href=\"$url\">" . ($desc || $url) . "</a>";
   },

   # Escape characters that need it and process \ source escapes
   escape => sub {
     my ($text) = @_;
     $text =~ s/\\(.)/$1/ge; # \ escapes the next character
     return $text;
   },
  );

# Render text
my ($file, $page, $baseurl, $root) = @ARGV;
$file = decode_utf8($file);
my ($text);
if ($file eq "-") {
  $text = slurp '<:crlf:utf8', \*STDIN;
} else {
  $text = (slurp '<:crlf:utf8', $file) || "";
}
binmode(STDOUT, ":utf8");
print Smutx::smutx($text, \%output, decode_utf8($page), decode_utf8($baseurl), decode_utf8($root));
