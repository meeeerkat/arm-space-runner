

/*
 *  Simple random generator test
 *  Prints a random number 0 <= n < 10
 *
 *  TODO:   test larger numbers, more cases & do that automatically ?
 *          testing randomness automatically seems complicated
 */



.data
    str: .ascii "_"

.text
.global _start


print_r0_as_digit:
    add r0, r0, #0x30
    ldr r1, =str
    strb r0, [r1]
    mov r0, #1     // stdout
    mov r2, #1
    mov r7, #4     // syscall ID
    swi #0
    mov pc, lr



_start:
    mov r0, #10
    bl get_random_number
    bl print_r0_as_digit 

    mov r0, #5
    mov r1, #10
    bl get_random_number_between
    bl print_r0_as_digit 
    
    /* exit syscall */
    mov r0, #0 // status
    mov r7, #1 // syscall ID
    swi #0

