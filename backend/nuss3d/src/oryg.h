#define sigma(i, j) (can_pair(RNA, i, j))
void oryg(){
	int n = N;
	int i,j,k;

	for ( i = n-1; i >= 0; i--) {
	   for (j = i + 1; j < n; j++) {
		 for (k = i; k < j ; k++) {
		   S[i][j]=max(S[i][k] + S[k + 1][j], S[i][j]); // s1
		 }
		 S[i][j]=max(S[i][j], S[i+1][j-1]+sigma(i,j)); // s2
	   }
	}
}
