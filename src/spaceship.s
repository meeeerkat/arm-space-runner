

.global spaceship_init
.global spaceship_tick
.global spaceship_handle_input
.global spaceship_check_game_over


/*
 * Spaceship management
 */

.data
    .equ ascii_left_key, 0x61   // a
    .equ ascii_right_key, 0x64  // d
    .equ ascii_right_keyown_key, 0x73   // s
    .equ ascii_up_key, 0x77     // w

    last_input: .byte 0

    .equ spaceship_char, 0x40
    spaceship_pos: .byte screen_height/2, screen_width/2

    next_move_spaceship_tick_nb: .word 0
    .equ move_spaceship_tick_delta, 5

.text

spaceship_init:
    push {lr}
    ldr r0, =spaceship_pos
    bl write_spaceship_to_screen
    pop {pc}

spaceship_tick:
    push {lr}
    bl move
    ldr r0, =spaceship_pos
    bl write_spaceship_to_screen
    pop {pc}



write_spaceship_to_screen:
    push {lr}
    // r0 = spaceship_pos buffer
    ldrb r2, [r0]
    ldrb r3, [r0, #1]
    ldr r0, =screen
    mov r1, #spaceship_char
    bl write_char_to_buffer

    pop {pc}
    

spaceship_handle_input:
    // r0 = character
    // out: r0 = (consumed) ? 0 : r0
    cmp r0, #ascii_up_key
    beq 1f
    cmp r0, #ascii_right_keyown_key
    beq 1f
    cmp r0, #ascii_right_key
    beq 1f
    cmp r0, #ascii_left_key
    beq 1f
    mov pc, lr // input key isn't used for spaceship control
1:
    // if the input is a valid key
    ldr r1, =last_input
    strb r0, [r1]
    mov r0, #0 // consuming character
    mov pc, lr

move:
    // Are we moving the spaceship this tick ?
    ldr r1, =next_move_spaceship_tick_nb
    TICK_CHECK_AND_UPDATE_OR_RETURN r0, r1, r2, #move_spaceship_tick_delta

    push {r7}

    // Loading the last input
    ldr r1, =last_input
    ldrb r1, [r1]

    // if there was no user spaceship related player input for this tick
    // to disable if wanted behavior is the ship always moving (as it becomes useless)
    cmp r1, #0
    beq move_end // we go directly to the end (no need to check every key or to update anything)

    // Loading spaceship_pos
    ldr r0, =spaceship_pos
    ldrb r2, [r0]
    ldrb r3, [r0, #1]
    // r2 = spaceship_pos.y, r3 = spaceship_pos.x
 
    // Updating r2, r3
    cmp r1, #ascii_up_key
    bne move_s
    cmp r2, #0
    beq move_end
    sub r2, r2, #1
    b move_save_newpos
move_s:
    cmp r1, #ascii_right_keyown_key
    bne move_d
    cmp r2, #screen_height-1
    beq move_end
    add r2, r2, #1
    b move_save_newpos
move_d:
    cmp r1, #ascii_right_key
    bne move_a
    cmp r3, #screen_width-1
    beq move_end
    add r3, r3, #1
    b move_save_newpos
move_a:
    cmp r1, #ascii_left_key
    bne move_end
    cmp r3, #0
    beq move_end
    sub r3, r3, #1

move_save_newpos:
    // saving new spaceship_pos
    strb r2, [r0]
    strb r3, [r0, #1]

    // Resetting last_input
    // this can be ommited if wanted behavior is to always have a ship that moves
    mov r0, #0
    ldr r1, =last_input
    strb r0, [r1]

move_end:
    pop {r7}
    mov pc, lr


spaceship_check_game_over:
    push {lr}
    // r0 = spaceship_pos buffer

    // Loading spaceship_pos
    ldr r0, =spaceship_pos
    ldrb r1, [r0]
    ldrb r2, [r0, #1]
 
    ldr r0, =screen
    bl get_char_from_buffer
    // r0 = buffer char

    // if r0 isn't the spaceship, it was overwritten by a laser
    cmp r0, #spaceship_char
    popne {lr} // restoring lr in lr to keep a valid stack
    blne main_game_over // game over

    pop {pc}
