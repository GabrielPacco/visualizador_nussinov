void byrow()
{
    int i,j,k;
    int diag,row,col;
    char a,b;
    int _max,t;


    #pragma omp parallel for
    for(i=0; i<=N-2; i++){
     S[i][i] = 0;
     S[i][i+1] = 0;
   }

    S[N-1][N-1] = 0;

    for(i=N-3; i>=0; i--){
      for(j=i+2; j<=N-1; j++)
         S[i][j] = S[i+1][j-1] + can_pair(RNA, i, j);
      for(k=i; k <=N-2; k++)
         #pragma omp parallel for private(j)
         for(j=k+1; j <=N-1; j++)
          S[i][j] = max(S[i][j], S[i][k] + S[k+1][j]);
     }

}


