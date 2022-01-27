



// GENERAL FUNCTIONS START


.data
    startup_codes: .ascii "\x1b[?25l"
    startup_codes_len = . - startup_codes
    cleanup_codes: .ascii "\x1b[?25h"
    cleanup_codes_len = . - cleanup_codes
    reset_graphics_codes: .ascii "\x1b[2J\x1b[H"
    reset_graphics_codes_len = . - reset_graphics_codes

    screen: .ascii "                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               "
    screen_end:
    screen_len = . - screen

    .align 4
    sleep_till_next_frame_timespec_struct:
        .long 0 // seconds
        .long 50000000 // nanoseconds

.text

.macro PRINT
    /* write syscall
    * assumes that r1 and r2 are positionned properly*/
    push {r7}
    mov r0, #1     // stdout
    mov r7, #4     // syscall ID
    swi #0
    pop {r7}
.endm

.macro PRINT_BUFFER, lab:req
    ldr r1, =\lab           // buffer
    ldr r2, =\lab\()_len    // len
    PRINT
.endm

.macro UPDATE_GRAPHICS
    PRINT_BUFFER reset_graphics_codes
    PRINT_BUFFER screen
.endm

write_char_to_buffer:
    // r0 = buffer, r1 = char, r2 = posy, r3 = posx
    // DOES NOT MODIFY ITS PARAMETERS
    push {r4}
    mov r4, #80
    mul r4, r2, r4
    add r4, r4, r3
    strb r1, [r0, r4]
    pop {r4}
    mov pc, lr
    

clear_screen_buffer:
    // Takes no arguments
    ldr r0, =screen
    ldr r1, =screen_end
    mov r2, #0x20 // space
    clear_buffer_set_spaces_while_start:
        strb r2, [r0], #1
        CMP r0, r1
        BNE clear_buffer_set_spaces_while_start
    mov r2, #0xa // adding EOL every 80 chars
    ldr r0, =screen+79
    clear_buffer_add_end_of_line_while_start:
        strb r2, [r0], #80
        cmp r0, r1
        blt clear_buffer_add_end_of_line_while_start
    mov pc, lr

sleep_till_next_frame:
    // Takes no arguments, uses sleep_timespec_struct defined above
    push {r7}
    ldr r0, =sleep_till_next_frame_timespec_struct
    mov r1, #0  // not used for now
    /* nanosleep syscall */
    mov r7, #0xa2 // syscall ID
    swi #0
    pop {r7}
    mov pc, lr

// GENERAL FUNCTIONS END



// SPECIFIC FUNCTIONS START
.data
// lasers {char, posy, vely, posx, velx}
lasers: .skip 1000
lasers_end:
//0x41, 20, -1, 0, 1, 0x42, 0, 1, 70, -1, 0x43, 0, 1, 30, 1
lasers_len = . - lasers
next_laser_addr: .word lasers   // Rotating addr
random_bytes: .skip 4
random_bytes_len = . - random_bytes

.text
update_lasers:
    // Takes no argument
    // Assumes that buffer has been cleared from previous lasers
    // Updates lasers position and writes them to screen buffer
    push {r4, r5, lr}

    ldr r0, =screen
    ldr r4, =lasers
    ldr r5, =next_laser_addr
update_one_laser:
    // Here we update all components of all lasers
    ldrb r1, [r4], #1   // loading char
    ldrb r2, [r4], #2   // loading posy
    ldrb r3, [r4], #2   // loading posx
    
    cmp r2, #25          // verifying value
    bge update_next_laser
    cmp r2, #0
    blt update_next_laser

    cmp r3, #80          // verifying value
    bge update_next_laser
    cmp r3, #0
    blt update_next_laser

    // r0,r1,r2 and r3 are all already properly positionned
    // We are assured that write_char_to_buffer doesn't modify it's parameter
    // (by the function's doc)
    bl write_char_to_buffer 

    // Updating pos
    ldrb r1, [r4, #-3]  // loading vely
    add r2, r2, r1      // calculating new posy
    strb r2, [r4, #-4]  // storing it
    
    ldrb r1, [r4, #-1]  // loading velx
    add r3, r3, r1      // calculating new posx
    strb r3, [r4, #-2]  // storing it
update_next_laser:
    cmp r4, r5
    bne update_one_laser
    pop {r4, r5, pc}


add_random_laser:
    // Takes no arguments
    push {r4, r5, r6, r7}

    ldr r3, =next_laser_addr
    ldr r3, [r3]
    add r3, r3, #10

    mov r5, #0x41
    strb r5, [r3], #1

    // Starting position calculation:
    // We need 2 random bits (4 combinations) to determine the side on which the lasers will spawn
    // We need 5 or 7 random bits (32 or 128 combinations) for the other component (the first 2 random bits
    // determine a component to be 0)
    // We then need to set the velocity (for now it'll be calculated based on starting position)
    // RIGHT NOW THE laserS WILL ONLY SPAWN FROM THE TOP OR BOTTOM (to simplify)

    ldr r0, =random_bytes
    ldr r1, =random_bytes_len
    mov r2, #0
    mov r7, #0x180     // syscall ID
    swi #0
    // r0 IS OVERWRITTEN BY size_t RETURN PARAMETER
    // TODO: handle case where we didn't received enough random bytes
    ldr r0, =random_bytes
    
    ldrb r5, [r0], #1

/*
    push {r0, r2, r7}
    mov r0, #1     // stdout
    add r1, r5, #0x30
    push {r1}
    mov r1, sp
    mov r2, #1
    mov r7, #4     // syscall ID
    swi #0
    pop {r1}
    pop {r0, r2, r7}
*/
    TST r5, #0b1
    // r5 = startpos.y, r6 = velocity.y
    moveq r5, #0
    moveq r6, #1
    movne r5, #24
    ldrne r6, =-1
    strb r5, [r3], #1
    strb r6, [r3], #1

    // loading the next random byte
    ldrb r5, [r0], #1
    mov r5, r5, LSR #2      // only using 6 bits so we only have 2^6=64 combinations
    add r5, r5, #(80-64)/2  // centering startpos.x
    strb r5, [r3], #1
    TST r5, #0b1000000      // Using the seventh random bit to determine velocity.x
    moveq r5, #1
    ldrne r5, =-1
    strb r5, [r3], #1
    
    ldr r4, =lasers_end
    cmp r3, r4          // if next_laser_addr is at the end of the lasers array
    ldrge r3, =lasers   // move it back to the beginning (r3 = r4+1 because we post index it)
    // Storing new next address
    ldr r4, =next_laser_addr
    str r3, [r4]

    pop {r4, r5, r6, r7}
    mov pc, lr


// SPECIFIC FUNCTIONS END



.text
.global _start
_start:
    PRINT_BUFFER startup_codes
    UPDATE_GRAPHICS

    mov r4, #100
    ldr r5, =screen
main_while_start:
    bl add_random_laser
    bl update_lasers
    UPDATE_GRAPHICS
    bl clear_screen_buffer
    bl sleep_till_next_frame
    cmp r4, #0
    sub r4, r4, #1
    bgt main_while_start

    PRINT_BUFFER cleanup_codes

    /* exit syscall */
    mov r0, #0 // status
    mov r7, #1 // syscall ID
    swi #0
