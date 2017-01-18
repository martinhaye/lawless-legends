;license:BSD-3-Clause
;extended open/read/write binary file in ProDOS filesystem, with random access
;copyright (c) Peter Ferrie 2013-17

!cpu 6502
*=$4000

;place no code before init label below.

                ;user-defined options
                verbose_info = 0        ;set to 1 to enable display of memory usage
                enable_floppy = 1       ;set to 1 to enable floppy drive support
                poll_drive   = 1        ;set to 1 to check if disk is in drive
                override_adr = 1        ;set to 1 to require an explicit load address
                aligned_read = 0        ;set to 1 if all reads can be a multiple of block size
                enable_write = 1        ;set to 1 to enable write support
                                        ;file must exist already and its size cannot be altered
                                        ;writes occur in multiples of block size (256 bytes for floppy, 512 bytes for HDD)
                enable_seek  = 1        ;set to 1 to enable seek support
                allow_multi  = 1        ;set to 1 to allow multiple floppies
                check_chksum = 1        ;set to 1 to enforce checksum verification for floppies
                allow_subdir = 0        ;set to 1 to allow opening subdirectories to access files
                might_exist  = 1        ;set to 1 if file is not known to always exist already
                                        ;makes use of status to indicate success or failure
                allow_aux    = 1        ;set to 1 to allow read/write directly to/from aux memory
                                        ;requires load_high to be set for arbitrary memory access
                                        ;else driver must be running from same memory target
                                        ;i.e. running from main if accessing main, running from aux if accessing aux
                allow_trees  = 1        ;enable support for tree files, as opposed to only seedlings and saplings
                                        ;requires an additional 512 bytes of RAM
                bounds_check = 0        ;set to 1 to prevent access beyond the end of the file
                                        ;but limits file size to 64k-2 bytes.
                load_high    = 0        ;set to 1 to load to top of RAM (either main or banked, enables a himem check)
                load_aux     = 1        ;load to aux memory
                load_banked  = 1        ;set to 1 to load into banked RAM instead of main RAM (can be combined with load_aux for aux banked)
                lc_bank      = 1        ;load into specified bank (1 or 2) if load_banked=1

                ;user-defined driver load address
!if load_banked = 1 {
  !if load_high = 1 {
    !ifdef PASS2 {
    } else { ;PASS2
                reloc     = $fb00       ;page-aligned, as high as possible, the ideal value will be shown on mismatch
    } ;PASS2
  } else { ;load_high
                reloc     = $d000       ;page-aligned, but otherwise wherever you want
  } ;load_high
} else { ;load_banked
  !if load_high = 1 {
    !ifdef PASS2 {
    } else { ;PASS2
                reloc     = $bf00       ;page-aligned, as high as possible, the ideal value will be shown on mismatch
    } ;PASS2
  } else { ;load_high
                reloc     = $1000       ;page-aligned, but otherwise wherever you want
  } ;load_high
} ;load_banked

                ;there are also buffers that can be moved if necessary:
                ;dirbuf, encbuf, treebuf (and corresponding hdd* versions that load to the same place)
                ;they are independent of each other so they can be placed separately
                ;see near EOF for those

                ;zpage usage, arbitrary selection except for the "ProDOS constant" ones
                ;feel free to move them around

!if (might_exist + poll_drive) > 0 {
                status    = $3          ;returns non-zero on error
} ;might_exist or poll_drive
!if allow_aux = 1 {
                auxreq    = $a          ;set to 1 to read/write aux memory, else main memory is used
} ;allow_aux
                sizelo    = $6          ;set if enable_write=1 and writing, or reading, or if enable_seek=1 and seeking
                sizehi    = $7          ;set if enable_write=1 and writing, or reading, or if enable_seek=1 and seeking
!if (enable_write + enable_seek + allow_multi) > 0 {
                reqcmd    = $2          ;set (read/write/seek) if enable_write=1 or enable_seek=1
                                        ;if allow_multi=1, bit 7 selects floppy drive in current slot (clear=drive 1, set=drive 2) during open call
                                        ;bit 7 must be clear for read/write/seek on opened file
} ;enable_write or enable_seek or allow_multi
                ldrlo     = $E          ;set to load address if override_adr=1
                ldrhi     = $F          ;set to load address if override_adr=1
                namlo     = $C          ;name of file to access
                namhi     = $D          ;name of file to access

!if enable_floppy = 1 {
                tmpsec    = $15         ;(internal) sector number read from disk
                reqsec    = $16         ;(internal) requested sector number
                curtrk    = $17         ;(internal) track number read from disk
} ;enable_floppy

                command   = $42         ;ProDOS constant
                unit      = $43         ;ProDOS constant
                adrlo     = $44         ;ProDOS constant
                adrhi     = $45         ;ProDOS constant
                bloklo    = $46         ;ProDOS constant
                blokhi    = $47         ;ProDOS constant

!if allow_trees = 1 {
                treeidx   = $13         ;(internal) index into tree block
                istree    = $14         ;(internal) flag to indicate tree file
} ;allow_trees
                entries   = $18         ;(internal) total number of entries in directory
!if bounds_check = 1 {
                bleftlo   = $1b         ;(internal) bytes left in file
                blefthi   = $1c         ;(internal) bytes left in file
} ;bounds_check
                blkofflo  = $19         ;(internal) offset within cache block
                blkoffhi  = $1a         ;(internal) offset within cache block
!if enable_floppy = 1 {
                step      = $1d         ;(internal) state for stepper motor
                tmptrk    = $1e         ;(internal) temporary copy of current track
                phase     = $1f         ;(internal) current phase for seek
} ;enable_floppy

                ;constants
                cmdseek   = 0           ;requires enable_seek=1
                cmdread   = 1           ;requires enable_write=1
                cmdwrite  = 2           ;requires enable_write=1
                SETKBD    = $fe89
                SETVID    = $fe93
                DEVNUM    = $bf30
                PHASEOFF  = $c080
                MOTOROFF  = $c088
                MOTORON   = $c089
                DRV0EN    = $c08a
                Q6L       = $c08c
                Q6H       = $c08d
                Q7L       = $c08e
                Q7H       = $c08f
                MLI       = $bf00
                NAME_LENGTH = $4        ;ProDOS constant
                MASK_SUBDIR = $d0       ;ProDOS constant
                MASK_ALL    = $f0       ;ProDOS constant
                KEY_POINTER = $11       ;ProDOS constant
                EOF_LO    = $15         ;ProDOS constant
                EOF_HI    = $16         ;ProDOS constant
                AUX_TYPE  = $1f         ;ProDOS constant
                ENTRY_SIZE = $27        ;ProDOS constant
                NEXT_BLOCK_LO = $2      ;ProDOS constant
                NEXT_BLOCK_HI = $3      ;ProDOS constant
                SAPLING   = $20         ;ProDOS constant
                FILE_COUNT = $25        ;ProDOS constant
                ROMIN     = $c081
                LCBANK2   = $c089
                CLRAUXRD  = $c002
                CLRAUXWR  = $c004
                SETAUXWR  = $c005
                CLRAUXZP  = $c008
                SETAUXZP  = $c009

init            jsr SETVID
                jsr SETKBD
                lda DEVNUM
                sta x80_parms + 1
                sta unrunit + 1
                and #$70
!if (enable_floppy + enable_write) > 1 {
                sta unrslot1 + 1
                sta unrslot2 + 1
                sta unrslot3 + 1
                sta unrslot4 + 1
} ;enable_floppy and enable_write
                pha
!if enable_floppy = 1 {
                ora #<PHASEOFF
                sta unrseek + 1
                ora #<MOTOROFF
  !if might_exist = 1 {
                sta unrdrvoff1 + 1
  } ;might_exist
                sta unrdrvoff2 + 1
                tax
                inx ;MOTORON
  !if poll_drive = 1 {
                stx unrdrvon1 + 1
  } ;poll_drive
                stx unrdrvon2 + 1
                inx ;DRV0EN
  !if allow_multi = 1 {
                stx unrdrvsel + 1
  } ;allow_multi
                inx
                inx ;Q6L
                stx unrread1 + 1
  !if poll_drive = 1 {
                stx unrread2 + 1
  } ;poll_drive
                stx unrread4 + 1
                stx unrread5 + 1
  !if check_chksum = 1 {
                stx unrread6 + 1
  } ;check_chksum
} ;enable_floppy
                ldx #1
                stx namlo
                inx
                stx namhi

                ;fetch path, if any

                jsr MLI
                !byte $c7
                !word c7_parms
                ldx $200
                dex
                stx sizelo
                bmi +++

                ;find current directory name in directory

readblock       jsr MLI
                !byte $80
                !word x80_parms

                lda #<(readbuff + NAME_LENGTH)
                sta bloklo
                lda #>(readbuff + NAME_LENGTH)
                sta blokhi
inextent        ldy #0
                lda (bloklo), y
                pha
                and #MASK_SUBDIR

                ;watch for subdirectory entries

                cmp #MASK_SUBDIR
                bne +

                lda (bloklo), y
                and #$0f
                tax
                iny
--              lda (bloklo), y
                cmp (namlo), y
                beq ifoundname

                ;match failed, move to next directory in this block, if possible

-
+               pla
                clc
                lda bloklo
                adc #ENTRY_SIZE
                sta bloklo
                bcc +

                ;there can be only one page crossed, so we can increment instead of adc

                inc blokhi
+               cmp #<(readbuff + $1ff) ;4 + ($27 * $0d)
                lda blokhi
                sbc #>(readbuff + $1ff)
                bcc inextent

                ;read next directory block when we reach the end of this block

                lda readbuff + NEXT_BLOCK_LO
                ldx readbuff + NEXT_BLOCK_HI
                bcs +

ifoundname      iny
                dex
                bne --

                ;parse path until last directory is seen

                lda (namlo), y
                cmp #'/'
                bne -
                tya
                eor #$ff
                adc sizelo
                sta sizelo
                clc
                tya
                adc namlo
                sta namlo
                pla
                and #$20                ;Volume Directory Header XOR subdirectory
                bne ++

                ;cache block number of current directory
                ;as starting position for subsequent searches

                ldy #(KEY_POINTER + 1)
                lda (bloklo), y
                tax
                dey
                lda (bloklo), y
!if enable_floppy = 1 {
                sta unrblocklo + 1
                stx unrblockhi + 1
} ;enable_floppy
                sta unrhddblocklo + 1
                stx unrhddblockhi + 1
+               sta x80_parms + 4
                stx x80_parms + 5
++              lda sizelo
                bne readblock

                ;unit to slot for SmartPort interface

+++             pla
                lsr
                lsr
                lsr
                tax
                lsr
                ora #$c0
                ldy $bf11, x
                cpy #$c8                ;max slot+1
                bcs set_slot
                tya
set_slot        sta slot + 2
                sta unrentry + 2
  !if load_banked = 1 {
                lda LCBANK2 - ((lc_bank - 1) * 8)
                lda LCBANK2 - ((lc_bank - 1) * 8)
  } ;load_banked
  !if load_aux = 1 {
                sta SETAUXWR + (load_banked * 4) ;SETAUXWR or SETAUXZP
  } ;load_aux
!if enable_floppy = 1 {
                ldx #>unrelocdsk
                ldy #<unrelocdsk
slot            lda $cfff
                sta unrentry + 1
                php
                beq copydrv
                ldx #>unrelochdd
                ldy #<unrelochdd

copydrv         stx blokhi
                sty bloklo
                ldx #>((codeend - rdwrpart) + $ff)
                ldy #0
-               lda (bloklo), y
reladr          sta reloc, y
                iny
                bne -
                inc blokhi
                inc reladr + 2
                dex
                bne -
                plp
                bne ++

                ;build 6-and-2 denibbilisation table

                ldx #$16
--              stx bloklo
                txa
                asl
                bit bloklo
                beq +
                ora bloklo
                eor #$ff
                and #$7e
-               bcs +
                lsr
                bne -
                tya
                sta nibtbl - $16, x
  !if enable_write = 1 {
                ;and 6-and-2 nibbilisation table if writing

                txa
                ora #$80
                sta xlattbl, y
  } ;enable_write
                iny
+               inx
                bpl --
++
} else { ;enable_floppy
slot            lda $cfff
                sta unrentry + 1
                ldy #0
-               lda unrelochdd, y
                sta reloc, y

                ;hack to avoid address overflow when load_high and load_banked
                ;and code is less than two pages long (e.g. aligned_read, no write)
                ;can't insert code during pass two because it breaks existing offsets

  !ifdef PASS2 {
    !if >(hddcodeend - reloc) > 0 {
      !set hack=$100
    } ;hddcodeend
  } else { ;PASS2
    !set hack=0
  } ;PASS2
                lda unrelochdd + hack, y
                sta reloc + hack, y
                iny
                bne -
} ;enable_floppy
  !if load_aux = 1 {
                sta CLRAUXWR + (load_banked * 4) ;CLRAUXWR or CLRAUXZP
  } ;load_aux
                rts

c7_parms        !byte 1
                !word $200

x80_parms       !byte 3, $d1
                !word readbuff, 2

!if enable_floppy = 1 {
unrelocdsk
!pseudopc reloc {
!if override_adr = 1 {
                ;only available when load address is specified

rdwrpart        jmp rdwrfile
} ;override_adr
                ;read volume directory key block
                ;self-modified by init code

opendir
unrblocklo = unrelocdsk + (* - reloc)
                ldx #2
unrblockhi = unrelocdsk + (* - reloc)
                lda #0
                jsr readdirsel

                ;include volume directory header in count

readdir
  !if might_exist = 1 {
                ldx dirbuf + FILE_COUNT ;assuming only 256 files per subdirectory
                inx
                stx entries
  } ;might_exist

firstent        lda #<(dirbuf + NAME_LENGTH)
                sta bloklo
                lda #>(dirbuf + NAME_LENGTH)
                sta blokhi

nextent         ldy #0
  !if might_exist = 1 {
                sty status
  } ;might_exist
                lda (bloklo), y
  !if might_exist = 1 {
                ;skip deleted entries without counting

                and #MASK_ALL
                beq ++
  } ;might_exist

                ;remember type

                ;now bits 5-4 are represented by carry (subdirectory), sign (sapling)

savetype
                asl
                asl

                ;now bits 5-3 are represented by carry (subdirectory), sign (sapling),
                ;overflow (seedling), and sign+overflow (tree)

    !if allow_trees = 1 {
                sta treeidx
                bit treeidx
    } ;allow_trees
                php

                ;match name lengths before attempting to match names

                lda (bloklo), y
                and #$0f
                tax
                inx
                !byte $2c       ;mask lda, y on first pass
-               lda (bloklo), y
                cmp (namlo), y
                beq foundname

                ;match failed, check if any directory entries remain

                plp
+
  !if might_exist = 1 {
                dec entries
                bne ++
  } ;might_exist
  !if (might_exist + poll_drive) > 0 {
nodisk
unrdrvoff1=unrelocdsk+(*-reloc)
                lda MOTOROFF
                inc status
                rts
  } ;might_exist or poll_drive

                ;move to next directory in this block, if possible

++              clc
                lda bloklo
                adc #ENTRY_SIZE
                sta bloklo
                bcc +

                ;there can be only one page crossed, so we can increment instead of adc

                inc blokhi
+               cmp #<(dirbuf + $1ff) ;4 + ($27 * $0d)
                lda blokhi
                sbc #>(dirbuf + $1ff)
                bcc nextent

                ;read next directory block when we reach the end of this block

                ldx dirbuf + NEXT_BLOCK_LO
                lda dirbuf + NEXT_BLOCK_HI
                jsr readdirsec
                bne firstent

foundname       iny
                dex
                bne -
  !if allow_trees = 1 {
                stx treeidx
                stx istree
  } ;allow_trees
                stx entries
                stx blkofflo
                stx blkoffhi

  !if enable_write = 1 {
                ldy reqcmd
                cpy #cmdwrite           ;control carry instead of zero
                bne +

                ;round requested size up to nearest block if writing

    !if aligned_read = 0 {
                php
    } ;aligned_read
                lda sizelo
                ldx sizehi
                jsr round
                sta sizehi
    !if aligned_read = 0 {
                plp
    } ;aligned_read
+
  } ;enable_write

  !if bounds_check = 1 {
                ;cache EOF (file size, loaded backwards)

                ldy #EOF_HI
                lda (bloklo), y
    !if (enable_write + aligned_read) > 0 {
                tax
    } else { ;enable_write or aligned_read
                sta blefthi
    } ;enable_write or aligned_read
                dey                     ;EOF_LO
                lda (bloklo), y
    !if (enable_write + aligned_read) > 0 {

                ;round file size up to nearest sector if writing without aligned reads
                ;or nearest block if using aligned reads

      !if aligned_read = 0 {
                bcc +
      } ;aligned_read

                jsr round
                tax
                lda #0
      !if aligned_read = 0 {
                sta sizelo
      } ;aligned_read
+               stx blefthi
    } ;enable_write or aligned_read
    !if aligned_read = 0 {
                sta bleftlo
    } ;aligned_read
  } else { ;bounds_check
    !if enable_write = 1 {
      !if aligned_read = 0 {
                bcc +
                lda #0
                sta sizelo
+
      } ;aligned_read
    } ;enable_write
  } ;bounds_check
                ;cache AUX_TYPE (load offset for binary files)

  !if override_adr = 0 {
                pla
                tax
                ldy #AUX_TYPE
                lda (bloklo), y
                pha
                iny
                lda (bloklo), y
                pha
                txa
                pha
  } ;override_adr

                ;cache KEY_POINTER

                ldy #KEY_POINTER
                lda (bloklo), y
                tax
                sta dirbuf
                iny
                lda (bloklo), y
                sta dirbuf + 256

                ;read index block in case of sapling

                plp
  !if (allow_subdir + allow_trees) > 0 {
                bpl rdwrfile
    !if allow_subdir = 1 {
                php
    } ;allow_subdir
    !if allow_trees = 1 {
                ldy #>dirbuf
                bvc +
                ldy #>treebuf
                sty istree
+
    } ;allow_trees
                jsr readdirsect
    !if allow_subdir = 1 {
                plp
    } ;allow_subdir
  } ;allow_subdir

                ;restore load offset

rdwrfile
  !if override_adr = 1 {
                ldx ldrhi
                lda ldrlo
  } else { ;override_adr
                pla
                tax
                pla
  } ;override_adr

  !if allow_subdir = 1 {
                ;check file type and fake size and load address for subdirectories

                bcc +
                ldy #2
                sty sizehi
                ldx #>dirbuf
                lda #<dirbuf
+
  } ;allow_subdir
                sta adrlo
                stx adrhi

                ;set requested size to min(length, requested size)

  !if aligned_read = 0 {
    !if bounds_check = 1 {
                lda bleftlo
                tay
                cmp sizelo
                lda blefthi
                tax
                sbc sizehi
                bcs copyblock
                sty sizelo
                stx sizehi
    } ;bounds_check

copyblock
    !if (enable_write + enable_seek) > 0 {
                ldy reqcmd
                ;cpy #cmdseek
                beq +
    } ;enable_write or enable_seek

    !if allow_aux = 1 {
                ldx auxreq
                jsr setaux
    } ;allow_aux
    !if (enable_write + enable_seek) > 0 {
                dey ;cpy #cmdread
      !if enable_write = 1 {
                bne rdwrloop
      } ;enable_write
    } ;enable_write or enable_seek
+
                lda blkofflo
                tax
                ora blkoffhi
                beq rdwrloop
                lda sizehi
                pha
                lda sizelo
                pha
                lda adrhi
                sta blokhi
                lda adrlo
                sta bloklo
                stx adrlo
                lda #>encbuf
                clc
                adc blkoffhi
                sta adrhi

                ;determine bytes left in block

      !if (enable_write + enable_seek) > 0 {
                tya
      } else { ;enable_write or enable_seek
                lda #0
      } ;enable_write or enable_seek
                sec
                sbc blkofflo
                tay
                lda #2
                sbc blkoffhi
                tax

                ;set requested size to min(bytes left, requested size)

                cpy sizelo
                sbc sizehi
                bcs +
                sty sizelo
                stx sizehi
+
                lda sizehi
                jsr copycache
                lda ldrlo
                adc sizelo
                sta ldrlo
                lda ldrhi
                adc sizehi
                sta ldrhi
                sec
                pla
                sbc sizelo
                sta sizelo
                pla
                sbc sizehi
                sta sizehi
                ora sizelo
                bne rdwrfile
                beq rdwrdone
  } else { ;aligned_read
    !if bounds_check = 1 {
                lda blefthi
                cmp sizehi
                bcs +
                sta sizehi
+
    } ;bounds_check
    !if allow_aux = 1 {
                ldx auxreq
                jsr setaux
    } ;allow_aux
  } ;aligned_read

rdwrloop
  !if (enable_write + enable_seek) > 0 {
                ldx reqcmd
  } ;enable_write or enable_seek
  !if aligned_read = 0 {

                ;set read/write size to min(length, $200)

                lda sizehi
                cmp #2
                bcs +
                pha
                lda #2
                sta sizehi

                ;redirect read to private buffer for partial copy

                lda adrhi
                pha
                lda adrlo
                pha
                lda #>encbuf
                sta adrhi
                lda #0
                sta adrlo
    !if (enable_write + enable_seek) > 0 {
                ldx #cmdread
    } ;enable_write or enable_seek
+
  } ;aligned_read

  !if allow_trees = 1 {
                ;read tree data block only if tree and not read already
                ;the indication of having read already is that at least one sapling/seed block entry has been read, too

                ldy entries
                bne +
                lda istree
                beq +
                lda adrhi
                pha
                lda adrlo
                pha
                lda #>dirbuf
                sta adrhi
                lda #0
                sta adrlo
                txa
                pha
                lda #cmdread
                sta command

                ;fetch tree data block and read it

                ldy treeidx
                inc treeidx
                ldx treebuf, y
                lda treebuf + 256, y
    !if aligned_read = 0 {
                php
    } ;aligned_read
                jsr seekrdwr
    !if aligned_read = 0 {
                plp
    } ;aligned_read
                pla
                tax
                pla
                sta adrlo
                pla
                sta adrhi
  } ;allow_trees

                ;fetch data block and read/write it

                ldy entries
+               inc entries
  !if enable_seek = 1 {
                txa ;cpx #cmdseek, but that would require php at top
                beq +
  } ;enable_seek
                stx command
                ldx dirbuf, y
                lda dirbuf + 256, y
  !if aligned_read = 0 {
                php
  } ;aligned_read
                jsr seekrdwr
  !if aligned_read = 0 {
                plp
+               bcc +
  } ;aligned_read
  !if bounds_check = 1 {
                dec blefthi
                dec blefthi
  } ;bounds_check
+               dec sizehi
                dec sizehi
                bne rdwrloop

unrdrvoff2 = unrelocdsk + (* - reloc)
                lda MOTOROFF
  !if aligned_read = 0 {
                bcc +
                lda sizelo
                bne rdwrloop
  } ;aligned_read
rdwrdone
  !if allow_aux = 1 {
                ldx #0
setaux          sta CLRAUXRD, x
                sta CLRAUXWR, x
  } ;allow_aux
                rts

  !if aligned_read = 0 {
                ;cache partial block offset

+               pla
                sta bloklo
                pla
                sta blokhi
                pla
                sta sizehi
                dec adrhi
                dec adrhi

copycache
    !if enable_seek = 1 {
                ldy reqcmd
                ;cpy #cmdseek
                beq ++
    } ;enable_seek
                tay
                beq +
                dey
-               lda (adrlo), y
                sta (bloklo), y
                iny
                bne -
                inc blokhi
                inc adrhi
                bne +
-               lda (adrlo), y
                sta (bloklo), y
                iny
+               cpy sizelo
                bne -
++
    !if bounds_check = 1 {
                lda bleftlo
                sec
                sbc sizelo
                sta bleftlo
                lda blefthi
                sbc sizehi
                sta blefthi
    } ;bounds_check
                clc
                lda blkofflo
                adc sizelo
                sta blkofflo
                lda blkoffhi
                adc sizehi
                and #$fd
                sta blkoffhi
                bcc rdwrdone            ;always
  } ;aligned_read

  !if (enable_write + (bounds_check & aligned_read)) > 0 {
round           clc
                adc #$ff
                txa
                adc #1
                and #$fe
                rts
  } ;enable_write or (bounds_check and aligned_read)

                ;no tricks here, just the regular stuff

seek            sty step
                asl phase
                txa
                asl
copy_cur        tax
                sta tmptrk
                sec
                sbc phase
                beq +++
                bcs +
                eor #$ff
                inx
                bcc ++
+               sbc #1
                dex
++              cmp step
                bcc +
                lda step
+               cmp #8
                bcs +
                tay
                sec
+               txa
                pha
                ldx step1, y
+++             php
                bne +
---             clc
                lda tmptrk
                ldx step2, y
+               stx tmpsec
                and #3
                rol
                tax
                lsr
unrseek = unrelocdsk + (* - reloc)
                lda PHASEOFF, x
--              ldx #$13
-               dex
                bne -
                dec tmpsec
                bne --
                bcs ---
                plp
                beq seekret
                pla
                inc step
                bne copy_cur

step1           !byte 1, $30, $28, $24, $20, $1e, $1d, $1c
step2           !byte $70, $2c, $26, $22, $1f, $1e, $1d, $1c

readadr
-               jsr readd5aa
                cmp #$96
                bne -
                ldy #3
-               sta curtrk
                jsr readnib
                rol
                sta tmpsec
                jsr readnib
                and tmpsec
                dey
                bne -
seekret         rts

readd5aa
--              jsr readnib
-               cmp #$d5
                bne --
                jsr readnib
                cmp #$aa
                bne -
                tay                    ;we need Y=#$AA later

readnib
unrread1 = unrelocdsk + (* - reloc)
-               lda Q6L
                bpl -
                rts

  !if poll_drive = 1 {
checkpoll       bcc pollinv            ;it's enough to cover an entire sector
failpoll        pla
                pla
                pla
                jmp nodisk
  } ;poll_drive

readdirsel      ldy #0
                sty adrlo

  !if allow_multi = 1 {
                asl reqcmd
                bcc seldrive
                iny
seldrive        lsr reqcmd
unrdrvsel = unrelocdsk + (* - reloc)
                cmp DRV0EN, y
  } ;allow_multi
  !if poll_drive = 1 {
                sty status
                pha
unrdrvon1 = unrelocdsk + (* - reloc)
                ldy MOTORON
                clc                     ;mark pass 1
                !byte $24               ;mask sec
pollinv         sec                     ;mark pass 2

                ;watch for a real data prolog

--              inc status
                beq checkpoll           ;loop max 510 times as worst-case
                ldy #(prolog_e - prolog - 1)

unrread2 = unrelocdsk + (* - reloc)
-               lda Q6L
                bpl -
                eor prolog,y
                bne --
                dey
                bpl -
                pla
  } ;poll_drive

readdirsec
!if allow_trees = 0 {
readdirsect
} ;allow_trees
                ldy #>dirbuf
!if allow_trees = 1 {
readdirsect
} ;allow_trees
                sty adrhi
                ldy #cmdread
                sty command

                ;convert block number to track/sector

seekrdwr
unrdrvon2 = unrelocdsk + (* - reloc)
                ldy MOTORON
                lsr
                txa
                ror
                lsr
                lsr
                sta phase
                txa
                and #3
                php
                asl
                plp
                rol
                sta reqsec
                jsr readadr

                ;if track does not match, then seek

                ldx curtrk
                cpx phase
                beq checksec
                jsr seek

                ;force sector mismatch

                lda #$ff

                ;match or read/write sector

checksec        jsr cmpsec
                inc reqsec
                inc reqsec

                ;force sector mismatch

cmpsecrd        lda #$ff

cmpsec
  !if enable_write = 1 {
                ldy command
                cpy #cmdwrite           ;we need Y=2 below
                beq encsec
  } ;enable_write
cmpsec2         cmp reqsec
                beq readdata
                jsr readadr
                beq cmpsec2

                ;read sector data

readdata        jsr readd5aa
                eor #$ad                ;zero A if match
;;                bne *                   ;lock if read failure
unrread4 = unrelocdsk + (* - reloc)
-               ldx Q6L
                bpl -
                eor nibtbl - $96, x
                sta bit2tbl - $aa, y
                iny
                bne -
unrread5 = unrelocdsk + (* - reloc)
-               ldx Q6L
                bpl -
                eor nibtbl - $96, x
                sta (adrlo), y          ;the real address
                iny
  !if check_chksum = 1 {
                bne -
unrread6 = unrelocdsk + (* - reloc)
-               ldx Q6L
                bpl -
                eor nibtbl - $96, x
                bne cmpsecrd
  } ;check_chksum
--              ldx #$a9
-               inx
                beq --
                lda (adrlo), y
                lsr bit2tbl - $aa, x
                rol
                lsr bit2tbl - $aa, x
                rol
                sta (adrlo), y
                iny
                bne -
readret         inc adrhi
                rts

  !if enable_write = 1 {
encsec
--              ldx #$aa
-               dey
                lda (adrlo), y
                lsr
                rol bit2tbl - $aa, x
                lsr
                rol bit2tbl - $aa, x
                sta encbuf, y
                lda bit2tbl - $aa, x
                and #$3f
                sta bit2tbl - $aa, x
                inx
                bne -
                tya
                bne --

cmpsecwr        jsr readadr
                cmp reqsec
                bne cmpsecwr

                ;skip tail #$DE #$AA #$EB some #$FFs ...

                ldy #$24
-               dey
                bpl -

                ;write sector data

unrslot1 = unrelocdsk + (* - reloc)
                ldx #$d1
                lda Q6H, x             ;prime drive
                lda Q7L, x             ;required by Unidisk
                tya
                sta Q7H, x
                ora Q6L, x

                ;40 cycles

                ldy #4                 ;2 cycles
                cmp $ea                ;3 cycles
                cmp ($ea, x)           ;6 cycles
-               jsr writenib1          ;(29 cycles)

                                       ;+6 cycles
                dey                    ;2 cycles
                bne -                  ;3 cycles if taken, 2 if not

                ;36 cycles
                                       ;+10 cycles
                ldy #(prolog_e - prolog)
                                       ;2 cycles
                cmp $ea                ;3 cycles
-               lda prolog - 1, y      ;4 cycles
                jsr writenib3          ;(17 cycles)

                ;32 cycles if branch taken
                                       ;+6 cycles
                dey                    ;2 cycles
                bne -                  ;3 cycles if taken, 2 if not

                ;36 cycles on first pass
                                       ;+10 cycles
                tya                    ;2 cycles
                ldy #$56               ;2 cycles
-               eor bit2tbl - 1, y     ;5 cycles
                tax                    ;2 cycles
                lda xlattbl, x         ;4 cycles
unrslot2 = unrelocdsk + (* - reloc)
                ldx #$d1               ;2 cycles
                sta Q6H, x             ;5 cycles
                lda Q6L, x             ;4 cycles

                ;32 cycles if branch taken

                lda bit2tbl - 1, y     ;5 cycles
                dey                    ;2 cycles
                bne -                  ;3 cycles if taken, 2 if not

                ;32 cycles
                                       ;+9 cycles
                clc                    ;2 cycles
--              eor encbuf, y          ;4 cycles
-               tax                    ;2 cycles
                lda xlattbl, x         ;4 cycles
unrslot3 = unrelocdsk + (* - reloc)
                ldx #$d1               ;2 cycles
                sta Q6H, x             ;5 cycles
                lda Q6L, x             ;4 cycles
                bcs +                  ;3 cycles if taken, 2 if not

                ;32 cycles if branch taken

                lda encbuf, y          ;4 cycles
                iny                    ;2 cycles
                bne --                 ;3 cycles if taken, 2 if not

                ;32 cycles
                                       ;+10 cycles
                sec                    ;2 cycles
                bcs -                  ;3 cycles

                ;32 cycles
                                       ;+3 cycles
+               ldy #(epilog_e - epilog)
                                       ;2 cycles
                cmp ($ea, x)           ;6 cycles
-               lda epilog - 1, y      ;4 cycles
                jsr writenib3          ;(17 cycles)

                ;32 cycles if branch taken
                                       ;+6 cycles
                dey                    ;2 cycles
                bne -                  ;3 cycles if branch taken, 2 if not

                lda Q7L, x
                lda Q6L, x             ;flush final value
                inc adrhi
                rts

writenib1       cmp ($ea, x)           ;6 cycles
writenib2       cmp ($ea, x)           ;6 cycles
writenib3
unrslot4=unrelocdsk+(*-reloc)
                ldx #$d1               ;2 cycles
writenib4       sta Q6H, x             ;5 cycles
                ora Q6L, x             ;4 cycles
                rts                    ;6 cycles

prolog          !byte $ad, $aa, $d5
prolog_e
epilog          !byte $ff, $eb, $aa, $de
epilog_e
  } ;enable_write
codeend
bit2tbl         = (* + 255) & -256
nibtbl          = bit2tbl + 86
  !if enable_write = 1 {
xlattbl         = nibtbl + 106
dataend         = xlattbl + 64
  } else { ;enable_write
dataend         = nibtbl + 106
  } ;enable_write
} ;enable_floppy
} ;reloc

unrelochdd
!pseudopc reloc {
!if override_adr = 1 {
hddrdwrpart     jmp hddrdwrfile
} ;override_adr
                ;read volume directory key block
                ;self-modified by init code

hddopendir
unrhddblocklo = unrelochdd + (* - reloc)
                ldx #2
unrhddblockhi = unrelochdd + (* - reloc)
                lda #0
                jsr hddreaddirsel

!if enable_floppy = 1 {
  !if (* - hddopendir) < (readdir - opendir) {
                ;essential padding to match offset with floppy version
    !fill (readdir - opendir) - (* - hddopendir), $ea
  }
} ;enable_floppy

                ;include volume directory header in count

hddreaddir
  !if might_exist = 1 {
                ldx hdddirbuf + FILE_COUNT ;assuming only 256 files per subdirectory
                inx
                stx entries
  } ;might_exist

hddfirstent     lda #<(hdddirbuf + NAME_LENGTH)
                sta bloklo
                lda #>(hdddirbuf + NAME_LENGTH)
                sta blokhi

hddnextent      ldy #0
  !if might_exist = 1 {
                sty status
  } ;might_exist
                lda (bloklo), y
  !if might_exist = 1 {
                ;skip deleted entries without counting

                and #MASK_ALL
                beq ++
  } ;might_exist

                ;remember type

                ;now bits 5-4 are represented by carry (subdirectory), sign (sapling)

hddsavetype
                asl
                asl

                ;now bits 5-3 are represented by carry (subdirectory), sign (sapling),
                ;overflow (seedling), and sign+overflow (tree)

    !if allow_trees = 1 {
                sta treeidx
                bit treeidx
    } ;allow_trees
                php

                ;match name lengths before attempting to match names

                lda (bloklo), y
                and #$0f
                tax
                inx
                !byte $2c       ;mask lda, y on first pass
-               lda (bloklo), y
                cmp (namlo), y
                beq hddfoundname

                ;match failed, check if any directory entries remain

                plp
+
  !if might_exist = 1 {
                dec entries
                bne ++
                inc status
                rts
  } ;might_exist

                ;move to next directory in this block, if possible

++              clc
                lda bloklo
                adc #ENTRY_SIZE
                sta bloklo
                bcc +

                ;there can be only one page crossed, so we can increment instead of adc

                inc blokhi
+               cmp #<(hdddirbuf + $1ff) ;4 + ($27 * $0d)
                lda blokhi
                sbc #>(hdddirbuf + $1ff)
                bcc hddnextent

                ;read next directory block when we reach the end of this block

                ldx hdddirbuf + NEXT_BLOCK_LO
                lda hdddirbuf + NEXT_BLOCK_HI
                jsr hddreaddirsec
                bcc hddfirstent

hddfoundname    iny
                dex
                bne -
  !if allow_trees = 1 {
                stx treeidx
                stx istree
  } ;allow_trees
                stx entries
                stx blkofflo
                stx blkoffhi

  !if enable_write = 1 {
                ldy reqcmd
                cpy #cmdwrite           ;control carry instead of zero
                bne +

                ;round requested size up to nearest block if writing

    !if aligned_read = 0 {
                php
    } ;aligned_read
                lda sizelo
                ldx sizehi
                jsr hddround
                sta sizehi
    !if aligned_read = 0 {
                plp
    } ;aligned_read
+
  } ;enable_write

  !if bounds_check = 1 {
                ;cache EOF (file size, loaded backwards)

                ldy #EOF_HI
                lda (bloklo), y
    !if (enable_write + aligned_read) > 0 {
                tax
    } else { ;enable_write or aligned_read
                sta blefthi
    } ;enable_write or aligned_read
                dey                     ;EOF_LO
                lda (bloklo), y
    !if (enable_write + aligned_read) > 0 {

                ;round file size up to nearest block if writing without aligned reads
                ;or always if using aligned reads

      !if aligned_read = 0 {
                bcc +
      } ;aligned_read

                jsr hddround
                tax
                lda #0
      !if aligned_read = 0 {
                sta sizelo
      } ;aligned_read
+               stx blefthi
    } ;enable_write or aligned_read
    !if aligned_read = 0 {
                sta bleftlo
    } ;aligned_read
  } else { ;bounds_check
    !if enable_write = 1 {
      !if aligned_read = 0 {
                bcc +
                lda #0
                sta sizelo
+
      } ;aligned_read
    } ;enable_write
  } ;bounds_check
                ;cache AUX_TYPE (load offset for binary files)

  !if override_adr = 0 {
                pla
                tax
                ldy #AUX_TYPE
                lda (bloklo), y
                pha
                iny
                lda (bloklo), y
                pha
                txa
                pha
  } ;override_adr

                ;cache KEY_POINTER

                ldy #KEY_POINTER
                lda (bloklo), y
                tax
                sta hdddirbuf
                iny
                lda (bloklo), y
                sta hdddirbuf + 256

                ;read index block in case of sapling

                plp
  !if (allow_subdir + allow_trees) > 0 {
                bpl hddrdwrfile
    !if allow_subdir = 1 {
                php
    } ;allow_subdir
    !if allow_trees = 1 {
                ldy #>hdddirbuf
                bvc +
                ldy #>hddtreebuf
                sty istree
+
    } ;allow_trees
                jsr hddreaddirsect
    !if allow_subdir = 1 {
                plp
    } ;allow_subdir
  } ;allow_subdir

                ;restore load offset

hddrdwrfile
  !if override_adr = 1 {
                ldx ldrhi
                lda ldrlo
  } else { ;override_adr
                pla
                tax
                pla
  } ;override_adr

  !if allow_subdir = 1 {
                ;check file type and fake size and load address for subdirectories

                bcc +
                ldy #2
                sty sizehi
                ldx #>hdddirbuf
                lda #<hdddirbuf
+
  } ;allow_subdir
                sta adrlo
                stx adrhi

                ;set requested size to min(length, requested size)

  !if aligned_read = 0 {
    !if bounds_check = 1 {
                lda bleftlo
                tay
                cmp sizelo
                lda blefthi
                tax
                sbc sizehi
                bcs hddcopyblock
                sty sizelo
                stx sizehi
    } ;bounds_check

hddcopyblock
    !if (enable_write + enable_seek) > 0 {
                ldy reqcmd
                ;cpy #cmdseek
                beq +
    } ;enable_write or enable_seek

    !if allow_aux = 1 {
                ldx auxreq
                jsr hddsetaux
    } ;allow_aux
    !if (enable_write + enable_seek) > 0 {
                dey ;cpy #cmdread
      !if enable_write = 1 {
                bne hddrdwrloop
      } ;enable_write
    } ;enable_write or enable_seek
+
                lda blkofflo
                tax
                ora blkoffhi
                beq hddrdwrloop
                lda sizehi
                pha
                lda sizelo
                pha
                lda adrhi
                sta blokhi
                lda adrlo
                sta bloklo
                stx adrlo
                lda #>hddencbuf
                clc
                adc blkoffhi
                sta adrhi

                ;determine bytes left in block

      !if (enable_write + enable_seek) > 0 {
                tya
      } else { ;enable_write or enable_seek
                lda #0
      } ;enable_write or enable_seek
                sec
                sbc blkofflo
                tay
                lda #2
                sbc blkoffhi
                tax

                ;set requested size to min(bytes left, requested size)

                cpy sizelo
                sbc sizehi
                bcs +
                sty sizelo
                stx sizehi
+
                lda sizehi
                jsr hddcopycache
                lda ldrlo
                adc sizelo
                sta ldrlo
                lda ldrhi
                adc sizehi
                sta ldrhi
                sec
                pla
                sbc sizelo
                sta sizelo
                pla
                sbc sizehi
                sta sizehi
                ora sizelo
                bne hddrdwrfile
                beq hddrdwrdone
  } else { ;aligned_read
    !if bounds_check = 1 {
                lda blefthi
                cmp sizehi
                bcs +
                sta sizehi
+
    } ;bounds_check
    !if allow_aux = 1 {
                ldx auxreq
                jsr setaux
    } ;allow_aux
  } ;aligned_read

hddrdwrloop
  !if (enable_write + enable_seek) > 0 {
                ldx reqcmd
  } ;enable_write or enable_seek
  !if aligned_read = 0 {

                ;set read/write size to min(length, $200)

                lda sizehi
                cmp #2
                bcs +
                pha
                lda #2
                sta sizehi

                ;redirect read to private buffer for partial copy

                lda adrhi
                pha
                lda adrlo
                pha
                lda #>hddencbuf
                sta adrhi
                lda #0
                sta adrlo
    !if (enable_write + enable_seek) > 0 {
                ldx #cmdread
    } ;enable_write or enable_seek
+
  } ;aligned_read

  !if allow_trees = 1 {
                ;read tree data block only if tree and not read already
                ;the indication of having read already is that at least one sapling/seed block entry has been read, too

                ldy entries
                bne +
                lda istree
                beq +
                lda adrhi
                pha
                lda adrlo
                pha
                lda #>hdddirbuf
                sta adrhi
                lda #0
                sta adrlo
                txa
                pha
                lda #cmdread
                sta command

                ;fetch tree data block and read it

                ldy treeidx
                inc treeidx
                ldx hddtreebuf, y
                lda hddtreebuf + 256, y
    !if aligned_read = 0 {
                php
    } ;aligned_read
                jsr hddseekrdwr
    !if aligned_read = 0 {
                plp
    } ;aligned_read
                pla
                tax
                pla
                sta adrlo
                pla
                sta adrhi
  } ;allow_trees

                ;fetch data block and read/write it

                ldy entries
+               inc entries
  !if enable_seek = 1 {
                txa ;cpx #cmdseek, but that would require php at top
                beq +
  } ;enable_seek
                stx command
                ldx hdddirbuf, y
                lda hdddirbuf + 256, y
  !if aligned_read = 0 {
                php
  } ;aligned_read
                jsr hddseekrdwr
  !if aligned_read = 0 {
                plp
+               bcc +
  } ;aligned_read
                inc adrhi
                inc adrhi
  !if bounds_check = 1 {
                dec blefthi
                dec blefthi
  } ;bounds_check
+               dec sizehi
                dec sizehi
                bne hddrdwrloop
  !if aligned_read=0 {
                bcc +
                lda sizelo
                bne hddrdwrloop
  } ;aligned_read
hddrdwrdone
  !if allow_aux = 1 {
                ldx #0
hddsetaux       sta CLRAUXRD, x
                sta CLRAUXWR, x
  } ;allow_aux
                rts

  !if aligned_read = 0 {
                ;cache partial block offset

+               pla
                sta bloklo
                pla
                sta blokhi
                pla
                sta sizehi

hddcopycache
    !if enable_seek = 1 {
                ldy reqcmd
                ;cpy #cmdseek
                beq ++
    } ;enable_seek
                tay
                beq +
                dey
-               lda (adrlo), y
                sta (bloklo), y
                iny
                bne -
                inc blokhi
                inc adrhi
                bne +
-               lda (adrlo), y
                sta (bloklo), y
                iny
+               cpy sizelo
                bne -
++
    !if bounds_check = 1 {
                lda bleftlo
                sec
                sbc sizelo
                sta bleftlo
                lda blefthi
                sbc sizehi
                sta blefthi
    } ;bounds_check
                clc
                lda blkofflo
                adc sizelo
                sta blkofflo
                lda blkoffhi
                adc sizehi
                and #$fd
                sta blkoffhi
                bcc hddrdwrdone
  } ;aligned_read

  !if (enable_write + (bounds_check & aligned_read)) > 0 {
hddround        clc
                adc #$ff
                txa
                adc #1
                and #$fe
                rts
  } ;enable_write or (bounds_check and aligned_read)

hddreaddirsel   ldy #0
                sty adrlo
  !if might_exist = 1 {
                sty status
  } ;might_exist

  !if allow_multi = 1 {
                asl reqcmd
                lsr reqcmd
  } ;allow_multi

hddreaddirsec
!if allow_trees = 0 {
hddreaddirsect
} ;allow_trees
                ldy #>hdddirbuf
!if allow_trees = 1 {
hddreaddirsect
} ;allow_trees
                sty adrhi
                ldy #cmdread
                sty command

hddseekrdwr     stx bloklo
                sta blokhi

unrunit=unrelochdd+(*-reloc)
                lda #$d1
                sta unit

unrentry=unrelochdd+(*-reloc)
                jmp $d1d1
hddcodeend
hdddataend
} ;reloc

;[music] you can't touch this [music]
;math magic to determine ideal loading address, and information dump
!ifdef PASS2 {
} else { ;PASS2
  !set PASS2=1
  !if enable_floppy = 1 {
    !if reloc < $c000 {
      !if ((dataend + $ff) & -256) > $c000 {
        !serious "initial reloc too high, adjust to ", $c000 - (((dataend + $ff) & -256) - reloc)
      } ;dataend
      !if load_high = 1 {
        !if ((dataend + $ff) & -256) != $c000 {
          !warn "initial reloc too low, adjust to ", $c000 - (((dataend + $ff) & -256) - reloc)
        } ;dataend
        dirbuf=reloc - $200
        encbuf=dirbuf - $200
        !if allow_trees = 1 {
          treebuf = encbuf - $200
        } ;allow_trees
      } else { ;load_high
        !pseudopc ((dataend + $ff) & -256) {
          dirbuf = *
        }
        encbuf=dirbuf + $200
        !if allow_trees = 1 {
          treebuf = encbuf + $200
        } ;allow_trees
      } ;load_high
    } else { ;reloc
      !if ((dataend + $ff) & -256) < reloc {
        !serious "initial reloc too high, adjust to ", (0 - (((dataend + $ff) & -256) - reloc)) & $ffff
      } ;dataend
      !if load_high = 1 {
        !if (((dataend + $ff) & -256) & $ffff) != 0 {
          !warn "initial reloc too low, adjust to ", (0 - (((dataend + $ff) & -256) - reloc)) & $ffff
        } ;dataend
        dirbuf=reloc - $200
        encbuf=dirbuf - $200
        !if allow_trees = 1 {
          treebuf = encbuf - $200
        } ;allow_trees
      } else { ;load_high
        !pseudopc ((dataend + $ff) & -256) {
          dirbuf = *
        }
        encbuf=dirbuf + $200
        !if allow_trees = 1 {
          treebuf = encbuf + $200
        } ;allow_trees
      } ;load_high
    } ;reloc
    !if verbose_info = 1 {
      !warn "floppy code: ", reloc, "-", codeend - 1
      !warn "floppy data: ", bit2tbl, "-", dataend - 1
      !warn "floppy dirbuf: ", dirbuf, "-", dirbuf + $1ff
      !warn "floppy encbuf: ", encbuf, "-", encbuf + $1ff
      !if allow_trees = 1 {
        !warn "floppy treebuf: ", treebuf, "-", treebuf + $1ff
      } ;allow_trees
      !warn "floppy driver start: ", unrelocdsk - init
    } ;verbose_info
  } ;enable_floppy
  !if reloc < $c000 {
    !if ((hdddataend + $ff) & -256) > $c000 {
      !serious "initial reloc too high, adjust to ", $c000 - (((hdddataend + $ff) & -256) - reloc)
    } ;hdddataend
    !if load_high = 1 {
      !if ((hdddataend + $ff) & -256) != $c000 {
        !warn "initial reloc too low, adjust to ", $c000 - (((hdddataend + $ff) & -256) - reloc)
      } ;hdddataend
      hdddirbuf = reloc - $200
      !if aligned_read = 0 {
        hddencbuf = hdddirbuf - $200
      } ;aligned_read
      !if allow_trees = 1 {
        !if aligned_read = 0 {
          hddtreebuf = hddencbuf - $200
        } else { ;aligned_read
          hddtreebuf = hdddirbuf - $200
        } ;aligned_read
      } ;allow_trees
    } else { ;load_high
      !pseudopc ((hdddataend + $ff) & -256) {
        hdddirbuf = *
      }
      !if aligned_read = 0 {
        hddencbuf = hdddirbuf + $200
      } ;aligned_read
      !if allow_trees = 1 {
        !if aligned_read = 0 {
          hddtreebuf = hddencbuf + $200
        } else { ;aligned_read
          hddtreebuf = hdddirbuf + $200
        } ;aligned_read
      } ;allow_trees
    } ;load_high
  } else { ;reloc
    !if ((hdddataend + $ff) & -256) < reloc {
      !serious "initial reloc too high, adjust to ", (0 - (((hdddataend + $ff) & -256) - reloc)) & $ffff
    } ;hdddataend
    !if load_high = 1 {
      !if enable_floppy = 0 {
        !if (((hdddataend + $ff) & -256) & $ffff) != 0 {
          !warn "initial reloc too low, adjust to ", (0 - (((hdddataend + $ff) & -256) - reloc)) & $ffff
        } ;hdddataend
      } ;enable_floppy
      hdddirbuf = reloc - $200
      !if aligned_read = 0 {
        hddencbuf = hdddirbuf - $200
      } ;aligned_read
      !if allow_trees = 1 {
        !if aligned_read = 0 {
          hddtreebuf = hddencbuf - $200
        } else { ;aligned_read
          hddtreebuf = hdddirbuf - $200
        } ;aligned_read
      } ;allow_trees
    } else { ;load_high
      !pseudopc ((hdddataend + $ff) & -256) {
        hdddirbuf = *
      }
      !if aligned_read = 0 {
        hddencbuf = hdddirbuf + $200
      } ;aligned_read
      !if allow_trees = 1 {
        !if aligned_read = 0 {
          hddtreebuf = hddencbuf + $200
        } else { ;aligned_read
          hddtreebuf = hdddirbuf + $200
        } ;aligned_read
      } ;allow_trees
    } ;load_high
  } ;reloc
  !if verbose_info = 1 {
    !warn "hdd code: ", reloc, "-", hddcodeend - 1
    !warn "hdd dirbuf: ", hdddirbuf, "-", hdddirbuf + $1ff
    !if aligned_read = 0 {
      !warn "hdd encbuf: ", hddencbuf, "-", hddencbuf + $1ff
    } ;aligned_read
    !if allow_trees = 1 {
      !warn "hdd treebuf: ", hddtreebuf, "-", hddtreebuf + $1ff
    } ;allow_trees
    !warn "hdd driver start: ", unrelochdd - init
  } ;verbose_info
} ;PASS2

readbuff
!byte $D3,$C1,$CE,$A0,$C9,$CE,$C3,$AE
