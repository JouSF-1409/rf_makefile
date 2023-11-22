#include "stdio.h"
#include "cmath"
#include "cstring"
#include "stdlib.h"
#include "cstdint"

#include "sac.h"


int main(int argc, char **argv){
    int verbose, iter_num, n_files;
    float rot_step,rot_min,rot_max,thre;
    bool error;

    //init all requ



    // take requ from CLI
    for (i=1; !error && i < argc; i++){
        if (argv[i][0] == '-'){
            switch(argv[i][1]){
                case 'S':
                    sscanf(&argv[i][2],"%f",&rot_step);
                    break;
                case 'C':
                    sscanf(&argv[i][2],"%f/%f",&rot_min,&rot_max);
                    break;

                case 'I':
                    sscanf(&argv[i][2],"%f",&thre);
                    break;
                default:
                    error = True;
                    break;
                }
        }
        else n_files++;
    }
}

void mt_rot_rz(SAMPLE *r,SAMPLE *z,
             SAMPLE *l,SAMPLE *q,
             int64_t lth, REAL inci){
    // modified from Zhang Zhou's
    // rot z and r to l and q
    //  [l    [ cosi , sini    [ z
    //      =
    //   q]     -sini , cosi ]   r ]
    REAL sini,cosi;
    cosi = cos(inci);
    sini = sin(inci);

    for (i = 0; i < lth; i++){
        l[i] = cosi * *z + sini * *r;
        q[i] = -sini * *z + cosi * *r;

    }

}

bool check_hd(sac_head* hd1, sac_head* hd2){

}