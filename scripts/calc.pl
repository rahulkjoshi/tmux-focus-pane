#! /usr/bin/env perl

use strict;
use warnings;

use 5.010;

use Getopt::Long;
use POSIX;

my ($min_horz_perc, $min_vert_perc) = (25, 10);
my ($horz_aspect, $vert_aspect) = (4, 3);
my ($min_horz, $max_horz) = (120, 10000);
my ($min_vert, $max_vert) = (40, 10000);
my $verbose = '';
GetOptions(
	'min_horz_perc|mhp:f' => \$min_horz_perc,
	'min_vert_perc|mvp:f' => \$min_vert_perc,
	'horz_aspect|h_aspect:f' => \$horz_aspect,
	'vert_aspect|v_aspect:f' => \$vert_aspect,
	'min_horz|min_h:f' => \$min_horz,
	'max_horz|max_h:f' => \$max_horz,
	'min_vert|min_v:f' => \$min_vert,
	'max_vert|max_v:f' => \$max_vert,
	'verbose|v' => \$verbose,
) or die "unknown or invalid flags";

my ($total_width, $total_height);

chomp($total_width = `tmux run "echo '#{window_width}'"`);
chomp($total_height = `tmux run "echo '#{window_height}'"`);

print("total_width=$total_width, total_heigth=$total_height\n") if $verbose;

my $win_width =  $total_width * (1 - ($min_horz_perc * 2)/100);
my $win_height =  $total_height * (1 - ($min_vert_perc * 2)/100);

print("after setting min_percs -- width=$win_width, height=$win_height\n") if $verbose;

if ($total_height < $total_width) {
	$win_width = ($horz_aspect * $win_height) / $vert_aspect;
} else {
	$win_height = ($vert_aspect * $win_width) / $horz_aspect;
}

print("after aspect -- width=$win_width, height=$win_height\n") if $verbose;

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

my $h_gutter = floor(($total_width - $win_width)/2);
my $v_gutter = floor(($total_height - $win_height)/2);

print("$h_gutter,$v_gutter");
