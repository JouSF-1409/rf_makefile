#!/usr/bin/env perl

$rad = 3.1415926535/180.0;
($phi0,$lam0,$delta,$baz) = @ARGV;

$sdl  = sin($delta*$rad);
$cdl  = cos($delta*$rad);
$sf0  = sin($phi0*$rad);
$cf0  = cos($phi0*$rad);
$sth  = sin($baz*$rad);
$cth  = cos($baz*$rad);

$sf  = $sf0 * $cdl + $cf0 * $sdl * $cth;
$cf  = sqrt(1.-$sf*$sf);
$sl  = $sdl*$sth/$cf;
$cl  = ($sf*$cf0 - $sdl*$cth) / ($cf*$sf0);
$lam = $lam0+atan2($sl, $cl)/$rad;
$phi = atan2($sf, $cf)/$rad;
printf "%7.3f %8.3f\n",$phi,$lam;
