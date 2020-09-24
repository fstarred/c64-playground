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

charaddr = $2000
attribsaddr = $2800
mapaddr = $2900		; $320	

charaddr2 = $3000
attribsaddr2 = $2d00
mapaddr2 = $2e00	; $0f0

prgcode = $5000

;---------------------------------------

memsetupval1 = $18
memsetupval2 = $1c

voffset = 40*9
screen1 = $0400+voffset
coloraddr = $d800+voffset

voffset2 = 40*19
screen12 = $0400+voffset2
coloraddr2 = $d800+voffset2

scrolldelay = 1
scrollspeed = 1		; 1 or 2

scrolldelay2 = 1
scrollspeed2 = 2

irq_checkinput = 20
irq_buildings_1 = 25
irq_buildings_2 = 80
irq_buildings_3 = 200

num_upper_lines_copy = 10
num_bottom_lines_copy = 6
    
mapwidth1 = 80 ; 16 bit supported
mapwidth2 = 40

visiblecharsy = 10
visiblecharsx = 40

visiblecharsy2 = 6

color_transparent = $06
color_bg1 = $0b
color_bg2 = $07

color_transparent2 = $00
color_bg21 = $0a
color_bg22 = $0b

;---------------------------------------

mapdata   = $02
colourmem = $26
mappointer = $32
sourcescreen = $34
destscreen = $36
mappointerend = $38
screenbase = $3a
scrolldelaycnt = $3e
scrolldelaycnt2 = $3f
xoffset = $40
xoffset2 = $41
charsy = $42
mapwidth = $43 ; 16 bit
mappointerend2 = $45
mappointer2 = $47
screenbase2 = $49
;---------------------------------------
;
;   BEHAVIOUR
;
;---------------------------------------

;0 = KEY DOWN
;1 = KEY PRESS
keymode = 1
	
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


decodercolour .macro

	lda charsy
	sta dcolor_cnt

dc_1
    ldy #$00

	lda (sourcescreen),y
	tax
	lda \1,x
	sta (destscreen),y
    iny
	
	lda (sourcescreen),y
	tax
	lda \1,x
	sta (destscreen),y
    iny
	
	lda (sourcescreen),y
	tax
	lda \1,x
	sta (destscreen),y
    iny
	
	lda (sourcescreen),y
	tax
	lda \1,x
	sta (destscreen),y
    iny
	
	lda (sourcescreen),y
	tax
	lda \1,x
	sta (destscreen),y
    iny
	
	lda (sourcescreen),y
	tax
	lda \1,x
	sta (destscreen),y
    iny
	
	cpy #36
	bne dc_1+2
	
	lda (sourcescreen),y
	tax
	lda \1,x
	sta (destscreen),y
    iny
	
	lda (sourcescreen),y
	tax
	lda \1,x
	sta (destscreen),y
    iny
	
	lda (sourcescreen),y
	tax
	lda \1,x
	sta (destscreen),y
    iny
	
	lda (sourcescreen),y
	tax
	lda \1,x
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
	
    .endm


	
;---------------------------------------
;
;   CODE
;
;---------------------------------------


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
	adc xoffset
	sta $d016
    ldy #memsetupval1
    sty $d018
	
	jsr $e544
	
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
	
	lda #$00
	sta $d020

	; map1 segment
    lda #<mapaddr
    sta mappointer
	lda #>mapaddr
    sta mappointer+1
	
	lda #<mapaddr
	clc
	adc #<mapwidth1-visiblecharsx
	sta mappointerend
	lda #>mapaddr
	adc #>mapwidth1
	sta mappointerend+1
	
	lda #<screen1
    sta screenbase
    lda #>screen1
    sta screenbase+1
    
    lda #<screen1
	sta sourcescreen
	lda #>screen1
	sta sourcescreen+1

	lda #color_transparent
	sta $d021
	lda #color_bg1
	sta $d022
	lda #color_bg2
	sta $d023
	
	lda #8-scrollspeed
	sta xoffset
	lda #scrolldelay
	sta scrolldelaycnt
	
	lda #visiblecharsy
	sta charsy
	lda #<mapwidth1
	sta mapwidth
	lda #>mapwidth1
	sta mapwidth+1
	
	lda mappointer
	sta mapdata
	lda mappointer+1
    sta mapdata+1
	
	lda screenbase
	sta printchar+1
	lda screenbase+1
	sta printchar+2
	
	lda charsy
	sta currentchary

	
	jsr decoderscreen
	
	lda #<coloraddr
	sta destscreen
	lda #>coloraddr
	sta destscreen+1

	lda screenbase
	sta sourcescreen
	lda screenbase+1
	sta sourcescreen+1
	
	#decodercolour attribsaddr

	; map2 segment
    lda #<mapaddr2
    sta mappointer2
	lda #>mapaddr2
    sta mappointer2+1
	
	lda #<mapaddr2
	clc
	adc #<mapwidth2-visiblecharsx
	sta mappointerend2
	lda #>mapaddr2
	adc #>mapwidth2
	sta mappointerend2+1
	
	lda #<screen12
    sta screenbase2
    lda #>screen12
    sta screenbase2+1
    
    lda #<screen12
	sta sourcescreen
	lda #>screen12
	sta sourcescreen+1

	lda #color_transparent2
	sta $d021
	lda #color_bg21
	sta $d022
	lda #color_bg22
	sta $d023
	
	lda #8-scrollspeed2
	sta xoffset2
	lda #scrolldelay2
	sta scrolldelaycnt
	
	lda #visiblecharsy2
	sta charsy
	lda #<mapwidth2
	sta mapwidth
	lda #>mapwidth2
	sta mapwidth+1

	lda mappointer2
	sta mapdata
	lda mappointer2+1
    sta mapdata+1
	
	lda screenbase2
	sta printchar+1
	lda screenbase2+1
	sta printchar+2
	
	lda charsy
	sta currentchary

	jsr decoderscreen

	lda #<coloraddr2
	sta destscreen
	lda #>coloraddr2
	sta destscreen+1	
	
	lda screenbase2
	sta sourcescreen
	lda screenbase2+1
	sta sourcescreen+1	
	
	#decodercolour attribsaddr2
	
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


checkinput_irq

	lda #<buildings_1_irq
    ldx #>buildings_1_irq
    ldy #irq_buildings_1
    sta $0314
    stx $0315
    sty $d012	
	
	#start_debug 1

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

	#end_debug
        
    asl $d019 
    jmp $ea81


buildings_1_irq

    lda #<buildings_2_irq
    ldx #>buildings_2_irq
    ldy #irq_buildings_2
    sta $0314
    stx $0315
    sty $d012

	#start_debug 7
	
	lda #color_transparent
	sta $d021
	lda #color_bg1
	sta $d022
	lda #color_bg2
	sta $d023
	
	lda #memsetupval1
	sta $d018
		
check_move_1
	lda dx
	bne input_on	
	sta stop
	beq choffset
input_on	
	; keymode
	lda stop
	bne choffset	
	lda #keymode
	sta stop	

	dec scrolldelaycnt
    bne choffset
    	
	lda xoffset
	sec
	sbc #scrollspeed
	sta xoffset
	
	bcc exitirq

;	lda #color_transparent
;	sta $d021
;	lda #color_bg1
;	sta $d022
;	lda #color_bg2
;	sta $d023
;	
;	lda #memsetupval1
;	sta $d018
;	
;check_move_1
;	lda dx
;	bne input_on	
;	sta stop
;	beq exitirq
;input_on	
;	; keymode
;	lda stop
;	bne exitirq	
;	lda #keymode
;	sta stop	
;
;	dec scrolldelaycnt
;    bne exitirq
;    	
;	lda xoffset
;	sec
;	sbc #scrollspeed
;	sta xoffset
;	
;	bpl exitirq
;    
;	lda #8-scrollspeed	; xoffset < 0 ? xoffset = 6 or 7
;	sta xoffset
;	
;	jsr uc_screen_shift_upper
;	jsr uc_color_shift_upper	
;	
;	jsr prepare_extractcolumn_upper
;	
choffset

	lda $d016
	and #248
	ora xoffset
	sta $d016

exitirq

	#end_debug
	
    asl $d019    
    jmp $ea81


buildings_2_irq
    
    lda #<buildings_3_irq
    ldx #>buildings_3_irq
    ldy #irq_buildings_3
	sta $0314
    stx $0315
    sty $d012
	
	#start_debug 6
	
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
;	
;	lda scrolldelaycnt	; check if movement in progress
;    beq rr18
;	jmp exitirq2
;rr18    	
;	ldx #scrolldelay	; reset scroll delay counter
;    stx scrolldelaycnt    	
;
;    lda xoffset
;    cmp #8-scrollspeed	; xoffset 6 or 7 ->	swap screen
;    beq rr19			
;	jmp exitirq2		;	extract new columns
;rr19	
;	
exitirq2

	#end_debug
	
	asl $d019    
    jmp $ea81
   
    

buildings_3_irq
    
    lda #<checkinput_irq
    ldx #>checkinput_irq
    ldy #irq_checkinput
	sta $0314
    stx $0315
    sty $d012
	
	#start_debug 4

	lda $d012
	cmp $d012
	beq *-3
	
	lda #memsetupval2
	sta $d018
	
	lda $d016
	and #248
	ora #0
	sta $d016	
	
	lda #color_transparent2
	sta $d021
	lda #color_bg21
	sta $d022
	lda #color_bg22
	sta $d023
tmp0
	lda scrolldelaycnt	; check if movement in progress
    beq rr18
	jmp exitirq3
rr18    	
	ldx #scrolldelay	; reset scroll delay counter
    stx scrolldelaycnt    	

	lda xoffset
	cmp #$ff
	bne exitirq3
    
	lda #8-scrollspeed	; xoffset < 0 ? xoffset = 6 or 7
	sta xoffset
tmp1
	jsr uc_screen_shift_upper
tmp2
	jsr uc_color_shift_upper	
tmp3	
	jsr prepare_extractcolumn_upper


exitirq3
	
	#end_debug
	
	asl $d019    
    jmp $ea81
   
	
uc_screen_shift_upper
	
	.for ue := screen1, ue < (screen1+(num_upper_lines_copy*40)), ue += $01
	lda ue+1
	sta ue
	.next

	rts

uc_screen_shift_lower
	
	.for ue := screen12, ue < (screen12+(num_bottom_lines_copy*40)), ue += $01
	lda ue+1
	sta ue
	.next

	rts


uc_color_shift_upper
	
	.for ue := coloraddr, ue < (coloraddr+(num_upper_lines_copy*40)), ue += $01
	lda ue+1
	sta ue
	.next

	rts

uc_color_shift_lower
	
	.for ue := coloraddr2, ue < (coloraddr2+(num_bottom_lines_copy*40)), ue += $01
	lda ue+1
	sta ue
	.next

	rts


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
	;adc #<mapwidth1
	adc mapwidth
	sta mapdata
	lda mapdata+1
	;adc #>mapwidth1
	adc mapwidth+1
	sta mapdata+1
	
	bcc decoderscreen ; branch always
exit_ds
	rts



prepare_extractcolumn_upper

	lda mappointer
	cmp mappointerend
	bne no_rx_limit
	
	lda mappointer+1
	cmp mappointerend+1
	bne no_rx_limit
	
	lda mappointer
	sec
	sbc #<mapwidth1
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
    adc #<mapwidth1
    sta mapdata
	lda mapdata+1
	adc #>mapwidth1
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

	rts
	
;---------------------------------------
dcolor_cnt   	.byte $00
currentchary	.byte $00    
dx       .byte $00 ; direction x flag
dy       .byte $00 ; direction y flag
stop     .byte $00 ; stop flag

;---------------------------------------

	*=charaddr
		.binary "./draft/Demo2/char.bin"
	
	*=mapaddr
		.binary "./draft/Demo2/map.bin"
	
	*=attribsaddr
		.binary "./draft/Demo2/attribs.bin"
	
	*=charaddr2
		.binary "./draft/Demo2/char2.bin"
	
	*=mapaddr2
		.binary "./draft/Demo2/map2.bin"
	
	*=attribsaddr2
		.binary "./draft/Demo2/attribs2.bin"
	