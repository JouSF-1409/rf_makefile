########### pre-process 

# do cross-correlation to modified arrival time.
# this process is not that neccessary when you chose iter_decon method,
# better after manually checks.
# % can't contain any '/' or modify crscrl.pl

cc_time_window=-30/30/15
cc_space=2
tP=t1

# inputs
# t8.dat is for mcc.tcl
# t8.dat has 3 cols like:
# file_index    arrival_time    take_or_discart
# cc_time_window is relivate to t1 in saclst, 3rd value r specify the cc time window as [t0+t1, t0+t2] and max. allowed shift in sec. (-5/10/10%).
# outputs
# cc.dat has 8 cols
# file1 t1 file1_onoff file2 cc_time file2_onoff cc_value norm 
%/cc.dat:
	saclst stla stlo f $*/*.z > sta.loc;\
	saclst $(tP) f $*/*.z|awk '{print $$1" 0 1"}'|\
		crscrl.pl -Asrc_ss -D$(cc_time_window) -Esta.loc/$(cc_space)>$@;\
	rm sta.loc;

min_cc_value=0.3
# using clusters2.pl to mannage all cc value
%/shift.dat:%/cc.dat
	awk '{if($$7 != "nan" && ($$7>$(min_cc_value) || $$7< -$(min_cc_value))){print $$0}}' $< |\
		sort -nr -k 7 |clusters2.pl>shift_temp.dat;
	awk '{\
		sac_ch="sachd $(tP) "$$2" f "$$1;\
		sac_ch|getline;close(sac_ch);\
        if (index($$1,"/")) {on=1;sub("$*/","",$$1);}\
        print $$1,$$2,on }' shift_temp.dat;
	mv shift_temp.dat $*/shift.dat;
#rm cluster*clst;
#for file in `awk '{if($$3 == 0){print $$1"-"$$2+30}}' $*/shift.dat`\
#do\
#t2=`echo "$$file"|awk -F- '{print $$2}'`;\
#file=`echo "$$file"|awk -F- '{print $$1}'`;\
#sachd t4 $$t2 f $*/$$file;\
#done

#STA/LTA for phase picking
%/SRC.s: %/shift.dat
	awk '{if ($$3>0) print "$*/" $$1,$$2}' $< | sacStack -Et-9 -N -O$@;
trig.dat:
	sacTrig -T4. $(events)/SRC.s > junk1;
	saclst a f $(events)/SRC.s > junk2;
	paste junk1 junk2 | nawk '{if ($$2>0) printf "%s %7.2f\n",$$1,$$2-$$4}' | sed 's/\/SRC.s//' > $@;
	rm junk1 junk2;

# arr.dat 
# dir/file gcarc baz rayp arrival_theoretical arrival_correct
arr.dat: .shift
	rm -f $@;
	for aa in $(events); \
	do \
	   paste $$aa/t8.dat $$aa/shift.dat | nawk '{if ($$8>0) print $$1,$$3,$$4,$$5,$$2,$$7}' | sed -e "s/^/$$aa /" -e 's/\.z//' >> $@ ;\
	done

event.res: arr.dat
	${RFSCRIPTS}/plt_res.pl $< . `cut -d' ' -f 2 $< | sort -u` > $@;

# tt.dat
# file arrival gcarc baz rayp
# doubtfull, probably for body wave moveout.  
# after sorted to station/files
sta.res: event.res
	ls */tt.dat > junk1;
	rm -f junk2;
	for aa in `cat junk1`; do nawk '{print $$5}' $$aa | aver.pl >> junk2; done;
	paste junk1 junk2 | sed 's/\/tt.dat//' > $@;
	rm junk1 junk2;

############# deconvoluton
folds=20*
iter_num=100
decon_time=-10/100
alpha=4.


# shift.dat like any file for mcc.tcl, in a form:
# filename shifttime on_off_switch(0 or 1)
# here we only make use of col1 and col3, and default time is write into t1. 

# iter_decon options:
# -F for filter to data/ guassian 3.0 /time before first Pick in RF is 5 sec.
# -N 100 is iter 100 times -T is tapper 0.1
# -C means cutting timewindow in dtwin in relevate to o（-3）
# mark = -5(b), -3(o), -2(a), 0-9 (t0-t9)

.decon:shift.dat
	for dir in $(folds);\
	do\
		rm -rf $$dir/*.?i;\
		for file in `awk '{if ($$3!=0) print $$1} $$dir/shift.dat';\
		do\
			rfile=`echo "${file}"|sed 's/.z$/.r/';\
			iter_decon -F3/$(alpha)/-5 -N$(iter_num) -T0.1 $$dir/$$file $$dir/$$rfile;\
		done;\
	done

# rot to great circle again. not sure why
.rot:.decon
	for dir in $(folds)\
	do\
        ls $$dir/*ri | awk '{sub("ri$$","[rt]i",$$1);\
            print "r "$1,"\nrotate\nw over"}\
            END{print "quit"}'|sac;
	done;\
    touch $@

rtwin = -5/15
## quality control:
## 1.(mean_value, max_value, min_value) of .ri for quality control
## 2. normal distribution of rms_value of .ti
## 3. cross_cor of average rf and rfs.
## save rms to user0, bugs
## junk[123] in the first place are in the same form
## 1st line: master_trace xxx xxx
## 2nd line...: trace xxx xxx xxx xxx xxx
%/rf.lst:
	if [ ! -d $* ]; then  mkdir $*; fi;
	saclst depmen depmax depmin f $(events)/$*.ri | awk '{
		sub("ri$$","ti",$$1);switch=1;
		if ($$2=="nan"||$$3>1.5||$$4<-1) switch=0;
		print "r",$$1,"\nRMS TO USER2,"\nCH USER3",switch}END{print "quit"}' | sac;
	saclst baz user2 user3 f *ti | awk '\
        BEGIN{n=0;m=0;mean=0.}{sub("ti$$","ri",$$1);filename[n]=$$1; baz[n]=$$2; rms[n]=$$3; switch[n]=$$4;n++;if ($$4>0.){mean+=$$10;m++}}\
        END{mean=mean/m;dev=0.;for(i=0;i<n;i++) if (switch[i]>0.) dev+=(rms[i]-mean)*(rms[i]-mean);\dev=sqrt(dev/(m-1));
			for(i=0;i<n;i++){
				if (rms[i]<mean-2*dev||rms[i]>mean+2*dev) switch[i]=0;
				print filename[i],baz[i],switch[i];\
            }}' > rf.lst.junk3;
	nawk '{if ($$3>0) print $$1}' rf.lst.junk3 | sacStack -O$*/rf.average;\
	nawk 'BEGIN{print "$*/rf.average 0"}{print $$1,0,$$3}' rf.lst.junk3 |\
		src_ss -D${rtwin}/0 -C0.3 -W > rf.lst.junk1
	cat rf.lst.junk1 | src_ss -D${rtwin}/0 -C0.5 -W > rf.lst.junk2
	cat rf.lst.junk2 | src_ss -D${rtwin}/0 -C0.5 -W | tail -n +2 > rf.lst.junk1
	paste rf.lst.junk3 rf.lst.junk1 | nawk '{\
        on=$$3;if ($$7<${minRCC}) on=0;\
        printf "%s %6.1f %d\n", $$1,$$2,on\
    }' | sort -n -k 2 > $@
#$(RFSCRIPTS)/plt1.sh $@
#$(RFSCRIPTS)/plt3.sh $@
#rm rf.lst.junk1 rf.lst.junk2 rf.lst.junk3


################ average receiver function by baz and rayp



################ ccp stacking 
ccp_data = */az.*.ri
conv = p
vmodel = iasp91
averH = 100

CCP = -R${prfLen}/-$(halfw)/$(halfw)/0/${depth} ${PRF} -I1/10/0.5 -S1/1/1 -E1

PRF = -C120/23 -A110
prfLen = -100/100
amplify = 1
Nmin = 3

piercing.dat: 
	saclst stla stlo baz user0 f ${ccp_data}|\
		piercing.pl $(conv) $(vmodel) $(averH) > $@

ccp.3d: piercing.dat
	awk '{print $$1}' $< | ccpStack3D ${CCP} -V$(vmodel) $(sta_vm) -G$@

## deeply relay on gmt4.0
## can't make 3Dslice
ccp.grd: ccp.3d
	3DSlice $< -Gjunk.grd -R${prfLen}/1 ${PRF}
	3DSlice $<.std -G$@.std -R${prfLen}/1 ${PRF}
	grdmath junk.grd $(amplify) MUL $@.std $(Nmin) GE 0 NAN OR = $@
	rm junk.grd
