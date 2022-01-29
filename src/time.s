

.global sleep_till_next_frame
.global sleep_game_over


/*
 * Time management
 */

.data
    .equ time_delta, 10000000 // in nanoseconds
    sleep_till_next_frame_timespec_struct:
        .long 0 // seconds
        .long time_delta // nanoseconds

    sleep_game_over_timespec_struct:
        .long 2 // seconds
        .long 0 // nanoseconds

.text


.macro SLEEP_TILL, timespec_struct_label:req
    // Takes no arguments, uses sleep_timespec_struct defined above
    push {r7}
    ldr r0, =\timespec_struct_label
    mov r1, #0  // not used for now
    /* nanosleep syscall */
    mov r7, #0xa2 // syscall ID
    swi #0
    pop {r7}
    mov pc, lr
.endm

sleep_till_next_frame:
    SLEEP_TILL sleep_till_next_frame_timespec_struct

sleep_game_over:
    SLEEP_TILL sleep_game_over_timespec_struct
