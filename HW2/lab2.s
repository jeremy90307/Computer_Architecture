.data
array: .word 0x3f99999a, 0x3f9a0000, 0x4013d70a, 0x40140000, 0x405d70a4, 0x405d0000, 0x40b428f6
# test data1: 1.200000, 1.203125, 2.310000, 2.312500, 3.460000, 3.4531255, 5.630000

array2: .word 0x3dcccccd, 0x3e4ccccd, 0x3f99999a, 0x40400000, 0x40066666, 0xc0866666, 0x40600000
# test data2: 0.1, 0.2, 1.2, 3, 2.1, -4.2, 3.5

array3: .word 0x40490fdb, 0x3dfcd6e9, 0x3f9e0652, 0x35a5167a, 0x322bcc77, 0x3f800000, 0x339652e8
# test data3: 3.14159265, 0.12345678 , 1.23456789 , 0.00000123, 0.00000001, 0.99999999 , 0.00000007

array_bf16: .word 0, 0, 0, 0, 0, 0, 0

exp_mask: .word 0x7F800000
man_mask: .word 0x007FFFFF
sign_exp_mask: .word 0xFF800000
bf16_mask: .word 0xFFFF0000

next_line: .string "\n"
max_string: .string "maximum number is "
bf16_string: .string "\nbfloat16 number is \n"

.text
main:
        # push data    
        addi sp, sp, -12
        la t0, array
        sw t0, 0(sp)
        la t0, array2
        sw t0, 4(sp)
        la t0, array3
        sw t0, 8(sp)
        la s10, array_bf16      # global array_bf16 address(s10)        
        addi s11, x0, 3         # data number(s11) -> three groups data
        la s9, exp_mask         # global exp(s9)
        la s8, man_mask         # global man(s8)
        la s6, bf16_mask        # global bf16(s6)
        lw s9, 0(s9)
        lw s8, 0(s8)
        lw s6, 0(s6)
        add s7, x0, sp
main_for:
        la a0, bf16_string
        addi a7, x0, 4
        ecall         
        addi a3, x0, 7          # array size(a3)
        lw a1, 0(s7)            # array_data pointer(a1)
        mv a2, s10              # array_bf16 pointer(a2)
        jal ra, fp32_to_bf16_findmax
               
        addi s11, s11, -1
        addi s7, s7, 4
        bne s11, x0, main_for
        # Exit program
        li a7, 10
        ecall 
        
fp32_to_bf16_findmax:
# array_data pointer(a1), array_bf16 pointer(a2), array size(a3)
        # prologue
        addi sp, sp, -8
        sw s0, 0(sp)
        sw s1, 4(sp)
        
# array loop
for1:
        lw a5, 0(a1)  # x(a5)
        # fp32_to_bf16
        and t0, a5, s9  # x exp(t0)
        and t1, a5, s8  # x man(t1)
        # if zero        
        bne t0, x0, else
        # exp is zero
        bne t1, x0, else
        j finish_bf16        
else: 
        # if infinity or NaN
        beq t0, s9, finish_bf16                              
        # round        
        # r = x.man shift right 8 bit
        # x+r = x.man + x.man>>8
        li t3, 0x00800000  # make up 1 to No.24bit
        or t1, t1, t3
        srli t2, t1, 8  # r(t2)
        add t1, t1, t2  # x+r
        
        # check carry
        and t4, t1, t3  # check No.24bit (t4), 0:carry, 1: nocarry
        bne t4, x0, no_carry
        add t0, t0, t3  # exp+1
        srli t1 ,t1, 1  # man alignment
no_carry:
        and t0, t0, s9  # mask exp(t0)
        and t1, t1, s8  # mask man(t1)
        or t2, t0, t1  # combine exp & man
        li t3, 0x80000000  # sign mask
        and t3, a5, t3  # x sign
        or a5, t3, t2  # bfloat16(a5) 
        and a5, a5, s6
finish_bf16:
        sw a5, 0(a2)
        
        mv a0, a5
        addi a7, x0, 34
        ecall
        la a0, next_line
        addi a7, x0, 4
        ecall
        
        slti t3, a3, 7  # (a3==7) t3=0, (a3<7) t3=1
        bne t3, x0, compare
        # saved first max
        j max_change
        
compare:
        # compare exp
        blt s0, t0, max_change 
        blt t0, s0, max_not_change
        
        # compare man       
        blt s1, t1, max_change
        blt t1, s1, max_not_change

max_change:
        mv s0, t0  # max exp(s0)
        mv s1, t1  # max man(s1)         
        mv a4, a5  # max bf16(a4)
max_not_change:               
        addi a3, a3, -1
        addi a1, a1, 4
        addi a2, a2, 4
        bne a3, x0, for1
        
        # Absolute
        li t2, 0x7fffffff
        and a4, a4, t2
        
        #print
        la a0, max_string
        addi a7, x0, 4
        ecall
        mv a0, a4
        addi a7, x0, 34
        ecall
     
        # epilogue
        lw s0, 0(sp)
        lw s1, 4(sp)
        addi sp, sp, 8
        jr ra