

.include "src/globals.s"

.global sleep_till_next_frame


/*
 * Time management
 */

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
