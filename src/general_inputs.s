

.global general_handle_input


/*
 * General input management
 */

.data
    .equ ascii_q, 0x71

.text

general_handle_input:
    // r0 = character
    // out: r0 = (consumed) ? 0 : r0

    // Right now there's only support for quitting properly the game
    cmp r0, #ascii_q
    // no need to save lr or to return as main_quit exits the program
    // no need to change r0 to 0 to say it's consumed either
    bleq main_quit

    mov pc, lr
