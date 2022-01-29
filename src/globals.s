
.data
    .equ screen_width, 80
    .equ screen_height, 25


.macro TICK_CHECK_OR_RETURN, tick_reg:req, next_tick_addr_reg:req, out_next_tick_reg:req
    // Are we performing this operation this tick ?
    ldr \out_next_tick_reg, [\next_tick_addr_reg]
    cmp \tick_reg, \out_next_tick_reg
    movne pc, lr // if not, return
.endm

.macro TICK_CHECK_AND_UPDATE_OR_RETURN, tick_reg:req, next_tick_addr_reg:req, out_next_tick_reg:req, tick_add:req
    TICK_CHECK_OR_RETURN \tick_reg, \next_tick_addr_reg, \out_next_tick_reg
    // If we get here we're doing it
    add \out_next_tick_reg, \out_next_tick_reg, \tick_add
    // update last_add_laser_tick_nb
    str \out_next_tick_reg, [\next_tick_addr_reg]
.endm

