





.data
    startup_codes: .ascii "\x1b[?25l"
    startup_codes_len = . - startup_codes
    cleanup_codes: .ascii "\x1b[?25h"
    cleanup_codes_len = . - cleanup_codes
    reset_screen_codes: .ascii "\x1b[2J\x1b[H"
    reset_screen_codes_len = . - reset_screen_codes

    screen_buffer: .ascii "                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                "
    screen_buffer_len = . - screen_buffer

.text

    .macro PRINT_BUFFER, lab:req
    /* write syscall */
    mov r0, #1     /* stdout */
    ldr r1, =\lab /* buffer */
    ldr r2, =\lab\()_len   /* len */
    mov r7, #4     /* Syscall ID. */
    swi #0
    .endm

.global _start
_start:
    PRINT_BUFFER startup_codes
    PRINT_BUFFER reset_screen_codes
    PRINT_BUFFER cleanup_codes

    /* exit syscall */
    mov r0, #0 /* Status. */
    mov r7, #1 /* Syscall ID. */
    swi #0

