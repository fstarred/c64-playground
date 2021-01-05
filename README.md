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

### Read map - colour mode: char

Full decoding of a char map

### Read map with 4x4 tiles - colour mode: char

Full decoding of a map composed by 4x4 tiles, colour mode: char

### Read map with 4x4 tiles - colour mode: tile

Full decoding of a map composed by 4x4 tiles, colour mode: tile

![screenshot](https://github.com/fstarred/c64-playground/blob/master/docs/gifs/metalwarrior.gif?raw=true) 

### Right scrolling with double buffer

Right screen scrolling using double buffering

![screenshot](https://github.com/fstarred/c64-playground/blob/master/docs/gifs/auto_scroll.gif?raw=true)

### Mixed graphics mode

Displaying BIT MAP and TEXT in MULTICOLOR mode, respectively on the upper and bottom side of the screen

![screenshot](https://github.com/fstarred/c64-playground/blob/master/docs/images/mixedmode.jpg?raw=true)

### Koala Image format

Displaying a 320x64 BIT MAP image

![screenshot](https://github.com/fstarred/c64-playground/blob/master/docs/images/image-mode.png?raw=true)

Normally, for a 320x200 image, assuming you load image at $2000, you would have :

```
$2000 - $3f3f (8000 bytes bitmap data)
$3f40 - $4327 (1000 bytes screen RAM)
$4328 - $470f (1000 bytes color  RAM)
$4710 background
```

Since we load an image of 64 pixels height instead of 200, we must calculate effective bitmap data:

```
320pixels / 8 = 40 bytes * 64 height = 2560 bytes bitmap data
320pixels / 8 = 40 bytes * 64 height / 8 = 140 bytes screen ram data
320pixels / 8 = 40 bytes * 64 height / 8 = 140 bytes color ram data
```

Thus:

```
$2000 - $29ff (2560 bytes bitmap data)
$2a00 - $2b3f (140 bytes screen RAM)
$2b40 - $2c3f (140 bytes color  RAM)
$2c40 background
```

## Demo

### Nightly City

![screenshot](https://github.com/fstarred/c64-playground/blob/master/docs/gifs/nightly-city.gif?raw=true)

#### Scrolling carousel text

This effect was ripped from [DavesClassics C64 video 05 YouTube video](https://www.youtube.com/watch?v=JR9Ou-62cEY&t=708s).

The carousel effect is done by rolling colors stored in ram and apply each rasterline.

Snippet for rotating color:

```
rotatecolours
	ldx #0
looprotcol
	lda ramcolour+1,x
	sta ramcolour,x
	inx
	cpx #$40
	bne looprotcol
	lda ramcolour
	sta ramcolour-1+$40
```

Apply different color for each line:

```
	ldx #0
colourloop
	lda ramcolour,x
	tay

	lda $d012
	cmp $d012
	beq *-3

	sty $d021
	inx

	lda #irq_0+9
	cmp $d012
	bne colourloop
```

#### Print big text on upper side of the screen

The font size is 2x2 and is disposed in a way that each letter takes 4 bytes which are consecutively ordered.
Thus, for printing the 'A' letter, just get the PET relative code, multiply by 4 and then get next 4 consecutive bytes.
The scheme is:

1|2  
3|4

```
    lda msg
    ldy #0
    ldx #0
printmsg
    sec
    sbc #$40 ; obtain correct character code

    asl a
    asl a ; multiply by 4

    clc
    sta $0400,x
    adc #1
    sta $0401,x
    adc #1
    sta $0400+40,x
    adc #1
    sta $0401+40,x

    inx
    inx ; move screen cursor by 2

    iny ; increment text pointer
    lda msg,y 
    bne printmsg ; print text until reach byte 0
    
    

msg
    .text "starred mediasoft"
    .byte 0
```

#### Horizontal right scrolling


Software scrolling is often considered a pain in early '80 computers due to the big CPU usage request.  
Furthermore, while character RAM can be double-buffered (which is the most common used tecnique to scroll a scenario), color RAM has only one reserved memory area, therefore all map must be copied in 1 or 2 frames.
This is the so called "race the beam" trick; wait at a certain line (i.e. 150) and then start to copy color map from the top of thescreen.  

##### Switch VIC-II bank

Take a look at the below code:

```
; shift screen left
rcopyscreenram
	ldy #$00

	lda (sourcescreen),y
	sta (destscreen),y
	iny
	lda (sourcescreen),y
	sta (destscreen),y
	iny
	lda (sourcescreen),y
	sta (destscreen),y
	iny
	lda (sourcescreen),y
	sta (destscreen),y
	iny
	lda (sourcescreen),y
	sta (destscreen),y
	iny
	lda (sourcescreen),y
	sta (destscreen),y
	iny
	cpy #36
	bne rcopyscreenram+2
	...
	
	; copy screen ram, color ram, then swith bank using $d018
```

We copy bytes from a certain position to another using indirect addressing; we can set sourcescreen and destscreen with respectively displayed screen and the alternate bank which works as the buffered screen.  
Notice that we can use the above code either for copying screen char or color map.  
Once we have to scroll the entire character set, we can switch screen bank by setting correct bit flags on $D018.

##### Unrolled loop

As the name suggest, unrolled loop code does not make usage of branches, so instead refer to address in direct mode; while the pro is the less cpu requirement, the cons is the ram usage because a lot of code is needed.
Take a look at the snippet below:

```
copyramscreen
	lda $0401
	sta $0400
	lda $0402
	sta $0401
	lda $0403
	sta $0402
; and so on
copyramcolor
        lda $d801
	sta $d800
	lda $d802
	sta $d801
	lda $d803
	sta $d802
; and so on
```

Writing code that copy 1000+1000 bytes of char and color using this way may take even an half day, but luckly nowadays we have the right compilers for accomplish this mission:

```
.for ue := $0400, ue < $07e7, ue += $01
	lda ue+1
	sta ue
.next
```

## Hints

### Badline

Badline occurs when VIC-II takes some time from CPU for fetching some stuff like colours, sprite or character data.

This operation takes 40 cycles, thus CPU has just 23 cycles left for computing.

In order to check if a certain line is the infamous badline, consider this formula:

```
D012 & 3 == D011 & 3 and $30 < D012 < $f7
```

Here are some badlines that occur on text mode ($D011 = $1B): $33, $3B, $43, $4B, $53, etc..

## External references

The following is a collection of noticeable source sites:

### Specs

* http://www.6502.org/tutorials/6502opcodes.html - 6502 OP Code, a quick and efficent reference guide
* http://sta.c64.org/cbm64mem.html - The C64 Memory map
* http://codebase64.org - One of the most important code and article repository for C64
* https://csdb.dk - The C64 Scene Database

### Articles
* http://www.antimon.org/code.asp - This is probably the holy bible for start programming with C64 (at least it was for me)
* https://github.com/petriw/Commodore64Programming
* https://dwheeler.com/6502/oneelkruns/asm1step.html - An assembly friendly guide

### Resources
* http://kofler.dot.at/c64/
* http://www.beigerecords.com/c64music.html

## Emulators

### Vice
Vice is propably the most famous emulator for C64. It contains several internal and included tools to improve the emulation's experience.

### c1541
If you want to develop with C64 using native assemblers like _Turbo Assembler_ or _Turbo Macro Pro_, you'll probably need to use this disk tool.
Some hints:

Create a disk image called disk1 and attach it to the current console session.

``
c1541 -format disk1,id d64 disk1.d64 -attach disk1.d64
``

Read disk content from the attached disk image

``
list
``

Read a .seq file from the attached disk image and write to the host directory

``
read "filename,s"
``

Write a .seq file from host to the attached disk image

``
write "filename" "filename,s"
``

### VICE MONITOR

Vice monitor is an integrated VICE tool that help developers to DEBUG its software.

Let's see most common commands:

```
break <memory address> - place a breakpoint at memory address
g - goto until next break point is reached
n - goto next instruction
dis [<number>] - disable breakpoint (ALL if no input specified)
en [<number>]  - enable breakpoint (ALL if no input specified)
del [<number>] - delete breakpoint (ALL if no input specified)
```

#### What is the memory address of my code ???

Simple answer: place a label before your opcode.

example:

```
mydebuglabel
  sta $0400
```

In order to achieve what value the Accumulator contains where stores to $0400, you need to know the _mydebuglabel_'s memory address.
Use this command with Turbo assembler / Turbo Macro Pro with:

``
{u+*
``

The output produces is like this:

``
mydebuglabel = $1376
``

Now, to put a breakpoint just type 'break 1376' on VICE MONITOR and then 'g' to run the assembled program.

*Notice:* Remember to assemble your program before running this or you may get wrong memory address values

#### Labels with 64tasm

If you're using Cross-Asm software like _64Tasm_ instead, run the compiler with option:

``
-l labels.txt
``

This write all the label's info into _labels.txt_ file

### Turbo Assembler command hints

Load prg from disk to memory address

``
{SHIFT+L - load to memory addr
``

Save a file with the content of a memory range (reccomanded in place of standard {5 in some cases)

``
{SHIFT+S - save to memory addr
``

``
{u+* - show labels
``
### BASIC command hints

Show disk content

``
LOAD"$",8
``

Delete a file

``
OPEN1,8,15,"S:FILENAME":CLOSE1
``

Load data in memory

```
10 sys 57812"<file>",8
20 poke781,<LO>:poke782,<HI>
30 poke780,0
40 sys65493
```

Program Restore to make jump at address x ($8000 in the case below)

```
POKE 792,0: POKE 793,128
```

HI = hi byte in decimal
LO = lo byte in decimal
