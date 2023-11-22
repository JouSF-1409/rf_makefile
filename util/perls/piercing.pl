#!/usr/bin/env perl
# calculate location of piecing point of ray at some depth
# giving ray parameter and incoming azimuth.
#
# modified by jous_1110 @ 20230721
#
# p for Sp and s for Ps
# v_model should be in format
# thickness Vp Vs

use strict;
use warnings;
use Math::Trig;

@ARGV == 3 or die "Usage: piercing.pl (p | s) v_model depth\n";

my($phase,$md,$depth)=@ARGV;

my $rad = 3.1415926535/180.0;

while(<STDIN>) {
  chop;
  # if you want to change your input format, change this line
  my ($file,$lat,$lon,$baz,$p) = split;

  my $dd = delta($phase, $md, $depth, $p);
  if($dd == -1){
    print STDERR "$file failed in piercing\n";
    next;
  }
  print "$dd\n";
  
  my $pierce=phi_lam($lat,$lon,$dd,$baz);

  # outputs
  print "$_ $dd $pierce";
}

sub delta{
  # for comparasion p~0.04,depth~100, delta will be ~0.5 deg.
  my ($phase,$model,$depth,$rayp) = @_;
  my ($thickness,$vel,$vs,$r1,$r2,$line);

  open(Model,"<$model") or return -1;
  my $r0 = 6371.0;
  my $space = 0.0;
  $r1 = $r0;
  $depth = $r0 - $depth;
  $rayp = $rayp * $r0;

  while(defined($line=<Model>)){
    chop($line);
    ($thickness,$vel,$vs) = split(/\s+/,$line);
    # ? if kappa=Vp/Vs, should Vs=Vp/kappa
    #$vel = ($phase == 'p') ? $vel * $rayp * $Kappa : $vel * $rayp;
    #$vel = ($phase == 'p') ? $vel * $rayp / $Kappa : $vel * $rayp;
    if($phase eq 's'){
      $vel=$vs;
      #$vel = $vel/$Kappa;
    }

    $vel = $vel * $rayp;

    $r2 = $r1 - $thickness;
    # print "r1: $r1, r2: $r2; thick: $thickness;\n";


    if ($vel > $r2) {return -1;}
    if ($r2 < $depth) {
      $space += (acos($vel/$r1) -acos($vel/$depth));
      print "$space\n";
      return $space;
    }
    $space += (acos($vel/$r1) -acos($vel/$r2));
    print "$space\n";
    $r1 = $r2;
  }
  close(Model);
  return -1;

}

sub phi_lam{
  # this code is from phi_lam.pl
  # should be modified in the future
  my ($phi0,$lam0,$delta,$baz) = @_;

  # this 2 line is from old script
  # if your delta is in degree. use these two line instead.
  # my $sdl  = sin($delta * $rad);
  # my $cdl  = cos($delta * $rad);

  my $sdl  = sin($delta);
  my $cdl  = cos($delta);
  my $sf0  = sin($phi0*$rad);
  my $cf0  = cos($phi0*$rad);
  my $sth  = sin($baz*$rad);
  my $cth  = cos($baz*$rad);

  my $sf  = $sf0 * $cdl + $cf0 * $sdl * $cth;
  my $cf  = sqrt(1.-$sf*$sf);
  my $sl  = $sdl*$sth/$cf;
  my $cl  = ($sf*$cf0 - $sdl*$cth) / ($cf*$sf0);
  my $lam = $lam0+atan2($sl, $cl)/$rad;
  my $phi = atan2($sf, $cf)/$rad;

  return sprintf("%7.3f %8.3f\n",$phi,$lam);
}

exit(0);
