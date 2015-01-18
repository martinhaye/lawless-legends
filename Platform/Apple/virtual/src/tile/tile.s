;@com.wudsn.ide.asm.hardware=APPLE2
; Tile routines
; ------------------
;     
 * = $6000

; Use hi-bit ASCII for Apple II
!convtab "../include/hiBitAscii.ct"

; Global definitions
!source "../include/global.i"
!source "../include/mem.i"
!source "../include/plasma.i"

DEBUG       = 1     ; 1=some logging, 2=lots of logging

HEADER_LENGTH=6
SECTION_WIDTH=22
SECTION_HEIGHT=23
VIEWPORT_WIDTH=9
VIEWPORT_HEIGHT=8
VIEWPORT_VERT_PAD=4 ; This is the distance between the center of the viewport and the top/bottom
VIEWPORT_HORIZ_PAD=4 ; This is the distance between the center of the viewport and the left/right

;--------------
;  0 1 2 3 4 5 6 7 8 9
;0           .\
;1           . |_ VERT PAD
;2           . |
;3           ./
;4           X . . . .
;5            \_____/
;6               |
;7              HORIZ PAD
;8
;9

MAX_MAP_ID=254  ; This means that the total map area can be as big as 5588x5842 tiles!

REL_X=$50   ; Will always be in the range 0-43
REL_Y=$51   ; Will always be in the range 0-45
; Map quadrant data pointers (Maybe move these to screen holes in 2078-207f?  There might be no advantage to using ZP for these)
NW_MAP_LOC=$52
NE_MAP_LOC=$54
SW_MAP_LOC=$56
SE_MAP_LOC=$58
NW_TILESET_LOC=$70
NE_TILESET_LOC=$72
SW_TILESET_LOC=$74
SE_TILESET_LOC=$76
; Map section IDs (255 = not loaded)
NOT_LOADED=$FF
NW_MAP_ID=$5A
NE_MAP_ID=$5B   
SW_MAP_ID=$5C
SE_MAP_ID=$5D

NORTH   =0
EAST    =1
SOUTH   =2
WEST    =3

;-- Variables used in drawing which can not be changed by the inner drawing loop
DRAW_X_START    = $5E   ; Starting column being drawn (between 0 and VIEWPORT_WIDTH)
DRAW_Y_START    = $5F   ; Starting row being drawn (between 0 and VIEWPORT_WIDTH)
DRAW_WIDTH      = $62   ; Number of columns to draw for current section (cannot be destroyed by drawing loop)
DRAW_HEIGHT     = $63   ; Number of rows to draw for current section (cannot be destroyed by drawing loop)
DRAW_SECTION    = $64   ; Location of section data being drawn
TILE_BASE       = $6B   ; Location of tile data
;-- These variables are set in the outer draw section but can be destroyed by the inner routine
SECTION_X_START = $60   ; X Offset relative to current section being drawn 
SECTION_Y_START = $61   ; Y Offset relative to current section being drawn 
X_COUNTER       = $66   ; Loop counter used during drawing
Y_COUNTER       = $67   ; Loop counter used during drawing
Y_LOC           = $68   ; Current row being drawn (between 0 and VIEWPORT_WIDTH)
ROW_LOCATION    = $69   ; Used for pointing at row offset in map data
TILE_SOURCE     = $6D   ; Location of tile data

;----------------------------------------------------------------------
; Vectors used to call in from the outside.
	jmp INIT
	jmp DRAW
	jmp CROSS

; Debug support -- must come after jump vectors, since it's not just macros.
!source "../include/debug.i"

;----------------------------------------------------------------------
; >> START LOADING MAP SECTIONS
START_MAP_LOAD
	LDX #0
	LDA #START_LOAD
	JMP mainLoader
!macro startLoad {
	JSR START_MAP_LOAD
}

;----------------------------------------------------------------------
; >> LOAD MAP SECTION
;   Section number is in A
;   Returns location of loaded data (Y = hi, X = lo)
;   First 6 bytes are header information
;   0 Resource ID of next map section (north), FF = none
;   1 Resource ID of next map section (east), FF = none
;   2 Resource ID of next map section (south), FF = none
;   3 Resource ID of next map section (west), FF = none
;   4 Tileset resource id
;   5 Resource ID of script library (FF = none)
LOAD_SECTION
	CMP #$FF
	BNE .doLoad
	LDX #00     ; This is a bogus map section, don't load
	LDY #00
	RTS
.doLoad     TAY     ; resource # in Y
	LDX #RES_TYPE_2D_MAP
	LDA #QUEUE_LOAD
	JMP mainLoader
!macro loadSection ptr {
	JSR LOAD_SECTION
	STX ptr 
	STY ptr+1
}

;----------------------------------------------------------------------
; >> FINISH LOADING MAP SECTIONS
FINISH_MAP_LOAD
	LDX #0      ; 1 to keep open for next load, 0 for close so you can flip to HGR page 2
	LDA #FINISH_LOAD
	JMP mainLoader
!macro finishLoad {
	JSR FINISH_MAP_LOAD
}

;----------------------------------------------------------------------
; >> RELEASE MAP SECTION OR TILESET
!macro freeResource ptr {
    ; --> free up unused resource
	LDX ptr
	LDY ptr+1
	LDA #FREE_MEMORY
	JSR mainLoader
}
;----------------------------------------------------------------------
; >> LOAD TILES
;   Load tile resource (A = Resource ID)
LOAD_TILESET
	TAY
	LDX #RES_TYPE_TILESET
	LDA #QUEUE_LOAD
	JMP mainLoader
!macro loadTileset mapData, ptr {
	LDY #4
	LDA (mapData),Y
	JSR LOAD_TILESET
	STX ptr
	STY ptr+1
}
;----------------------------------------------------------------------
; >> MOVE NORTH
;   Check for boundary
;   If none, check for map boundary
;       If so, move to bottom of next map
;   If not at boundary
;       Move up one row
;       Check to see if viewport is crossing section boundary;          
;   Does new location have a script assigned?
;       execute script
;----------------------------------------------------------------------
; >> MOVE EAST
;   (same as move north, might be able to overlap functionality)
;----------------------------------------------------------------------
; >> MOVE SOUTH
;   (same as move north, might be able to overlap functionality)
;----------------------------------------------------------------------
; >> MOVE WEST
;   (same as move north, might be able to overlap functionality)
;----------------------------------------------------------------------
; >> GET TILE IN CARDINAL DIRECTION AND FLAGS 
;   (Returns Tile # in Y, Flags in A)
;   Each tile in memory can be 0-64, the flags are the upper 3 bits
;   0 0 0
;   | | `- Script assigned, triggers script lookup
;   | `--- Boundary (Can not walk on it)
;   `----- Visible obstruction (Can not see behind it)
;----------------------------------------------------------------------
; >> SET X,Y COORDINATES FOR VIEWPORT CENTER
SET_XY
	STX REL_X
	STY REL_Y
	RTS
;----------------------------------------------------------------------
; >> TRIGGER SCRIPT AT TILE (X,Y = Coordinates in section)
;----------------------------------------------------------------------
!macro move_word from, to {
	+move_byte from, to
	+move_byte from+1, to+1
}

!macro move_byte from, to {
	LDX from
	STX to
}

FREE_ALL_TILES
	+freeResource NW_TILESET_LOC
	+freeResource NE_TILESET_LOC
	+freeResource SW_TILESET_LOC
	+freeResource SE_TILESET_LOC
	RTS     
!macro freeAllTiles {
	JSR FREE_ALL_TILES
}

LOAD_ALL_TILES
	+loadTileset NW_MAP_LOC, NW_TILESET_LOC
	+loadTileset NE_MAP_LOC, NW_TILESET_LOC
	+loadTileset SW_MAP_LOC, NW_TILESET_LOC
	+loadTileset SE_MAP_LOC, NW_TILESET_LOC
	RTS
!macro loadAllTiles {
	JSR LOAD_ALL_TILES
}

; >> CHECK CROSSINGS
!zone
CROSS
	LDA REL_Y
	CMP #VIEWPORT_VERT_PAD-1
	BPL .10
	JSR CROSS_NORTH
.10	LDA REL_Y
	CMP #VIEWPORT_VERT_PAD+SECTION_HEIGHT
	BMI .20
	JSR CROSS_SOUTH
.20	LDA REL_X
	CMP #VIEWPORT_HORZ_PAD-1
	BPL .30
	JSR CROSS_WEST
.30	LDA REL_X
	CMP #VIEWPORT_HORZ_PAD+SECTION_WIDTH
	BMI .40
	JSR CROSS_EAST
.40	RTS

; >> CROSS NORTH BOUNDARY (Load next section to the north)
!zone
CROSS_NORTH
	+freeAllTiles
	+freeResource SW_MAP_LOC
	+freeResource SE_MAP_LOC
	LDA REL_Y
	CLC
	ADC #SECTION_HEIGHT
	STA REL_Y
	+move_byte NW_MAP_ID, SW_MAP_ID
	+move_word NW_MAP_LOC, SW_MAP_LOC
	+move_byte NE_MAP_ID, SE_MAP_ID
	+move_word NE_MAP_LOC, SE_MAP_LOC
	; Get new NW section
	+startLoad
	LDY #00
	LDA (SW_MAP_LOC),Y
	STA NW_MAP_ID
	+loadSection NW_MAP_LOC
	; Get the new NE section
	LDA (SE_MAP_LOC),Y
	STA NE_MAP_ID
	+loadSection NE_MAP_LOC
	+loadAllTiles
	+finishLoad
	RTS
;----------------------------------------------------------------------
; >> CROSS EAST BOUNDARY (Load next section to the east)
!zone
CROSS_EAST
	+freeAllTiles
	+freeResource NW_MAP_LOC
	+freeResource SW_MAP_LOC
	LDA REL_X
	SEC
	SBC #SECTION_WIDTH
	STA REL_X
	+move_byte NE_MAP_ID, NW_MAP_ID
	+move_word NE_MAP_LOC, NW_MAP_LOC
	+move_byte SE_MAP_ID, SW_MAP_ID
	+move_word SE_MAP_LOC, SW_MAP_LOC
	; Get new NE section
	+startLoad
	LDY #EAST
	LDA (NW_MAP_LOC),Y
	STA NE_MAP_ID
	+loadSection NE_MAP_LOC
	; Get the new SE section
	LDY #EAST
	LDA (SW_MAP_LOC),Y
	STA SE_MAP_ID
	+loadSection SE_MAP_LOC
	+loadAllTiles
	+finishLoad
	RTS
;----------------------------------------------------------------------
; >> CROSS SOUTH BOUNDARY (Load next section to the south)
!zone
CROSS_SOUTH
	+freeAllTiles
	+freeResource NW_MAP_LOC
	+freeResource NE_MAP_LOC
	LDA REL_Y
	SEC
	SBC #SECTION_HEIGHT
	STA REL_Y
	+move_byte SW_MAP_ID, NW_MAP_ID
	+move_word SW_MAP_LOC, NW_MAP_LOC
	+move_byte SE_MAP_ID, NE_MAP_ID
	+move_word SE_MAP_LOC, NE_MAP_LOC
	; Get new SW section
	+startLoad
	LDY #SOUTH
	LDA (NW_MAP_LOC),Y
	STA SW_MAP_ID
	+loadSection SW_MAP_LOC
	; Get the new SE section
	LDY #SOUTH
	LDA (NE_MAP_LOC),Y
	STA SE_MAP_ID
	+loadSection SE_MAP_LOC
	+loadAllTiles
	+finishLoad
	RTS
;----------------------------------------------------------------------
; >> CROSS WEST BOUNDARY (load next section to the west)
!zone
CROSS_WEST
	+freeAllTiles
	+freeResource NE_MAP_LOC
	+freeResource SE_MAP_LOC
	LDA REL_X
	CLC
	ADC #SECTION_WIDTH
	STA REL_X
	+move_byte NW_MAP_ID, NE_MAP_ID
	+move_word NW_MAP_LOC, NE_MAP_LOC
	+move_byte SW_MAP_ID, SE_MAP_ID
	+move_word SW_MAP_LOC, SE_MAP_LOC
	; Get new NW section
	+startLoad
	LDY #WEST
	LDA (NE_MAP_LOC),Y
	STA NW_MAP_ID
	+loadSection NW_MAP_LOC
	; Get the new SE section
	LDY #WEST
	LDA (SE_MAP_LOC),Y
	STA SW_MAP_ID
	+loadSection SW_MAP_LOC
	+loadAllTiles
	+finishLoad
	RTS
;----------------------------------------------------------------------
; >> SET PLAYER TILE (A = tile)
;----------------------------------------------------------------------
; >> SET NPC TILE (A = tile, X,Y = coordinates in section)
;----------------------------------------------------------------------
; >> DRAW
!zone draw
!macro drawMapSection mapPtr, tilesetPtr, deltaX, deltaY {
    ; Determine X1 and X2 bounds for what is being drawn
	LDA REL_X
	SEC
	SBC #(deltaX+VIEWPORT_HORIZ_PAD)
	TAX
	BPL .10
	LDA #0
.10     STA SECTION_X_START
	TXA
	CLC
	ADC #VIEWPORT_WIDTH
	CMP #SECTION_WIDTH
	BMI .11
	LDA #SECTION_WIDTH
.11     
	SEC
	SBC SECTION_X_START
	STA DRAW_WIDTH
	BMI .30
    ; Determine Y1 and Y2 bounds for what is being drawn
	LDA REL_Y
	SEC
	SBC #(deltaY+VIEWPORT_VERT_PAD)
	TAX
	BPL .20
	LDA #0
.20     STA SECTION_Y_START
	TXA
	CLC
	ADC #VIEWPORT_HEIGHT
	CMP #SECTION_HEIGHT
	BMI .21
	LDA #SECTION_HEIGHT
.21
	SEC
	SBC SECTION_Y_START
	STA DRAW_HEIGHT
	BMI .30
	+move_word mapPtr, DRAW_SECTION
	+move_word tilesetPtr, TILE_BASE
	JSR MainDraw
.30
}

DRAW
; For each quadrant, display relevant parts of screen
!if DEBUG { +prStr : !text "In draw.",0 }
.checkNWQuad
	LDA #00
	STA DRAW_Y_START
	STA DRAW_X_START
	+drawMapSection NW_MAP_LOC, NW_TILESET_LOC, 0, 0
.checkNEQuad
	LDA DRAW_WIDTH
	STA DRAW_X_START
	+drawMapSection NE_MAP_LOC, NE_TILESET_LOC, SECTION_WIDTH, 0
.checkSWQuad
	LDA DRAW_HEIGHT
	STA DRAW_Y_START
	LDA #00
	STA DRAW_X_START
	+drawMapSection SW_MAP_LOC, SW_TILESET_LOC, 0, SECTION_HEIGHT
.checkSEQuad
	LDA DRAW_WIDTH
	STA DRAW_X_START
	+drawMapSection SE_MAP_LOC, SE_TILESET_LOC, SECTION_WIDTH, SECTION_HEIGHT
!if DEBUG { +prStr : !text "Draw complete.",0 }
	RTS

MainDraw
;----- Tracking visible tile data -----
;There are a total of 512 screen holes in a hires page located in xx78-xx7F and xxF8-xxFF
;We only need 81 screen holes to track the 9x9 visible area.  So to do this a little translation is needed
;      78  79  7a  7b  7c  7d  7e  7f  f8 
;2000   
;2100  
;2200  
; .
; .
;2800
;
; The calculation goes like this:  Page + $78 + (Row * $100) + (Col & 7) + ((Col & 8) << 4)
; When the display is drawn, the screen hole is compared to see if there is a different tile to draw 
; and if there is not then the tile is skipped.  Otherwise the tile is drawn, etc.
;--------------------------------------

COL_OFFSET = 2
ROW_OFFSET = 3

	LDA DRAW_SECTION+1	; skip if no map section here
	BNE .gotMap
	RTS
.gotMap

!if DEBUG >= 1 {
	+prStr : !text "SECTION_X_START=",0
	+prByte SECTION_X_START
	+prStr : !text "DRAW_WIDTH=", 0
	+prByte DRAW_WIDTH
	+prStr : !text "SECTION_Y_START=",0
	+prByte SECTION_Y_START
	+prStr : !text "DRAW_HEIGHT=", 0
	+prByte DRAW_HEIGHT
	+crout
}
	LDA DRAW_HEIGHT
	STA Y_COUNTER
	LDA DRAW_Y_START
	STA Y_LOC
.rowLoop        
; Identify start of map data (upper left)
	; Self-modifying code: Update all the STA statements in the drawTile section
	LDA Y_LOC
	ASL		; double because each tile is two rows high
	TAY
	LDA tblHGRl+ROW_OFFSET, Y
	CLC
	ADC #COL_OFFSET
	TAX
	INX
	!for store, 16 {
	    STA .drawTile+((store-1)*12)+3
	    STX .drawTile+((store-1)*12)+9
	    !if store = 8 {
		LDA tblHGRl+ROW_OFFSET+1, Y
		CLC
		ADC #COL_OFFSET
		TAX
		INX
	    }
	}
	LDA tblHGRh+ROW_OFFSET, Y
	!for store, 16 {
	    STA .drawTile+((store-1)*12)+4
	    STA .drawTile+((store-1)*12)+10
	    !if store = 8 {
		LDA tblHGRh+ROW_OFFSET+1, Y
	    } else {
		; We have to calculate the start of the next row but only if we are not already at the last row
		!if store < 16 {
		    adc #$04
		}
	    }
	}

;Calculate data offset == DRAW_SECTION + (row * 22) + 6 == DRAW_SECTION + (row * 2 + row * 4 + row * 16) + 6
	CLC
	LDA SECTION_Y_START ;row * 2
	ASL
	ADC #HEADER_LENGTH  ; +6
	ADC SECTION_X_START
	STA ROW_LOCATION
	LDA SECTION_Y_START ; row * 4
	ASL
	ASL
	ADC ROW_LOCATION
	STA ROW_LOCATION
	LDA SECTION_Y_START ; row * 16 -- possibly carry
	ASL
	ASL
	ASL
	ASL
	ADC ROW_LOCATION
	STA ROW_LOCATION        
	LDA DRAW_SECTION + 1
	ADC #$00    ; This is a short way for handling carry without a branch
	STA ROW_LOCATION + 1
	LDA DRAW_SECTION  ; DRAW_SECTION is done at the very end in case it causes an overflow
	ADC ROW_LOCATION
	STA ROW_LOCATION
	; Handle carry if needed
	BCC .doneCalculatingLocation
	INC ROW_LOCATION + 1
.doneCalculatingLocation
	LDA DRAW_WIDTH
	STA X_COUNTER
	LDX DRAW_X_START        
; Display row of tiles
.next_col
; Get tile
	TXA
	TAY
	LDA (ROW_LOCATION), Y
	; Calculate location of tile data == tile_base + ((tile & 31) * 16)
	AND #31
	ASL
	ASL
	ASL
	ASL
	STA TILE_SOURCE
	LDA TILE_BASE + 1
	ADC #$00
	STA TILE_SOURCE+1
	LDA TILE_BASE
	ADC TILE_SOURCE
	STA TILE_SOURCE
	BCC .doneCalculatingTileLocation
	INC TILE_SOURCE+1
.doneCalculatingTileLocation
;   Is there a NPC there?
;     No, use map tile
;     Yes, use NPC tile
; Compare tile to last-drawn tile
; Skip if no change
; Is this the first time we are drawing this row?
;   -- It is, update the draw pointers
; If tile is different then redraw
;   -- unrolled loop for 16 rows at a time
	    LDY #$00
	    TXA ; In the drawing part, we need X=X*2
	    ASL
	    TAX
!if DEBUG >= 2 {
	+prStr : !text "Draw at ",0
	+prX
	+crout
	+waitKey
}
.drawTile   !for row, 16 {
		LDA (TILE_SOURCE),Y	;0
		STA $2000, X    	;2
		INY                 	;5
		LDA (TILE_SOURCE),Y 	;6
		STA $2000, X		;8
		!if row < 16 {
		    INY			;11
		}
	    }
	    DEC X_COUNTER
	    BEQ .next_row
	    TXA ; Outside the drawing part we need to put X back (divide by 2)
	    LSR
	    TAX
	    INX
	    JMP .next_col
; Increment row
.next_row
	DEC Y_COUNTER
	BNE .notDone
	RTS
.notDone
	INC Y_LOC
	INC SECTION_Y_START
	JMP .rowLoop
; Draw player


;----------------------------------------------------------------------
; >> INIT (reset map drawing vars, load initial map in A)
INIT
	; load the NW map section first
	STA NW_MAP_ID
	+startLoad
	LDA NW_MAP_ID
	+loadSection NW_MAP_LOC
	+finishLoad
	+startLoad
	; from the NW section we can get the ID of the NE section
	LDY #EAST
	LDA (NW_MAP_LOC),Y
	STA NE_MAP_ID
	+loadSection NE_MAP_LOC
	; from the NW section we can get the ID of the SW section
	LDY #SOUTH
	LDA (NW_MAP_LOC),Y
	STA SW_MAP_ID
	+loadSection SW_MAP_LOC
	+finishLoad
	+startLoad
	; if there's no SW section, there's also no SE section
	LDA #$FF
	STA SE_MAP_ID
	CMP SW_MAP_ID
	BEQ +
	; get the SE section from the SW section
	LDY #EAST
	LDA (SW_MAP_LOC),Y
	STA SE_MAP_ID
	+loadSection SE_MAP_LOC
+       +loadAllTiles
	+finishLoad
	; set up the X and Y coordinates
	LDX #VIEWPORT_HORIZ_PAD
	LDY #VIEWPORT_VERT_PAD
	JSR SET_XY
	RTS

tblHGRl     
	!byte   $00,$80,$00,$80,$00,$80,$00,$80
	!byte   $28,$A8,$28,$A8,$28,$A8,$28,$A8
	!byte   $50,$D0,$50,$D0,$50,$D0,$50,$D0

tblHGRh 
	!byte   $20,$20,$21,$21,$22,$22,$23,$23
	!byte   $20,$20,$21,$21,$22,$22,$23,$23
	!byte   $20,$20,$21,$21,$22,$22,$23,$23