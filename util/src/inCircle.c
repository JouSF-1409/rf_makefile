#include <stdio.h>
#include "math.h"

//circles across 180 or 90 should be rotated to avoid bugs

typedef struct {
    //lat-y,lon-x
    float lat,lon;
} point;

float CrossMult(point* p1,point* p2);
int RayWay(point* ps,int count);
point* FromCLI(int count,char* list);
point* FromExist();

int main(int argc, char* argv[])
{
    int count=5;
    //point* p=FromCLI(argc,argv);count=(argc-1)/2;
    point* p=FromExist();count=5;
    if(p==NULL){
        fprintf(stderr,"usage: point_lat point_lon1 lat1 lon1 lat2 lon2 lat3 lon3....\n");
        return -1;
    }

    if (RayWay(p,count)){
        printf("inner");
    } else{
        printf("outter");
    }
    return 1;
}

int RayWay(point* ps,int count){


    int cross_left=0;
    int cross_right=0;
    float left,right;
    point side1,side2;
    side1.lat=ps[0].lat;side1.lon=-200;
    side2.lat=ps[0].lat;side2.lon=200;

    for(int i=2;i<count;i++){
        if(CrossMult(ps[0],side1,ps[i],ps[i-1])<0)cross_left++;
        left = CrossMult();
        right = CrossMult(ps[0],side2,ps[i],ps[i-1]);
        if (left*right<0)
    }
    if (mid<0 && CrossMult(&side1,&ps[i])<0) cross_left++;
    if (mid<0 && CrossMult(&side1,&ps[i])<0) cross_left++;

    if(cross_right % 2 == 0 || cross_left % 2 == 0) return 1;

    return 0;
}

float CrossMult(point* p1,point* p2,point* p3,point* p4){
    // test_line p1,p2; line of multiside p3,p4
    float side=(((p2->lon-p1->lon)(p3->lat-p1->lat)
            -(p3->lon-p1->lon)(p2->lat-p1->lat))*
            ((p2->lon-p1->lon)(p4->lat-p1->lat)
             -(p4->lon-p1->lon)(p2->lat-p1->lat)));
    return side;
}

point* FromCLI(int count,char* list){
    if(count<8 || count%2==0) return NULL;
    num=(count-1)/2
    point p[num];
    for (int i=0;i<=count;i++){
        sscanf(list[i],"%f",p[i].lat);
        sscanf(list[i],"%f",p[i].lon);
        if(fabs(p[i].lat)>90 || fabs(p[i].lat)>180) return NULL;
    }
    return p;
}

point* FromExist(){
    point p[5];
    p[0].lat=2;p[0].lon=2;
    p[1].lat=1;p[1].lon=1;
    p[2].lat=1;p[2].lon=4;
    p[3].lat=4;p[3].lon=4;
    p[4].lat=4;p[4].lon=1;
    return p;
}