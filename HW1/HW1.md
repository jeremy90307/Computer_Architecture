# Implementation
**Topic : Convert FP32 to BF16 and Count the Number of Ones in the Binary Representation**

## test data


| Single-precision (FP32) | float16 as HEX literals | float16 as binary literals|
| - | - | - |
| 1.200000 | 0x3f99999a |00111111100110011001100110011010|
| 1.203125 | 0x3f9a0000 |00111111100110100000000000000000|
| 2.312500 | 0x40140000 |01000000000101000000000000000000|



## c code
```
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
```
## Assembly code
### First version
Attempting to convert Problem B from C code to RISC-V.
```
.data
    test0: .word 1067030938                         
    test1: .word 1067057152                            
    test2: .word 1075052544                           
.text
.globl main
main:
    lw a0, test0                                       #a0=x=2.2
    
    mv t0, a0                                       #t0=y
    li t1, 0x7F800000  
    and t2, t1, a0                                  #t2=exp
    li t3, 0x007FFFFF  
    and t4, t3, a0                                  #t4=man  
    
    beq a0, t1, infinity_or_NaN                     #infinity or NaN   
    beq a0, zero, z                                 #zero 
    
    mv t5, a0                                       #t5=r
    li t6, 0xFF800000                               #r has the same exp as x
    and t5, t6, t5
    
    #mv s2, t5                                       #find s2=exp
    #srli s2, s2, 23
    #addi s2, s2, -8
    #slli s2, s2, 23                                 #s2=0xxxxxxxx0...0000 
    #add s2, s2, t4                                  #r/=0x100      value r
    
    # srli t5, t5, 8  (false)
    
    #add t0, a0, s2 (false)
    mv s3, t4                                   
    srli s3, s3, 8                              
    li s4, 0x8000                                    
    or s3, s3, s4                                  #obtain r_man when r_exp no change
                                                   #find y
    add s5, s3, t4                                 #s5=y_man
    add t0, s5, t2                                 #value y
    
    li t1, 0xFFFF0000
    and t0, t0, t1                                #transfer to bf16
                                                  #t0=y
    mv a0, t0                                     
    j end

infinity_or_NaN:
    j end
z:
    j end
end:
    li a7, 2
    ecall
    
```
### Second version
Modify the original question to include how many '1's are there in the binary representation of BF16.
```
.data
    test0: .word 1067030938                            #true t0=0x3f99999a
    test1: .word 1067057152                            #true t0=0x3f9a0000
    test2: .word 1075052544                            #true t0=0x40140000
    str: .string "How many '1's are there in BF16 (binary)? ANS : "
.text
.globl main
main:
    lw a0, test0                                      #x=16
    mv a1, x0                                       #count=0

    mv t0, a0                                       #t0=y
    li t1, 0x7F800000  
    and t2, t1, a0                                  #t2=exp
    li t3, 0x007FFFFF  
    and t4, t3, a0                                  #t4=man  
    
    beq a0, t1, end                                 #infinity or NaN   
    beq a0, zero, end                               #zero 
    
    mv t5, a0                                       #t5=r
    li t6, 0xFF800000                               #r has the same exp as x
    and t5, t6, t5
    
    mv s3, t4                                      #find y = x + r ; r/=0x100
    srli s3, s3, 8                              
    li s4, 0x8000                                    
    or s3, s3, s4                                  #obtain r_man when r_exp no change

    add s5, s3, t4                                 #s5=y_man
    add t0, s5, t2                                 #value y
    
    li t1, 0xFFFF0000
    and t0, t0, t1                                #transfer to bf16
                                                  #t0=y
    jal ra, count_ones
    
    la a0, str
    li a7, 4
    ecall
    
    mv a0, a1                                     
    j end
    
count_ones:
    addi t1, t0, -1                               # *p - 1
    and t0, t0, t1                                #*p &= (*p - 1)
    addi a1, a1, 1                                #count++
    bne t0, x0, count_ones                        #if t0!=0 goto loop
    ret                                           #goto ra
    
end:
    li a7, 1
    ecall
```

## Result
![](https://hackmd.io/_uploads/HyPx7LOeT.png)
![](https://hackmd.io/_uploads/ryJlUUdlp.png)

**Test 0**
* c : Count to ten '1' in BF16.
* Assembly : Count to ten '1' in BF16.
* 
**Test 1**
* c : Count to ten '1' in BF16.
* Assembly : Count to ten '1' in BF16.

**Test 2**
* c : Count to one '1' in BF16.
* Assembly : Count to one '1' in BF16.


# Analysis
## Ripes Simulator
![](https://hackmd.io/_uploads/HySKJEula.png)


| stage | description | 
| -------- | -------- | 
| IF     | Instruction Fetch     | 
| ID     | Instruction Decode & Register Read     |
| EX     | Execution or Address Calculation     |
| MEM     | Data Memory Access    |
| WB     | Write Back     |

example:```mv t0, a0 ```
### IF
![](https://hackmd.io/_uploads/r1_U8yuxa.png)
* PC=PC+4

![](https://hackmd.io/_uploads/rJmcPJue6.png)

I-Format instruction `addi`

| imm[11:0] | rs1 | funct3 | rd | opcode |
| --- | -------- | -------- | - |- |
| 000000000000 | 01010 | 000 | 00101 | 0010011 |

* After converting it to Hex, you can get `0x00050293`
### ID
![](https://hackmd.io/_uploads/Bk2urWdlT.png)
The instruction has been decoded, input `R1_idx=0x0a` `R2_idx=0x00`, output `Reg1=0x10000000` `Reg2=0x00000000`
### EX
![](https://hackmd.io/_uploads/rJDB6-dgp.png)

![](https://hackmd.io/_uploads/rkxbjZugp.png)

In this stage, there are four multiplexer(MUX) to choise which inputs will be used.
Obtained`Op1=0x40140000`and`Op2=0x00000000`.
At the red circle, due to receiving the updated x10 from the previous load word (lw) instruction, the value is directly brought back to the multiplexer (MUX) in the write-back (WB) stage.
### MEM
![](https://hackmd.io/_uploads/r1G8kGug6.png)
We can infer that the Addi instruction does not read or write to memory but instead directly enters the write-back (WB) stage.
### WB
![](https://hackmd.io/_uploads/S1cFlG_e6.png)
In the write-back (WB) stage, the new value is written into the register
## Hazards
* Structural Hazard : Two or more instrucbons in the pipeline compete for access to a single physical resource
![](https://hackmd.io/_uploads/ByhKlEdxa.png)
* Data Hazard
![](https://hackmd.io/_uploads/BJGMb4uxa.png)

solution :
1.stalling : Adding the `NOP` instruction causes the affected instruction to do nothing.
2.Forwarding : grab operand from pipeline stage,rather than register file
* Control Hazard
![](https://hackmd.io/_uploads/HJu4QE_gT.png)

Reducing Branch Penalties : To improve performance, use “branch prediction” to guess which way branch will go earlier in pipeline
![](https://hackmd.io/_uploads/BkwuNVdg6.png)
## Find my hazard
1. In my assembly code,`jal ra, count_ones`is a branch,and exist cotrol hazard.

![](https://hackmd.io/_uploads/SyomCV_xa.png)
![](https://hackmd.io/_uploads/S1GZANdxa.png)

When jumping to the label `<count_ones>`, the IF and ID stages will be flushed and converted to `NOP`.

2. 

# Reference
* [Ripes Environmental Calls](https://github.com/mortbopet/Ripes)
* [green reference](https://www.cs.sfu.ca/~ashriram/Courses/CS295/assets/notebooks/RISCV/RISCV_CARD.pdf)
* [Environmental Calls](https://github.com/ThaumicMekanism/venus/wiki/Environmental-Calls)
* [2022 Computer Architecture HW1 by wanghanch](https://hackmd.io/@wanghanchi/BkM-53UWi)