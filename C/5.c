/*
	65-90	A-Z
	97-122	a-z
*/

/*
char		>= 1
short		>= 2
long		>= 4
long long	>= 8
*/


| x | y | z | \0 |
              ^

| x | w | z | \0 |
              ^



char alphabet[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
//                 ^  ^

char rotate(char original, int offset) {
	return alphabet[(strchr(alphabet, original) - alphabet + offset) % 52];
}

void shift(const char *src, char *dst, int offset) {
	for (; *src != '\0'; ++src, ++dst) {
		*dst = rotate(*src, offset);
	}
}
 
int compare(const char *str1, const char *str2) {
	int match = 0;
	for (; *str1 != '\0' && str2 != '\0'; ++str1, ++str2)
		match += (*str1 != *str2);
	return match;
}

int main () {
	int length;
	scanf("%i", &length);
	char sifra[length + 1];
	char posun[length + 1];
	char odposlech[length + 1];

	scanf("%s%s", sifra, odposlech);

	int min = length;    // 7
	int offset; // 3
	int dist;

	for (int i = 0; i < 52; ++i) {
		shift(sifra, posun, i);
		dist = compare(posun, odposlech);
		/*if (i == 0) {
			min = dist;
			offset = i;
		} else*/ if (dist < min) {
			min = dist;
			offset = i;
		}
	}



	6  0 <-
	5  1 <-
	10 2
	7  3 <-

}