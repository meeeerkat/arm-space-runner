
## A terminal based mini game made in ARM assembly
### Current state
Right now, only a basic system to make random "lasers" appear on the upper and bottom sides of the screen is implemented.  

### Goal
In the finished game the player will control a "spacecraft" and will have to avoid being hit by a laser.


### TODO
- First make it functional by adding the player, inputs management and implement the game over event
- Improve laser's generation
- Add options to change the "screen" size and lasers generation, first at compile time then as arguments
- Improve the screen printing by using 2 buffers: one that is modified by the user (me) and one that represents the currently printed screen. Updating the screen would only need to apply the differences between the two and would be much more efficient (ncurses like).
