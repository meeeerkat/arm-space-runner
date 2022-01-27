



// GENERAL FUNCTIONS START


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
        .long 50000000 // 0 nanoseconds

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
    strb r4, [r2, r0]
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

// GENERAL FUNCTIONS END



// SPECIFIC FUNCTIONS START
.data
// lazers {char, posy, vely, posx, velx}
lazers: .byte 0x41, 20, -1, 0, 1, 0x42, 0, 1, 70, -1
lazers_len = . - lazers

.text
update_lazers:
    // assumes that buffer has been cleared from previous lazers
    // updates lazers position and writes them to screen buffer
    // r2 = screen buffer, r3 = screen buffer length
    push {r4, r5, lr}

    ldr r0, =lazers
    ldr r1, =lazers_len
    add r1, r1, r0
update_one_lazer:
    // Here we update all components of all lazers
    ldrb r4, [r0], #1   // loading char
    ldrb r5, [r0], #2   // loading posy
    ldrb r6, [r0], #2   // loading posx
 
    cmp r5, #25          // verifying value
    bge update_next_lazer
    cmp r5, #0
    blt update_next_lazer

    cmp r6, #80          // verifying value
    bge update_next_lazer
    cmp r6, #0
    blt update_next_lazer

    // r2,r4,r5 and r6 are all already properly positionned
    push {r0, r1}
    bl write_char_to_buffer 
    pop {r0, r1}
   

    ldrb r7, [r0, #-3]  // loading vely
    add r5, r5, r7      // calculating new posy
    strb r5, [r0, #-4]  // storing it
    
    ldrb r7, [r0, #-1]  // loading velx
    add r6, r6, r7      // calculating new posx
    strb r6, [r0, #-2]  // storing it

    
update_next_lazer:
    cmp r0, r1
    bne update_one_lazer
    pop {r4, r5, pc}
    
    
// SPECIFIC FUNCTIONS END



.text
.global _start
_start:
    PRINT_BUFFER startup_codes
    UPDATE_GRAPHICS

ldr r2, =screen
ldr r3, =screen_len
mov r4, #100
main_while_start:
    bl update_lazers
    UPDATE_GRAPHICS
    bl clear_buffer
    bl sleep_till_next_frame
    cmp r4, #0
    sub r4, r4, #1
    bgt main_while_start

    PRINT_BUFFER cleanup_codes

    /* exit syscall */
    mov r0, #0 // status
    mov r7, #1 // syscall ID
    swi #0
