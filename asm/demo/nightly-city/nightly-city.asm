;***************************************
;
;   STARRED MEDIASOFT
;
;   NIGHTLY CITY DEMO 2021
;
;
;***************************************

black=$00
white=$01
red=$02
cyan=$03
violet=$04
green=$05
blue=$06
yellow=$07
orange=$08
brown=$09
lightred=$0a
darkgrey=$0b
grey=$0c
lightgreen=$0d
lightblue=$0e
lightgrey=$0f

sprite_streetlamp_addr = $2380
sprite_cloud_addr = $2240
sprite_moon_addr = $2280
sprite_airplane_addr = $22C0

sidaddr = $1000-$7e
charaddr = $2000
attribsaddr = $2300
mapaddr = $2400
char2addr = $3800
prgcode = $5000

;---------------------------------------

; screen points to $0400 address
memsetupval1 = $17  ; characters ROM 
memsetupval2 = $1f  ; characters point to $3800
memsetupval3 = $18  ; characters point to $2000

; screen points to $0800 address
memsetupval4 = $2f  ; characters point to $3800

totalrows=25
totalcols=40

screen0 = $0400
voffset = totalcols*(totalrows-visiblecharsy)
screen1 = $0400+voffset
coloraddr = $d800+voffset

voffset2 = totalcols*(totalrows-visiblecharsy+num_upper_lines_copy)
screen2 = $0400+voffset2
coloraddr2 = $d800+voffset2


irq_0 = 48
irq_1 = 60
irq_2 = 104
irq_3 = 175
irq_4 = 209

num_upper_lines_copy = 11
num_bottom_lines_copy = 5
    
mapwidthnum_upper = 320 ; 16 bit supported
mapwidthnum_lower = 320 ; 16 bit supported

visiblecharsy = 16
visiblecharsx = 40

color_transparent = blue
color_bg1 = darkgrey
color_bg2 = black

sky_char = 0
star_char = 1
star_char_bytepos = charaddr+(star_char*8)
sea_char = 37
sea_char_bytepos = charaddr+(sea_char*8)
sidewalk_char1 = 42
sidewalk_char2 = 43

delaycarousel = 5
delaysea = 30
delayblinkstar = 3
delaycloud = 7

spr_cloud_flgval = $00
spr_airplane_flgval = $ff


;---------------------------------------
;
;   ZERO PAGES
;
;---------------------------------------

mapdata   = $02
colourmem = $26
mappointer_upper = $32
mappointer_lower = $34
sourcescreen = $36
destscreen = $38
mappointerend_upper = $3a
mappointerend_lower = $3c
scrolldelaycnt_upper = $42
scrolldelaycnt_lower = $43
xoffset_upper = $44
xoffset_lower = $45
xoffset_text = $46
mapwidth = $48 ; 16 bit
currentchary = $4a
delaycloud_cnt = $50

speed_ncloud = 1 ; normal cloud
speed_lcloud = 2 ; little cloud
speed_airplane = 1 ; airplane

;---------------------------------------
;
;   BEHAVIOUR
;
;---------------------------------------

;0 = KEY DOWN
;1 = KEY PRESS
keymode = 0
	
;---------------------------------------
;
;   64TASS DIRECTIVE
;
;---------------------------------------
	
debug = 0

;---------------------------------------
;
;   MACRO
;
;---------------------------------------
	
start_benchmark	.macro
	.ifne debug
	lda #\1
	sta $d020	
	.endif
	.endm
	
end_benchmark	.macro
	.ifne debug
	lda $d012
	cmp benchmark_irq+\1
	bcc turn_black
	sta benchmark_irq+\1
turn_black
	lda #0
	sta $d020	
	.endif
	.endm

; use this macro if routine start before and finish beyond line 255
end_benchmark_alt	.macro
	.ifne debug
	lda $d012
	cmp #\2
    bcs turn_black
    cmp benchmark_irq+\1
	bcc turn_black
	sta benchmark_irq+\1
turn_black
	lda #0
	sta $d020	
	.endif
	.endm


wait_5x_cycles .macro ; wait ((5 * x) + 1) cycles
    .option allow_branch_across_page = 0
    ldx #\1
    dex
    bne *-1
    .option allow_branch_across_page = 1
.endm

;---------------------------------------
;
;   IRQ TRACK
;
;---------------------------------------
	


.comment

------------------------------

IRQ 0

    1. apply carousel effect on upper scrolling text
    2. set sprite extra colors
    3. set background color

------------------------------

IRQ 1

    1. set logo colors
    2. set hr scroll
    3. check user input
    4. update bottom screen hr offset
    5. if hr offset < 0 then 3
    6. eventually scroll bottom chars and colors (part 1)

------------------------------

IRQ 2
        
    1. update hr scroll
    2. update system colors
    3. if moving then 4 to 7
    4. update top hr offset
    5. move sprite 0
    6. eventually scroll bottom chars and colors (part 2)
    7. draw lower chars on right margin  
    8. scroll upper scrolling text
    9. do carousel effect 

------------------------------

IRQ 3

    1. play sid
    2. set sprite extra colors
    3. eventually scroll upper chars and colors (part 1)
    
------------------------------

IRQ 4

    1. wait some cycles before apply hr scroll
    2. apply hr scroll on lower screen
    3. eventually scroll upper chars and colors (part 2)
    4. eventually draw right margin on upper screen
    5. eventually draw star
    6. roll stars according to hr offset
    7. roll sea chars
    8. move sprites
    9. blink stars
   10. check keyboard input



-------------------------------
-------------------------------





IRQ i0

    1. delay

-------------------------------

IRQ i1

    1. print next text

-------------------------------

IRQ i2

    1. clear message section
    2. prepare upper fixed colors for next screen

-------------------------------

IRQ i3

    1. delay with blinking

-------------------------------

IRQ i4

    1. draw star 
    2. enable sprites
    3. init system colors

-------------------------------

.endc
    
    
;---------------------------------------
;
;   CODE
;
;---------------------------------------
; basic loader program
;10 SYS 32768; $0801 = 2049

; $0C $08 = $080C 2-byte pointer to the next line of BASIC code
; $0A = 10; 2-byte line number low byte ($000A = 10)
; $00 = 0 ; 2-byte line number high byte
; $9E = SYS BASIC token
; $20 = [space]
; $32 = "2" , $30 = "0", $34 = "4", $38 = "8", $30 = "0" (ASCII encoded numbers for decimal starting address)
; $0 = end of line
; $00 $00 = 2-byte pointer to the next line of BASIC code ($0000 = end of program)

;---------------------------------------

    *=$0801
	
.byte $0c, $08, $0a, $00, $9e, $20
.byte $32, $30, $34, $38, $30, $00
.byte $00, $00

    *= prgcode

    sei

	lda $dd00
	and #$fc
	ora #$03
	sta $dd00	; set vic Bank #0, $0000-$3FFF
	
	lda #$7f
    ldx #$01
    sta $dc0d	;turn off cia1 int
    sta $dd0d   ;turn off cia2 int
    stx $d01a   ;turn on raster int

    lda #$1b
	sta $d011
    lda #$d0
	clc
	adc xoffset_upper
	sta $d016

	lda #memsetupval4
    sta $d018
	
	ldx #$00
	lda #$00
clrscr
	sta $0400,x
	sta $0500,x
	sta $0600,x
	sta $06e8,x
	sta $0800,x
	sta $0900,x
	sta $0a00,x
	sta $0ae8,x
	sta $d800,x
	sta $d900,x
	sta $da00,x
	sta $dae8,x
	dex
	bne clrscr 
	
    ; clear garbage on last char
    lda #$00
    sta $3fff
	
    ; background color
	lda #black
	sta $d020
    
    lda #%11111111  ; cia#1 port a = outputs 
    sta $dc02             

    lda #%00000000  ; cia#1 port b = inputs
    sta $dc03             

    ; init map segments
	; map1 segment
    lda #<mapaddr
    sta mappointer_upper
	lda #>mapaddr
    sta mappointer_upper+1
	
	; map2 segment
	lda #<mapaddr+(mapwidthnum_upper*num_upper_lines_copy)
	sta mappointer_lower
	lda #>mapaddr+(mapwidthnum_upper*num_upper_lines_copy)
	sta mappointer_lower+1
	
    ; map1 pointer end
	lda #<mapaddr+mapwidthnum_upper-visiblecharsx
	sta mappointerend_upper
	lda #>mapaddr+mapwidthnum_upper-visiblecharsx
	sta mappointerend_upper+1

    ; map2 pointer end
	lda #<mapaddr+(mapwidthnum_upper*num_upper_lines_copy)+mapwidthnum_lower-visiblecharsx
	sta mappointerend_lower
	lda #>mapaddr+(mapwidthnum_upper*num_upper_lines_copy)+mapwidthnum_lower-visiblecharsx
	sta mappointerend_lower+1
	
    lda #<screen1
	sta sourcescreen
	lda #>screen1
	sta sourcescreen+1
	
    ; init vars
    jsr init_charscrollvars
	
    lda #delaycloud
    sta delaycloud_cnt
    
	lda #7
	sta xoffset_text
	
	lda #<mapwidthnum_upper
	sta mapwidth
	lda #>mapwidthnum_upper
	sta mapwidth+1
	
    ; build map on screen
	lda mappointer_upper
	sta mapdata
	lda mappointer_upper+1
    sta mapdata+1
	
	lda #<screen1
	sta printchar+1
	lda #>screen1
	sta printchar+2
	
	lda #visiblecharsy
	sta currentchary
	
	jsr decoderscreen
	
	lda #<coloraddr
	sta destscreen
	lda #>coloraddr
	sta destscreen+1

	lda #<screen1
	sta sourcescreen
	lda #>screen1
	sta sourcescreen+1
	
	jsr decodercolour
    
	;clear dirt colours below scrolling text
	lda #darkgrey
	ldx #80
lp_clear_dirty_color
	dex
    sta $d800,x
	bne lp_clear_dirty_color
	
	; init sid
    lda #$00
    tax
    tay
    jsr $1000
	
    ; build logo
	ldx #0
	lda scrollingtext
    clc
lp_normalize_text
	adc #$80
	sta scrollingtext,x
	inx
	lda scrollingtext,x
	bne lp_normalize_text

	ldx #40
	lda #$a0 ; space char
lp_normalize_line
	dex
	sta screen0,x
	bne lp_normalize_line
	
	ldx #160
	lda #darkgrey
lp_clear_color
	dex
	sta $d850,x
	bne lp_clear_color
    
    
    ; print logo
    lda textscroffset
    sta destscreen
    lda textscroffset+1
    sta destscreen+1
    
    jsr print_large_text
    
    jsr print_large_text
	
    ; init sprites
    ; street lamp
    lda #sprite_streetlamp_addr / $40
    sta $07f8  ; spr point 0 (screen $400)
    sta $0bf8  ; spr point 0 (screen $800)
    lda #$f7
    sta $d000  ; sprite 0 x
    lda #$ba     
    sta $d001  ; sprite 0 y
    lda #yellow  
    sta $d027  ; sprite 0 color
    
    ; cloud
    lda #sprite_cloud_addr / $40
    sta $07f9  ; spr point 1 (screen $400); spr point 1
    sta $0bf9  ; spr point 1 (screen $800);
    sta $07fa  ; spr point 2 (screen $400); spr point 2
    sta $0bfa  ; spr point 2 (screen $800)
    sta $07fb  ; spr point 3 (screen $400); spr point 3
    sta $0bfb  ; spr point 3 (screen $800)
    sta $07fc  ; spr point 4 (screen $400); spr point 4
    sta $0bfc  ; spr point 4 (screen $800)
    lda #$ff   
    sta $d002  ; sprite 1 x
    lda #$6e   
    sta $d003  ; sprite 1 y
    lda #$80
    sta $d004  ; sprite 2 x
    lda #$40
    sta $d005  ; sprite 2 y
    lda #darkgrey
    sta $d028 ;  sprite 1 color
    sta $d029 ;  sprite 2 color
    
    lda #$50   
    sta $d006  ; sprite 3 x
    lda #$50   
    sta $d007  ; sprite 3 y
    lda #$c0
    sta $d008  ; sprite 4 x
    lda #$73
    sta $d009  ; sprite 4 y
    lda #darkgrey
    sta $d02a ;  sprite 3 color
    sta $d02b ;  sprite 4 color
    
    lda #sprite_moon_addr / $40
    sta $07fd  ; spr point 5 (screen $400); spr point 5
    sta $0bfd  ; spr point 5 (screen $800)
    lda #$ff   
    sta $d00a  ; sprite 5 x
    lda #$70   
    sta $d00b  ; sprite 5 y
    lda #lightgrey
    sta $d02c ;  sprite 5 color
    

    ; global sprites setting
    lda #darkgrey
    sta $d025  ;  sprite extra color 1
    lda #grey
    sta $d026  ;  sprite extra color 2
    lda #%00111110
    sta $d015  ;  enable sprites
    lda #%00000001
    sta $d01c  ;  sprite multicolor
    lda #%00000110
    sta $d01d  ;  expand sprites x
    lda #%00000001
    sta $d017  ;  expand sprites y	
    lda #%00100110
    sta $d01b  ;  sprite priority register	

    ; prepare system colors
    lda #black
    sta $d021
    lda #blue
    sta $d022
    lda #white
    sta $d023

	; init irq
	lda #$7f
    ldx #$01
    sta $dc0d
    sta $dd0d
    stx $d01a

    lda #<step_irq_i0
    ldx #>step_irq_i0
    ldy #irq_3
    sta vectaddr
    stx vectaddr+1
    sta $0314
    stx $0315
    sty $d012

    lda $dc0d
    lda $dd0d
    asl $d019
    
    cli
    jmp *


;*****************
;
;	IRQ 0
;
;*****************


step_irq_0

	lda #<step_irq_1
    ldx #>step_irq_1
    ldy #irq_1
    sta $0314
    stx $0315
    sty $d012	
	
	#start_benchmark white

	lda #memsetupval1
    sta $d018
	
	lda $d016
	and #248
	ora xoffset_text
	sta $d016

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

	;wait some cycles before setting bg color
	;.for ue := 0, ue < 22, ue += 1
	;nop
	;.next
    
    lda #cyan
    sta $d025  ;  sprite extra color 1
    lda #yellow
    sta $d026  ;  sprite extra color 2
    
    #wait_5x_cycles 7
    
	lda #color_transparent
	sta $d021

exit_irq0
	#end_benchmark 0
        
    asl $d019 
    jmp $ea81



;*****************
;
;	IRQ 1
;
;*****************


step_irq_1

    lda #<step_irq_2
    ldx #>step_irq_2
    ldy #irq_2
    sta $0314
    stx $0315
    sty $d012
	
	#start_benchmark green

	ldy #memsetupval2
	sty $d018
	
	; bg color 1
	lda #red
	sta $d022

	; bg color 2
	lda #white
	sta $d023
        
    ; set hr scroll
	lda $d016
	and #248
	ora #7
	sta $d016
    
    lda #$00
    sta ismoving
    
    .ifne keymode
    lda dx
    sta lastdx
    .endif
    
    ldx automove
    bne setdir
    
djrr    
    lda $dc00     ; get input from port 2 only
djrrb   
    ldy #0        ; this routine reads and decodes the
    ldx #0        ; joystick/firebutton input data in
    lsr           ; the accumulator. this least significant
    bcs djr0      ; 5 bits contain the switch closure
    dey           ; information. if a switch is closed then it
djr0    
    lsr           ; produces a zero bit. if a switch is open then
    bcs djr1      ; it produces a one bit. The joystick dir-
    iny           ; ections are right, left, forward, backward
djr1    
    lsr           ; bit3=right, bit2=left, bit1=backward,
    bcs djr2      ; bit0=forward and bit4=fire button.
    dex           ; at rts time dx and dy contain 2's compliment
djr2    
    lsr           ; direction numbers i.e. $ff=-1, $00=0, $01=1.
    bcs djr3      ; dx=1 (move right), dx=-1 (move left),
    inx           ; dx=0 (no x change). dy=-1 (move up screen),
djr3    
    lsr           ; dy=0 (move down screen), dy=0 (no y change).
setdir
    stx dx        ; the forward joystick position corresponds
    sty dy        ; to move up the screen and the backward
    
    ldx dx
    beq checkoffset_lower_1
    
input_on	
    .ifne keymode
	lda lastdx
    bne checkoffset_lower_1
    .endif	
    
    lda #$01
    sta ismoving
	
    ; update speed lower
	dec scrolldelaycnt_lower
	bne checkoffset_lower_1
    
    lda scrolldelay_lower
	sta scrolldelaycnt_lower
	
	lda xoffset_lower
	sec
    sbc scrollspeed_lower
	sta xoffset_lower
    
movespr0
    ; move sprite 0 (street lamp)
    sec
    lda $d000
    sbc scrollspeed_lower
    sta $d000
    bcs checkoffset_lower_1

    lda $d010
    eor #%00000001
    sta $d010

checkoffset_lower_1

    lda #$00
    sec
    sbc scrollspeed_lower
    cmp xoffset_lower
	bne exit_irq1
	
	jsr uc_screen_shift_lower_1
	jsr uc_color_shift_lower_1

exit_irq1

	#end_benchmark 1
	
    asl $d019    
    jmp $ea81


;*****************
;
;	IRQ 2
;
;*****************

step_irq_2

	lda #<step_irq_3
    ldx #>step_irq_3
    ldy #irq_3
	sta $0314
    stx $0315
    sty $d012

	#start_benchmark grey
	
	ldy #memsetupval3
	sty $d018	
	
	lda $d016
	and #248
	ora xoffset_upper
	sta $d016
	
	lda #color_bg1
	sta $d022
	lda #color_bg2
	sta $d023
	
	lda ismoving
    beq carousel_effect

    ;updspeed upper
	dec scrolldelaycnt_upper
    bne checkoffset_lower_2
    
    lda scrolldelay_upper
	sta scrolldelaycnt_upper

	lda xoffset_upper
	sec
	sbc scrollspeed_upper
	sta xoffset_upper

checkoffset_lower_2
    lda #$00
    sec
    sbc scrollspeed_lower
    cmp xoffset_lower
	bne carousel_effect
	
    ;	xoffset_lower < 0 ? xoffset_lower = 6 or 7 according to scroll speed
    lda #8
    sec
    sbc scrollspeed_lower
	sta xoffset_lower

	jsr uc_screen_shift_lower_2
	jsr uc_color_shift_lower_2
	jsr prepare_extractcolumn_lower
        
carousel_effect

	dec delaycarousel_cnt
	bne decxoffset3
	
	lda #delaycarousel
	sta delaycarousel_cnt

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

decxoffset3
	dec xoffset_text
    bpl exit_irq2

scrollsoft
	ldx #0
scrsft
	lda screen0+1,x
	sta screen0,x
	inx
	cpx #39
	bne scrsft

newchar
	ldx charpointer
	lda scrollingtext,x
	bne notzero
	ldx #0
	sta charpointer
	lda scrollingtext,x
notzero
	sta screen0+39

	inx
	stx charpointer

	lda #7
	sta xoffset_text

exit_irq2

	#end_benchmark 2
	
	asl $d019    
    jmp $ea81




;*****************
;
;	IRQ 3
;
;*****************

step_irq_3

    lda #<step_irq_4
    ldx #>step_irq_4
    ldy #irq_4
	sta $0314
    stx $0315
    sty $d012

	#start_benchmark lightred
	
    lda music
    beq s3_1
    
	jsr $1003

s3_1
    lda #darkgrey
    sta $d025  ;  sprite extra color 1
    lda #grey
    sta $d026  ;  sprite extra color 2
	
    lda #$00
    sec
    sbc scrollspeed_upper
    cmp xoffset_upper
    
	bne exit_irq3
	
	jsr uc_screen_shift_upper_1
	jsr uc_color_shift_upper_1
    
exit_irq3
	   
	#end_benchmark 3
	
	asl $d019    
    jmp $ea81
  
  
;*****************
;
;	IRQ 4
;
;*****************

step_irq_4

	lda #<step_irq_0
    ldx #>step_irq_0
    ldy #irq_0
	sta $0314
    stx $0315
    sty $d012

	#start_benchmark red
    
    ;24
	;.for ue := 0, ue < 24, ue += 1
	;nop
	;.next
    
    #wait_5x_cycles 9

	lda $d016
	and #248
	ora xoffset_lower
	sta $d016

	lda $d012
	cmp $d012
	beq *-3
	
    lda #$00
    sec
    sbc scrollspeed_upper
    cmp xoffset_upper
	bne roll_stars
	
    ; xoffset_upper < 0 ? xoffset_upper = 6 or 7 according to scroll speed
    lda #8
    sec
    sbc scrollspeed_upper    
	sta xoffset_upper
	
	jsr uc_screen_shift_upper_2
	jsr uc_color_shift_upper_2
	jsr prepare_extractcolumn_upper
	
	jsr createstars
	
roll_stars
    ; roll star
	ldx xoffset_upper
	lda staroffset,x
	sta star_char_bytepos+4

roll_sea

    dec delaysea_cnt
    bne i4_1
    
    lda #delaysea
    sta delaysea_cnt
    
    lda sea_char_bytepos+3
    ror a
    ror sea_char_bytepos+3
    ror a
    ror sea_char_bytepos+3
    
    lda sea_char_bytepos+4
    ror a        
    ror sea_char_bytepos+4
    ror a        
    ror sea_char_bytepos+4

i4_1
    jsr movesprites
    
    jsr blinkstars
    
    jsr check_inputkey
       
exit_irq4
    
	#end_benchmark_alt 4,irq_4
	
	asl $d019    
    jmp $ea81
    



;*****************
;
;	IRQ i0
;
;*****************

step_irq_i0

    #start_benchmark white

    jsr check_next_irq

    lda vectaddr
    ldx vectaddr+1
    ldy dynirq
    sta $0314
    stx $0315
    sty $d012

    jsr $1003
    
    jsr movesprites

    #end_benchmark 5

    asl $d019
    jmp $ea81


;*****************
;
;	IRQ i1
;
;*****************


step_irq_i1

    #start_benchmark white

    jsr check_next_irq

    lda vectaddr
    ldx vectaddr+1
    ldy dynirq
    sta $0314
    stx $0315
    sty $d012
    
    jsr $1003

    jsr print_large_text
    
    #end_benchmark 6
    
    asl $d019
    jmp $ea81


;*****************
;
;	IRQ i2
;
;*****************
 
step_irq_i2

    #start_benchmark white

    jsr check_next_irq

    lda vectaddr
    ldx vectaddr+1
    ldy dynirq
    sta $0314
    stx $0315
    sty $d012
    
    jsr $1003
    
    ldx #0
si10_0
    lda #0
    sta $0800,x
    lda #darkgrey
    sta $d800,x
    inx
    bne si10_0

    ldx #40
    lda #black
si10_1
    dex
    sta $d800,x
    bne si10_1
    
    ldx #40
    lda #blue
si10_2
    dex
    sta $d828,x
    bne si10_2
    
    #end_benchmark 7

    asl $d019
    jmp $ea81
    

;*****************
;
;	IRQ i3
;
;*****************

step_irq_i3

;    #start_benchmark white

    jsr check_next_irq

    lda vectaddr
    ldx vectaddr+1
    ldy dynirq
    sta $0314
    stx $0315
    sty $d012
    
si3_lp1
    lda $d012
    cmp $d012
    beq *-3
    
    inc $d020
    
    lda #$ad
    cmp $d012
    bne si3_lp1
    
    jsr $1003
    
    inc $d020
    
;    #end_benchmark 11
    
    asl $d019
    jmp $ea81


;*****************
;
;	IRQ i4
;
;*****************

step_irq_i4

    #start_benchmark white

    lda #<step_irq_0
    ldx #>step_irq_0
    ldy #irq_0
    sta $0314
    stx $0315
    sty $d012
    
    jsr createstars
    
    lda #%00111111
    sta $d015  ;  enable sprites
    
    lda #black
    sta $d020
	lda #color_transparent
	sta $d021
	lda #color_bg1
	sta $d022
	lda #color_bg2
	sta $d023
    
    #end_benchmark 8
    
    asl $d019
    jmp $ea81




;********************************
;
;   SUB ROUTINES
;
;*********************************

init_charscrollvars

    lda #8
    sec
    sbc scrollspeed_upper
	sta xoffset_upper
    lda scrolldelay_upper
	sta scrolldelaycnt_upper
	
    lda #8
    sec
    sbc scrollspeed_lower
	sta xoffset_lower
    lda scrolldelay_lower
	sta scrolldelaycnt_lower

    rts



; ***************************************



check_inputkey
    
    lda #%11111110  ; testing column 0 (col0) of the matrix
    sta $dc00
    
    lda $dc01
    tax             ; transfer $dc01 value to register x
    cpx #$ff
    beq checkMkey
    cpx lastkey     
    bne checkF1
    jmp exit_css
    
checkF1
    stx lastkey
    and #%00010000  ; masking row 4 (row4) ; F1
    bne checkF3
    
    lda #2
    sta scrolldelay_upper
    lda #1
    sta scrolldelay_lower
    sta scrollspeed_upper
    sta scrollspeed_lower
    sta automove
    
    jsr init_charscrollvars
    
    bne exit_css ; branch always
    
checkF3
    txa             ; check $dc01
    and #%00100000  ; masking row 5 (row4) ; F3
    bne checkF5
    
    lda #4
    sta scrolldelay_upper
    lda #2
    sta scrolldelay_lower
    lda #1
    sta scrollspeed_lower
    sta scrollspeed_upper
    sta automove
    
    jsr init_charscrollvars
    
    bne exit_css ; branch always 

checkF5
    txa             ; check $dc01
    and #%01000000  ; masking row 6 (row4) ; F5
    bne checkF7
 
    lda #2
    sta scrollspeed_lower
    lda #1
    sta scrolldelay_upper
    sta scrolldelay_lower
    sta scrollspeed_upper
    sta automove
    
    jsr init_charscrollvars

    bne exit_css ; branch always 
    
checkF7
    txa             ; check $dc01
    and #%00001000  ; masking row 3 (row4) ; F7
    bne checkMkey
    
    lda #0
    sta automove
    
    beq exit_css ; branch always
   
checkMkey

    lda #%11101111
    sta $dc00
    
    lda $dc01
    tax
    and #%00010000
    bne exit_css
    
    cpx lastkey
    beq exit_css
    
    stx lastkey
    
    lda music
    eor #$ff
    sta music
    
    bne enable_volume

; disable volume
    
    lda $d418
    and #%11110000
    sta $d418
    
    jmp exit_css
    
enable_volume

    lda $d418
    ora #%00001111
    sta $d418

exit_css    
    stx lastkey
    rts
    

; ***************************************

movesprites

    ; check if street lamp is on the sidewalk. When street lamp is on the right border,
    ; verify that is on the sidewalk char and enable it, otherwise disable sprite
    
    lda $d010
    and #%00000001
    beq checkspr1

    lda $d000
    cmp #$50
    bcs checkspr1 ; gte checkspr1
    cmp #$48
    bcc checkspr1 ; lt checkspr1

    lda screen2+(totalcols*3)-1 ; check last char on col x
    cmp #sidewalk_char1
    beq enablespr0
    
    cmp #sidewalk_char2
    beq enablespr0

    lda $d015
    and #%11111110
    sta $d015       ; disable sprite

    bne checkspr1   ; branch always
 
enablespr0
    
    lda $d015
    ora #%00000001
    sta $d015       ; enable sprite

checkspr1

    dec delaycloud_cnt
    bne checkspr4
    
    lda #delaycloud
    sta delaycloud_cnt

    ; move sprite 1 (cloud)
movespr1
    sec
    lda $d002
    sbc #speed_ncloud
    sta $d002
    bcs movespr2

    lda $d010
    eor #%00000010
    sta $d010
    
    and #%00000010
    beq movespr2
    lda #$f7
    sta $d002
    
    ; move sprite 2 (cloud)
movespr2
    sec
    lda $d004
    sbc #speed_ncloud
    sta $d004
    bcs movespr3

    lda $d010
    eor #%00000100
    sta $d010
    
    and #%00000100
    beq movespr3
    lda #$f7
    sta $d004

    ; move sprite 3 (cloud 2)
movespr3
    sec
    lda $d006
    sbc #speed_lcloud
    sta $d006
    bcs animatespr4

    lda $d010
    eor #%00001000
    sta $d010

    jmp animatespr4

    ; move sprite 4 (cloud 2)
checkspr4
    lda cur_spr4_flag
    beq exit_movesprites ; if cloud then exit, otherwise move
animatespr4

    jsr spr4switchlight

movespr4
    sec
    lda $d008
    sbc cur_spr4_speed
    sta $d008
    bcs exit_movesprites
    
    lda $d010
    eor #%00010000
    sta $d010
    
    and #%00010000          ; check sprite x coordinate (bit #8)
    beq exit_movesprites    ; switch sprite if has reached left margin
    
switchsprite

    lda cur_spr4_flag
    eor #$ff
    sta cur_spr4_flag   ; check what sprite is displayed
    bne spr4airplane
spr4cloud
    lda $d01c
    and #%11101111
    sta $d01c  ;  disable sprite multicolor flag
    lda #speed_lcloud
    sta cur_spr4_speed  ; set sprite speed
    lda #sprite_cloud_addr / $40
    bne setspr4 ; branch always
spr4airplane
    lda $d01c
    ora #%00010000
    sta $d01c  ;  enable sprite multicolor flag   
    lda #speed_airplane
    sta cur_spr4_speed  ; set sprite speed
    lda #sprite_airplane_addr / $40    
setspr4
    sta $07fc  ; set sprite 4 pointer

exit_movesprites
    rts


; ***************************************

spr4switchlight

    dec lightcnt
    bne exit_spr4switchlight

    lda sprite_airplane_addr+16
    cmp #$0c
    bne to0c

    lda #$08
    ldy #$28
    bne spr4lights
to0c
    lda #$0c
    ldy #$2c
spr4lights
    sta sprite_airplane_addr+14
    sta sprite_airplane_addr+16
    sty sprite_airplane_addr+34

    ldx lightptr
    bne declightptr
    ldx #$04

declightptr
    dex
    stx lightptr

    lda lighttbl,x
    sta lightcnt

exit_spr4switchlight
    rts


; ***************************************

blinkstars

    ldx starptr
    bne bstars_0
    
    dec delayblinkstar_cnt
    bne exit_bstars
    
bstars_0
    ldy #1
    
    lda starposition,x
    sta sourcescreen
    inx
    lda starposition,x
    sta sourcescreen+1
    
    lda (sourcescreen),y
    cmp #star_char
    bne bstars_2

    lda sourcescreen+1
    clc
    adc #$d4
    sta sourcescreen+1
    
    lda (sourcescreen),y
    and #$0f
    cmp #white
    bne bstars11
    lda #cyan
    bne bstars13
bstars11
    cmp #cyan
    bne bstars12
    lda #yellow
    bne bstars13
bstars12
    lda #white
bstars13
    sta (sourcescreen),y
bstars_2
    inx
    cpx #12*2
    bne exit_bstars
   
    lda #delayblinkstar
    sta delayblinkstar_cnt
    ldx #0    
    
exit_bstars
    stx starptr
    rts

; ***************************************


createstars

	ldx #0
loopstar		
	ldy #1
	lda starposition,x
	sta sourcescreen
	inx
	lda starposition,x
	sta sourcescreen+1
	
	lda (sourcescreen),y ; check presence of sky char
    sta bck_starchar
    cmp #sky_char
	bne ls_1
	lda #star_char  ; draw star
	sta (sourcescreen),y
ls_1	
	; clear "cloned" stars generated by soft scroll
	dey
	lda (sourcescreen),y
	cmp #star_char
	bne ls_2
	lda #sky_char
	sta (sourcescreen),y
    
    lda bck_starchar
    cmp #sky_char
    ; get star last color and store to current star position
    bne ls_2
    lda sourcescreen+1
    clc
    adc #$d4
    sta sourcescreen+1
    
    lda (sourcescreen),y
    iny
    sta (sourcescreen),y
    
ls_2	
	inx
	cpx #12*2
	bne loopstar
	
	rts

; ***************************************


print_large_text
    
    lda #$00
    sta fontaddr+1
    pha
    
printbegin    
    ldx textptr
    lda slideshowtext,x
    ldy #0
plt_1
    sec
    sbc #$40

    asl a
    asl a

    clc
fontaddr
    adc #$ff

    clc
    sta (destscreen),y
    adc #1
    iny
    sta (destscreen),y
    inx
    iny

    lda slideshowtext,x
    bne plt_1

    pla
    eor #$ff
    beq exit_plt    ; font section flag; first print upper part. if at this point ack = $ff then write bottom part
    pha
    
    lda destscreen
    clc
    adc #$28
    sta destscreen
    bcc *+4
    inc destscreen+1

    lda #$02
    sta fontaddr+1

    bne printbegin ; branch always

exit_plt
    
    ; update text pointer
    inx
    stx textptr
    
    ; update screen pointer (16 bit)
    ldx textscrptr
    inx
    inx
    stx textscrptr
    
    ; update destscreen
    lda textscroffset,x
    sta destscreen
    inx
    lda textscroffset,x
    sta destscreen+1

    rts
    
; ***************************************    

uc_screen_shift_upper_1
	
	.for ue := screen1, ue < (screen1+((num_upper_lines_copy-10)*totalcols)), ue += $01
	lda ue+1
	sta ue
	.next

	rts

; ***************************************

uc_screen_shift_upper_2
	
	.for ue := screen1+(40*1), ue < (screen1+(num_upper_lines_copy*totalcols)), ue += $01
	lda ue+1
	sta ue
	.next

	rts

; ***************************************


uc_screen_shift_lower_1
	
	.for ue := screen2, ue < (screen2+((num_bottom_lines_copy-2)*totalcols)), ue += $01
	lda ue+1
	sta ue
	.next

	rts

; ***************************************


uc_screen_shift_lower_2
	
	.for ue := screen2+(40*3), ue < (screen2+(num_bottom_lines_copy*totalcols)), ue += $01
	lda ue+1
	sta ue
	.next

	rts

; ***************************************


uc_color_shift_upper_1
	
	.for ue := coloraddr, ue < (coloraddr+((num_upper_lines_copy-10)*totalcols)), ue += $01
	lda ue+1
	sta ue
	.next

	rts

; ***************************************

    
uc_color_shift_upper_2
	
	.for ue := coloraddr+(40*1), ue < (coloraddr+(num_upper_lines_copy*totalcols)), ue += $01
	lda ue+1
	sta ue
	.next

	rts

; ***************************************

uc_color_shift_lower_1
	
	.for ue := coloraddr2, ue < (coloraddr2+((num_bottom_lines_copy-2)*totalcols)), ue += $01
	lda ue+1
	sta ue
	.next

	rts


; ***************************************

uc_color_shift_lower_2
	
	.for ue := coloraddr2+(40*3), ue < (coloraddr2+(num_bottom_lines_copy*totalcols)), ue += $01
	lda ue+1
	sta ue
	.next

	rts

; ***************************************


decodercolour

	lda #visiblecharsy
dc_1
    pha
    ldy #$00
dc_11

	lda (sourcescreen),y
	tax
	lda attribsaddr,x
	sta (destscreen),y
    iny
	
	lda (sourcescreen),y
	tax
	lda attribsaddr,x
	sta (destscreen),y
    iny
	
	lda (sourcescreen),y
	tax
	lda attribsaddr,x
	sta (destscreen),y
    iny
	
	lda (sourcescreen),y
	tax
	lda attribsaddr,x
	sta (destscreen),y
    iny
	
	lda (sourcescreen),y
	tax
	lda attribsaddr,x
	sta (destscreen),y
    iny
	
	lda (sourcescreen),y
	tax
	lda attribsaddr,x
	sta (destscreen),y
    iny
	
	cpy #36
	bne dc_11
	
	lda (sourcescreen),y
	tax
	lda attribsaddr,x
	sta (destscreen),y
    iny
	
	lda (sourcescreen),y
	tax
	lda attribsaddr,x
	sta (destscreen),y
    iny
	
	lda (sourcescreen),y
	tax
	lda attribsaddr,x
	sta (destscreen),y
    iny
	
	lda (sourcescreen),y
	tax
	lda attribsaddr,x
	sta (destscreen),y
    
	lda sourcescreen
    clc
    adc #$28
    sta sourcescreen
    bcc *+4
    inc sourcescreen+1
	
	lda destscreen
    clc
    adc #$28
    sta destscreen
    bcc *+4
    inc destscreen+1

    pla
    sec
    sbc #1
	bne dc_1
	
    rts


; ***************************************


decoderscreen
	
	ldy #$28
	ldx #$28
readchar			
	dey
	lda (mapdata),y
	dex
printchar		
	sta $ffff,x	
	bne readchar
	
	dec currentchary
	beq exit_ds
	
	lda printchar+1
	clc
	adc #$28
	sta printchar+1
	bcc *+5
	inc printchar+2
	
	clc
	lda mapdata
	adc mapwidth
	sta mapdata
	lda mapdata+1
	adc mapwidth+1
	sta mapdata+1
	
	bcc decoderscreen ; branch always
exit_ds
	rts

; ***************************************


prepare_extractcolumn_upper

	lda mappointer_upper
	cmp mappointerend_upper
	bne no_rx_limit_upper
	
	lda mappointer_upper+1
	cmp mappointerend_upper+1
	bne no_rx_limit_upper

	lda #<mapaddr-visiblecharsx
	sta mappointer_upper
	lda #>mapaddr-visiblecharsx
	sta mappointer_upper+1
	
no_rx_limit_upper
	lda mappointer_upper
	clc
	adc #$28
	sta mapdata
	lda mappointer_upper+1
	adc #$00
	sta mapdata+1
    
    lda #<screen1
	clc
	adc #$27
	sta sourcescreen
    sta colourmem
	bcs peu1
	
	lda #>screen1
	sta sourcescreen+1
	lda #>coloraddr
	sta colourmem+1
	bcc extractcolumnupper ; branch always
peu1
	lda #>screen1
	adc #$00
	sta sourcescreen+1
	lda #>coloraddr
	adc #$01
	sta colourmem+1

extractcolumnupper
		
	lda #num_upper_lines_copy
	sta currentchary
		
	ldy #$00
ecu1	
	lda (mapdata),y
	sta (sourcescreen),y
	
	tax
    lda attribsaddr,x
    sta (colourmem),y
	
	; update colour memory position
	lda mapdata
    clc	
    adc #<mapwidthnum_upper
    sta mapdata
	lda mapdata+1
	adc #>mapwidthnum_upper
	sta mapdata+1
	
	; update colour memory position
    lda colourmem
    clc
    adc #$28
    sta colourmem
    bcc *+4
    inc colourmem+1
	
	; update char memory position
	lda sourcescreen
    clc
    adc #$28        
    sta sourcescreen
    bcc *+4
    inc sourcescreen+1
	
	dec currentchary
	bne ecu1
    
	inc mappointer_upper
	bne *+4
	inc mappointer_upper+1

	rts


; ***************************************


prepare_extractcolumn_lower

	lda mappointer_lower
	cmp mappointerend_lower
	bne no_rx_limit_lower
	
	lda mappointer_lower+1
	cmp mappointerend_lower+1
	bne no_rx_limit_lower

	lda #<mapaddr+(mapwidthnum_upper*num_upper_lines_copy)-visiblecharsx
	sta mappointer_lower
	lda #>mapaddr+(mapwidthnum_upper*num_upper_lines_copy)-visiblecharsx
	sta mappointer_lower+1
	
no_rx_limit_lower
	lda mappointer_lower
	clc
	adc #$28
	sta mapdata
	lda mappointer_lower+1
	adc #$00
	sta mapdata+1
    
    lda #<screen2
	clc
	adc #$27
	sta sourcescreen
    sta colourmem
	bcs pel1
	
	lda >#screen2
	sta sourcescreen+1
	lda #>coloraddr2
	sta colourmem+1
	bcc extractcolumnlower ; branch always
pel1
	lda #>screen2
	adc #$00
	sta sourcescreen+1
	lda #>coloraddr2
	adc #$01
	sta colourmem+1

extractcolumnlower
		
	lda #num_bottom_lines_copy
	sta currentchary
		
	ldy #$00
ecl1	
	lda (mapdata),y
	sta (sourcescreen),y
	
	tax
    lda attribsaddr,x
    sta (colourmem),y

	; update colour memory position
	lda mapdata
    clc	
    adc #<mapwidthnum_lower
    sta mapdata
	lda mapdata+1
	adc #>mapwidthnum_lower
	sta mapdata+1

	; update colour memory position
    lda colourmem
    clc
    adc #$28
    sta colourmem
    bcc *+4
    inc colourmem+1

	; update char memory position
	lda sourcescreen
    clc
    adc #$28        
    sta sourcescreen
    bcc *+4
    inc sourcescreen+1
	
	dec currentchary
	bne ecl1
    
	inc mappointer_lower
	bne *+4
	inc mappointer_lower+1

	rts

; ***************************************


check_next_irq

    dec slideshowcntstart
    bne cni_exit

    ldx irqptr
    lda lookuptblirq,x
    sta vectaddr
    inx
    lda lookuptblirq,x
    sta vectaddr+1
    inx
    lda lookuptblirq,x
    sta dynirq
    inx
    lda lookuptblirq,x
    sta slideshowcntstart
    inx
    stx irqptr

cni_exit
    rts

;---------------------------------------
;
;   DATA
;	
;---------------------------------------


        ; non-indexed data
.ifne keymode
lastdx   .byte $00 ; lastdx command
.endif

dx       .byte $00 ; direction x flag
dy       .byte $00 ; direction y flag
ismoving .byte $00 ; move flag
lastkey  .byte $ff ; last key pressed
music
    .byte $ff
automove
    .byte $01
textptr
    .byte $00
starptr
    .byte $00
bck_starchar
    .byte $00
irqptr
    .byte $00
delaycarousel_cnt
	.byte delaycarousel
textscrptr      ; pointer to screen
    .byte $00
vectaddr
    .word $ffff
dynirq
    .byte $ff
slideshowcntstart
    .byte $9d
scrollspeed_upper
    .byte $01
scrolldelay_upper
    .byte $02
scrollspeed_lower
    .byte $01
scrolldelay_lower
    .byte $01
cur_spr4_flag
    .byte spr_cloud_flgval
cur_spr4_speed
    .byte speed_lcloud
delaysea_cnt
    .byte delaysea
lighttbl
    .byte 10,10,10,40
lightcnt
    .byte 40
lightptr
    .byte 3
delayblinkstar_cnt
    .byte delayblinkstar
benchmark_irq
	.byte 0,0,0,0,0 ; 0 - 4
    .byte 0,0,0,0,0 ; i0 - i4
    
    *=$7900
    
.page   ; indexed data
staroffset
	.byte $01, $02, $04, $08, $10, $20, $40, $80
starposition
	.word screen1+00*40+06,screen1+01*40+25,screen1+02*40+17,screen1+02*40+35
	.word screen1+03*40+31,screen1+04*40+10,screen1+05*40+19,screen1+05*40+29
	.word screen1+06*40+02,screen1+06*40+28,screen1+07*40+15,screen1+08*40+18
;	.word screen1+08*40+32,screen1+08*40+03,screen1+09*40+12,screen1+09*40+23
charpointer
	.byte 0
ramcolourbck
	.byte 0
ramcolour
	.text "  bbhhhjjjqqqjjjhhhbb"
	.text "  eeeccmmmqqqmmmccee"
	.text "  ffkknnnqqqnnnkkff"
	.text "       "
	.byte 0
slideshowtext
    .text "STARRED@MEDIASOFT"
	.byte 0
	.text "NIGHTLY@CITY@DEMO"
    .byte 0
	.text "STARRED"
	.byte 0
	.text "MEDIASOFT"
	.byte 0
	.text "PRESENTS"
	.byte 0

textscroffset
    .word $0452
    .word $04a2
    
    .word $080b
    .word $0859
    .word $08aa
    .word $08fa
.endp

    *=$7a00

.page   ; indexed data

; the below lookup table contains the following data:
; 1. word - next vector address to point in
; 2. byte - rasterline of irq
; 3. byte - step duration, misured in number of occurrences with raster line
lookuptblirq
    .word step_irq_i1  ; STARRED
    .byte $ad
    .byte $01
    .word step_irq_i0  ; DELAY
    .byte $ad
    .byte $9c
    .word step_irq_i1  ; MEDIASOFT
    .byte $ad
    .byte $01
    .word step_irq_i0  ; DELAY
    .byte $ad
    .byte $9c
    .word step_irq_i1  ; PRESENTS
    .byte $ad
    .byte $01
    .word step_irq_i0  ; DELAY
    .byte $ad
    .byte $9c
    .word step_irq_i2 ; BLANK
    .byte $ad
    .byte $01
    .word step_irq_i0  ; DELAY
    .byte $ad
    .byte $5e
    .word step_irq_i3 ; DELAY WITH FLASHING
    .byte $30
    .byte $3c
    .word step_irq_i4 ; INIT LAST SETTINGS
    .byte $30
    .byte $00
endlookuptblirq

.endp

    *=$7b00

.page
scrollingtext
	.text 'HELLO FOLKS! THIS IS A STARRED MEDIASOFT DEMO CALLED NIGHTLY CITY. PRESS FUNCTION KEYS FOR NORMAL (F1), SLOW (F3), FAST SPEED (F5). '
    .text 'PRESS F7 FOR MANUAL CAMERA SCROLL (LEFT / RIGHT JOYSTICK MOVE CAMERA RIGHT). PRESS M FOR SWITCH MUSIC ON / OFF            '
	.byte 0
.endp

;stars_addr = [00*40+06,01*40+25,02*40+17,02*40+35,
;            03*40+31,04*40+10,05*40+19,05*40+29,
;            06*40+02,06*40+28,07*40+15,08*40+18,
;            08*40+32,08*40+03,09*40+12,09*40+23]


;---------------------------------------
;
;   SPRITE DATA
;
;---------------------------------------

    *=sprite_streetlamp_addr
        .byte $00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$10,$00
        .byte $00,$54,$00,$01
        .byte $20,$00,$01,$00,$00,$01
        .byte $00,$00,$01,$00,$00,$01
        .byte $00,$00,$01,$00
        .byte $00,$01,$00,$00,$01,$00
        .byte $00,$01,$00,$00,$01,$00
        .byte $00,$01,$00,$00
        .byte $03,$00,$00,$03,$00,$00
        .byte $03,$00,$00,$05,$c0,$00
        .byte $05,$c0,$00,$87
    
    *=sprite_cloud_addr
        .byte $00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$30
        .byte $fe,$00,$1f,$ff,$f0,$ff
        .byte $87,$e8,$fb,$3f,$fc,$03
        .byte $fe,$3e,$00,$00
        .byte $00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$0b
        
    *=sprite_moon_addr
        .byte $00,$00,$00,$00,$00,$00
        .byte $00,$fc,$00,$03,$ff,$00
        .byte $07,$c7,$80,$0e
        .byte $6d,$c0,$0d,$7c,$c0,$1d
        .byte $72,$e0,$1c,$f3,$e0,$1f
        .byte $df,$e0,$1f,$ff
        .byte $e0,$1f,$fd,$e0,$0f,$fb
        .byte $c0,$0f,$ff,$c0,$07,$ff
        .byte $80,$03,$ff,$00
        .byte $00,$fc,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$0c
        
    *=sprite_airplane_addr        
        .byte $00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00
        .byte $00,$00,$0c,$00
        .byte $0c,$08,$00,$28,$28,$2a
        .byte $aa,$a8,$a6,$66,$a0,$aa
        .byte $aa,$80,$00,$a0
        .byte $00,$00,$2c,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00
        .byte $00,$00,$00,$8b

;---------------------------------------
;
;   ADDRESS DATA
;
;---------------------------------------
	
	*=sidaddr
		.binary "demosong1.sid"
		
	*=charaddr
		.binary "char.bin"
	
	*=mapaddr
		.binary "map.bin"
	
	*=attribsaddr
		.binary "attribs.bin"
	
	*=char2addr
		.binary "chrome.64c",2
	