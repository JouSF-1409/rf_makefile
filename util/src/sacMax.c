/********************************************************
*	Show SAC data max. amplitude withing specified time window
*	Usage:
*		sacMax [-Wt1/t2] sac_files ...
*	modified by xyf at 2023-05
********************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include "sac.h"

int Maxof(float* arr, const int n1, const int n2){
    float amp_max;
    int n=n1;
    for(int j=n1+1;j<n2;j++){
        if (n==n1 && amp_max>arr[j]) amp_max=arr[j];
        if (arr[j]>amp_max && arr[j]>=arr[j-1] && arr[j]>arr[j+1]) {
            amp_max = arr[j];
            n = j;
        }
    }
    return n;
}

int main(int argc, char **argv) {
  SACHEAD	hd;
  int		j,n,n1,n2,error,win;
  float		*ar;
  float		t1, t2, am, t;
  int       positive;

  error = 0;
  win = 0;
  positive=1;
  for (j=1; !error && j < argc; j++) {
     if (argv[j][0] == '-') {
        switch(argv[j][1]) {
	case 'W':
	    win = 1;
            sscanf(&argv[j][2], "%f/%f",&t1,&t2);
	    break;
    case 'P':
        sscanf(&argv[j][2],"%d",&positive);
        break;
	default:
	    error = 1;
	}
     }
  }
  if (argc == 1 || error) {
     fprintf(stderr, "show location of max. amp. in a SAC trace\n\
	Usage: sacMax [-D -Wt1/t2] sac_files ...\n\
		-W  specify time window\n\
        -P  max of abs or not,input int, 0 for False\n\
	Output: name tm Am\n");
     return -1;
  }


  while(*(++argv)) {
     //iter file list, ar is float data array, hd is header struct
     if (argv[0][0] == '-' || (ar = read_sac(*argv,&hd)) == NULL) continue;
     n1 = 0; n2 = hd.npts-1;
     // cal time window on point
     if (win) {
        n1 = rint((t1-hd.b)/hd.delta);if(n1<0) n1=0;
        n2 = rint((t2-hd.b)/hd.delta);if(n2>hd.npts-1) n2=hd.npts-1;
     }
     //pre checks
     if (n1>n2) {
        fprintf(stderr,"no time window for %s, %d %d\n",*argv,n1,n2);
        continue;
     }
     // iter point in array ar
     if (positive){
         n=Maxof(ar,n1,n2);
         am=ar[n];
     }else{
         for(int i=n1;i<n2+1;i++){
             ar[i]=fabs(ar[i]);
         }
         n=Maxof(ar,n1,n2);
         am=ar[n];
     }
     if (n==n1) {
        fprintf(stderr,"%s Warning: no max. found\n",*argv);
     }
         //print filename time_point max_amp
     printf("%s %9.5f %8.2e\n", *argv,(n+t)*hd.delta+hd.b,am);

  }

  return 0;
}
