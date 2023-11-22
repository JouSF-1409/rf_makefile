/*********************************************************************
*	scc.c: Sliding Cross-Correlation
*		cross-correlate a segment of waveform of a known event
*		with a long data stream and use cross-correlation
*		coefficient to detect new events.
*		For details, see
*		Yang, H., L. Zhu, and R. Chu, 2009, Fault plane determination
*		of the April 18, 2008 Mt. Carmel, Illinois earthquake by detecting
*		and relocating aftershocks, BSSA, 99(6), 3413-3420.
*
*	Usage:
*		see the usage below.
*		
*	Author:  Lupei Zhu
*
*	Revision History
*		09/18 2004	Initial coding
*		05/13 2008	added options of using 3 components (-M) and setting
*				the minimum time separation between events (-T)
*		12/05 2009	handle reading three components that have
*				different b and npts.
*		02/11 2010	correct beginning time error of the output scc trace.
*		09/20 2011	correct a bug when reading traces using read_sac2()
*********************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <float.h>
#include "sac.h"

int main(int argc, char **argv) {
  int		i, j, k, i0, mm, error, outcc, ic, ncom, npts;
  float 	dt, tBefore, tAfter, normMaster, threshold, cc, ccmax, aa, aamax, tw, arr, tb, te, maxShift;
  float		*master[3], *trace[3], *ccdata;
  double	norm;
  char		fnm[128], line[128], *ccc, com[3]={'r','t','z'};
  SACHEAD	hd;
  
  error = 0;
  tBefore = -5.;
  tAfter = 10.;
  tw = -1.;
  maxShift = -1.;
  threshold = 0.7;
  outcc = 0;
  ncom = 1;
  /* input parameters */
  for (i=1; !error && i < argc; i++) {
    if (argv[i][0] == '-') {
       switch(argv[i][1]) {
       case 'C':
         sscanf(&argv[i][2],"%f",&threshold);
         break;
       case 'M':
	 sscanf(&argv[i][2],"%d",&ncom);
	 break;
       case 'O':
         outcc=1;
	 break;
       case 'T':
         sscanf(&argv[i][2],"%f",&tw);
	 break;
       case 'W':
         j=sscanf(&argv[i][2],"%f/%f/%f",&tBefore,&tAfter,&aa);
	 if (j>2) maxShift=aa;
         break;
       default:
         error = 1;
         break;
       }
    }
  }

  if (argc == 1 || error) {
     fprintf(stderr,"usage: %s [-Ccc] [-Mn] [-O] [-Tlength] [-Wt1/t2[/maxShift (0.5*(t2-t1))]]\n\
	-C: cc threshold (%f).\n\
	-M: use n=2 or 3 components .r .t .z (%d).\n\
	-O: output cc (no).\n\
	-T: set minimum time separation between events (t2-t1).\n\
	-W: specify the time window [a+t1, a+t2] of the template waveform (%f/%f s).\n\
      Input names of the template trace and others from stdin, e.g. \n\
          template [a] \n\
	  name1 [a] \n\
	  ... \n\
      If no arrival time is specified, the code uses the A in the template SAC header.\n\
      If name1 has arrival time provided, then only the time window [a+t1-maxShift,a+t2+maxShift] of name1 is used.\n",
      argv[0],threshold,ncom,tBefore,tAfter);
     return -1;
  }
  fprintf(stderr, "++++ You are using %d components\n",ncom);
  if (tw<0.) tw = tAfter-tBefore;
  if (maxShift<0.) maxShift = 0.5*(tAfter-tBefore);

  /* input the template trace */
  fgets(line,128,stdin);
  j=sscanf(line, "%s %f",fnm,&arr);
  k=-1; if (j<2) {k=-2; arr=0.;}
  ccc = fnm + strlen(fnm) - 1;
  for(ic=0;ic<ncom;ic++) {
    if (ncom>1) *ccc = com[ic];
    if ( (master[ic]=read_sac2(fnm,&hd,k,arr+tBefore,arr+tAfter))==NULL ) return -1;
  }
  if (j<2) arr=hd.a;
  mm = hd.npts;
  dt = hd.delta;
  normMaster=0.;
  for(ic=0;ic<ncom;ic++) for(k=0;k<mm;k++) normMaster+=master[ic][k]*master[ic][k];
  if (normMaster == 0.) {
     fprintf(stderr, "The template is outside the specified time window\n");
     return 0;
  }
  normMaster=sqrt(normMaster);
  printf("%s %10.3f 1\n",fnm,arr);
  
  while(fgets(line,128,stdin)) {
    j=sscanf(line,"%s %f",fnm,&arr);
    if (j==2) {
       tb = arr+tBefore-maxShift;
       te = arr+tAfter+maxShift;
       tw = te-tb;
    }
    ccc = fnm + strlen(fnm) - 1;
    for(error=0,ic=0;ic<ncom;ic++) {
      if (ncom>1) *ccc = com[ic];
      if (j<2 && ic==0) {
         if ( (trace[ic]=read_sac(fnm,&hd))==NULL ) error++;
         npts = hd.npts;
	 tb = hd.b;
	 te = hd.e;
      } else {
         if ( (trace[ic]=read_sac2(fnm,&hd,-1,tb,te))==NULL ) error++;
	 if ( ic==0 ) npts = hd.npts;
         if (hd.npts < npts) npts=hd.npts;
      }
    }
    if (error || npts<mm || fabs(hd.delta-dt) > 0.0001 || (outcc && (ccdata=(float *) calloc(npts,sizeof(float)))==NULL) ) {
       fprintf(stderr,"%s : read data error (%d) or trace is shorter than the template (%d %d) or dt=%f does not match %f or fail to allocate memory for output cc\n",fnm,error,npts,mm,hd.delta,dt);
       for(ic=0;ic<ncom;ic++) free(trace[ic]);
       continue;
    }
    for (norm=0.,j=0;j<mm-1;j++) {
       for(ic=0;ic<ncom;ic++) norm += trace[ic][j]*trace[ic][j];
    }
    ccmax = 0.;
    hd.b -= tBefore;
    for (j=0;j<=npts-mm;j++) {
       for(cc=0.,ic=0;ic<ncom;ic++) {
         norm += trace[ic][j+mm-1]*trace[ic][j+mm-1];
         for(k=0;k<mm;k++) cc += master[ic][k]*trace[ic][j+k];
       }
       aa = sqrt(norm)/normMaster;
       if (fabs(norm)>FLT_EPSILON) cc = cc*aa/norm; else cc = 0.;
       if (cc>ccmax) {
          ccmax = cc;
	  aamax = aa;
	  i0 = j;
       }
       if (ccmax>threshold&&(j-i0)*dt>tw) {
          printf("%s %10.3f 1 %6.3f %8.2e\n",fnm,hd.b+i0*dt,ccmax,aamax);
	  ccmax = cc;
	  aamax = aa;
	  i0 = j;
       }
       if (outcc) ccdata[j] = cc;
       for(ic=0;ic<ncom;ic++) norm -= trace[ic][j]*trace[ic][j];
    }
    if (ccmax>threshold)
       printf("%s %10.3f 1 %6.3f %8.2e\n",fnm,hd.b+i0*dt,ccmax,aamax);
    for(ic=0;ic<ncom;ic++) free(trace[ic]);
    if (outcc) {
       hd.npts = npts-mm+1;
       write_sac(strcat(strcpy(line,fnm),".cc"),hd,ccdata);
       free(ccdata);
    }

  }

  return 0;
  
}
