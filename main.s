

.include "screen.s"
.include "lasers.s"
.include "spaceship.s"


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

