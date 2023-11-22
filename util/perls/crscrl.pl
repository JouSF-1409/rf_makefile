#!/usr/bin/perl
# do cross-correlation between sacfiles
# modified from Lupei Zhu's crscrl.pl

# jous_1110 07/10/23
# simplized, since loca_space requirement is same for sta and event

# requirements:
# cmd: method to cal cross-correlations,
#      user can change cmd to any cc method as wises as long as they has same -D options and output
# -Ecatalog: locas need to be restrict by sep in file. should contain 3cols : filename loc_la loc_lo
# if -E is not given, cal cc between all traces.



# use strict;
# use warnings;

$cmd="scc";
$loca_file="";
$sep=2;

@ARGV > 0 or die "Usage: crscrl.pl [-Acmd ($cmd)] [-Ecatalog[/max_sep_in_deg ($sep)]][other options for scc or src_ss]
	and input (files ref_time on_or_off) from stdin\n";

foreach (grep(/^-/,@ARGV)){
    my $opt = substr($_,1,1);
    my @value = split(/\//,substr($_,2));
    if ($opt eq "A") {
        $cmd = $value[0];
   } elsif ($opt eq "E") {
        $loca_file = $value[0];
        $sep = $value[1] if $#value > 0;
   } elsif ($opt eq "V") {
        my $verbose = 1;
   } else {
        $cmd = "$cmd $_";
   }
}
#print STDERR "$cmd\n";

if ($loca_file && open(locas,$loca_file)){
    while(<locas>){
        @temp = split;
        $file = $temp[0];
        $loca_la{$file}=@temp[1];
        $loca_lo{$file}=@temp[2];
    }
    close(locas);
} else{
    $loca_file="";
    # die "loca_file unsupported!"
}

while (<STDIN>){
    # input format is 
    # dir/filename arrivaltime on_or_off_switch
    my @temp = split(/[\s]/,$_);
    next if $temp[2]==0;
    $arrival_dict{$temp[0]}=$temp[1];
}

# do cross-correlations
@all_trace = keys(%arrival_dict);
while($trace_main = pop(@all_trace)){
    open(transit,"|$cmd >> cc_temp.out");
    print transit "$trace_main $arrival_dict{$trace_main} 1\n";
    foreach $trace_B (@all_trace){
        if (($loca_file eq "") or ($loca_file and
            abs($loca_la{$trace_main}-$loca_la{$trace_B})<$sep and 
            abs($loca_lo{$trace_main}-$loca_lo{$trace_B})<$sep )){
                    print transit "$trace_B $arrival_dict{$trace_B} 1\n";
                    #print "$trace_B $arrival_dict 1\n";
        }
    }
    close(transit);
}


# output will be arranged to form like
# trace_main arrival on_off_switch trace_B arrival_from_cc ..... on_off switch
open(raw_info,"cc_temp.out");
while(<raw_info>){
    chop;
    @aa=split;
    if($#aa == 2){
        $master = $_;
    }else{
        print "$master $_\n";
    }
}
close(raw_info);
unlink("cc_temp.out");