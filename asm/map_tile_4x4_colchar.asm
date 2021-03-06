;---------------------------------------
;
;   MAP METHOD: TILE 4x4
;   COLOUR METHOD: PER CHAR
;
;---------------------------------------
    *=$0801
.byte $0c, $08, $0a, $00, $9e, $20
.byte $34, $30, $39, $36, $00, $00
.byte $00

    *=$1000

;---------------------------------------
;
;   MAP INFO (VARIABLE)
;
;---------------------------------------

screenaddr = $0400
coloraddr = $d800
    
;---------------------------------------

charaddr = $2000
attribsaddr = $2800
tilesaddr = $3000
mapaddr = $4000

;---------------------------------------

mapwidth = 115
visible_vtiles = 6
visible_htiles = 10

color_transparent = $06
color_bg1 = $0c
color_bg2 = $09

;---------------------------------------

mapdata   = $02
tiledata = $04
colourmem = $26
mappointer = $32
sourcescreen = $34
destscreen = $36

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
;   CODE
;
;---------------------------------------
	       
    jsr $e544
    
    ; irq
    sei
    lda #$7f
    ldx #$01
    sta $dc0d
    sta $dd0d
    stx $d01a
    
    lda #$17
    ldx #$d8
    ldy #$18
    sta $d011
    stx $d016
    sty $d018
    
    lda #<irq
    ldx #>irq
    ldy #$ff
    sta $0314
    stx $0315
    sty $d012
    
    lda $dc0d
    lda $dd0d
    asl $d019    
    ; end irq
    
    ; code
    lda #<mapaddr
    sta mappointer
	lda #>mapaddr
    sta mappointer+1

	lda #$00
	sta sourcescreen
	lda #$04
	sta sourcescreen+1

	lda #color_transparent
	sta $d021
	lda #$00
	sta $d020
	lda #color_bg1
	sta $d022
	lda #color_bg2
	sta $d023
	
	jsr decoderscreen

    jsr decodercolour
    ; end code
    
    cli
    
    jmp *
    
    
irq    
    
    jsr mainloop
    
    asl $d019
    jmp $ea81
	

mainloop
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

	lda dx
	bne movex

	lda dy
	beq nomove
	jmp movey
nomove
	lda #$00
	sta stop
	rts
movex
	lda stop
	beq shiftcol
    rts
    
shiftcol    
	lda #keymode
	sta stop
    
	lda dx
	cmp #$01
	beq right

left
	lda #$00
	sta sourcescreen
	lda #$04
	sta sourcescreen+1

	lda #$01
	sta destscreen
	lda #$04
	sta destscreen+1

	jsr lcopyscreenram

    lda #$00
	sta sourcescreen
	
	lda #$01
	sta destscreen
	
    lda #>coloraddr
	sta sourcescreen+1
    sta destscreen+1
    
	jsr lcopyscreenram

	ldx tilex
	dex
	bpl le1
	lda mappointer
	sec
	sbc #$01
	sta mappointer
	lda mappointer+1
	sbc #$00
	sta mappointer+1
	ldx #$03
le1
	stx tilex

	lda mappointer
	sta mapdata
	lda mappointer+1
	sta mapdata+1

    ldx #>coloraddr
    stx colourmem+1
    
	ldy #$00
	sty sourcescreen
    sty colourmem
	ldx #$04
	stx sourcescreen+1
	
    ; ldy lo-bytescreenleft
	; ldx lo-bytescreenleft
    
	jsr extractcolumn
    
	rts

right

	lda #$01
	sta sourcescreen
	lda #$04
	sta sourcescreen+1

	lda #$00
	sta destscreen
	lda #$04
	sta destscreen+1

	jsr rcopyscreenram

    lda #$01
    sta sourcescreen
    
    lda #$00
	sta destscreen
    
    lda #>coloraddr
    sta sourcescreen+1
    sta destscreen+1

    jsr rcopyscreenram

	lda mappointer
	clc
	adc #visible_htiles
	sta mapdata
	lda mappointer+1
	adc #$00
	sta mapdata+1
    
    ldx #>coloraddr
    stx colourmem+1
    
    ldy #39
	sty sourcescreen
    sty colourmem    
    ldx #$04
    stx sourcescreen+1

    ; ldy lo-bytescreenleft
	; ldx lo-bytescreenleft
    
	jsr extractcolumn   
   
	ldx tilex
	inx
	cpx #$04
	bne ri2
	inc mappointer
	bne *+4
	inc mappointer+1

	ldx #$00
ri2
	stx tilex

	rts
    
    
    
movey
	lda stop
	beq shiftrow
	rts
    
shiftrow
	lda #keymode
	sta stop

	lda dy
	cmp #$01
	beq down
up
    lda #$98
    sta sourcescreen
    
    lda #$c0
    sta destscreen
    
    lda #$07
    sta sourcescreen+1
    sta destscreen+1

    jsr ucopyscreenram

    lda #$98
    sta sourcescreen
    
    lda #$c0
    sta destscreen
    
    lda #$db
    sta sourcescreen+1
    sta destscreen+1

    jsr ucopyscreenram
    
	lda tiley
	bne samemaprow

	lda mappointer
	sec
	sbc #mapwidth
	sta mappointer
	lda mappointer+1
	sbc #$00
	sta mappointer+1
	lda #$10
samemaprow
	sec
	sbc #$04
	sta tiley

	lda mappointer
	sta mapdata
	lda mappointer+1
	sta mapdata+1
    
	lda #<screenaddr
    ldx #>screenaddr+1
    
    ;lda lo-bytescreentop
    ;ldx hi-bytescreentop
    
	jsr extractrow
    
    lda #<screenaddr
    sta sourcescreen
	ldx #>screenaddr+1
    stx sourcescreen+1
    
    lda #<coloraddr
    sta colourmem
    lda #>coloraddr
    sta colourmem+1
    
    jsr extractrowcolor

	rts

down

	lda #$28
	sta sourcescreen
	lda #$04
	sta sourcescreen+1

	lda #$00
	sta destscreen
	lda #$04
	sta destscreen+1

	jsr dcopyscreenram

    lda #$28
	sta sourcescreen	

	lda #$00
	sta destscreen
    
	lda #>coloraddr
    sta sourcescreen+1
	sta destscreen+1

	jsr dcopyscreenram    

	lda mappointer
	sta mapdata
	lda mappointer+1
	sta mapdata+1

	ldx #visible_vtiles
	dex
	stx numbertilesy
dw2
	lda mapdata
	clc
	adc #mapwidth
	sta mapdata
	lda mapdata+1
	adc #$00
	sta mapdata+1
	dex
	bpl dw2

    ;lda lo-bytescreenbotto
    ;ldx hi-bytescreenbotto

	lda #$98
	ldx #$07

	jsr extractrow
    
    lda #$98
    sta colourmem
    lda #$db
    sta colourmem+1
    
    lda #$98
    sta sourcescreen
    lda #$07
    sta sourcescreen+1
            
    jsr extractrowcolor

	lda tiley
	cmp #$0c
	bne dw3
	lda mappointer
	clc
	adc #mapwidth
	sta mappointer
	lda mappointer+1
	adc #$00
	sta mappointer+1
	lda #$fc ; set to 0
dw3
	clc
	adc #$04
	sta tiley

	rts




        
extractcolumn
	
	lda #visible_vtiles
	sta numbertilesy
    
    ; reset with non-zero value
    sta rc21+1
    sta rc22+1    
    sta rc23+1
    
    
    lda tiley
    beq *+5
    inc numbertilesy
    sta tiletmp
    
    ; tiletmp
    ;00 = a0
    ;04 = 78
    ;08 = 50
    ;0c = 28    
    
    lda tiley
	lsr a
    lsr a
    tax
    lda #$00
    clc
rc1
    adc #$28
    inx
    cpx #$04
	bne rc1

    sta rc4+1
    
readcolumn
    ; get tile index
	ldy #$00
	lda (mapdata),y
	and #$0f
	asl a
	asl a
	asl a
	asl a
	sta tiledata
	lda (mapdata),y
	and #$f0
	lsr a
	lsr a
	lsr a
	lsr a
	clc
	adc #>tilesaddr
	sta tiledata+1
    
    ; is the latest vertical tile ?
    dec numbertilesy    
    bne rc2
    
    ; set an exit on latest vertical tile
    lda tiley
    lsr a
    lsr a
    tax
    dex
    stx rc21+1
    dex
    stx rc22+1
    dex
    stx rc23+1  
    
rc2
    ; read / write screen data
    lda tiletmp
    clc
    adc tilex
    sta tiletmp
    tay
    
    lda (tiledata),y
    ldy #$00
    sta (sourcescreen),y
    
    tax
    lda attribsaddr,x
    sta (colourmem),y
rc21    
    lda #$ff ; variable
    beq rc3
    
    lda tiletmp
    clc
    adc #$04    
    tay
    lda (tiledata),y
    ldy #$28
    sta (sourcescreen),y
    
    tax
    lda attribsaddr,x
    sta (colourmem),y
rc22
    lda #$ff ; variable
    beq rc3
    
    lda tiletmp
    clc
    adc #$08
    tay  
    lda (tiledata),y
    ldy #$50
    sta (sourcescreen),y
    
    tax
    lda attribsaddr,x
    sta (colourmem),y
rc23
    lda #$ff ; variable
    beq rc3
    
    lda tiletmp
    clc
    adc #$0c
    tay
    lda (tiledata),y
    ldy #$78
    sta (sourcescreen),y
    
    tax
    lda attribsaddr,x
    sta (colourmem),y
    
rc3    
    lda mapdata		;next map row			
    clc	
    adc #mapwidth
    sta mapdata
    bcc *+4
    inc mapdata+1
    
    lda numbertilesy		; all tiles done?
    beq rc5
    
    lda sourcescreen
    clc
rc4
    adc #$ff    ; variable
    ; update char memory position
    sta sourcescreen
    bcc *+4
    inc sourcescreen+1
    
    ; update colour memory position
    lda colourmem
    clc
    adc rc4+1
    sta colourmem
    bcc *+4
    inc colourmem+1
    
    lda #$00
    sta tiletmp
    lda #$a0
    sta rc4+1
    
    jmp readcolumn
rc5
    rts	
   
    
    

extractrowcolor
    ldy #39
nrc1    
    lda (sourcescreen),y
    tax
    lda attribsaddr,x
    sta (colourmem),y
    dey
    
    lda (sourcescreen),y
    tax
    lda attribsaddr,x
    sta (colourmem),y
    dey
    
    lda (sourcescreen),y
    tax
    lda attribsaddr,x
    sta (colourmem),y
    dey
    
    lda (sourcescreen),y
    tax
    lda attribsaddr,x
    sta (colourmem),y
    dey
    
    lda (sourcescreen),y
    tax
    lda attribsaddr,x
    sta (colourmem),y
    dey
    
    bpl nrc1

    rts
    
decoderscreen
	lda mappointer
	sta mapdata
	lda mappointer+1
    sta mapdata+1
	
	lda #$04
	sta tiley
	lda #$03
	sta tilex

	lda #visible_htiles
	sta numbertilesx

	lda #visible_vtiles
    sta numbertilesy

	lda sourcescreen
	sta printchar+1
	lda sourcescreen+1
	sta printchar+2

readmap
	ldy #$00
	lda (mapdata),y

	and #$0f
	asl a
	asl a
	asl a
	asl a
	sta tiledata
	lda (mapdata),y
	and #$f0
	lsr a
	lsr a
	lsr a
	lsr a
	clc
	adc #>tilesaddr
	sta tiledata+1

	ldx #$03
	ldy tilex
readchar
	lda (tiledata),y
printchar
    sta $ffff,x ; variable
	dey
	dex
	bpl readchar
    
	inc mapdata
	bne *+4
	inc mapdata+1

	lda printchar+1
	clc
	adc #$04
	sta printchar+1
	bcc *+5
	inc printchar+2

	dec numbertilesx
	bne readmap

	lda #visible_htiles
	sta numbertilesx
	lda tilex
	clc
	adc #$04
	sta tilex
	lda mapdata
	sec
	sbc #visible_htiles
	sta mapdata
	bcs *+4
	dec mapdata+1

	dec tiley
	beq *+5
	jmp readmap

	lda #$04
	sta tiley
	lda #$03
	sta tilex
	lda mapdata
	clc
	adc #mapwidth
	sta mapdata
	bcc *+4    
	inc mapdata+1

	dec numbertilesy
	beq *+5
	jmp readmap

	lda #$00
	sta tilex
	sta tiley
    
	rts

    
    
    
decodercolour

    ldx #$00
loop
	ldy screenaddr,x
	lda attribsaddr,y
	sta coloraddr,x
    
    ldy screenaddr+$100,x
    lda attribsaddr,y
	sta coloraddr+$100,x
	
    ldy screenaddr+$200,x
    lda attribsaddr,y
	sta coloraddr+$200,x
	
    ldy screenaddr+$2e8,x
    lda attribsaddr,y
	sta coloraddr+$2e8,x
    
    inx
	bne loop
    
    rts
    
    
 
 
extractrow

    ; set screen end offset
	sta plotrow+1	
	clc
	adc #$28
    sta check+1
	stx plotrow+2            
    
    lda tilex
    sta tiletmp ; first tile starts from tilex
    eor #$03
    tax
    
extract
    ; get tile index
	ldy #$00
	lda (mapdata),y
	and #$0f
	asl a
	asl a
	asl a
	asl a
	sta tiledata
	lda (mapdata),y
	and #$f0
	lsr a
	lsr a
	lsr a
	lsr a
	clc
	adc #>tilesaddr
	sta tiledata+1
    
    lda tiletmp    
    clc
    adc tiley    
    tay    
    
readtile
    ; read tile data
	lda (tiledata),y
plotrow
    ; write tile data
	sta $ffff ; variable
            
	inc plotrow+1
	bne *+5
	inc plotrow+2
    
	lda plotrow+1
check
	cmp #$ff ; variable
	beq ck1
	iny
	dex
	bpl readtile
	inc mapdata
	bne *+4
	inc mapdata+1
    
    ldx #$03
    lda #$00
    sta tiletmp

	beq extract ; branch always
ck1
	rts


    
; shift screen left
rcopyscreenram
	ldx #24
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
	bne rcopyscreenram+4

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
	bpl rcopyscreenram+2

	rts

; shift screen right
lcopyscreenram
	ldx #24
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
	bne lcopyscreenram+4

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
	bpl lcopyscreenram+2

	rts

; shift screen down    
ucopyscreenram
    ldx #24
    ldy #39

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
    cpy #3
    bne ucopyscreenram+4

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

    lda sourcescreen
    sec
    sbc #40
    sta sourcescreen
    bcs *+4
    dec sourcescreen+1
    lda destscreen
    sec
    sbc #40
    sta destscreen
    bcs *+4
    dec destscreen+1
    dex
    bpl ucopyscreenram+2

    rts

; shift screen up
dcopyscreenram
    ldx #24
	ldy #39

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
	cpy #3
	bne dcopyscreenram+4

	lda (sourcescreen),y
	sta (destscreen),y
	dey
	lda (sourcescreen),y
	sta (destscreen),y
	dey
	lda (sourcescreen),y
	sta (destscreen),y
	lda (sourcescreen),y
	sta (destscreen),y
	dey
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
	bpl dcopyscreenram+2

	rts


;---------------------------------------
    
numbertilesx .byte $ff ; tile counter x
numbertilesy .byte $ff ; tile counter y
tilex    .byte $00 ; tile x
tiley    .byte $00 ; tile y
tiletmp  .byte $00 ; tmp variable for computation
dx       .byte $00 ; direction x flag
dy       .byte $00 ; direction y flag
stop     .byte $00 ; stop flag

;---------------------------------------

	*=charaddr
	.binary "../resources/Turrican-L1-3/char.bin"
	
	*=tilesaddr
	.binary "../resources/Turrican-L1-3/tile.bin"
	
	*=mapaddr
	.binary "../resources/Turrican-L1-3/map.bin"
	
	*=attribsaddr
	.binary "../resources/Turrican-L1-3/attribs.bin"