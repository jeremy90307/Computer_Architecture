#include<stdio.h>
#include <stdlib.h>
float fp32_to_bf16(float x)
{
    float y = x;
    int* p = (int*)&y;
    unsigned int exp = *p & 0x7F800000;
    unsigned int man = *p & 0x007FFFFF;
    if (exp == 0 && man == 0) /* zero */
        return x;
    if (exp == 0x7F800000 /* Fill this! */) /* infinity or NaN */
        return x;

    /* Normalized number */
    /* round to nearest */
    float r = x;
    int* pr = (int*)&r;
    *pr &= 0xFF800000;  /* r has the same exp as x */
    r /= 0x100 /* Fill this! */;
    y = x + r;

    *p &= 0xFFFF0000;

    int count = 0;    //bitcount
    while (y)
    {
        count++;
        *p &= (*p - 1);
    }
    
    return (float)count;
}
int main()
{
    int count = 0;
    float a;
    a = 2.312500;
    count = (float) fp32_to_bf16(a);
    printf("%lf��%d�Ӧ줸��1\n\n", a, count);

    system("pause");
    return 0;
}

