

.include "global_constants.s"

.global lasers_init
.global lasers_tick


/*
 * Lasers management
 */

.data
    /* laser {
     * .word next_update_tick_nb,
     * .byte update_tick_delta,
     * .byte char,
     * .byte posy,
     * .byte posx,
     * .byte offsety,
     * .byte offsetx
     * };
     *
     * sizeof(laser) = 4+1+1+4*1 = 10 bytes
     *
     * ex:  0, 10, 0x41, 20, -1, 0, 1,
     *      0, 5, 0x42, 0, 1, 70, -1, 
     *      0, 8, 0x43, 0, 1, 30, 1
     */
    .align 4
    lasers: .skip 1000
    lasers_end:
    lasers_len = . - lasers
    next_laser_addr: .word lasers   // Rotating addr
    random_bytes: .skip 4
    random_bytes_len = . - random_bytes

    last_add_laser_tick_nb: .word 0
    .equ add_laser_tick_delta, 4
    .equ update_laser_tick_delta, 4

.text

lasers_init:
    mov pc, lr

lasers_tick:
    push {lr}
    mov r4, r0 // saving r0 = current_tick_nb
    // add_random_laser called before update_lasers so the new laser gets updated this tick
    bl add_random_laser
    mov r0, r4 // so it can be used in update_lasers too
    bl update_lasers
    pop {pc}



update_lasers:
    /* Takes r0 = current_tick_nb
     * Assumes that buffer has been cleared from previous lasers
     * Updates lasers position and writes them to screen buffer
     */
    push {r4, r5, r6, r7, lr}

    mov r6, r0 // r6 = current tick nb

    ldr r0, =screen
    ldr r4, =lasers
    ldr r5, =next_laser_addr
update_one_laser:
    // Here we load all components of a laser
    ldrb r1, [r4, #5]   // loading char
    ldrb r2, [r4, #6]   // loading posy
    ldrb r3, [r4, #7]   // loading posx
    
    // Checking if it's not out of view
    // if it is, it's not displayed nor updated
    cmp r2, #screen_height  // verifying value
    bge update_next_laser
    cmp r2, #0
    blt update_next_laser

    cmp r3, #screen_width   // verifying value
    bge update_next_laser
    cmp r3, #0
    blt update_next_laser

    // r0,r1,r2 and r3 are all already properly positionned
    // We are assured that write_char_to_buffer doesn't modify it's parameter
    // (by the function's doc)
    bl write_char_to_buffer 

    // Checking if we need to update this laser this tick
    ldr r1, [r4]    // loading next_update_tick_nb
    // if it's not the right tick
    cmp r1, r6
    bne update_next_laser

    // If we get here we're updating this laser
    
    // Updating next_update_tick_nb
    ldrb r7, [r4, #4]   // loading update_tick_delta
    add r1, r1, r7
    str r1, [r4]        // updating next_update_tick_nb

    // Updating pos
    ldrb r1, [r4, #8]   // loading offsety
    add r2, r2, r1      // calculating new posy
    strb r2, [r4, #6]   // storing new posy

    ldrb r1, [r4, #9]   // loading offsetx
    add r3, r3, r1      // calculating new posx
    strb r3, [r4, #7]   // storing new posx


update_next_laser:
    add r4, r4, #10
    cmp r4, r5
    bne update_one_laser
    pop {r4, r5, r6, r7, pc}




add_random_laser:
    // r0 = current_tick_nb
    
    // Are we adding a laser this tick ?
    ldr r1, =last_add_laser_tick_nb
    ldr r2, [r1]
    add r2, r2, #add_laser_tick_delta
    cmp r0, r2
    movne pc, lr // if not, return
    // update last_add_laser_tick_nb
    str r2, [r1]

    // actual laser adding
    push {r4, r5, r6, r7}

    ldr r3, =next_laser_addr
    ldr r3, [r3]

    // storing tick related data
    str r0, [r3], #4 // current tick is the base one
    mov r0, #update_laser_tick_delta
    strb r0, [r3], #1 // TODO: set random tick base

    // storing char
    mov r5, #0x41
    strb r5, [r3], #1

    // Starting position calculation:
    // We need 2 random bits (4 combinations) to determine the side on which the lasers will spawn
    // We need 5 or 7 random bits (32 or 128 combinations) for the other component (the first 2 random bits
    // determine a component to be 0)
    // We then need to set the velocity (for now it'll be calculated based on starting position)
    // RIGHT NOW THE laserS WILL ONLY SPAWN FROM THE TOP OR BOTTOM (to simplify)

    /* getrandom syscall */
    ldr r0, =random_bytes
    ldr r1, =random_bytes_len
    mov r2, #0
    mov r7, #0x180     // syscall ID
    swi #0
    // r0 IS OVERWRITTEN BY size_t RETURN PARAMETER
    // TODO: handle case where we didn't received enough random bytes
    ldr r0, =random_bytes
    
    ldrb r5, [r0], #1   // loading first random byte in r5
    TST r5, #0b1        // determining startpos.y with the first bit
    // r5 = startpos.y, r6 = velocity.y
    moveq r5, #0
    moveq r6, #1
    movne r5, #24
    ldrne r6, =-1
    strb r5, [r3], #2
    strb r6, [r3], #-1

    ldrb r5, [r0], #2       // loading the next random byte
    mov r5, r5, LSR #2      // only using 6 bits so we only have 2^6=64 combinations
    add r5, r5, #(screen_width-64)/2  // centering startpos.x
    strb r5, [r3], #2
    TST r5, #0b1000000      // using the seventh random bit to determine velocity.x
    moveq r5, #1
    ldrne r5, =-1
    strb r5, [r3], #1
    
    ldr r4, =lasers_end
    cmp r3, r4              // if next_laser_addr is at the end of the lasers array
    ldrge r3, =lasers       // move it back to the beginning (r3 = r4+1 because we post index it)
    // Storing new next address
    ldr r4, =next_laser_addr
    str r3, [r4]

    pop {r4, r5, r6, r7}
    mov pc, lr

