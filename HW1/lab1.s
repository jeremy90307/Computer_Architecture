.data
    test0: .word 1067030938                            #false
    test1: .word 1067057152                            #true t0=0x3f9a0000
    test2: .word 1075052544                            #true t0=0x40140000
    str: .string "How many '1's are there in BF16 (binary)? ANS : "
.text
.globl main
main:
    lw a0, test2                                      #x=16
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