#! /usr/bin/perl
# smut-html (simply marked up text --> HTML)
# (c) 2002-2016 Reuben Thomas (rrt@sc3d.org,  http://rrt.sc3d.org/)
# Distributed under the GNU General Public License

require 5.8.4;

use utf8;
use strict;
use warnings;

use Perl6::Slurp;
use CGI qw(:standard);
use Encode;

use RRT::Misc;
use Smutx;

use vars qw($Page $File);

my %output =
  (
   open => sub {"<" . $_[0] . ">"},
   close => sub {"</" . $_[0] . ">"},

   emphasis => sub {"<em>" . $_[0] . "</em>"},
   bold => sub {"<strong>" . $_[0] . "</strong>"},
   typewriter => sub {"<tt>" . $_[0] . "</tt>"},

   sectlevel1 => sub {""},
   sect1title => sub {h1($_[0])},
   sectlevel2 => sub {""},
   sect2title => sub {h2($_[0])},
   sectlevel3 => sub {""},
   sect3title => sub {h3($_[0])},
   sectlevel4 => sub {""},
   sect4title => sub {h4($_[0])},
   leadingspace => sub {"&nbsp;" x $_[0]},

   descriptionlist => sub {"dl"},
   opendescriptionlistitem => sub {"<dd>"},
   closedescriptionlistitem => sub {"</dd>"},
   describeditem => sub {"<dt>" . $_[0] . "</dt>"},
   itemizedlist => sub {"ul"},
   openitemizedlistitem => sub {"<li>"},
   closeitemizedlistitem => sub {"</li>"},
   orderedlist => sub {"ol"},
   openorderedlistitem => sub {"<li>"},
   closeorderedlistitem => sub {"</li>"},

   openpara => sub {"<p>"},
   closepara => sub {"</p>"},
   linebreak => sub {"<br />"},

   notinpara => sub {$_[0] =~ m/^<h/},

   preamble => sub {
     return <<"EOF";
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>$Page</title>
</head>
<body>
EOF
   },
   postamble => sub {"</body>\n</html>"},

   image => sub {
     my ($image, $alt, $width, $height) = @_;
     $image = url($image) if $image !~ /^http:/;
     $alt ||= "image";
     my $ret = "<img src=\"$image\" alt=\"$alt\"";
     $ret .= "width=\"$width\" " if defined $width;
     $ret .= "height=\"$height\" " if defined $height;
     $ret .= "/>";
     return $ret;
   },

   hyperlink => sub {
     my ($url, $desc) = @_;
     $desc ||= $url;
     return "<a href=\"$url\">$desc</a>";
   },

   # Escape characters that need it and process \ source escapes
   escape => sub {
     my ($text) = @_;
     # FIXME: Re-enable this; currently it messes up macro escaping
     #$text =~ s/\\(.)/"&#" . (ord $1) . ";"/ge; # \ escapes the next character
     $text =~ s/&(?!#?[\pN\pL_]+;)/&amp;/g; # escape ampersands (but not in entities)
     $text =~ s/</&lt\;/g;      # escape <
     $text =~ s/>/&gt\;/g;      # escape >
     return $text;
   },
  );

# Render text
my ($root, $baseurl);
($File, $Page, $baseurl, $root) = @ARGV;
$File = decode_utf8($File);
my ($text);
if ($File eq "-") {
  $text = slurp '<:crlf:utf8', \*STDIN;
} else {
  $text = (slurp '<:crlf:utf8', $File) || "";
}
$Page = decode_utf8($Page);
binmode(STDOUT, ":utf8");
print Smutx::smutx($text, \%output, $File, decode_utf8($baseurl), decode_utf8($root));
