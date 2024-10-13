#! /usr/bin/env perl
# Computes the size of the floating focus pane.
#
# ASPECT RATIO:
# Fits the largest pane possible for the window size with the specified aspect ratio. Then ensures
# that it fits within min & max limits
# To force the window to float (i.e. not be all the way to the window edge), set horz_pad_perc or
# vert_pad_perc, which will add padding.

use strict;
use warnings;

use 5.010;

use Getopt::Long;
use POSIX;

my ($horz_pad_perc, $vert_pad_perc) = (0, 0);
my ($horz_aspect, $vert_aspect) = (0, 0);
my ($min_horz, $max_horz) = (120, 250);
my ($min_vert, $max_vert) = (40, 100);
my $verbose = '';
GetOptions(
	'horz_pad_perc|pad_h:i' => \$horz_pad_perc,
	'vert_pad_perc|pad_v:i' => \$vert_pad_perc,
	'horz_aspect|aspect_h:i' => \$horz_aspect,
	'vert_aspect|aspect_v:i' => \$vert_aspect,
	'min_horz|min_h:i' => \$min_horz,
	'max_horz|max_h:i' => \$max_horz,
	'min_vert|min_v:i' => \$min_vert,
	'max_vert|max_v:i' => \$max_vert,
	'verbose|v' => \$verbose,
) or die "unknown or invalid flags";

if ($horz_pad_perc == 0 && $vert_pad_perc == 0 && $horz_aspect == 0 && $vert_aspect == 0) {
	die "Must specify either percentages (horz_pad_perc, vert_pad_perc) or aspect ratios (horz_aspect, vert_aspect).";
}

my ($total_width, $total_height);
chomp($total_width = `tmux display-message -p '#{window_width}'`);
chomp($total_height = `tmux display-message -p '#{window_height}'`);

print("total_width=$total_width, total_heigth=$total_height\n") if $verbose;

my ($win_width, $win_height);
if ($horz_aspect != 0 || $vert_aspect != 0) {
	die "horz_aspect cannot be 0 if vert_aspect is specified" if ($horz_aspect == 0);
	die "vert_aspect cannot be 0 if horz_aspect is specified" if ($vert_aspect == 0);
	($win_width, $win_height) = aspect();
} else {
	die "horz_pad_perc must be specified if vert_pad_perc is set" if ($horz_pad_perc == 0);
	die "vert_pad_perc must be specified if horz_pad_perc is set" if ($vert_pad_perc == 0);
	($win_width, $win_height) = percentages();
}

print("after computation -- width=$win_width, height=$win_height\n") if $verbose;

my $h_gutter = floor(($total_width - floor($win_width))/2);
my $v_gutter = floor(($total_height - floor($win_height))/2);

print("$h_gutter,$v_gutter");

sub aspect {
	my $float_height = $total_height * (($vert_pad_perc != 0) ? (1 - ($vert_pad_perc * 2)/100): 1);
	my $float_width = $total_width * (($horz_pad_perc != 0) ? (1 - ($horz_pad_perc * 2)/100): 1);
	my ($win_width, $win_height);
	if ($vert_aspect > $horz_aspect) {
		$win_height = ($float_height > $max_vert) ? $max_vert : $float_height;
		$win_width = ($win_height / $vert_aspect) * $horz_aspect;
	} else {
		$win_width = ($float_width > $max_horz) ? $max_horz : $float_width;
		$win_height = ($win_width / $horz_aspect) * $vert_aspect;
	}
	print("after aspect -- width=$win_width, height=$win_height\n") if $verbose;

	$win_width = ($win_width < $min_horz) ? $min_horz : $win_width;
	$win_height = ($win_height < $min_vert) ? $min_vert : $win_height;
	print("after clamping -- width=$win_width, height=$win_height\n") if $verbose;

	return ($win_width, $win_height)
}

sub percentages {
	my $win_width =  $total_width * (1 - ($horz_pad_perc * 2)/100);
	my $win_height =  $total_height * (1 - ($vert_pad_perc * 2)/100);
	print("after setting min_percs -- width=$win_width, height=$win_height\n") if $verbose;

	if ($win_width > $max_horz) {
		$win_width = $max_horz;
	} elsif ($win_width < $min_horz) {
		$win_width = $min_horz;
	}
	if ($win_width > $total_width) {
		$win_width = $total_width
	}
	if ($win_height > $max_vert) {
		$win_height = $max_vert;
	} elsif ($win_height < $min_vert) {
		$win_height = $min_vert;
	}
	if ($win_height > $total_height) {
		$win_height = $total_height
	}
	print("after clamping -- width=$win_width, height=$win_height\n") if $verbose;

	return ($win_width, $win_height)
}
