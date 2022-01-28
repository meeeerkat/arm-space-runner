
## A terminal based mini game made in ARM assembly
### Current state
Right now, one can move around in the spaceship using wasd and look at (yet inoffensive) lasers wondering around.

### Goal
In the finished game the player will control a "spacecraft" and will have to avoid being hit by a laser.


### TODO
- Prevent spaceship from going out of the screen
- Add event when the spaceship is hit to game over
- Improve spaceship control
- Improve laser's generation
- Add options to change the "screen" size, lasers generation and the number of ships in the game as well as their starting position and their controls, first at compile time then as arguments
- Option to add multiple spaceships with different or the same controls (so the same movements) + add configurable rule on weather one loses when all spaceships are hit or just one + option to change spaceships' character display to multi character shapes defined by the user
- Improve the screen printing by using 2 buffers: one that is modified by the user (me) and one that represents the currently printed screen. Updating the screen would only need to apply the differences between the two and would be much more efficient (ncurses like).
- Separate the code into multiple files: one that manages the screen in a general way and one that is specific to the game (these sections are already done in main.S but the cut needs to be clarified)
