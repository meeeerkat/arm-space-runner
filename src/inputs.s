

.global handle_input


/*
 * Inputs management
 */

.data
    input_buffer: .skip 1000
    input_buffer_len = . - input_buffer

.text

handle_input:
    // we read buffer at every tick

    push {r4, r5, r7, lr}
    /* read syscall */
    mov r0, #1                  // stdin
    ldr r1, =input_buffer       // buffer
    ldr r2, =input_buffer_len   // clearing buffer by taking many chars
    mov r7, #0x3                // syscall ID
    swi #0

    // checking we actually read something
    cmp r0, #0
    ble handle_input_end

    add r5, r0, r1  // r5 is the end of the read buffer
    mov r4, r1      // r4 is the start of the read buffer
handle_input_loop_start:
    ldrb r0, [r4], #1 // read one char
    // input_handlers must not modify r0 if it's not consumed
    // if it's consumed, r0 = 0
    bl general_handle_input
    cmp r0, #0
    blne spaceship_handle_input
    cmp r4, r5
    bne handle_input_loop_start

handle_input_end:
    pop {r4, r5, r7, pc}

