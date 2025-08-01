#include <stdio.h>
#include <stdlib.h>
#include <omp.h>
#include <math.h>
#include <time.h>
#include <cstring>
#include <string>

#include <tbb/blocked_range.h>
#include <tbb/parallel_for.h>

#define min(a,b) (((a)<(b))?(a):(b))
#define max(a,b) (((a)>(b))?(a):(b))
#define MIN(a,b) (((a)<(b))?(a):(b))
#define MAX(a,b) (((a)>(b))?(a):(b))
#define floord(n,d) floor(((double)(n))/((double)(d)))
#define ceild(n,d) ceil(((double)(n))/((double)(d)))



long double **S;
char *RNA;
int N=1000;

#include "library.h"
#include "oryg.h"
#include "tstile.h"
#include "tilecorr.h"

#include "pluto.h"
#include "li.h"
#include "byrow.h"
#include "traceback.h"
#include "3D.h"


int main(int argc, char *argv[]){

    int i,j,k;
    char *filename, *method;
    int num_proc=-1;

    method = "oryg";

    if(argc > 1)
        filename = argv[1];
    else{
        // blasz 3d code
        // li transpose code
        printf("./nuss filename [method: oryg,tstile,tilecorr,blasz,byrow,li,pluto] [number of threads] [RNA size]\n");
        return -1;
        }

    if(argc > 2)
        method = argv[2];


    if(argc > 3)
        num_proc = atoi(argv[3]);

    if(num_proc > 0)
       omp_set_num_threads(num_proc);  // else default max number

    //uncomment for sequennces from FASTA file
    // default random RNA
    N = readRNA(filename);
    // N = atoi(filename);

    RNA = new char[N+5];
    S = mem();

    printf("\nmethod %s\n", method);
    printf("N %i\n", N);

    double start = omp_get_wtime();


    if(strcmp(method, "oryg")==0)
       oryg();
    if(strcmp(method, "tstile")==0)
       tstile();


    if(strcmp(method, "tilecorr")==0)
       tilecorr();


    if(strcmp(method, "pluto")==0)
       pluto();

    if(strcmp(method, "li")==0)
       li();

    if(strcmp(method, "byrow")==0)
       byrow();


    if(strcmp(method, "3D")==0)
       n3D();




    double stop = omp_get_wtime();

    saveTable(method, num_proc, filename);
    saveTable();



    printf("Time: %.2f\n", stop - start);

    printf("Traceback:\n");
     

     char *wout = new char[256];
     strcpy(wout, filename);

     FILE *plik = fopen(strcat(wout, ".traceback.txt") ,"w");
     traceback(0, N-1, plik);
     fclose(plik);

     return 0;
}

