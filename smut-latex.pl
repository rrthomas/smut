#! /usr/bin/perl -Tw
# smut-latex (simply marked up text --> LaTeX)
# (c) 2002-2007 Reuben Thomas (rrt@sc3d.org,  http://rrt.sc3d.org/)
# Distributed under the GNU General Public License

require 5.8.4;

use strict;
use warnings;

use lib ".";
use RRT::Misc;
use Smutx;


# Output routines

my %output =
  (
   open => sub {"\\begin{" . $_[0] . "}\n"},
   close => sub {"\\end{" . $_[0] . "}\n"},

   emphasis => sub {"\\emph{" . $_[0] . "}"},
   bold => sub {"\\textbf{" . $_[0] . "}"},
   typewriter => sub {"\\texttt{" . $_[0] . "}"},

   sectlevel1 => sub {""},
   sect1title => sub {"\\title{" . $_[0] . "}\\date{\\relax}\\maketitle"},
   sectlevel2 => sub {""},
   sect2title => sub {"\\section*{" . $_[0] . "}"},
   sectlevel3 => sub {""},
   sect3title => sub {"\\subsection*{" . $_[0] . "}"},
   sectlevel4 => sub {""},
   sect4title => sub {"\\subsubsection*{" . $_[0] . "}"},
   leadingspcae => sub {"\\ " x $_[0]},

   descriptionlist => sub {"description"},
   opendescriptionlistitem => sub {"\\item"},
   closedescriptionlistitem => sub {"\n"},
   describeditem => sub {"[" . $_[0] . "]"},
   itemizedlist => sub {"itemize"},
   openitemizedlistitem => sub {"\\item "},
   closeitemizedlistitem => sub {"\n"},
   orderedlist => sub {"enumerate"},
   openorderedlistitem => sub {"\\item "},
   closeorderedlistitem => sub {"\n"},

   openpara => sub {""},
   closepara => sub {"\n\n"},
   linebreak => sub {"\\linebreak "},

   notinpara => sub {0},

   preamble => sub {
     return <<"EOF";
\\documentclass[english]{scrartcl}
\\usepackage{babel,a4,newlfont,hyperref}
\\usepackage[utf8]{inputenc}

% Alter some default parameters for general typesetting
\\frenchspacing

\\begin{document}
EOF
   },
   postamble => sub {"\n\\end{document}"},

   image => sub { # FIXME
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
     return "\\href{$url}{$desc}";
   },

   # Escape characters that need it and process \ source escapes
   escape => sub {
     my ($text) = @_;
     $text =~ s/\\(.)/\\$1/ge; # \ escapes the next character (FIXME)
     $text =~ s/([\\\$&])/\\$1/g; # escape special characters
     $text =~ s/(^|\s)"/$1``/g; # open quotes
     $text =~ s/"/''/g;    # close quotes (unnecessary, but symmetric)
     return $text;
   },
  );

# Render text
my ($file, $page, $baseurl, $root) = @ARGV;
binmode(STDOUT, ":utf8");
print Smutx::smutx(readText($file), \%output, $page, $baseurl, $root);
