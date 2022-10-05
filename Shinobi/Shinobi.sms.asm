; ROM layout

.memorymap
slotsize $7ff0
slot 0 $0000
slotsize $0010
slot 1 $7ff0
slotsize $4000
slot 2 $8000
defaultslot 2
.endme

.rombankmap
bankstotal 20 ; multiple of 4 for better Everdrive compatibility
banksize $7ff0
banks 1
banksize $0010
banks 1
banksize $4000
banks 18
.endro

; The ROM to patch, with certain areas marked as free to use
.background "Shinobi.original.sms"
.unbackground $1aca2 $1bfff ; old sample player + data
.unbackground $7ca5 $7fff ; blank space + header

; We add an SDSC header, which rewrites the header so we also restore some values to match the original ROM
.smsheader
  productcode $09, $70, 0 ; 2.5 bytes
  regioncode 4
  reservedspace $ff, $ff
.endsms
.sdsctag 1.00, "Shinobi (Arcade Voices)", "http://www.smspower.org/Hacks/Shinobi-SMS-ArcadeVoices-Mod", "Maxim"

; RAM mapping
;.define RAM_MusicControl $c000 ; Write here to play music
;.define RAM_Unused $c700 ; We use this for temporary storage
;.define RAM_Score $dfba ; 4 bytes BCD

; Patches to existing sample player
.bank 6 slot 2
.org $1ac4b-$18000
.section "Magic sample" force
  ld a,:magic
  ld hl,magic
  call PlaySample
  jp $84dd
.ends

; Patches to add samples
; TODO

; The new sample player code

.org 0
.section "Replayer" free
; This is the raw player, it needss to be wrapped to support multi-bank samples
.include "../Common/replayer_core_p4_rto3_8kHz.asm"
.ends

.section "Sample players" free
PSGSampleSettings:
.db $9f $bf $df $ff ; Maximum attenuation on all channels
.db $80 $00 ; Frequency 0 on tone channels
.db $a0 $00 
.db $c0 $00

PlaySample:
  ; page in
  ld a,($ffff)
  push af
    ld ($ffff),a

    ; Prepare PSG settings for sample
    push hl
      ld hl,PSGSampleSettings
      ld bc,$0a7f
      otir
    pop hl

    ; Get block count
    ld b,(hl)
    inc hl
  
    ; enable PSG
    xor a
    out ($f2),a
  
    di
-:    ; Play a block (from hl)
      push bc
        call PLAY_SAMPLE
      pop bc
      ; Switch to the next bank
      ld hl,$ffff
      inc (hl)
      ld hl,$8000
      ; And repeat
      djnz -
    ei
  
  ; Put audio control back to where it started
	ld a, ($de00) ; presumably a saved value from startup
	out ($f2), a
  ; And do something if in FM mode..? This is copied from the original game's sample player
	or a
	jr nz, +

	ld hl, $df2e ; Presumably some sound engine thing?
	bit 7, (hl)
	jr z, +
	ld a, $df ; %11011111 = silence ch2
	out ($7f), a
	ld a, $e7 ; %11100111 = noise mode
	out ($7f), a
+:  
  ret
.ends

; We add our data at the end of the ROM

.include "../Common/addfile.asm"
.define databank 16
.define bankspace $4000
.bank databank slot 2
.org 0
mission:              addfile "mission.wav.pcmenc"
one:                  addfile "one.wav.pcmenc"
two:                  addfile "two.wav.pcmenc"
three:                addfile "three.wav.pcmenc"
four:                 addfile "four.wav.pcmenc"
five:                 addfile "five.wav.pcmenc"
finish:               addfile "finish.wav.pcmenc"
magic:                addfile "magic.wav.pcmenc"
welcometobonusstage:  addfile "welcometobonusstage.wav.pcmenc"
