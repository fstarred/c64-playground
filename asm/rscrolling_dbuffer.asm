;---------------------------------------
;
;   RIGHT SCROLLING SCREEN EXAMPLE
;   WITH BANK SWAP (DOUBLE BUFFERING)
;	
;	see also: 
;	https://github.com/jeff-1amstudios/c64-smooth-scrolling
;
;---------------------------------------

    *=$0801
.byte $0c, $08, $0a, $00, $9e, $20
.byte $34, $30, $39, $36, $00, $00
.byte $00

    *=$1000

scrolldelay = 1
irqupperline = 65
irqlowerline = 255
    
sourcescreen = $04
destscreen = $06

screen1=$0400
screen2=$0800

    jsr $e544
    jsr draw

    sei
    lda #$7f
    ldx #$01
    sta $dc0d
    sta $dd0d
    stx $d01a

    lda #$1b
    ldx #$c0
    ldy #$17
    sta $d011 ;set text mode
    stx $d016 ;single color 38 cols
    sty $d018 ;screen at $0400        
    
    lda #<screen1
    sta screenbase
    lda #>screen1
    sta screenbase+1
    
    lda #<screen2
    sta screenbuffer
    lda #>screen2
    sta screenbuffer+1
    
    lda #<irq
    ldx #>irq
    ldy #irqupperline
    sta $0314
    stx $0315
    sty $d012

    lda $dc0d
    lda $dd0d
    asl $d019
    cli

    jmp *

    
irq

    lda #<irq2
    ldx #>irq2
    ldy #irqlowerline
    sta $0314
    stx $0315
    sty $d012

    dec scrolldelaycnt
    bne exitirq
    
    lda xoffset
    bne exitirq

    jsr color_shift_upper	; xoffset 0 -> shift upper color
    
exitirq
    asl $d019
        
    jmp $ea81


irq2
    
    lda #<irq
    ldx #>irq
    ldy #irqupperline
    sta $0314
    stx $0315
    sty $d012

    lda scrolldelaycnt
    bne exitirq2
    
    lda #scrolldelay
    sta scrolldelaycnt
    
    dec xoffset
    bmi rr22
    
    lda $d016
    and #248
    ora xoffset
    sta $d016

    lda xoffset

    cmp #6	; xoffset 6 -> get new column data to temp data
    bne rr20
    
    ldy #$00
    jsr copydatacolumntmp
    ldy #$00
    jsr copycolourcolumntmp
    jmp exitirq2
rr20
    cmp #4  ; xoffset 4 -> shift upper screen
    bne rr21
    jsr screen_shift_upper
    jmp exitirq2

rr21
    cmp #2	; xoffset 2 -> shift lower screen
    bne exitirq2
    jsr screen_shift_lower
    jmp exitirq2

rr22
    lda #7	; xoffset 7 -> swap screen
			;			-> shift lower color
			;			-> copy temp data to actual screen
    sta xoffset    
    
    lda $d016
    and #248
    ora xoffset
    sta $d016

    jsr screenswap
    
    jsr color_shift_lower
    
    ldy #39
    jsr copy_tmp_datacolumn

    ldy #39
    jsr copy_tmp_colourcolumn

exitirq2

    asl $d019
    
    jmp $ea81

screen_shift_upper

    lda screenbase    
    sta sourcescreen
    inc sourcescreen    
    lda screenbase+1
    sta sourcescreen+1    

    lda screenbuffer
    sta destscreen
    lda screenbuffer+1
    sta destscreen+1

    ldx #11
    jsr rcopyscreenram


    rts

screen_shift_lower

    lda screenbase
    clc 
    adc #$e1    
    sta sourcescreen
    lda screenbase+1
    sta sourcescreen+1
    inc sourcescreen+1

    lda screenbuffer
    clc 
    adc #$e0
    sta destscreen
    lda screenbuffer+1
    sta destscreen+1
    inc destscreen+1
    
    ldx #12
    jsr rcopyscreenram

    rts

color_shift_upper

    ; upper section colour
    lda #$01
    sta sourcescreen
    lda #$d8
    sta sourcescreen+1
    
    lda #$00
    sta destscreen
    lda #$d8
    sta destscreen+1
    
    ldx #11
    jsr rcopyscreenram
    
    rts
    
color_shift_lower    
    ; bottom section colour
    lda #$e1
    sta sourcescreen
    lda #$d9
    sta sourcescreen+1
    
    lda #$e0
    sta destscreen
    lda #$d9
    sta destscreen+1
    
    ldx #12
    jsr rcopyscreenram
    
    rts

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

    lda (sourcescreen),y
    sta (destscreen),y
    iny
    lda (sourcescreen),y
    sta (destscreen),y
    iny
    lda (sourcescreen),y
    sta (destscreen),y
    iny

    lda sourcescreen
    clc
    adc #40
    sta sourcescreen
    bcc *+4
    inc sourcescreen+1

    lda destscreen
    clc
    adc #40
    sta destscreen
    bcc *+4
    inc destscreen+1

    dex
    bpl rcopyscreenram

    rts


lcopyscreenram
    ldy #38

    lda (sourcescreen),y
    sta (destscreen),y
    dey
    lda (sourcescreen),y
    sta (destscreen),y
    dey
    lda (sourcescreen),y
    sta (destscreen),y
    dey
    lda (sourcescreen),y
    sta (destscreen),y
    dey
    lda (sourcescreen),y
    sta (destscreen),y
    dey
    lda (sourcescreen),y
    sta (destscreen),y
    dey
    cpy #2
    bne lcopyscreenram+2

    lda (sourcescreen),y
    sta (destscreen),y
    dey
    lda (sourcescreen),y
    sta (destscreen),y
    dey
    lda (sourcescreen),y
    sta (destscreen),y

    lda sourcescreen
    clc
    adc #40
    sta sourcescreen
    bcc *+4
    inc sourcescreen+1
    lda destscreen
    clc
    adc #40
    sta destscreen
    bcc *+4
    inc destscreen+1
    dex
    bpl lcopyscreenram

    rts

copydatacolumntmp

    lda screenbase
    sta sourcescreen
    lda screenbase+1
    sta sourcescreen+1

    lda tempaddress
    sta cct2+1
    lda tempaddress+1
    sta cct2+2

    jsr copycolumntmp

    rts

copycolourcolumntmp


    lda #$00
    sta sourcescreen
    lda #$d8
    sta sourcescreen+1

    lda tempaddress+2
    sta cct2+1
    lda tempaddress+3
    sta cct2+2

    jsr copycolumntmp

    rts


copy_tmp_datacolumn


    lda screenbase
    sta sourcescreen
    lda screenbase+1
    sta sourcescreen+1

    lda tempaddress
    sta ctc1+1
    lda tempaddress+1
    sta ctc1+2

    jsr copytmpcolumn

    rts

copy_tmp_colourcolumn


    lda #$00
    sta sourcescreen
    lda #$d8
    sta sourcescreen+1

    lda tempaddress+2
    sta ctc1+1
    lda tempaddress+3
    sta ctc1+2

    jsr copytmpcolumn

    rts

copycolumntmp
    ldx #24
cct1
    lda (sourcescreen),y
cct2
    sta $ffff,x
    lda sourcescreen
    clc
    adc #40
    sta sourcescreen
    bcc *+4
    inc sourcescreen+1

    dex
    bpl cct1
    rts



copytmpcolumn
    ldx #24
ctc1
    lda $ffff,x
    sta (sourcescreen),y
    lda sourcescreen
    clc
    adc #40
    sta sourcescreen
    bcc *+4
    inc sourcescreen+1

    dex
    bpl ctc1
    rts

;---------------------------------------
;
;	Bits #4-#7: Pointer to screen memory
;
;	$17 = %0001xxxx = $0400
;	$18 = %0010xxxx = $0800
;
;---------------------------------------


; VIC-II bank swapping
screenswap

    lda scrflgbuf
    eor #1
    sta scrflgbuf
    bne scrswpalt

	; enable bank $0400

    lda $d018
    and #$0f
    ora #$17
    sta $d018

    lda #$00
    sta screenbase
    lda #$04
    sta screenbase+1

    lda #$00
    sta screenbuffer
    lda #$08
    sta screenbuffer+1

    rts

; enable bank $0800
scrswpalt

    lda $d018
    and #$0f
    ora #$27	; %0010 000 
    sta $d018

    lda #$00
    sta screenbase
    lda #$08
    sta screenbase+1

    lda #$00
    sta screenbuffer
    lda #$04
    sta screenbuffer+1

    rts

    
; prepare screen
draw
    ldx #0
    lda #0
drawloop
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $db00,x
    inx
    txa
    bne drawloop

    rts

    
tmp
tmpe *= tmp+25
tmpcol
tmpcole *= tmpcol+25

tempaddress
    .word tmp,tmpcol

dx  .byte 0
dy  .byte 0
stop .byte 0
xoffset .byte 7
scrflgbuf .byte 0
screenbase .word 0
screenbuffer .word 0
scrolldelaycnt .byte scrolldelay