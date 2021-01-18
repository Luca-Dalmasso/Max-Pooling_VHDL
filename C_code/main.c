#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define FILE_DEST 	"pooling.mem"
#define FILE_SOURCE "samples.mem"
#define N 4
#define M 2
#define LIMIT 100

void gen_rand_matrix(int n,int matrix[][N]);
void matrix_pooling(int matrix[][N],int n,int m);

int main(int argc, char *argv[])
{
	int i,j;
	int matr[N][N];
	gen_rand_matrix(N,matr);
	matrix_pooling(matr,N,M);
	return 0;
}

/*matrix pooling algorithm
 *the result of the pooling is saved into a file
 *n=NxN source matrix
 *m=MxM dest matrix
 */
void matrix_pooling(int matrix[][N],int n,int m)
{
	int i,j,k,p,max;
	FILE *fp;
	fp=fopen(FILE_DEST,"w");
	if(fp==NULL)
	{
		fprintf(stderr,"no destination file found!\n");
		exit(-1);
	}
	for(i=0;i<N;i=i+M){
		for(j=0;j<N;j=j+M){
			max=matrix[i][j];
			for(k=i;k<i+M;k++){
				for(p=j;p<j+M;p++){
					if(k==i && p==j)
						continue;
					if(matrix[k][p] > max)
						max=matrix[k][p];
				}
			}
			fprintf(fp,"%d\n",max);
		}
	}
	fclose(fp);
}


/*generates a random NxN matrix
 *matrix is generated and saved into a file
 */
void gen_rand_matrix(int n,int matrix[][N])
{
	int i,j;
	FILE *fp;
	time_t t;
	srand((unsigned)time(&t));
	fp=fopen(FILE_SOURCE,"w");
	if(fp==NULL)
	{
		fprintf(stderr,"no destination file found!\n");
		exit(-1);
	}
	for(i=0;i<n;i++){
		for(j=0;j<n;j++){
			matrix[i][j]=rand()%LIMIT;
			fprintf(fp,"%d\n",matrix[i][j]);
		}
	}
	fclose(fp);
}























