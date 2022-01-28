

.include "screen_management.S"


// SLEEP START
.data
    .equ time_delta, 50000000 // in nanoseconds
    sleep_till_next_frame_timespec_struct:
        .long 0 // seconds
        .long time_delta // nanoseconds
.text

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

// SLEEP END




// SPECIFIC FUNCTIONS START
.data
    // lasers {char, posy, vely, posx, velx}
    // ex: ex:  0x41, 20, -1, 0, 1, 0x42, 0, 1, 70, -1, 0x43, 0, 1, 30, 1
    lasers: .skip 1000
    lasers_end:
    lasers_len = . - lasers
    next_laser_addr: .word lasers   // Rotating addr
    random_bytes: .skip 4
    random_bytes_len = . - random_bytes

    input_buffer: .skip 1
    .equ spaceship_char, 0x40
    spaceship_pos: .byte screen_height/2, screen_width/2

    .equ ascii_a, 0x61
    .equ ascii_d, 0x64
    .equ ascii_s, 0x73
    .equ ascii_w, 0x77


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
    strb r5, [r3], #1
    strb r6, [r3], #1

    ldrb r5, [r0], #1       // loading the next random byte
    mov r5, r5, LSR #2      // only using 6 bits so we only have 2^6=64 combinations
    add r5, r5, #(screen_width-64)/2  // centering startpos.x
    strb r5, [r3], #1
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

write_spaceship_to_screen:
    push {lr}
    // r0 = spaceship_pos buffer
    ldrb r2, [r0]
    ldrb r3, [r0, #1]
    ldr r0, =screen
    mov r1, #spaceship_char
    bl write_char_to_buffer

    pop {pc}
    

handle_input:
    push {r7}
    /* read syscall */
    mov r0, #1              // stdin
    ldr r1, =input_buffer   // buffer
    mov r2, #1              // reading char by char
    mov r7, #0x3            // syscall ID
    swi #0

    // checking we actually read something
    cmp r0, #0
    blt handle_input_end
    
    // actual input hanling
    // loading spaceship_pos
    ldr r0, =spaceship_pos
    ldrb r2, [r0]
    ldrb r3, [r0, #1]
    // r2 = spaceship_pos.y, r3 = spaceship_pos.x
    // updating r2, r3
    ldrb r1, [r1]

    cmp r1, #ascii_w
    bne handle_input_s
    cmp r2, #0
    beq handle_input_end
    sub r2, r2, #1
    b handle_input_save_newpos
handle_input_s:
    cmp r1, #ascii_s
    bne handle_input_d
    cmp r2, #screen_height-1
    beq handle_input_end
    add r2, r2, #1
    b handle_input_save_newpos
handle_input_d:
    cmp r1, #ascii_d
    bne handle_input_a
    cmp r3, #screen_width-1
    beq handle_input_end
    add r3, r3, #1
    b handle_input_save_newpos
handle_input_a:
    cmp r1, #ascii_a
    bne handle_input_end
    cmp r3, #1                  // WHY 1 AND NOT 0 ??? (doesnt work with 0 but why)
    beq handle_input_end
    sub r3, r3, #1

handle_input_save_newpos:
    // saving new spaceship_pos
    strb r2, [r0]
    strb r3, [r0, #1]

handle_input_end:
    pop {r7}
    mov pc, lr

// SPECIFIC FUNCTIONS END



.text
.global _start
_start:
    PRINT_BUFFER startup_codes
    PRINT_BUFFER reset_graphics_codes
    NONCANONICAL_MODE_START
    CONFIGURE_NON_BLOCKING_INPUT

    bl clear_screen_buffer

    ldr r0, =spaceship_pos
    bl write_spaceship_to_screen

    mov r4, #1000
    ldr r5, =screen
main_while_start:
    bl handle_input
    ldr r0, =spaceship_pos
    bl write_spaceship_to_screen
    bl add_random_laser
    bl update_lasers
    UPDATE_GRAPHICS
    bl clear_screen_buffer
    bl sleep_till_next_frame
    cmp r4, #0
    sub r4, r4, #1
    bgt main_while_start
    
    NONCANONICAL_MODE_END
    PRINT_BUFFER reset_graphics_codes
    PRINT_BUFFER cleanup_codes

    /* exit syscall */
    mov r0, #0 // status
    mov r7, #1 // syscall ID
    swi #0

