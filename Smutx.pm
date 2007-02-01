#! /usr/bin/perl -Tw
# smutx (simply marked up text --> something else)
# (c) 2002-2007 Reuben Thomas (rrt@sc3d.org,  http://rrt.sc3d.org/)
# Distributed under the GNU General Public License

require 5.8.4;
package Smutx;

use utf8;
use strict;
use warnings;

use File::Basename;

use lib ".";
use RRT::Misc;

use vars qw($Root $Page $BaseUrl $Output);


# Rendering

sub url {
  my ($path) = @_;
  $path = normalizePath($path, $Page);
  $path =~ s/\?/%3F/;     # escape ? to avoid generating parameters
  return $BaseUrl . $path;
}

# Process nested objects
sub nest {
  my ($list, $cont, $item, $openSubitem, $closeSubitem, $depth) = @_;
  my $result = "";
  if (@$list < $depth) {
    while (@$list < $depth - 1) {
      push @$list, [$item, $closeSubitem];
      $result .= $$Output{open}($item) if $item;
      $result .= $openSubitem;
    }
    push @$list, [$item, $closeSubitem];
    $result .= $$Output{open}($item) if $item;
  } elsif (@$list > $depth) {
    while (@$list > $depth) {
      my ($oldItem, $oldCloseSubitem) = @{pop @$list};
      $result .= $oldCloseSubitem;
      $result .= $$Output{close}($oldItem) if $oldItem;
    }
  } elsif (@$list > 0) {
    my ($oldItem, $oldCloseSubitem) = @{pop @$list};
    $result .= $oldCloseSubitem;
    if (!$cont || $item ne $oldItem) {
      $result .= $$Output{close}($oldItem) if $oldItem;
      $result .= $$Output{open}($item) if $item;
    }
    push @$list, [$item, $closeSubitem];
  }
  return $result;
}

sub flushNest {
  my ($list) = @_;
  my $flush = nest($list, 0, "", "", "", 0); # flush nested markup
  $flush = $flush if $flush ne ""; # only add newline if there is flushed markup
  return $flush;
}

sub addItem {
  my ($list, $cont, $item, $opensubitem, $closesubitem, $depth, $prefix) = @_;
  return nest($list, $cont, $item, $opensubitem, $closesubitem, $depth) .
    ($prefix || "") . $opensubitem;
}

# FIXME: rewrite parser properly:
#   Softwrap the input if it needs it
#   Two routines, render (blocks) and renderPara (lines)
#   Former calls latter (and latter may recurse)
#   Construct output, don't substitute input
#   Escape just before returning from renderPara
sub render {
  my $text = shift;
  my (@section, @list);
  $text = $$Output{escape}($text); # escape the raw text
  $text =~ s/^[ \t]*(.*)\n[ \t]*###+$/addItem(\@section, 0, $$Output{sectlevel1}(), "", "", 1, $$Output{sect1title}($1))/gme; # title
  $text =~ s/^[ \t]*(.*)\n[ \t]*===+$/addItem(\@section, 0, $$Output{sectlevel2}(), "", "", 2, $$Output{sect2title}($1))/gme; # heading
  $text =~ s/^[ \t]*(.*)\n[ \t]*---+$/addItem(\@section, 0, $$Output{sectlevel3}(), "", "", 3, $$Output{sect3title}($1))/gme; # subheading
  $text =~ s/^[ \t]*(.*)\n[ \t]*~~~+$/addItem(\@section, 0, $$Output{sectlevel4}(), "", "", 4, $$Output{sect4title}($1))/gme; # subsubheading
  $text =~ s/^#.*$//gm;         # comment
  $text .= "\n";                # Add sentinel
  my $result = "";
  my $inPara = 0;
  my $oldInPara = 0;
  foreach (split /\n/, $text, -1) { # limit of -1 gives us trailing empty fields
    $inPara = 0;                # assume the line is a block element
    if (/^$/) {                 # paragraph
      $result .= flushNest(\@list);
    } else {
      s/(?<!\pL)_(?=\S)(.*?)_(?!\pL)/$$Output{emphasis}($1)/ge; # emphasis
      s/(?<!\pL)\*(?=\S)(.*?)\*(?!\pL)/$$Output{bold}($1)/ge; # strong
      s/(?<!\pL)@(?=\S)(.*?)@(?!\pL)/$$Output{typewriter}($1)/ge; # typewriter
      s/\[(http:\S*(?:(?i)gif|jpg|jpeg|png|bmp))(?:\|(.*?))?\]/$$Output{image}($1, $2)/ge; # external image
      s/(^|\s)((?:http|ftp):[\S]+[^\s\.,!\?;:])/$1 . $$Output{hyperlink}($2)/ge; # bare URL
      s/\[((?:http|ftp):[^\s|]+[^\s\.,!\?;:|])(?:\|(.*?))?\]/$$Output{hyperlink}($1, $2)/ge; # external URL
      s/\[([^]]+\.(?:(?i)gif|jpg|jpeg|png|bmp))(?:\|(.*?))?\]/$$Output{image}($1, $2)/ge; # internal image
      s/\[(.*?)(?:\|(.*?))?\]/$$Output{hyperlink}(url($1), $2 ? $2 : $1)/ge; # internal link
      # FIXME: In next line, don't assume HTML escapes
      s/^((?:   )+)\&lt;(.+?)\&gt;// && ($result .= addItem(\@list, 1, $$Output{descriptionlist}(), $$Output{opendescriptionlistitem}(), $$Output{closedescriptionlistitem}(), (length $1) / 3, $$Output{describeditem}($2))) or # description list
        s/^((?:   )+)\* // && ($result .= addItem(\@list, 1, $$Output{itemizedlist}(), $$Output{openitemizedlistitem}(), $$Output{closeitemizedlistitem}(), (length $1) / 3)) or # bulleted list
          s/^((?:   )+)\pN+ // && ($result .= addItem(\@list, 1, $$Output{orderedlist}(), $$Output{openorderedlistitem}(), $$Output{closeorderedlistitem}(), (length $1) / 3)) or # numbered list
            $$Output{notinpara}($_) or # titles and headings are not in paragraphs
              $inPara = 1;
    }
    $result .= $$Output{openpara}() if $inPara == 1 && $oldInPara == 0;
    $result .= $$Output{linebreak}() if $inPara == 1 && $oldInPara == 1;
    $result .= $_;
    $result .= $$Output{closepara}() if $inPara == 0 && $oldInPara == 1;
    $oldInPara = $inPara;
  }
  $result .= flushNest(\@list);
  $result .= flushNest(\@section);
  # Put the next rule last so as not to mess up lists
  $text =~ s/^([ \t]+)/$$Output{leadingspace}(length $1)/gme; # leading spaces
  return $result;
}

sub smutx {
  my $text;
  ($text, $Output, $Page, $BaseUrl, $Root) = @_;
  chomp $text;
  return $$Output{preamble}() .  render($text) . $$Output{postamble}();
}


1;                              # return a true value
