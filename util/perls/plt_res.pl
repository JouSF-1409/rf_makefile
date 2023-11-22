#!/usr/bin/perl
#
# plotting travel time residuals for each station (either with respect
# to the average or to a reference station $ref
#
#require "timelocal.pl";
use Time::Local;

$scl = 0.5;

die "Usage: plt_res.pl shift_file ref stations ...\n" unless $#ARGV > 0;

open(AAA,"grep -v ^# outlier.lst |") if -f "outlier.lst";
@outlier = <AAA>;
close(AAA);

open(AAA,"timing.error") if -f "timing.error";
while(<AAA>) {
   @aa=split;
   if ($#aa<0) {
      next;
   } elsif ($#aa==0) {
      $sta=$aa[0];
      $t{$sta} = [];
      $dt{$sta} = [];
   } else {
      ($year,$mon,$day,$hr,$mn,$sec) = ($aa[0]=~/(\d...)(\d.)(\d.)(\d.)(\d.)(\d.)\s*/);
      @{$t{$sta}} = (@{$t{$sta}},timegm($sec,$mn,$hr,$day,$mon-1,$year-1900));
      @{$dt{$sta}} = (@{$dt{$sta}},$aa[1]);
   }
}
close(AAA);

($file, $ref, @sta_lst) = @ARGV;

if ( $ref ne "." && -e $ref ) {
    open(AAA,$ref);
    while(<AAA>) {
        @aa=split;
	$nnn0{$aa[0]} = $aa[1];
        $res0{$aa[0]} = $aa[2]*$aa[1];
    }
    close(AAA);
} else {
    open(AAA, $file);
    while(<AAA>) {
        @aa=split;
        next if ($ref ne "." and $aa[1] ne $ref) or grep(/$aa[0]\s$aa[1]/,@outlier) > 0;
	$res = $aa[6]-$aa[5]-&cor($aa[0],$t{$aa[1]},$dt{$aa[1]});
        if ($ref ne ".") {
            $res0{$aa[0]} = $res;	# residual at reference station
            $nnn0{$aa[0]} = 1;
        } else {
            $res0{$aa[0]} += $res;	# average residual
            $nnn0{$aa[0]} ++;
        }
    }
    close(AAA);

}

@refEve = keys(%res0);
foreach $key (@refEve)  {
    $res0{$key} = $res0{$key}/$nnn0{$key};
    printf "$key %4d %5.1f\n", $nnn0{$key}, $res0{$key};
}

foreach $sta (@sta_lst) {
    @pos=();
    @neg=();
    mkdir ("$sta",0777) unless -d $sta;
    open(AAA,$file);
    open(RES,"> $sta/tt.dat");
    while(<AAA>) {
        @aa=split;
        next unless $aa[1] eq $sta and grep(/$aa[0]/, @refEve);
        next if grep(/$aa[0]\s$aa[1]/,@outlier) > 0;
	$res = $aa[6]-$aa[5]-$res0{$aa[0]}-&cor($aa[0],$t{$sta},$dt{$sta});
        printf RES "$aa[0] $sta %8s %8s %5.1f\n",$aa[3],$aa[4],$res;
        $baz = 90-$aa[3]; $baz=360+$baz if $baz < 0;
        $res = $scl*$res;
        if ($res>0.) {
            @pos = (@pos,"$baz $aa[4] $res\n");
        } else {
            $res=-$res+0.01;
            @neg = (@neg,"$baz $aa[4] $res\n");
        }
    }
    close(AAA);
    close(RES);

    open(AAA, "|psxy -JP6 -R0/360/0.005/0.10 -Sc -W2 -G0/255/0 -Bg10:.${sta}:/a0.02g0.01NW -K -N > $sta/res.ps");
    print AAA "@pos";
    close(AAA);
    open(AAA,"|psxy -JP -R -Ss -O -K -N >> $sta/res.ps");
    print AAA "@neg";
    close(AAA);
    $x = 1;
    open(AAA,"|psxy -JX2/1 -R0/6/-1/1 -Ss -O -K -Y-0.3 >> $sta/res.ps");
    foreach $res (-1.0, -0.5) {
       printf AAA "%d 0 %f\n",$x++,-$scl*$res;
    }
    close(AAA);
    $x++;
    open(AAA,"|psxy -JX -R -Sc -G0/255/0 -W2 -K -O >> $sta/res.ps");
    foreach $res (0.5, 1.0) {
       printf AAA "%d 0 %f\n",$x++,$scl*$res;
    }
    close(AAA);
    $x = 1;
    open(AAA,"|pstext -JX -R -O >> $sta/res.ps");
    foreach $res (-1.0, -0.5, 0.0, 0.5, 1.0) {
       printf AAA "%d -0.7 12 0 0 2 $res\n",$x++;
    }
    close(AAA);
}
exit(0);

sub cor {
    local ($tt,$t,$dt) = @_;
    ($year,$mon,$day,$hr,$mn,$sec) = ($tt=~/(\d...)(\d.)(\d.)(\d.)(\d.)(\d.)/);
    unless ($sec) {
       ($year,$day,$hr,$mn,$sec) = ($tt=~/(\d.)(\d..)(\d.)(\d.)(\d.)/);
       $day = `calday $day 19$year | grep Calend`;
       ($dum,$dum,$mon,$day,$year) = split(' ',$day);
    }
    $tt = timegm($sec,$mn,$hr,$day,$mon-1,$year-1900);
    $j=0;
    while($j<=$#$t and $$t[$j]<$tt) {$j++;}
    return 0 if $j<1 or $j>$#$t;
    return $$dt[$j-1] + ($tt-$$t[$j-1])*($$dt[$j]-$$dt[$j-1])/($$t[$j]-$$t[$j-1]);
}
