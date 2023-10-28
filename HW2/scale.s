.data
maxbf16: .word 0x40b40000
.text
main:
        lw a4, maxbf16
        li t6, 0x007FFFFF
        
quant_bf16_to_int8:
        li s2, 0x7F    #127 to hex
        
        and t0, a4, t6 #max_man->t0 maxbf16->a4
        srli t0, t0, 15
        srli t1, a4, 23 #max_exp
        addi t1, t1, -127 #Denominator-> power of exp <- t1
        li t4, 7
        sub t3, t4, t1
        srl t0, t0, t3
        li t5, 1
        sll t5, t5, t1 #1<<t1
        or t0, t5, t5  #10^(t1) + fraction
        li s3, 0 
scale:
        add s4, s4, t0
        addi s3, s3, 1 #count scale
        bge s2, s4, scale
exit:
        mv a0, s3
        li a7, 1
        ecall