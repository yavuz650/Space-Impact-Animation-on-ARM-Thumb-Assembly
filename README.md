# Space-Impact-Animation-on-ARM-Thumb-Assembly
Space Impact is an old school game from Nokia 3310 cellphone. In this project, the game is animated on an ARM Thumb Emulator. Animation is written in Thumb Assembly and it is running on the emulator. Emulator is written in C.

Original Game             |  Animation
:-------------------------:|:-------------------------:
![Original Game](/original_game.jpg)  |  ![Animation](/animation.png)

The animation is intended to be run on Linux operating systems. However, you can port it to other platforms as you wish.

The emulator and the animation has a couple of dependencies. The emulator alone requires GNU ARM toolchain to be installed in your system. If you also want to run the animation, you will need SDL-1.2 installed in your system. 

# Installing Dependencies
Install GNU ARM toolchain by running the command,

`sudo apt-get install gcc-arm-none-eabi`

Install SDL-1.2 for animation

`sudo apt-get install libsdl1.2-dev`

Your environment should be ready now

# Building the Emulator and running the Animation
Compile the source code of the Emulator by running the command,

`gcc emulator.c emulib.c -lSDL -o emulator`

Run the animation by executing the command,

`./emulator animation.s`

You should now see a window popped up in your screen and the animation running in it. The animation lasts around 60 seconds. You can prematurely end the animation by pressing `CTRL + 4`, or you can wait for it to end, then press `Enter` to exit.
