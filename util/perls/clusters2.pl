#!/usr/bin/perl
#
# Find clusters among events linked by waveform cross-correlation using the
# Greedy algorithm.
#
# Usage: clusters2.pl [cc_file] (must be sorted by cc with the largest first)
# Output: list of traces and the their optimal arrival times.
#
# Written by Lupei Zhu, SLU, 2009/06/22.
#    revision:
#    	09/21/2011	output errors in time differences by cc
#
use strict;

my ($node1,$t1,$node2,$t2,$cc,$flg,$dt);
my ($clst,$clst1,$clst2,%clusters,%arr,%ccdt);

while(<>) {
  ($node1,$t1,$clst,$node2,$t2,$flg,$cc,$clst) = split;
  next if $flg == 0;
    #input dt relivate
  $ccdt{"$node1:$node2"} = $t2-$t1;

  # find whether the nodes have already been linked to a cluster.
  $clst1 = $clst2 = 0;
  foreach $clst (keys(%clusters)) {
     foreach (@{$clusters{$clst}}) {
       $clst1=$clst if $_ eq $node1;
       $clst2=$clst if $_ eq $node2;
     }
  }

  # don't do anything if both nodes are in the same cluster
  next if $clst1 eq $clst2 and $clst1;
  # clusters contains
  if ( $clst1==0 && $clst2==0 ) {	# put the two nodes in a new cluster
     $clusters{$node1} = [$node1,$node2];
     $arr{$node1} = $t1;
     $arr{$node2} = $t2;
  } elsif ( $clst1==0 ) {		# add node1 to cluster2
     @{$clusters{$clst2}} = (@{$clusters{$clst2}}, $node1);
     $arr{$node1} = $arr{$node2} + $t1 - $t2;
  } elsif ( $clst2==0 ) { 		# add node2 to cluster1
     @{$clusters{$clst1}} = (@{$clusters{$clst1}}, $node2);
     $arr{$node2} = $arr{$node1} + $t2 - $t1;
  } else { 		# merge cluster2 to cluster1 by connecting node2 to node1
     $dt = $arr{$node1} - $arr{$node2} + $t2 - $t1;
     foreach (@{$clusters{$clst2}}) {
       $arr{$_} += $dt;
     }
     @{$clusters{$clst1}} = (@{$clusters{$clst1}}, @{$clusters{$clst2}});
     delete $clusters{$clst2};
  }
}

# output
my $i = 0;
foreach $clst (keys(%clusters)) {
  $flg = 2;
  open(AAA,">cluster.$i.clst");
  foreach (@{$clusters{$clst}}) {
     printf "$_ %8.3f $flg\n", $arr{$_};
     printf AAA "$_ %8.3f 1\n", $arr{$_};
     $flg = 1;
  }
  close(AAA);
  $i++;
}

# output cc time difference errors
open(AAA,">cluster.err");
foreach (keys(%ccdt)) {
   ($node1, $node2) = split(':',$_);
   printf AAA "$node1 $node2 %8.3f\n",$ccdt{$_}-($arr{$node2}-$arr{$node1});
}
close(AAA);
