#! /usr/bin/perl -Tw
# smut-txt (simply marked up text --> plain text)
# (c) 2002-2007 Reuben Thomas (rrt@sc3d.org,  http://rrt.sc3d.org/)
# Distributed under the GNU General Public License

require 5.8.4;

use utf8;
use strict;
use warnings;

use CGI qw(:standard unescapeHTML);
use Encode;

use lib ".";
use RRT::Misc;
use Smutx;

use vars qw($Page $BaseUrl);


# FIXME: Why is this needed here and in Smutx.pm? (Otherwise images don't work)
sub url {
  my ($path) = @_;
  $path = normalizePath($path, $Page);
  $path =~ s/\?/%3F/;     # escape ? to avoid generating parameters
  return $BaseUrl . $path;
}

my %output =
  (
   emphasis => sub {"_" . $_[0] . "_"},
   bold => sub {"*" . $_[0] . "*"},
   typewriter => sub {"`" . $_[0] . "'"},

   sectlevel1 => sub {""},
   sect1title => sub {uc($_[0]) . "\n" . ("=" x length $_[0])},
   sectlevel2 => sub {""},
   sect2title => sub {$_[0] . "\n" . ("=" x length $_[0])},
   sectlevel3 => sub {""},
   sect3title => sub {$_[0] . "\n" . ("-" x length $_[0])},
   sectlevel4 => sub {""},
   sect4title => sub {$_[0]},
   leadingspace => sub {" " x $_[0]},

   descriptionlist => sub {""},
   opendescriptionlistitem => sub {""},
   closedescriptionlistitem => sub {""},
   describeditem => sub {$_[0] . "\n"},
   itemizedlist => sub {""},
   openitemizedlistitem => sub {"* "},
   closeitemizedlistitem => sub {""},
   orderedlist => sub {""},
   # FIXME: Make numbered items
   openorderedlistitem => sub {"* "},
   closeorderedlistitem => sub {""},

   openpara => sub {""},
   closepara => sub {"\n"},
   linebreak => sub {"\n"},

   notinpara => sub {0},

   preamble => sub {""},
   postamble => sub {""},

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
($file, $Page, $BaseUrl, $root) = @ARGV;
$file = decode_utf8($file);
my $text = readText($file) || "";
$Page = decode_utf8($Page);
$BaseUrl = decode_utf8($BaseUrl);
$root = decode_utf8($root);
binmode(STDOUT, ":utf8");
print Smutx::smumtx($text, \%output, $Page, $BaseUrl, $root);
