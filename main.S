
.data
    startup_codes: .ascii "\x1b[2J\x1b[H\x1b[?25l"
    startup_codes_len = . - startup_codes
    cleanup_codes: .ascii "\x1b[?25h"
    cleanup_codes_len = . - cleanup_codes

    screen_buffer: .ascii "                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                
                                                                                "
    screen_buffer_len = . - screen_buffer

.text
.global _start
_start:
    /* write syscall */
    mov r0, #1     /* stdout */
    ldr r1, =startup_codes /* buffer */
    ldr r2, =startup_codes_len   /* len */
    mov r7, #4     /* Syscall ID. */
    swi #0

    /* write syscall */
    mov r0, #1     /* stdout */
    ldr r1, =screen_buffer /* buffer */
    ldr r2, =screen_buffer_len   /* len */
    mov r7, #4     /* Syscall ID. */
    swi #0

    /* write syscall */
    mov r0, #1     /* stdout */
    ldr r1, =cleanup_codes /* buffer */
    ldr r2, =cleanup_codes_len   /* len */
    mov r7, #4     /* Syscall ID. */
    swi #0

    /* exit syscall */
    mov r0, #0 /* Status. */
    mov r7, #1 /* Syscall ID. */
    swi #0
