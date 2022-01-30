
## A terminal based mini game made in ARM assembly
### Current state
Right now, one can move around in the spaceship using wasd and look at (yet inoffensive) lasers wondering around.

### Goal
In the finished game the player will control a "spacecraft" and will have to avoid being hit by a laser.


### TODO
- Print a proper Game over screen
- Improve spaceship control
- Improve lasers graphics : add some color
- Add options to change the "screen" size, lasers generation and the number of ships in the game as well as their starting position and their controls, first at compile time then as arguments
- Option to add multiple spaceships with different or the same controls (so the same movements) + add configurable rule on weather one loses when all spaceships are hit or just one + option to change spaceships' character display to multi character shapes defined by the user
- Improve the screen printing by using 2 buffers: one that is modified by the user (me) and one that represents the currently printed screen. Updating the screen would only need to apply the differences between the two and would be much more efficient (ncurses like). This could still be done in 1 write syscall with a pattern such as "code\_to\_move\_cursor-update-code\_to\_move\_cursor-update-...).
- Fix bug that causes (0, 0) to be a position where the spaceship disapears (and the player automatically loses). This is caused by view's write\_char\_to\_buffer and get\_char\_from\_buffer who add 1 to the final position compensate for the home ("\x1b[H") character that seems to take some place. This bug might be automatically fixed when the screen update is improved (see above).
