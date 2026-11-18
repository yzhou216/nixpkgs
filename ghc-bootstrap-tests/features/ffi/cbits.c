#include "cbits.h"

int add3(int a, int b, int c)
{
	return a + b + c;
}

double dot(const double *a, const double *b, int n)
{
	double s = 0;
	int i;

	for (i = 0; i < n; i++)
		s += a[i] * b[i];
	return s;
}

void fill(int *p, int n)
{
	int i;

	for (i = 0; i < n; i++)
		p[i] = i * i;
}

int twice(int x)
{
	return 2 * x;
}

long long mix(long long a, unsigned long long b, int c, unsigned char d, double e, float f)
{
	return a + (long long)(b >> 60) + c + d + (long long)e + (long long)f;
}
