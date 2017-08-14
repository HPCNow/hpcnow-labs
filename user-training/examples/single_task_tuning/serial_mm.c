/******************************************************************************
* file: serial_mm.c
* Serial Example - Matrix Multiply - C Version
* Inspired in the material developed by Blaise Barney at LLNL
* https://computing.llnl.gov/tutorials/openMP/
* Developed by Jordi Blasco <jordi.blasco@hpcnow.com>
******************************************************************************/
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define NRA 10000              /* number of rows in matrix A */
#define NCA 1500               /* number of columns in matrix A */
#define NCB 700                /* number of columns in matrix B */

int main (int argc, char *argv[]) 
{
    FILE *f = fopen("./results.txt", "w");
    int  i, j, k, chunk;
    chunk = 10;                /* set loop iteration chunk size */
    double  a[NRA][NCA],       /* matrix A to be multiplied */
        b[NCA][NCB],           /* matrix B to be multiplied */
        c[NRA][NCB];           /* result matrix C */
    // Start to evaluate the runtime 
    clock_t start = clock(), diff;
    {
        /*** Initialize matrices ***/
        for (i=0; i<NRA; i++)
        {
            for (j=0; j<NCA; j++)
            {
                a[i][j]= i+j;
            }
        }
        for (i=0; i<NCA; i++)
        {
            for (j=0; j<NCB; j++)
            {
                b[i][j]= i*j;
            }
        }
        for (i=0; i<NRA; i++)
        {
            for (j=0; j<NCB; j++)
            {
                c[i][j]= 0;
            }
        }
    
        /*** Do matrix multiply sharing iterations on outer loop ***/
        for (i=0; i<NRA; i++)    
        {
            for(j=0; j<NCB; j++)       
            {
                for (k=0; k<NCA; k++)
                {
                    c[i][j] += a[i][k] * b[k][j];
                }
            }
        }

        /*** Print results ***/
        // Comment this loop to avoid noise related with IO
        for (i=0; i<NRA; i++)
        {
            for (j=0; j<NCB; j++) 
            {
                fprintf(f, "%6.2f   ", c[i][j]);
            }
            fprintf(f, "\n"); 
        }
    }
    fclose(f);

    // Stop the clock
    diff = clock() - start;
    int msec = diff * 1000 / CLOCKS_PER_SEC;
    printf("Time taken %d seconds %d milliseconds", msec/1000, msec%1000);
}
