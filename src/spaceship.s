

.include "src/global_constants.s"

.global spaceship_init
.global spaceship_tick


/*
 * Spaceship management
 */

.data
    input_buffer: .skip 1
    .equ spaceship_char, 0x40
    spaceship_pos: .byte screen_height/2, screen_width/2

    .equ ascii_a, 0x61
    .equ ascii_d, 0x64
    .equ ascii_s, 0x73
    .equ ascii_w, 0x77


.text

spaceship_init:
    push {lr}
    ldr r0, =spaceship_pos
    bl write_spaceship_to_screen
    pop {pc}

spaceship_tick:
    push {lr}
    bl handle_input
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

