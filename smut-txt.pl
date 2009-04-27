#! /usr/bin/perl -T
# smut-txt (simply marked up text --> plain text)
# (c) 2002-2009 Reuben Thomas (rrt@sc3d.org,  http://rrt.sc3d.org/)
# Distributed under the GNU General Public License

require 5.8.4;

use utf8;
use strict;
use warnings;

use Perl6::Slurp;
use CGI qw(:standard unescapeHTML);
use Encode;

use lib ".";
use RRT::Misc;
use Smutx;

use vars qw($Page $ServerUrl $BaseUrl);

my %output =
  (
   emphasis => sub {"_" . $_[0] . "_"},
   bold => sub {"*" . $_[0] . "*"},
   typewriter => sub {"`" . $_[0] . "'"},

   # FIXME: Need spurious spaces because input is split after titles have been marked up
   sectlevel1 => sub {""},
   sect1title => sub {"\n \n" . uc($_[0]) . "\n" . ("=" x length $_[0]) . " \n "},
   sectlevel2 => sub {""},
   sect2title => sub {"\n \n" . $_[0] . "\n" . ("=" x length $_[0]) . " \n "},
   sectlevel3 => sub {""},
   sect3title => sub {"\n \n" . $_[0] . "\n" . ("-" x length $_[0]) . " \n "},
   sectlevel4 => sub {""},
   sect4title => sub {"\n \n" . $_[0] . " \n "},
   leadingspace => sub {" " x $_[0]},

   descriptionlist => sub {""},
   opendescriptionlistitem => sub {""},
   closedescriptionlistitem => sub {"\n"},
   describeditem => sub {$_[0] . "\n"},
   itemizedlist => sub {""},
   openitemizedlistitem => sub {"* "},
   closeitemizedlistitem => sub {"\n"},
   orderedlist => sub {""},
   # FIXME: Make numbered items
   openorderedlistitem => sub {"* "},
   closeorderedlistitem => sub {"\n"},

   openpara => sub {""},
   closepara => sub {"\n"},
   linebreak => sub {"\n"},

   notinpara => sub {0},

   preamble => sub {""},
   postamble => sub {"\n"},

   image => sub {
     my ($image, $alt, $width, $height) = @_;
     $image = url($image) if $image !~ /^http:/;
     $alt ||= "";
     return "$alt ($image)";
   },

   hyperlink => sub {
     my ($url, $desc) = @_;
     return "$desc ($url)" if $desc;
     return $url;
   },

   # Escape characters that need it and process \ source escapes
   escape => sub {
     my ($text) = @_;
     $text =~ s/\\(.)/$1/ge; # \ escapes the next character
     return $text;
   },
  );

# Render text
my ($file, $root);
($file, $Page, $ServerUrl, $BaseUrl, $root) = @ARGV;
$file = decode_utf8($file);
my ($text);
if ($file eq "-") {
  $text = slurp '<:crlf:utf8', \*STDIN;
} else {
  $text = slurp '<:crlf:utf8', $file || "";
}
$Page = decode_utf8($Page);
$BaseUrl = decode_utf8($BaseUrl);
$root = decode_utf8($root);
binmode(STDOUT, ":utf8");
print Smutx::smutx($text, \%output, $Page, $ServerUrl, $BaseUrl, $root);
