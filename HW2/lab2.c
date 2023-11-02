#include <stdio.h>
#include <stdlib.h>
#include<math.h>
#include <inttypes.h>

# define array_size 7
# define range 127 /*2^(n-1)-1, n: quant bit*/ 

float fp32_to_bf16(float x);
int* quant_bf16_to_int8(float x[]);
float bf16_findmax(float x[]);
typedef uint64_t ticks;
static inline ticks getticks(void)
{
    uint64_t result;
    uint32_t l, h, h2;
    asm volatile(
        "rdcycleh %0\n"
        "rdcycle %1\n"
        "rdcycleh %2\n"
        "sub %0, %0, %2\n"
        "seqz %0, %0\n"
        "sub %0, zero, %0\n"
        "and %1, %1, %0\n"
        : "=r"(h), "=r"(l), "=r"(h2));
    result = (((uint64_t) h) << 32) | ((uint64_t) l);
    return result;
}
int main()
{
	ticks t0 = getticks();
	float array[array_size] = {1.200000, 1.203125, 2.310000, 2.312500, 3.460000, 3.4531255, 5.630000};
	float array2[array_size] = { 0.1, 0.2, 1.2, 3, 2.1, -4.2, 3.5};
	float array3[array_size] = { 3.14159265, 0.12345678 , 1.23456789 , 0.00000123, 0.00000001, 0.99999999 , 0.00000007 };
	float array_bf16[array_size] = {};
	int *after_quant;
	/*data 1*/
	for (int i = 0; i < 7; i++) {
		array_bf16[i] = fp32_to_bf16(array[i]);
	}
	printf("data 1\nbfloat16 number is \n");
	for (int i = 0; i < array_size; i++) {
		printf("%.12f\n", array_bf16[i]);
	}
	after_quant = quant_bf16_to_int8(array_bf16);
	printf("after quantization \n");
	for (int i = 0; i < array_size; i++) {
		printf("%d\n", after_quant[i]);
	}
	/*data 2*/
	for (int i = 0; i < 7; i++) {
		array_bf16[i] = fp32_to_bf16(array2[i]);
	}
	printf("data 2\nbfloat16 number is \n");
	for (int i = 0; i < array_size; i++) {
		printf("%.12f\n", array_bf16[i]);
	}
	after_quant = quant_bf16_to_int8(array_bf16);
	printf("after quantization \n");
	for (int i = 0; i < array_size; i++) {
		printf("%d\n", after_quant[i]);
	}
	/*data 3*/
	for (int i = 0; i < 7; i++) {
		array_bf16[i] = fp32_to_bf16(array3[i]);
	}
	printf("data 3\nbfloat16 number is \n");
	for (int i = 0; i < array_size; i++) {
		printf("%.12f\n", array_bf16[i]);
	}
	after_quant = quant_bf16_to_int8(array_bf16);
	printf("after quantization \n");
	for (int i = 0; i < array_size; i++) {
		printf("%d\n", after_quant[i]);
	}
	ticks t1 = getticks();
    printf("elapsed cycle: %" PRIu64 "\n", t1 - t0);
	system("pause");
	return 0;
}

float fp32_to_bf16(float x)
{
	float y = x;
	int *p = (int *)&y;
	unsigned int exp = *p & 0x7F800000;
	unsigned int man = *p & 0x007FFFFF;
	if (exp == 0 && man == 0) /* zero */
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
	for (int i = 0; i < array_size; i++) {
		after_quant[i] = (x[i] * scale);
	}
	return after_quant;
}
