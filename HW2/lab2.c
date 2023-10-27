#include <stdio.h>
#include <stdlib.h>
#include<math.h>

# define array_size 7
# define range 127 /*2^(n-1)-1, n: quant bit*/ 

float fp32_to_bf16(float x);
int* quant_bf16_to_int8(float x[]);
float bf16_findmax(float x[]);
void print_bf16_number();
void print_after_quantization();
int main()
{
	float array[array_size] = {1.200000, 1.203125, 2.310000, 2.312500, 3.460000, 3.4531255, 5.630000};
	float array_bf16[array_size] = {};
	int *after_quant;
	/*data 1*/
	for (int i = 0; i < 7; i++) {
		array_bf16[i] = fp32_to_bf16(array[i]);
	}
	print_bf16_number(array_bf16);
	after_quant = quant_bf16_to_int8(array_bf16);
	print_after_quantization(after_quant);


	system("pause");
	return 0;
}

float fp32_to_bf16(float x)
{
	float y = x;
	int *p = (int *)&y;
	unsigned int exp = *p & 0x7F800000;
	unsigned int man = *p & 0x007FFFFF;
	if (exp == 0 && man == 0) /* zero		printf("%f\n",after_quant[i]); */
		return x;
	if (exp == 0x7F800000 /* Fill this! */) /* infinity or NaN */
		return x;

	/* Normalized number */
	/* round to nearest */
	float r = x;
	int *pr = (int *)&r;
	*pr &= 0xFF800000;  /* r has the same exp as x */
	r /= 0x100 /* Fill this! */;
	y = x + r;

	*p &= 0xFFFF0000;

	return y;
}

int* quant_bf16_to_int8(float x[array_size])
{
	static int after_quant[array_size] = {};
	float max = fabs(x[0]);
	for (int i = 1; i < array_size; i++) {
		if (fabs(x[i]) > max) {
			max = fabs(x[i]);
		}
	}
	printf("maximum number is %.12f\n", max);
	float scale = range / max;
	printf("scale = %f\n",scale);
	for (int i = 0; i < array_size; i++)
	{
		after_quant[i] = (x[i] * scale);
	}
	
	return after_quant;
}

void print_bf16_number(float *x)
{
	printf("data 1\nbfloat16 number is \n");
	for (int i = 0; i < array_size; i++) {
		printf("%.12f\n", x[i]);
	}

}
void print_after_quantization(int *x)
{
	printf("after quantization \n");

	for (int i = 0; i < array_size; i++) {
		printf("%d\n", x[i]);
	}
}