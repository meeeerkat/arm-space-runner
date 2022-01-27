





.data
    startup_codes: .ascii "\x1b[?25l"
    startup_codes_len = . - startup_codes
    cleanup_codes: .ascii "\x1b[?25h"
    cleanup_codes_len = . - cleanup_codes
    reset_screen_codes: .ascii "\x1b[2J\x1b[H"
    reset_screen_codes_len = . - reset_screen_codes

    screen: .ascii "                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               
                                                                               "
    screen_len = . - screen

.text

    .macro PRINT_BUFFER, lab:req
    /* write syscall */
    mov r0, #1     /* stdout */
    ldr r1, =\lab /* buffer */
    ldr r2, =\lab\()_len   /* len */
    mov r7, #4     /* Syscall ID. */
    swi #0
    .endm

    .macro WRITE_CHAR, buff_addr:req, char:req, posy:req, posx:req, tmp:req
    mov \tmp, #80
    mul \tmp, \posy, \tmp
    add \tmp, \tmp, \posx
    str \char, [\buff_addr, \tmp]
    .endm

.global _start
_start:
    PRINT_BUFFER startup_codes
    PRINT_BUFFER reset_screen_codes

    ldr r0, =screen
    mov r1, #0x30
    mov r2, #22
    mov r3, #2
    WRITE_CHAR r0, r1, r2, r3, r4
    PRINT_BUFFER screen

    PRINT_BUFFER cleanup_codes

    /* exit syscall */
    mov r0, #0 /* Status. */
    mov r7, #1 /* Syscall ID. */
    swi #0

