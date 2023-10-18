#include <stdio.h>
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
    
    return count;
}
int main()
{
    int count = 0;
    float a = 1.200000, b = 1.203125, c = 2.312500;

    count = (float)fp32_to_bf16(a);
    printf("The number %lf has %d bits set to 1.\n", a, count);
    count = (float)fp32_to_bf16(b);
    printf("The number %lf has %d bits set to 1.\n", b, count);
    count = (float)fp32_to_bf16(c);
    printf("The number %lf has %d bits set to 1.\n", c, count);
    
    system("pause");
    return 0;
}