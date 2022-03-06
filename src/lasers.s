

.global lasers_init
.global lasers_tick


/*
 * Lasers management
 */

.data
    /* laser {
     * .word next_update_tick_nb,
     * .byte update_tick_delta,
     * .byte posy,
     * .byte posx,
     * .byte offsety,
     * .byte offsetx,
     * .byte char
     * };
     *
     * sizeof(laser) = 4+1+1+4*1 = 10 bytes
     *
     * ex:  0, 10, 0x41, 20, -1, 0, 1,
     *      0, 5, 0x42, 0, 1, 70, -1, 
     *      0, 8, 0x43, 0, 1, 30, 1
     */
    .align 4
    lasers: .skip 10*1000
    lasers_end:
    lasers_len = . - lasers
    next_laser_addr: .word lasers   // Rotating addr

    next_add_laser_tick_nb: .word 0
    .equ add_laser_tick_delta, 5
    .equ update_laser_tick_delta_min, 10
    .equ update_laser_tick_delta_max, 12

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
    ldrb r1, [r4, #9]   // loading char
    ldrb r2, [r4, #5]   // loading posy
    ldrb r3, [r4, #6]   // loading posx
    
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
    ldrsb r1, [r4, #7]   // loading offsety
    add r2, r2, r1      // calculating new posy
    strb r2, [r4, #5]   // storing new posy

    ldrsb r1, [r4, #8]   // loading offsetx
    add r3, r3, r1      // calculating new posx
    strb r3, [r4, #6]   // storing new posx

update_next_laser:
    add r4, r4, #10
    cmp r4, r5
    bne update_one_laser
    pop {r4, r5, r6, r7, pc}




// Used only in add_random_laser
// to factor set_random_laser_vertical and set_random_laser_horizontal
.macro SET_START_POS_AND_OFFSET, max_first_comp_pos:req, max_second_comp_pos:req, first_comp_addr_offset:req, second_comp_addr_offset:req
    moveq r0, #0
    moveq r1, #1
    movne r0, #\max_first_comp_pos-1
    ldrne r1, =-1
    strb r0, [r4, #\first_comp_addr_offset]
    strb r1, [r4, #\first_comp_addr_offset+2]

    // setting random second_comp_pos & second_comp_offset
    mov r0, #\max_second_comp_pos
    bl get_random_number
    // 0 <= r0 < max_second_comp_pos & random
    strb r0, [r4, #\second_comp_addr_offset]
    mov r0, #3
    bl get_random_number
    cmp r0, #2      // r0 = {0,1} -> offset = r0
    ldreq r0, =-1   // r0 = 2 -> offset = -1
    strb r0, [r4, #\second_comp_addr_offset+2]
.endm

add_random_laser:
    // r0 = current_tick_nb
    
    // Are we adding a laser this tick ?
    // Doesn't modify r0
    ldr r1, =next_add_laser_tick_nb
    TICK_CHECK_AND_UPDATE_OR_RETURN r0, r1, r2, #add_laser_tick_delta

    // Actual laser adding
    push {r4, lr}

    // Loading next_laser in r4 because it's not modified by get_random functions
    ldr r4, =next_laser_addr
    ldr r4, [r4]

    // storing tick related data
    str r0, [r4], #4 // current tick is the base one

    // getting random update_tick_delta: min <= update_tick_delta < max
    mov r0, #update_laser_tick_delta_min
    mov r1, #update_laser_tick_delta_max
    bl get_random_number_between
    strb r0, [r4], #1 // saving it

    mov r0, #2
    bl get_random_bits
    TST r0, #0b1        // first r0 bit = 1 => vertical, else horizontal
    bne set_random_laser_horizontal

    // here first r0 bit = 1
    TST r0, #0b11   // determining startpos.y with r0's second bit
    SET_START_POS_AND_OFFSET screen_height, screen_width, 0, 1
    b random_laser_set_char

set_random_laser_horizontal:
    // here first r0 bit = 0
    TST r0, #0b10       // second r0 bit = 
    SET_START_POS_AND_OFFSET screen_width, screen_height, 1, 0

random_laser_set_char:
    // SET_START_POS_AND_OFFSET doesn't modify r4 so it's done here
    add r4, r4, #2      // jumping pos
    ldrsb r0, [r4], #1   // loading offsets
    ldrsb r1, [r4], #1
    // This could be called at every update_laser but storing it at creation is more efficient
    bl calculate_char_from_offset
    strb r0, [r4], #1   // storing char

    ldr r0, =lasers_end
    cmp r4, r0              // if next_laser_addr is at the end of the lasers array
    ldrge r4, =lasers       // move it back to the beginning (r4 = r4+1 because we post index it)
    // Storing new next address
    ldr r0, =next_laser_addr
    str r4, [r0]

    pop {r4, pc}


// Takes r0 = offsety, r1 = offsetx as argument
// Returns r0 = char
calculate_char_from_offset:
    cmp r1, #0
    bgt calculate_char_from_offset_going_right
    blt calculate_char_from_offset_going_left
    // if offsetx == 0 we return '|' immediatly
    mov r0, #0x7c   // = '|', going down
    mov pc, lr

calculate_char_from_offset_going_right:
    cmp r0, #0
    movgt r0, #0x5c // = '\', going right-down
    movlt r0, #0x2f // = '/', going right-up
    moveq r0, #0x2d // = '-', going right
    mov pc, lr
calculate_char_from_offset_going_left:
    cmp r0, #0
    movgt r0, #0x2f // = '/', going left-down
    movlt r0, #0x5c // = '\', going left-up
    moveq r0, #0x2d // = '-', going left
    mov pc, lr
