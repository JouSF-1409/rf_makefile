/*********************************************************************
*	src_ss.c:
*		does cross-correlations between a master trace
*		and other traces to find the time shifts to align
*		them together.
*
*	Usage:
*		src_ss -Dt1/t2/max_time_shift [-W] [-N] [-Sxx] [-Txx]
*		then input name of file from stdin, in following format:
*			name arr onoff
*		where arr is the approx. arrival time for the trace.
*		The first line is for the master trace.
*		
*		The outputs are in the same format with cc added. It can be used
*		as input for the next iteration
*
*	Author:  Lupei Zhu
*
*	Revision History
*		June 1997	Initial coding
*		06/23/97	input component names from stdio with
*				a shift0.
*		09/04/97	change shift0 to arrival time
*		02/11/02	output cross-correlation value
*		07/14/04	correct a time-window check bug;
*				use coswndw() for tapering
*		09/01/04	add sliding window option -S
*		02/08/07	add integration option -I
*		12/13/10	add -C minCC option
*********************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <float.h>
#include "sac.h"
#include "Complex.h"

int main(int argc, char **argv) {
  int 		i, nn, mm, max_shift, error, intg, set0, onoff;
  int		shift, start, end, ntrace, overWrite, normalize, slide;
  char		line[128],inf[64],outf[64];
  float		tshift, tap, norm, dt, arr0, arr, tBefore, tAfter, amp, overlap, minCC;
  float 	*src, *master, *trace, *wndw;
  SACHEAD	hd_m, hd;
  
  error = 0;
  tBefore = -5.;
  tAfter = 10.;
  tshift = 1.5;
  overWrite = 0;
  normalize = 0;
  set0 = 0;
  intg = 0;
  slide = 0;
  tap = 0.2;
  minCC = 0.;
  /* input parameters */
  for (i=1; !error && i < argc; i++) {
    if (argv[i][0] == '-') {
       switch(argv[i][1]) {
  
       case 'C':
         sscanf(&argv[i][2],"%f",&minCC);
	 break;

       case 'D':
         nn = sscanf(&argv[i][2],"%f/%f/%f",&tBefore,&tAfter,&tshift);
	 if (nn<3) tshift = 0.1*(tAfter-tBefore);
         break;
  
       case 'I':
         intg = 1;
	 break;

       case 'N':
	 overWrite = 1;
	 normalize = 1;
	 if (argv[i][2] == 'a') normalize = 2;
	 break;

       case 'S':
	 slide = 1;
         sscanf(&argv[i][2],"%f",&overlap);
         break;

       case 'T':
         sscanf(&argv[i][2],"%f",&tap);
         break;

       case 'W':
	 overWrite = 1;
	 if (argv[i][2] == 's') set0 = 1;
         break;
  
       default:
         error = 1;
         break;
  
       }
    } else {
       error  = 1;
    }
  }

  if (argc == 1 || error) {
     fprintf(stderr,"usage: %s [-Cmin] [-Dt1/t2[/max_shift]] [-I] [-N[a]] [-Soverlap] [-Ttaper] [-W[s]]\n\
  input the names of SAC files from stdin, in the form: \n\
     name1 t01 \n\
     name2 t02 \n\
     ... \n\
  output will be \
\
  where t0 is the arrival time for the trace. The code cross-correlates all the\n\
  traces with the first trace (the master) and outputs adjusted arrival time,\n\
  cc coefficient, and best-match amplitude ratio for each trace.\n\
  -C: specify min cc for stacking and updating the master trace (0)\n\
  -D: specify the cc time window as [t0+t1, t0+t2] and max. allowed shift in sec. (-5/10/10%%).\n\
  -I: integrate before cc (off).\n\
  -N: normalize traces, append a to use area instead of amplitude (off).\n\
  -S: using a sliding window of length max_shift with overlap (0-1, off).\n\
  -T: tapering the window (0-0.5, default 0.2).\n\
  -W: overr-write the master trace by the average (off);\n\
      append s to set its arrival time to 0.\n",argv[0]);
     return -1;
  }

  /* input the master trace */
  fgets(line,128,stdin);
  sscanf(line,"%s %f",outf,&arr0);
  if ( (master=read_sac2(outf,&hd_m,-1,arr0+tBefore,arr0+tAfter))==NULL ) return -1;
  printf("%-6s %8.3f 1\n",outf,arr0);
  fflush(stdout);
  mm = hd_m.npts;
  dt = hd_m.delta;
  max_shift = (int) rint(tshift/dt);
  wndw = coswndw(mm,tap);
  for(i=0;i<mm;i++) master[i] *= wndw[i];
  if (intg) for(amp=0.,i=0;i<mm;i++) {amp+=master[i];master[i]=amp;}
  
  if (overWrite) {
     ntrace = 0;
     if ( read_sachead(outf,&hd_m)<0 ||
          (src = (float *) calloc(hd_m.npts,sizeof(float)))==NULL ) return -1;
     nn = hd_m.npts;
     hd_m.a = arr0;
  }

  while (fgets(line,128,stdin)) {

    sscanf(line,"%s%f%d",inf,&arr,&onoff);
    if ( (trace=read_sac2(inf,&hd,-1,arr+tBefore,arr+tAfter)) == NULL ) continue;
    if ( fabs(hd.delta-dt)>0.0001 ) {
       fprintf(stderr,"Warning: %s has different dt %f from the master %s %f, skip\n",inf,hd.delta,outf,dt);
       free(trace);
       continue;
    }
    for(i=0;i<mm;i++) trace[i] *= wndw[i];
    if (intg) for(amp=0.,i=0;i<mm;i++) {amp+=trace[i];trace[i]=amp;}
    if (slide)
       norm = maxCorSlide(master,trace,mm,max_shift,overlap,&shift,&amp);
    else
       norm = maxCor(master,trace,mm,max_shift,&shift,&amp);
    arr -= shift*dt;
    printf("%-6s %8.3f %d %6.3f %8.2e\n",inf,arr,onoff,norm,amp);
    fflush(stdout);
    free(trace);

    /* stacking */
    if (overWrite) {
       if ( onoff==0 || (minCC>0. && norm<minCC) || (trace=read_sac(inf,&hd))==NULL ) continue;
       ntrace++;
       shift = (int) rint((arr0-hd_m.b-(arr-hd.b))/dt);
       start = shift;		if (start<0) start = 0;
       end   = hd.npts+shift;	if (end>nn) end = nn;
       norm = 1.;
       if (normalize) {
          if (normalize==1) norm = 1./amp;
	  else for (norm=0.,i=start; i<end; i++) norm += trace[i-shift];
       }
       for (i=start; i<end; i++) src[i] += trace[i-shift]/norm;
       free(trace);
    }

  }
  
  if (ntrace<1 || !overWrite) return 0;
  fprintf(stderr, "total number of traces stacked: %d\n",ntrace);
  norm = 1./ntrace;
  for(i=0;i<nn;i++) src[i] *= norm;
  if (set0) {
     hd_m.a -= arr0;
     hd_m.b -= arr0;
     hd_m.e -= arr0;
  }
  return write_sac(outf, hd_m, src);

}
