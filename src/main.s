

.include "src/globals.s"

.global main_quit
.global main_game_over


/*
 * Main
 */

.text
.global _start

_start:
    bl view_init
    bl lasers_init
    bl spaceship_init

// r4 = tick counter
mov r4, #0
main_while_start:
    bl handle_input

    // tick functions take r0=tick_nb ad parameter
    mov r0, r4
    bl spaceship_tick
    mov r0, r4
    bl lasers_tick
    mov r0, r4
    bl view_tick

    // Checking game over before calling view_clear_buffer because it clears the buffer
    mov r0, r4
    bl spaceship_check_game_over

    bl view_clear_buffer

    bl sleep_till_next_frame
    add r4, r4, #1
    b main_while_start

main_game_over:
    bl view_game_over
    bl sleep_game_over
    
main_quit:
    bl view_destroy

    /* exit syscall */
    mov r0, #0 // status
    mov r7, #1 // syscall ID
    swi #0

