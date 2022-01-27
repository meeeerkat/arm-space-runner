





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
    sleep_timespec_struct:
        .long 1 // 1 second
        .long 0 // 0 nanoseconds

.text

    .macro PRINT
    /* write syscall
    * assumes that r1 and r2 are positionned properly*/
    mov r0, #1     // stdout
    mov r7, #4     // syscall ID
    swi #0
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

    .macro WRITE_CHAR, buff_addr:req, char:req, posy:req, posx:req, tmp:req
    mov \tmp, #80
    mul \tmp, \posy, \tmp
    add \tmp, \tmp, \posx
    str \char, [\buff_addr, \tmp]
    .endm

    .macro CLEAR_SCREEN_BUFFER, lab:req, tmp_char:req, tmp_buff_addr:req, tmp_buff_end:req
    mov \tmp_char, #0x20 // space
    ldr \tmp_buff_addr, =\lab
    ldr \tmp_buff_end, =\lab\()_len
    add \tmp_buff_end, \tmp_buff_end, \tmp_buff_addr
    clear_buffer_set_spaces_while_start:
        strb \tmp_char, [\tmp_buff_addr], #1
        CMP \tmp_buff_addr, \tmp_buff_end
        BNE clear_buffer_set_spaces_while_start
    mov \tmp_char, #0xa // adding EOL every 80 chars
    ldr \tmp_buff_addr, =\lab+79
    clear_buffer_add_end_of_line_while_start:
        strb \tmp_char, [\tmp_buff_addr], #80
        CMP \tmp_buff_addr, \tmp_buff_end
        BLT clear_buffer_add_end_of_line_while_start
    .endm

    .macro SLEEP
    ldr r0, =sleep_timespec_struct
    mov r1, #0  // not used for now
    /* nanosleep syscall */
    mov r7, #0xa2 // syscall ID
    swi #0
    .endm

.global _start
_start:
    PRINT_BUFFER startup_codes
    UPDATE_GRAPHICS

    ldr r0, =screen
    mov r1, #0x30
    mov r2, #0
    mov r3, #0
    WRITE_CHAR r0, r1, r2, r3, r4
    UPDATE_GRAPHICS
    SLEEP
    CLEAR_SCREEN_BUFFER screen, r0, r1, r2
    UPDATE_GRAPHICS

    PRINT_BUFFER cleanup_codes

    /* exit syscall */
    mov r0, #0 // status
    mov r7, #1 // syscall ID
    swi #0

