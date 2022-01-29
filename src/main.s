

.include "src/global_constants.s"


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
m_while_start:
    mov r0, r4
    bl spaceship_tick
    mov r0, r4
    bl lasers_tick
    mov r0, r4
    bl view_tick
    bl sleep_till_next_frame

    add r4, r4, #1
    cmp r4, #1000
    blt m_while_start

    bl view_destroy

    /* exit syscall */
    mov r0, #0 // status
    mov r7, #1 // syscall ID
    swi #0

