

.global view_init
.global view_tick
.global view_game_over
.global view_destroy
.global view_clear_buffer

.global screen
.global screen_end
.global screen_len
.global write_char_to_buffer
.global get_char_from_buffer


/*
 * Screen management
 */

.data
    startup_codes: .ascii "\x1b[?25l"
    startup_codes_len = . - startup_codes
    cleanup_codes: .ascii "\x1b[?25h"
    cleanup_codes_len = . - cleanup_codes
    reset_graphics_codes: .ascii "\x1b[2J\x1b[H"
    reset_graphics_codes_len = . - reset_graphics_codes
    go_home_code: .ascii "\x1b[H"
    go_home_code_len = . - go_home_code
    
    game_over_message: .ascii "Game over\n"
    game_over_message_len = . - game_over_message

    screen: .skip actual_screen_width*screen_height
    screen_end:
    screen_len = . - screen


    // struct termios declared in /usr/arm-linux-gnueabihf/usr/include/asm-generic/termbits.h
    my_termios_struct:
        .skip 4*4 + 1 + 19

    saved_termios_struct:
        .skip 4*4 + 1 + 19

    winsize_struct:
        .short screen_height
        .short actual_screen_width
        .short 0     // unused
        .short 0     // unused

.text


// MACROS START

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
    ldr r1, =\lab           // buffer
    ldr r2, =\lab\()_len    // len
    PRINT
.endm

/* ioctl syscall (with stdin so no need to do an open syscall)
     * see man tty_ioctl
     * It's pretty hard to find good information on how to use this
     * strace to check system calls of a ncurses program revealed the
     * reapeted use of the following calls
     * ioctl(1, TCGETS, {B38400 opost isig icanon echo ...}) = 0
     * ioctl(1, TIOCGWINSZ, {ws_row=47, ws_col=151, ws_xpixel=1359, ws_ypixel=705}) = 0
     * ioctl(1, SNDCTL_TMR_STOP or TCSETSW, {B38400 opost isig -icanon echo ...}) = 0
     * ioctl(1, SNDCTL_TMR_STOP or TCSETSW, {B38400 opost isig -icanon -echo ...}) = 0
     * The 2 last ones where called only once and after that strace prints weirdly
     * which leds to believe that these last two are what launch the canonical mode
     * The value of constants like TCGETS or structs like termios was found in the includes files in
     * /usr/arm-linux-gnueabihf/usr/include/asm-generic/ such as ioctls.h, termios.h
     * Using grep to find the file defining the required symbol (like B38400 or TCGETS) is practical
     * */

.macro NONCANONICAL_MODE_START
    push {r7}

    mov r0, #1      // stdin
    mov r7, #0x36   // syscall ID

    // Saving old termios struct
    mov r1, #0x5401 // TCGETS
    ldr r2, =saved_termios_struct
    swi #0
    // Getting old termios struct again to modify it
    // TODO: copy saved_termios_struct instead of making another syscall
    ldr r2, =my_termios_struct
    swi #0
    
    ldr r2, =my_termios_struct
    ldr r3, [r2, #12]
    and r3, r3, #~10 // clear ICANON (=2) and ECHO (=10=8+2)
    str r3, [r2, #12]

    // Setting modified termios struct
    mov r1, #0x5402 // TCSETS
    ldr r2, =my_termios_struct
    swi #0

/*
    // Setting window size
    mov r1, #0x5414 // TIOCSWINSZ
    ldr r2, =winsize_struct
    swi #0
*/
    pop {r7}
.endm

.macro NONCANONICAL_MODE_END
    push {r7}
    // Resetting saved termios struct
    mov r0, #1      // stdin
    mov r1, #0x5402 // TCSETSA
    ldr r2, =saved_termios_struct
    mov r7, #0x36   // syscall ID
    swi #0
    pop {r7}
.endm

.macro CONFIGURE_NON_BLOCKING_INPUT
    push {r7}
    /* fcntl get syscall */
    mov r0, #1      // stdin
    mov r1, #3      // F_GETFL
    mov r2, #0
    mov r7, #0x37   // syscall ID
    swi #0
    mov r2, r0
    // r2 = fcntl return = current flags

    /* fcntl set syscall */
    mov r0, #1              // stdin reset (r0 was return value)
    mov r1, #4              // F_SETFL
    orr r2, r2, #00004000   // O_NONBLOCK flag set
    swi #0

    pop {r7}
.endm

// MACROS END



view_init:
    push {lr}
    PRINT_BUFFER startup_codes
    PRINT_BUFFER reset_graphics_codes
    NONCANONICAL_MODE_START
    CONFIGURE_NON_BLOCKING_INPUT
    
    bl view_clear_buffer
    pop {pc}

view_tick:
    // Updating graphics
    PRINT_BUFFER go_home_code
    PRINT_BUFFER screen
    mov pc, lr

view_game_over:
    PRINT_BUFFER game_over_message
    mov pc, lr

view_destroy:
    NONCANONICAL_MODE_END
    PRINT_BUFFER reset_graphics_codes
    PRINT_BUFFER cleanup_codes
    mov pc, lr



write_char_to_buffer:
    // r0 = buffer, r1 = char, r2 = posy, r3 = posx
    // DOES NOT MODIFY ITS PARAMETERS
    push {r4}
    mov r4, #actual_screen_width
    mul r4, r2, r4
    add r4, r4, r3
    add r4, r4, #1      // Needed due to \n but causes a bug at the very first pos (0,0)
    strb r1, [r0, r4]
    pop {r4}
    mov pc, lr

get_char_from_buffer:
    // r0 = buffer, r1 = posy, r2 = posx
    // returns r0 = char, r1 & r2 not modified
    mov r3, #actual_screen_width
    mul r3, r1, r3
    add r3, r3, r2
    add r3, r3, #1      // Needed due to \n but causes a bug at the very first pos (0,0)
    ldrb r0, [r0, r3]
    mov pc, lr

view_clear_buffer:
    // Takes no arguments
    ldr r0, =screen
    ldr r1, =screen_end
    mov r2, #0x20 // space
    clear_buffer_set_spaces_while_start: // TODO: write word by word to be faster
        strb r2, [r0], #1
        CMP r0, r1
        BNE clear_buffer_set_spaces_while_start
    mov r2, #0xa // adding EOL every #actual_screen_width# chars
    ldr r0, =screen+actual_screen_width
    clear_buffer_add_end_of_line_while_start:
        strb r2, [r0], #actual_screen_width
        cmp r0, r1
        blt clear_buffer_add_end_of_line_while_start
    mov pc, lr


