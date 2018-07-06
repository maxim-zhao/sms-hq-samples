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
.background "Alex Kidd - The Lost Stars.sms"
.unbackground $e9c9 $ffff ; old sample player and data
.unbackground $7ff0 $7fff ; header - no space for SDSC? :(

; We add an SDSC header, which rewrites the header so we also restore some values to match the original ROM
.smsheader
  productcode $18, $70, 0 ; 2.5 bytes
.endsms

; Patches to places already playing samples
.bank 3 slot 2
.org $29c9
.section "Play Aargh" force
PlayAargh:
  ld c,:Aargh
  ld hl,Aargh - $4000
  jp PlaySample
.ends

.org $29D7
.section "Play Find the Miracle Ball" force
PlayFindTheMiracleBall:
  ld c,:FindTheMiracleBall
  ld hl,FindTheMiracleBall - $4000
  jp PlaySample
.ends

; The new sample player code

.section "Replayer" free
.include "../Common/replayer_core_p4_rto3_8kHz.asm"
.ends
.section "Sample multi-bank player" free
PSGSampleSettings:
.db $9f $bf $df $ff ; Maximum attenuation on all channels
.db $81 $00 ; Frequency 0 on tone channels
.db $a1 $00 
.db $c1 $00

PlaySample:
  call   $89c9           ; 00E9E2 CD C9 89 ; Init chips
  xor    a               ; 00E9E9 AF 
  out    ($f2),a         ; 00E9EA D3 F2 
  ; Set PSG channel settings
  push hl
  push bc
    ld hl,PSGSampleSettings
    ld bc,$0b7f
    otir
  pop bc
  pop hl
  ld a,($fffe)
  push af
    ld a,c
    ld ($fffe),a
    ld b,(hl) ; block count
    inc hl
-:  push bc
      call PLAY_SAMPLE
    pop bc
    ld hl,$fffe
    inc (hl)
    ld hl,$4000
    djnz -
  pop af
  ; Restore paging
  ld ($fffe),a
  ld     a,($d000)       ; 00EA11 3A 00 D0 
  out    ($f2),a         ; 00EA14 D3 F2 
  jp $843f
  ret
.ends

; We add our data at the end of the ROM
.include "../Common/addfile.asm"
.define databank 16
.define bankspace $4000
.bank databank slot 2
.org 0
Aargh:              addfile "Aargh.wav.pcmenc"
FindTheMiracleBall: addfile "Find the Miracle Ball.wav.pcmenc"
