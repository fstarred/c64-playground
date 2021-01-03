;---------------------------------------
;
;   open vertical borders trick
;
;
;
;
;---------------------------------------
; basic loader program
;10 SYS 32768; $0801 = 2049

; $0C $08 = $080C 2-byte pointer to the next line of BASIC code
; $0A = 10; 2-byte line number low byte ($000A = 10)
; $00 = 0 ; 2-byte line number high bye
; $9E = SYS BASIC token
; $20 = [space]
; $32 = "2" , $30 = "0", $34 = "4", $38 = "8", $30 = "0" (ASCII encoded numbers for decimal starting address)
; $0 = end of line
; $00 $00 = 2-byte pointer to the next line of BASIC code ($0000 = end of program)

    *=$0801
	
.byte $0c, $08, $0a, $00, $9e, $20
.byte $32, $30, $34, $38, $30, $00
.byte $00, $00

spr1frames = 6
spr1pointer = 188
spr1animdelay = 5
spr1movcount = 40


sidaddr = $1000-$7e
logoaddr = $2000
spr1addr = spr1pointer * 64

charaddr = $3800
attribsaddr = $4000
mapaddr = $4100


;---------------------------------------


voffset = 40*9
screen1 = $0400+voffset
screen2= $0800+voffset
coloraddr = $d800+voffset

bgrolldelay = 2
scrolldelay = 1
scrollspeed = 1		; 1 or 2

irq_checkinput = 0
irq_buildings_1 = 10
irq_music_line = 95
irq_buildings_2 = 115
;irq_bgroll = 230
;irq_ball_line = 255


num_upper_lines_copy = 7
num_bottom_lines_copy = 7
    
mapwidth = 80 ; 16 bit supported

visiblecharsy = 16
visiblecharsx = 40

color_transparent = $00
color_bg1 = $0c
color_bg2 = $0b

sky_char = 0
star_char = 14
star_char_bytepos = charaddr+(star_char*8)

;---------------------------------------

mapdata   = $02
colourmem = $26
mappointer = $32
sourcescreen = $34
destscreen = $36
mappointerend = $38
screenbase = $3a
screenbuffer = $3c
scrolldelaycnt = $3e
xoffset = $3f
scrflgbuf = $40

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
	
debug = 1

;---------------------------------------
;
;   MACRO
;
;---------------------------------------
	
start_debug	.macro
	.ifne debug
	lda #\1
	sta $d020	
	.endif
	.endm
	
end_debug	.macro
	.ifne debug
	lda #0
	sta $d020	
	.endif
	.endm

create_star .macro

	ldy #1
	ldx #0
loopstar	
	
	lda starposition,x
	clc
	adc screenbase
	sta sourcescreen
	inx
	lda starposition,x
	adc screenbase+1
	sta sourcescreen+1
	cpx #4*2+1
	bmi ls_1
	inc sourcescreen+1
ls_1
	lda (sourcescreen),y
	cmp #sky_char
	bne ls_2
	lda #star_char
	sta (sourcescreen),y
ls_2	
	inx
	cpx #8*2
	bne loopstar

	.endm
	

clear_star_upper_buffer .segment

	ldy #0
	ldx #0
csu_loopstar	
	
	lda starposition,x
	clc
	adc screenbuffer
	sta sourcescreen
	inx
	lda starposition,x
	adc screenbuffer+1
	sta sourcescreen+1
	
	lda (sourcescreen),y
	cmp #star_char
	bne csu_2
	lda #sky_char
	sta (sourcescreen),y
csu_2
	inx
	cpx #4*2
	bne csu_loopstar

	.endm


clear_star_lower_buffer .segment

	ldy #0
	ldx #4*2
csl_loopstar	
	
	lda starposition,x
	clc
	adc screenbuffer
	sta sourcescreen
	inx
	lda starposition,x
	adc screenbuffer+1
	sta sourcescreen+1
	inc sourcescreen+1
	lda (sourcescreen),y
	cmp #star_char
	bne csl_2
	lda #sky_char
	sta (sourcescreen),y
csl_2
	inx
	cpx #8*2
	bne csl_loopstar

	.endm



; VIC-II bank swapping
screenswap .segment

    lda scrflgbuf
    eor #1
    sta scrflgbuf
    bne scrswpalt

	
	lda #$1e
	sta screenmode

	; enable bank $0400

    lda $d018
    and #$0f
    ora #$1e	; %0001 xxxx
    sta $d018

    lda #<screen1
    sta screenbase
    lda #>screen1
    sta screenbase+1

    lda #<screen2
    sta screenbuffer
    lda #>screen2
    sta screenbuffer+1

    jmp exitscrswp

; enable bank $0800
scrswpalt

	lda #$2e
	sta screenmode

    lda $d018
    and #$0f
    ora #$2e	; %0010 xxxx 
    sta $d018

    lda #<screen2
    sta screenbase
    lda #>screen2
    sta screenbase+1

    lda #<screen1
    sta screenbuffer
    lda #>screen1
    sta screenbuffer+1

exitscrswp
    .endm


prepare_extractcolumn .segment

	lda mappointer
	cmp mappointerend
	bne no_rx_limit
	
	lda mappointer+1
	cmp mappointerend+1
	bne no_rx_limit
	
	lda mappointer
	sec
	sbc #<mapwidth
	sta mappointer
	sta mapdata
	lda mappointer+1
	sbc #$00
	sta mappointer+1
	sta mapdata+1
	
no_rx_limit
	lda mappointer
	clc
	adc #$28
	sta mapdata
	lda mappointer+1
	adc #$00
	sta mapdata+1
    
    lda screenbase
	clc
	adc #$27
	sta sourcescreen
    sta colourmem
	bcs pe1
	
	lda screenbase+1
	sta sourcescreen+1
	lda #>coloraddr
	sta colourmem+1
	bcc extractcolumn ; branch always
pe1
	lda screenbase+1
	adc #$00
	sta sourcescreen+1
	lda #>coloraddr
	adc #$01
	sta colourmem+1

extractcolumn
		
	lda #visiblecharsy
	sta currentchary
		
	ldy #$00
ec1	
	lda (mapdata),y
	sta (sourcescreen),y
	
	tax
    lda attribsaddr,x
    sta (colourmem),y
	
	; update colour memory position
	lda mapdata
    clc	
    adc #<mapwidth
    sta mapdata
	lda mapdata+1
	adc #>mapwidth
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
	bne ec1
    
	inc mappointer
	bne *+4
	inc mappointer+1

	.endm

    


screen_shift_upper .segment

    lda screenbase    
    sta sourcescreen
	inc sourcescreen    
    lda screenbase+1
    sta sourcescreen+1    

    lda screenbuffer
	sta destscreen
    lda screenbuffer+1
    sta destscreen+1

    ldx #num_upper_lines_copy
    jsr rcopyscreenram

	.endm

screen_shift_lower .segment

    lda screenbase
    clc 
    adc #<((num_upper_lines_copy+1)*40+1)
    sta sourcescreen
    lda screenbase+1
	adc #>((num_upper_lines_copy+1)*40+1)
    sta sourcescreen+1

    lda screenbuffer
    clc 
    adc #<((num_upper_lines_copy+1)*40)
    sta destscreen
    lda screenbuffer+1
	adc #>((num_upper_lines_copy+1)*40)
    sta destscreen+1
    
    ldx #num_bottom_lines_copy
    jsr rcopyscreenram

    .endm

color_shift_upper .segment

    ; upper section colour
    lda #<coloraddr+1
    sta sourcescreen
    lda #>coloraddr
    sta sourcescreen+1
    
    lda #<coloraddr
    sta destscreen
    lda #>coloraddr
    sta destscreen+1
    
    ldx #num_upper_lines_copy
    jsr rcopyscreenram
    
    .endm
    
color_shift_lower .segment
    ; bottom section colour
    lda #<coloraddr+((num_upper_lines_copy+1)*40+1)
    sta sourcescreen
    lda #>coloraddr+((num_upper_lines_copy+1)*40+1)
    sta sourcescreen+1
    
    lda #<coloraddr+((num_upper_lines_copy+1)*40)
    sta destscreen
    lda #>coloraddr+((num_upper_lines_copy+1)*40)
    sta destscreen+1
    
    ldx #num_bottom_lines_copy
    jsr rcopyscreenram
    
    .endm
    
	
;---------------------------------------
;
;   CODE
;
;---------------------------------------


    *= $5000

	lda #0
	sta $d020  ;border screen color
	sta $d021  ;bgrnd  screen color

    lda #0
    ldx #0	
clearscrcol
    sta $0540,x ; clear last line
	sta $0940,x 
    sta $d940,x
    sta $da40,x
    inx
    bne clearscrcol

    sta $db40   ; clear last 8 col
    sta $db41
    sta $db42
    sta $db43
    sta $db44
    sta $db45
    sta $db46
    sta $db47


loadimage     ; 320 * 64 height
    lda $2a00,x	; charmem data
    sta $0400,x
    lda $2a40,x
    sta $0440,x
    lda $2b40,x	; colormem data
    sta $d800,x
    lda $2b80,x
    sta $d840,x
    inx
    bne loadimage

    ; init sid
    lda #$00
    tax
    tay
    jsr $1000

    sei
	
    ; clear garbage on last char
    lda #$00
    sta $3fff

    lda #spr1pointer
    sta $07f8 ; spr1 pointer ($400)
	sta $0bf8 ; spr1 pointer ($800)
    lda #$01
    sta $d015 ; enable spr1
;    lda #$80
;    sta $d000 ; spr1 x
;    lda #$80
;    sta $d001 ; spr1 y

    lda #$01
    sta $d027 ; spr1 colour 1
    lda #$0c
    sta $d025 ; spr1 colour 2
    lda #$0b
    sta $d026 ; spr1 colour 3

    lda #$00
    sta $d01c ; spr1 multicolor
	
	
    lda #<mapaddr
    sta mappointer
	lda #>mapaddr
    sta mappointer+1
	
	lda #<mapaddr
	clc
	adc #<mapwidth-visiblecharsx
	sta mappointerend
	lda #>mapaddr
	adc #>mapwidth
	sta mappointerend+1
	
	lda #<screen1
    sta screenbase
    lda #>screen1
    sta screenbase+1
    
    lda #<screen2
    sta screenbuffer
    lda #>screen2
    sta screenbuffer+1

	lda #<screen1
	sta sourcescreen
	lda #>screen1
	sta sourcescreen+1

	lda #color_transparent
	sta $d021
	lda #$00
	sta $d020
	lda #color_bg1
	sta $d022
	lda #color_bg2
	sta $d023
	
	; init var
	lda #8-scrollspeed
	sta xoffset
	lda #scrolldelay
	sta scrolldelaycnt
	lda #0
	sta scrflgbuf
	
	jsr decoderscreen
	
	jsr decodercolour

	#create_star
	
	; init irq
	lda #$7f
    ldx #$01
    sta $dc0d
    sta $dd0d
    stx $d01a

    lda #<checkinput_irq
    ldx #>checkinput_irq
    ldy #irq_checkinput

    sta $0314
    stx $0315
    sty $d012

    lda $dc0d
    lda $dd0d
    asl $d019
    cli

    jmp *




music_irq

	lda #<buildings_2_irq
    ldx #>buildings_2_irq
    ldy #irq_buildings_2

    sta $0314
    stx $0315
    sty $d012
	
	#start_debug 3
	
	jsr $1003
	
	#end_debug
	
	asl $d019
    jmp $ea81



checkinput_irq

	lda #<buildings_1_irq
    ldx #>buildings_1_irq
    ldy #irq_buildings_1
    sta $0314
    stx $0315
    sty $d012	

djrr     
    lda $dc00
djrrb    
    ldy #0
	ldx #0
	lsr a
	bcs djr0
	dey
djr0     
    lsr a
	bcs djr1
	iny
djr1     
    lsr a
	bcs djr2
	dex
djr2     
    lsr a
	bcs djr3
	inx
djr3     
    lsr a
	stx dx
	sty dy

exit_checkinput
        
    asl $d019 
    jmp $ea81


buildings_1_irq

    lda #<music_irq
    ldx #>music_irq
    ldy #irq_music_line
    sta $0314
    stx $0315
    sty $d012

	#start_debug 1
	
	; graphics mode
	lda #$18   ; address $2000
    sta $d018
	
    lda #$3b
    sta $d011    ; bitmap

    lda #$d0	; image at a fixed offset
	sta $d016	; multicolor
    ; end graphics mode
	
check_move_1
	lda dx
	bne input_on	
	sta stop
	beq exitirq
input_on	
	; keymode
	lda stop
	bne exitirq	
	lda #keymode
	sta stop	

	dec scrolldelaycnt
    bne exitirq
    	
	lda xoffset
	sec
	sbc #scrollspeed
	sta xoffset
	
	bpl exitirq
    
	lda #8-scrollspeed	; xoffset < 0 ? xoffset = 6 or 7
	sta xoffset
	
	#color_shift_upper	; xoffset 6 or 7 -> shift upper color

exitirq
	
	; roll star char
	
	ldx xoffset
	lda staroffset,x
	sta star_char_bytepos+4

	#end_debug
	
    asl $d019    
    jmp $ea81


buildings_2_irq
    
    lda #<checkinput_irq
    ldx #>checkinput_irq
    ldy #irq_checkinput
	sta $0314
    stx $0315
    sty $d012
	
	#start_debug 5

	; text mode
	lda #$1b
	sta $d011
	
	lda $d016
	and #248
	ora xoffset
	sta $d016	

	lda screenmode
	sta $d018
	; end text mode
	
	lda scrolldelaycnt	; check if movement in progress
    beq rr18
	jmp exitirq2
rr18    	
	ldx #scrolldelay	; reset scroll delay counter
    stx scrolldelaycnt    	

    lda xoffset
    cmp #8-scrollspeed	; xoffset 6 or 7 ->	swap screen
    beq rr19			;					shift lower colors
	jmp rr20			;					extract new columns
rr19	
	#screenswap

	#create_star

    #color_shift_lower
    
	#prepare_extractcolumn	

	jmp exitirq2
	
rr20
	lda xoffset
    cmp #4  ; xoffset 4 -> shift upper screen
    bne rr21
	#screen_shift_upper
	#clear_star_upper_buffer
	jmp exitirq2
rr21
    cmp #2	; xoffset 2 -> shift lower screen
	bne exitirq2

    #screen_shift_lower
	#clear_star_lower_buffer
    
exitirq2

	#end_debug
	
	asl $d019    
    jmp $ea81




;bgroll_irq
;
;	lda #<ball_irq
;    ldx #>ball_irq
;    ldy #irq_ball_line
;	sta $0314
;    stx $0315
;    sty $d012
;	
;	#start_debug 6
;	
;	lda moveflg
;	beq exit_bgroll
;	
;	dec bgrolldelaycnt
;	bne exit_bgroll
;	
;	lda #bgrolldelay
;	sta bgrolldelaycnt
;
;;	ldy #$01	; enable for multi color
;    ldx #$07
;bgroll
;    lda rolling_char_11,x
;    lsr a
;    ror rolling_char_12,x
;    ror rolling_char_11,x
;
;    lda rolling_char_21,x
;    lsr a
;    ror rolling_char_22,x
;    ror rolling_char_21,x
;    dex
;    bpl bgroll
;;	dey
;;	bne bgroll-2
;
;exit_bgroll
;
;	#end_debug
;
;	asl $d019    
;    jmp $ea81

	
	
	
    
    


decoderscreen
	lda mappointer
	sta mapdata
	lda mappointer+1
    sta mapdata+1
	
	lda screenbase
	sta printchar+1
	lda screenbase+1
	sta printchar+2
	
	lda #visiblecharsy	
	sta currentchary

readmap
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
	beq ds1
	
	lda printchar+1
	clc
	adc #$28
	sta printchar+1
	bcc *+5
	inc printchar+2
	
	clc
	lda mapdata
	adc #<mapwidth
	sta mapdata
	lda mapdata+1
	adc #>mapwidth
	sta mapdata+1
	
	bcc readmap ; branch always
	
ds1
	rts

    
dcolor_cnt    .byte visiblecharsy
decodercolour

	lda screenbase
	sta sourcescreen
	lda screenbase+1
	sta sourcescreen+1
	
	lda #<coloraddr
	sta destscreen
	lda #>coloraddr
	sta destscreen+1

dc_1
    ldy #$00

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
	bne dc_1+2
	
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

	dec dcolor_cnt
	bne dc_1
	
    rts
    
    
 
 
    
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

	lda (sourcescreen),y
	sta (destscreen),y
	iny
	lda (sourcescreen),y
	sta (destscreen),y
	iny
	lda (sourcescreen),y
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

	dex
	bpl rcopyscreenram

	rts


;---------------------------------------
;
;	Bits #4-#7: Pointer to screen memory
;
;	$17 = %0001xxxx = $0400
;	$18 = %0010xxxx = $0800
;
;---------------------------------------


	
; DATA	
	

spr1frmcounter
    .byte spr1frames

spr1animdelcnt
    .byte spr1animdelay

spr1pos
    .byte $00


    ;min=255
    ;max=0
    ;count=40
    ;start=0
    ;end=360
    ;amp=100%


spr1move
    .byte $7f,$89,$93,$9e
    .byte $a7,$b1,$ba,$c3
    .byte $cc,$d4,$db,$e2
    .byte $e8,$ed,$f2,$f6
    .byte $f9,$fc,$fe,$fe
    .byte $fe,$fe,$fc,$f9
    .byte $f6,$f2,$ed,$e8
    .byte $e2,$db,$d4,$cc
    .byte $c3,$ba,$b1,$a7
    .byte $9e,$93,$89,$7f
	
	
;spr1data *= spr1addr
;    .byte $00,$69,$00,$02,$aa,$80
;    .byte $0a,$aa,$a0,$2a,$aa,$a8
;    .byte $2b,$aa,$a8,$6f,$ea,$a9
;    .byte $6f,$ea,$a9,$af,$ea,$aa
;    .byte $ab,$aa,$aa,$aa,$aa,$aa
;    .byte $aa,$aa,$aa,$aa,$aa,$aa
;    .byte $aa,$aa,$aa,$6a,$aa,$a9
;    .byte $6a,$aa,$a9,$2a,$aa,$a8
;    .byte $2a,$aa,$a8,$1a,$aa,$a4
;    .byte $0a,$aa,$a0,$02,$aa,$80
;    .byte $00,$69,$00,$81,$00,$69
;    .byte $00,$02,$aa,$80,$0a,$ba
;    .byte $a0,$2a,$fe,$a8,$2a,$fe
;    .byte $a8,$6a,$fe,$a9,$6a,$ba
;    .byte $a9,$aa,$aa,$aa,$aa,$aa
;    .byte $aa,$aa,$aa,$aa,$aa,$aa
;    .byte $aa,$aa,$aa,$aa,$aa,$aa
;    .byte $aa,$6a,$aa,$a9,$6a,$aa
;    .byte $a9,$2a,$aa,$a8,$2a,$aa
;    .byte $a8,$1a,$aa,$a4,$0a,$aa
;    .byte $a0,$02,$aa,$80,$00,$69
;    .byte $00,$81,$00,$69,$00,$02
;    .byte $aa,$80,$0a,$aa,$a0,$2a
;    .byte $aa,$a8,$2a,$aa,$e8,$6a
;    .byte $ab,$f9,$6a,$ab,$f9,$aa
;    .byte $ab,$fa,$aa,$aa,$ea,$aa
;    .byte $aa,$aa,$aa,$aa,$aa,$aa
;    .byte $aa,$aa,$aa,$aa,$aa,$6a
;    .byte $aa,$a9,$6a,$aa,$a9,$2a
;    .byte $aa,$a8,$2a,$aa,$a8,$1a
;    .byte $aa,$a4,$0a,$aa,$a0,$02
;    .byte $aa,$80,$00,$69,$00,$81
;    .byte $00,$69,$00,$02,$aa,$80
;    .byte $0a,$aa,$a0,$2a,$aa,$a8
;    .byte $2a,$aa,$a8,$6a,$aa,$a9
;    .byte $6a,$aa,$a9,$aa,$aa,$aa
;    .byte $aa,$aa,$aa,$aa,$aa,$aa
;    .byte $aa,$aa,$aa,$aa,$aa,$aa
;    .byte $aa,$aa,$ea,$aa,$ab,$fa
;    .byte $6a,$ab,$f9,$6a,$ab,$f9
;    .byte $2a,$aa,$e8,$2a,$aa,$a8
;    .byte $0a,$aa,$a0,$02,$aa,$80
;    .byte $00,$69,$00,$81,$00,$69
;    .byte $00,$02,$aa,$80,$0a,$aa
;    .byte $a0,$2a,$aa,$a8,$2a,$aa
;    .byte $a8,$6a,$aa,$a9,$6a,$aa
;    .byte $a9,$aa,$aa,$aa,$aa,$aa
;    .byte $aa,$aa,$aa,$aa,$aa,$aa
;    .byte $aa,$aa,$aa,$aa,$aa,$aa
;    .byte $aa,$aa,$aa,$aa,$6a,$ba
;    .byte $a9,$6a,$fe,$a9,$2a,$fe
;    .byte $a8,$2a,$fe,$a8,$0a,$ba
;    .byte $a0,$02,$aa,$80,$00,$69
;    .byte $00,$81,$00,$69,$00,$02
;    .byte $aa,$80,$0a,$aa,$a0,$2a
;    .byte $aa,$a8,$2a,$aa,$a8,$6a
;    .byte $aa,$a9,$6a,$aa,$a9,$aa
;    .byte $aa,$aa,$aa,$aa,$aa,$aa
;    .byte $aa,$aa,$aa,$aa,$aa,$aa
;    .byte $aa,$aa,$ab,$aa,$aa,$af
;    .byte $ea,$aa,$6f,$ea,$a9,$6f
;    .byte $ea,$a9,$2b,$aa,$a8,$2a
;    .byte $aa,$a8,$0a,$aa,$a0,$02
;    .byte $aa,$80,$00,$69,$00,$81
			
;---------------------------------------

currentchary	.byte $00 ; char y counter    
dx       .byte $00 ; direction x flag
dy       .byte $00 ; direction y flag
stop     .byte $00 ; stop flag
screenmode .byte $1e
staroffset
	.byte $01, $02, $04, $08, $10, $20, $40, $80
starposition
	.word 00*40+12,01*40+30,03*40+03,05*40+12
	.word 00*40+37,01*40+06,03*40+32,04*40+08
;	.word 00*40+01,01*40+01,02*40+01,03*40+01
;	.word 00*40+25,01*40+25,02*40+25,03*40+25

;---------------------------------------

	*=sidaddr
		.binary "./draft/Demo1/demosong1.sid"
		
	*=spr1addr
		.byte $80
		
	*=logoaddr
		.binary "./draft/Demo1/logo_320_64.prg",2
		
	*=charaddr
		.binary "./draft/Demo1/char.bin"
	
	*=mapaddr
		.binary "./draft/Demo1/map.bin"
	
	*=attribsaddr
		.binary "./draft/Demo1/attribs.bin"
		