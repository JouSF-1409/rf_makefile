#!/usr/bin/env perl
# bin and average (x,y) data
# Usage:
#	aver.pl	< one_column_data
#		average all data points
#	aver.pl x0 step overlap < two_column_data
#		bin the data with bin size step*overlap, start at x0 and
#		average within each bin,
#

($x0, $step, $overlap) = @ARGV;
$step = 1.e+32 unless $step;
$overlap = 0 unless $overlap;

while(<STDIN>) {
  ($x,$y)=split;
  if (defined $x0) {
     $i = int(($x-$x0)/$step);
  } else {
     $i = 0;
     $y=$x;
  }
  for($j=$i-$overlap;$j<=$i+$overlap;$j++) {
     $bin{$j} .= "$y:";
  }
}

foreach $i (keys(%bin)) {
  chop($bin{$i});
  @data = split(/:/,$bin{$i});
  $n = $#data + 1;
  $mean = 0;
  foreach $dd (@data) {
    $mean+=$dd;
  }
  $mean /= $n;
  $std = 0;
  foreach $dd (@data) {
    $std += ($dd-$mean)*($dd-$mean);
  }
  $std = sqrt($std/($n-1)) if $n > 1;
  if (defined $x0) {
     printf "%10.4f",$x0+($i+0.5)*$step;
  } else {
     print $n;
  }
  printf " %10.4f %10.4f %d\n",$mean,$std,$n;
}

exit(0);
