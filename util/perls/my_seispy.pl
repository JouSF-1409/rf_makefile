#!/bin/perl

open(Model,"<iasp914delta");
while(defined($line=<Model>)){
    @temp=split(/\s+/,$line);
    ($thickness,$vel,$kappa)=@temp;


    print "thick:$thickness,vp:$temp[1],kappa:$temp[2]\n";
}
