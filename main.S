





.data
    startup_codes: .ascii "\x1b[?25l"
    startup_codes_len = . - startup_codes
    cleanup_codes: .ascii "\x1b[?25h"
    cleanup_codes_len = . - cleanup_codes
    reset_graphics_codes: .ascii "\x1b[2J\x1b[H"
    reset_graphics_codes_len = . - reset_graphics_codes

    screen: .ascii "                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               "
    screen_len = . - screen

    .align 4
    sleep_till_next_frame_timespec_struct:
        .long 0 // 1 second
        .long 30000000 // 0 nanoseconds

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
    push {r2}
    ldr r1, =\lab           // buffer
    ldr r2, =\lab\()_len    // len
    PRINT
    pop {r2}
    .endm

    .macro UPDATE_GRAPHICS
    PRINT_BUFFER reset_graphics_codes
    PRINT_BUFFER screen
    .endm

write_char_to_buffer:
    // r2 = buffer, r4 = char, r5 = posy, r6 = posx
    mov r0, #80
    mul r0, r5, r0
    add r0, r0, r6
    str r4, [r2, r0]
    mov pc, lr
    

clear_buffer:
    // r2 = buffer, r3 = buffer length
    push {r2}
    mov r0, #0x20 // space
    add r1, r2, r3
    clear_buffer_set_spaces_while_start:
        strb r0, [r2], #1
        CMP r2, r1
        BNE clear_buffer_set_spaces_while_start
    mov r0, #0xa // adding EOL every 80 chars
    ldr r2, =screen+79
    clear_buffer_add_end_of_line_while_start:
        strb r0, [r2], #80
        cmp r2, r1
        blt clear_buffer_add_end_of_line_while_start
    pop {r2}
    mov pc, lr

sleep_till_next_frame:
    // No arguments, uses sleep_timespec_struct defined above
    push {r7}
    ldr r0, =sleep_till_next_frame_timespec_struct
    mov r1, #0  // not used for now
    /* nanosleep syscall */
    mov r7, #0xa2 // syscall ID
    swi #0
    pop {r7}
    mov pc, lr

.global _start
_start:
    PRINT_BUFFER startup_codes
    UPDATE_GRAPHICS

    ldr r2, =screen
    ldr r3, =screen_len
    mov r4, #0x40
    mov r5, #0
    mov r6, #0
test_while_start:
    bl write_char_to_buffer
    UPDATE_GRAPHICS
    bl sleep_till_next_frame
    bl clear_buffer
    add r6, r6, #1
    cmp r6, #80
    blt test_while_start

    PRINT_BUFFER cleanup_codes

    /* exit syscall */
    mov r0, #0 // status
    mov r7, #1 // syscall ID
    swi #0

