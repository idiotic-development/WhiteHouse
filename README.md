# White House #
An interactive fiction mapping program.

## What is it? ##

### What is interactive fiction? ###
You can think of interactive fiction as an RPG made from only text. In a typical IF, the game file simulates an environment or story and the player uses commands to interact or change it. Some common commands might be `get apple`, `drop apple`, or `north`. Most IFs are a type of puzzle with a goal such as "find all treasure" or "escape from the house".

### What is a mapping program? ###
Interactive fiction is implemented in a series of rooms with connections at the compass points (north, northeast etc.) in addition to up and down. A mapper helps the player keep track of where he is and how to get where he needs to go.

## Features ##
* **Auto mapping**  
Automatically builds a map by reading the game transcript as you play the game.

* **Handles multi-floor maps**  
Navigate maps floor by floor, or view with the 3d interface. (3d not yet implemented.)

## Compiling ##

There are not currently any binaries built so will have to compile from source. White House uses the standard linux build system.

`./autogen.sh && make && sudo make install`