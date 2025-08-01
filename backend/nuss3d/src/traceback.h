void traceback(int i,int j, FILE *plik)
{
int k;



if(j<=i)
   return;
else if (S[i][j] == S[i][j-1]){
    traceback(i, j-1, plik);
    return;
    }
else
   for(k=i; k<=j; k++)
     if(can_pair(RNA, k, j))
       if(k-1 < 0){
         if (S[i][j] == S[k+1][j-1] + 1){
           fprintf(plik,"%d %d\n", k, j);
           traceback(k + 1, j - 1, plik);
           break;
         }
         }
         else{
         if (S[i][j] == S[i][k-1] + S[k+1][j-1] + 1){
          fprintf(plik, "%d %d\n", k, j);
          traceback(i, k - 1, plik);
          traceback(k + 1, j - 1, plik);
          break;
          }
        }


}


