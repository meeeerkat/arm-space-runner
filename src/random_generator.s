

.global get_random_number
.global get_random_number_between

/*
 *  Random generator helper
 *  Uses getrandom syscall to get randomness
 *  and converts the raw byte results into random elements
 *  
 *  Right now the only function we're interested in is get_random_number
 */


.data
    /* only 256 bytes long because we are certain that getrandom returns that much
     * TODO: using a larger random_buffer would reduce the number of calls to
     * getrandom and improve performance but we would need to store the actual
     * number of bytes returned by getrandom
     */
    random_buffer: .skip 256
    random_buffer_end:
    random_buffer_len = . - random_buffer
    random_buffer_current: .word random_buffer_end



.text


/*
 *  Private helper for the module
 *  Gets r0 random bits in r0 and refills the random_buffer
 *  with a call to getrandom if needed and resetting attributes
 */
get_bits:
    push {r4, r7}

    mov r3, r0 // r3 = random bits nb to get

    ldr r4, =random_buffer_current
    ldr r0, [r4]    // r0 is the current random_buffer
    ldr r1, =random_buffer_end
    add r2, r0, r3
    cmp r2, r1
    blt get_bits_jump_refill
    
    // Refilling random_buffer & resetting attributes

     /* getrandom syscall */
    ldr r0, =random_buffer
    ldr r1, =random_buffer_len
    mov r2, #0
    mov r7, #0x180     // syscall ID
    swi #0
    
    // r0 is overwritten by getrandom call
    // need to re set it
    ldr r0, =random_buffer

get_bits_jump_refill:
    // in any case, r0 is the current random_buffer
    // and r4 is random_buffer_current (pointing to current random_buffer = r0)
    ldr r1, [r0], r3    // loading result
    str r0, [r4]        // updating random_buffer_current
    rsb r3, r3, #32
    lsr r0, r1, r3      // shifting result to get only the needed bits
    pop {r4, r7}
    mov pc, lr


/*
 *  Returns a random number that is: 0 <= return < param
 *  assumes param > 0
 *  param & return are r0
 */
get_random_number:
    push {r4, r5, lr}

    // using r4 & r5 because they wont be overriden by get_bits
    mov r5, r0      // r5 = param

    clz r4, r5      // r4 = param's leading zeroes nb
    rsb r4, r4, #32 // r4 = param's position of first 1 (max power of 2)
    
    // We hence need to take r4 bits from buffer to generate the number
get_random_number_while_start:
    mov r0, r4  // set param every time because r0 is overriden by get_bits
    bl get_bits    // r0 is already properly positionned
    cmp r0, r5  // while the number we got is higher than the param
    bge get_random_number_while_start   // we get another one

    // r0 is already the right return value

    pop {r4, r5, pc}


/*
 *  Returns a random number that is: param0 <= return < param1
 *  assumes params > 0
 *  param0 is r0, param1 is r1
 *  return is r0
 */
get_random_number_between:
    push {r4, lr}

    mov r4, r0      // r4 = param0
    sub r0, r1, r0  // base is now zero, r0 = max
    bl get_random_number
    add r0, r0, r4  // we add param0 to offset this number

    pop {r4, pc}
