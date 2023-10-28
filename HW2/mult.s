.data
test1: .word 0x42000000
test2: .word 0x40860000
.text
Multi_bfloat:
# decoder function input is a0
# jal ra,decoder        # load a0(two bloat number in one register) to t0
# decoder function output is s5,s6
        lw s5,test1
        lw s6,test2
        add t0,s5,x0          # store s5(bfloat 2) to t0
        add t1,s6,x0          # store s6(bfloat 1) to t1
        li t6,0x7F800000      # mask 0x7F800000
        # get exponent to t2,t3
        and t3,t0,t6          # use mask 0x7F800000 to get t0 exponent
        and t2,t1,t6          # use mask 0x7F800000 to get t1 exponent
        add t3,t3,t2          # add two exponent to t3
        li t6,0x3F800000      # mask 0x3F800000
        sub t3,t3,t6          # sub 127 to exponent

        # get sign
        xor t2,t0,t1          # get sign and store on t2
        srli t2,t2,31         # get rid of useless data
        slli t2,t2,31         # let sign back to right position
    
        # get sign and exponent together
        or t3,t3,t2
        # set the sign and exponent to t0
        slli t0,t0,9
        srli t0,t0,9
        or t0,t3,t0

        # get fraction to t2 and t3
        li t6,0x7F            # mask 0x7F
        slli t6,t6,16         # shift mask to 0x7F0000
        and t2,t0,t6          # use mask 0x7F0000 get fraction
        and t3,t1,t6          # use mask 0x7F0000 get fraction
        slli t2,t2,9          # shift left let no leading 0
        srli t2,t2,1          # shift right let leading has one 0
        li t6,80000000        # mask 80000000
        or t2,t2,t6           # use mask 0x80000000 to add integer
        srli t2,t2,1          # shift right to add space for overflow

        slli t3,t3,8          # shift left let no leading 0
        or t3,t3,t6           # use mask 0x80000000 to add integer
        srli t3,t3,1          # shift right to add space for overflow

        add s11,x0,x0         # set a counter and 0
        addi s10,x0,8         # set a end condition
        add t1,x0,x0          # reset t1 to 0 and let this register be result
        li t6,0x80000000      # mask 0x80000000

loop:
        addi s11,s11,1        # add 1 at counter every loop
        srli t6,t6,1          # shift right at 1 every loop
    
        and t4,t2,t6          # use mask to specified number at that place
        beq t4,x0,not_add     # jump if t4 equal to 0
        add t1,t1,t3          # add t3 to t1
not_add:
        srli t3,t3,1          # shift left 1 bit to t3
        bne s11,s10,loop      # if the condition not satisfy return to loop
# end of loop 
  
        # check if overflow
        li t6,0x80000000
        and t4,t1,t6          # get t1 max bit
    
        # if t4 max bit equal to 0 will not overflow
        beq t4,x0,not_overflow
    
        # if overflow
        slli t1,t1,1          # shift left 1 bits to remove integer
        li t6,0x800000        # mask 0x800000
        add t0,t0,t6          # exponent add 1 if overflow
        j Mult_end            # jump to Mult_end
     
        # if not overflow
not_overflow:
        slli t1,t1,2          # shift left 2 bits to remove integer
Mult_end:
        srli t1,t1,24         # shift right to remove useless bits
        addi t1,t1,1          # add 1 little bit to check if carry
        srli t1,t1,1          # shift right to remove useless bits
        slli t1,t1,16         # shift left to let fraction be right position
    
        srli t0,t0,23         # shift right to remove useless bits
        slli t0,t0,23         # shift left to let sign and exponent be right position
        or t0,t0,t1           # combine t0 and t1 together to get bfloat

        add s3,t0,x0          # store bfloat after multiplication to  s3
        #ret                   # return to main
### end of function
exit:
        mv a0,s3
        li a7,2
        ecall