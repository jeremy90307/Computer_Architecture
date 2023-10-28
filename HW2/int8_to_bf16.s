int_to_floatpoint:
        addi sp, sp, -16
        sw s2, 0(sp)
        sw s3, 4(sp)
        sw s4, 8(sp)
        sw s5, 12(sp)
        li t0, 0
        mv s2, a6
loop2:
        
        srli a6, a6, 1
        
        addi t0, t0, 1 
        blt x0, a6, loop2
###end loop2
        addi t0, t0, -1 # count shift right num
        
        addi s3, t0, 127 # exp_num
        # Why not +127? Because the shift count is one extra.
        slli s3, s3, 23 # exp in bf16 -> s3
        
        li t1, 0xFFFFFFFF
        li t2, 32
        sub t3, t2, t0
        srl t1, t1, t3
        and s4, s2, t1 # frac_num in bf16
        li t1, 23
        sub t1, t1, t0 # t1=23-(count shift right num)
        sll s4, s4, t1 # frac in bf16
        or s5, s4, s3 # int->bf16 ok
        mv a6, s5 
        
        
        la a0,next_line
        li a7,4
        ecall
        
        mv a0, a6
        li a7, 34
        ecall
        
        lw s2, 0(sp)
        lw s3, 4(sp)
        lw s4, 8(sp)
        lw s5, 12(sp)
        addi sp, sp, 16