# C64-playground
A repository dedicate to C64 programming, music, etc

# Contents
This repo contains two kind of source files:
* .seq
* .asm

While <i>.seq</i> is granted to run either from native C64 assembler (ex. Turbo Assemler or C64 TMP) and 64Tass cross assembler, the latter format is oftern compiled with <i>64tass</i> using specific options to grant as more compliance as possible with old assemblers.

Therefore, in many cases it may be enough to replace <i>underscore</i> char with a blank one some else PETSCII char available for example and the program may be assembled even from TASM.

## Sources

### How to compile

Edit *compile.bat* in root repo directory and set *64tass* and vice path, then launch as:

```
compile.bat <file.asm>

example:
compile.bat asm\map_colchar_4x4.asm

```

If all paths are set correctly, program should be compiled and run automatically with *VICE* emulator

### Files

#### map_colchar_4x4.asm

An example of colourized per char mode

#### map_coltile 4x4.asm

An example of colourized per tile map

![screenshot](https://github.com/fstarred/c64-playground/blob/master/docs/gifs/metalwarrior.gif?raw=true) 

#### rscrolling_dbuffer.asm

An example of right scrolling screen using double buffering

![screenshot](https://github.com/fstarred/c64-playground/blob/master/docs/gifs/auto_scroll.gif?raw=true)
