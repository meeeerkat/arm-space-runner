



// GENERAL FUNCTIONS START


.data
    startup_codes: .ascii "\x1b[?25l"
    startup_codes_len = . - startup_codes
    cleanup_codes: .ascii "\x1b[?25h"
    cleanup_codes_len = . - cleanup_codes
    reset_graphics_codes: .ascii "\x1b[2J\x1b[H"
    reset_graphics_codes_len = . - reset_graphics_codes
    go_home_code: .ascii "\x1b[H"
    go_home_code_len = . - go_home_code

    screen: .skip 80*25
    screen_end:
    screen_len = . - screen


    // struct termios declared in /usr/arm-linux-gnueabihf/usr/include/asm-generic/termbits.h
    my_termios_struct:
        .skip 4*4 + 1 + 19

    saved_termios_struct:
        .skip 4*4 + 1 + 19

    winsize_struct:
        .short 25
        .short 80
        .short 0     // unused
        .short 0     // unused

    sleep_till_next_frame_timespec_struct:
        .long 0 // seconds
        .long 500000000 // nanoseconds

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
    ldr r1, =\lab           // buffer
    ldr r2, =\lab\()_len    // len
    PRINT
.endm

.macro UPDATE_GRAPHICS
    PRINT_BUFFER go_home_code
    PRINT_BUFFER screen
.endm

write_char_to_buffer:
    // r0 = buffer, r1 = char, r2 = posy, r3 = posx
    // DOES NOT MODIFY ITS PARAMETERS
    push {r4}
    mov r4, #80
    mul r4, r2, r4
    add r4, r4, r3
    strb r1, [r0, r4]
    pop {r4}
    mov pc, lr
    

clear_screen_buffer:
    // Takes no arguments
    ldr r0, =screen
    ldr r1, =screen_end
    mov r2, #0x20 // space
    clear_buffer_set_spaces_while_start:
        strb r2, [r0], #1
        CMP r0, r1
        BNE clear_buffer_set_spaces_while_start
    mov r2, #0xa // adding EOL every 80 chars
    ldr r0, =screen+80
    clear_buffer_add_end_of_line_while_start:
        strb r2, [r0], #80
        cmp r0, r1
        blt clear_buffer_add_end_of_line_while_start
    mov pc, lr

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
    mov r4, #0
    orr r4, r4, #2
    orr r4, r4, #10
    mvn r4, r4
    and r3, r3, r4 // clear ICANON (=2) and ECHO (=10=8+2)
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


// GENERAL FUNCTIONS END



// SPECIFIC FUNCTIONS START
.data
// lasers {char, posy, vely, posx, velx}
// ex: ex:  0x41, 20, -1, 0, 1, 0x42, 0, 1, 70, -1, 0x43, 0, 1, 30, 1
lasers: .skip 1000
lasers_end:
lasers_len = . - lasers
next_laser_addr: .word lasers   // Rotating addr
random_bytes: .skip 4
random_bytes_len = . - random_bytes

.text
update_lasers:
    // Takes no argument
    // Assumes that buffer has been cleared from previous lasers
    // Updates lasers position and writes them to screen buffer
    push {r4, r5, lr}

    ldr r0, =screen
    ldr r4, =lasers
    ldr r5, =next_laser_addr
update_one_laser:
    // Here we update all components of all lasers
    ldrb r1, [r4], #1   // loading char
    ldrb r2, [r4], #2   // loading posy
    ldrb r3, [r4], #2   // loading posx
    
    cmp r2, #25          // verifying value
    bge update_next_laser
    cmp r2, #0
    blt update_next_laser

    cmp r3, #79          // verifying value
    bge update_next_laser
    cmp r3, #0
    blt update_next_laser

    // r0,r1,r2 and r3 are all already properly positionned
    // We are assured that write_char_to_buffer doesn't modify it's parameter
    // (by the function's doc)
    bl write_char_to_buffer 

    // Updating pos
    ldrb r1, [r4, #-3]  // loading vely
    add r2, r2, r1      // calculating new posy
    strb r2, [r4, #-4]  // storing it
    
    ldrb r1, [r4, #-1]  // loading velx
    add r3, r3, r1      // calculating new posx
    strb r3, [r4, #-2]  // storing it
update_next_laser:
    cmp r4, r5
    bne update_one_laser
    pop {r4, r5, pc}


add_random_laser:
    // Takes no arguments
    push {r4, r5, r6, r7}

    ldr r3, =next_laser_addr
    ldr r3, [r3]

    mov r5, #0x41
    strb r5, [r3], #1

    // Starting position calculation:
    // We need 2 random bits (4 combinations) to determine the side on which the lasers will spawn
    // We need 5 or 7 random bits (32 or 128 combinations) for the other component (the first 2 random bits
    // determine a component to be 0)
    // We then need to set the velocity (for now it'll be calculated based on starting position)
    // RIGHT NOW THE laserS WILL ONLY SPAWN FROM THE TOP OR BOTTOM (to simplify)

    /* getrandom syscall */
    ldr r0, =random_bytes
    ldr r1, =random_bytes_len
    mov r2, #0
    mov r7, #0x180     // syscall ID
    swi #0
    // r0 IS OVERWRITTEN BY size_t RETURN PARAMETER
    // TODO: handle case where we didn't received enough random bytes
    ldr r0, =random_bytes
    
    ldrb r5, [r0], #1   // loading first random byte in r5
    TST r5, #0b1        // determining startpos.y with the first bit
    // r5 = startpos.y, r6 = velocity.y
    moveq r5, #0
    moveq r6, #1
    movne r5, #24
    ldrne r6, =-1
    strb r5, [r3], #1
    strb r6, [r3], #1

    ldrb r5, [r0], #1       // loading the next random byte
    mov r5, r5, LSR #2      // only using 6 bits so we only have 2^6=64 combinations
    add r5, r5, #(80-64)/2  // centering startpos.x
    strb r5, [r3], #1
    TST r5, #0b1000000      // using the seventh random bit to determine velocity.x
    moveq r5, #1
    ldrne r5, =-1
    strb r5, [r3], #1
    
    ldr r4, =lasers_end
    cmp r3, r4              // if next_laser_addr is at the end of the lasers array
    ldrge r3, =lasers       // move it back to the beginning (r3 = r4+1 because we post index it)
    // Storing new next address
    ldr r4, =next_laser_addr
    str r3, [r4]

    pop {r4, r5, r6, r7}
    mov pc, lr


// SPECIFIC FUNCTIONS END



.text
.global _start
_start:
    PRINT_BUFFER startup_codes
    PRINT_BUFFER reset_graphics_codes
    NONCANONICAL_MODE_START

    bl clear_screen_buffer

    mov r4, #10
    ldr r5, =screen
main_while_start:
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

