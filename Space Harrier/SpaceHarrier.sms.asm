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
.background "SpaceHarrier.original.sms"
.unbackground $1a70a $1bfff ; old samples
.unbackground $1dda $1e03 ; old sample player entry
.unbackground $7e62 $7fff ; old sample player + blank space + header

; We add an SDSC header, which rewrites the header so we also restore some values to match the original ROM
.smsheader
  productcode $01, $70, 0 ; 2.5 bytes
  regioncode 4
  reservedspace $ff, $ff
.endsms
.sdsctag 1.30, "Space Harrier (Arcade Voices)", "http://www.smspower.org/Hacks/SpaceHarrier-SMS-ArcadeVoices-Mod", "Maxim"

; RAM mapping
.define RAM_MusicControl $c000 ; Write here to play music
.define RAM_Unused $c700 ; We use this for temporary storage
.define RAM_Score $dfba ; 4 bytes BCD

.bank 0 slot 0

; Patches to places already playing samples
.orga $1dda
.section "Get Ready sound test" force
  ld a,:GetReady
  ld hl,GetReady
  jp PlaySampleDI
.ends

.orga $1de2
.section "Aargh sound test" force
  ld a,:Aargh
  ld hl,Aargh
  jp PlaySampleDI
.ends

.orga $7e2a
.section "Aargh in-game" overwrite
  ld a,:Aargh
  ld hl,Aargh
  jp PlaySample
.ends

.orga $7e4f
.section "Get Ready in-game" overwrite
  ld a,:GetReady
  ld hl,GetReady
  call PlaySample ; can't DI here as it breaks the raster horizon colour change
  nop ; to balance space
.ends

; Patches to insert a extra sample at the start of the game

.orga $11fb
.section "Welcome hack part 0" overwrite
  ; don't start music yet - remember the value here (seems unused)
  ld (RAM_Unused),a
.ends

.orga $12dc
.section "Welcome hack part 1" overwrite
  call WelcomeHack
.ends

.org 0
.section "WelcomeHack" free
WelcomeHack:
  ; What I replaced to get here
  call $5063
  
  ; We only want to play at the start of the game. We check if the score is zero... (there may be a better way)
  ld hl, RAM_Score
  ld a,(hl)
  inc hl
  or (hl)
  inc hl
  or (hl)
  inc hl
  or (hl)
  jr nz,+

  ; We freeze the game while playing
  di
    ld a,:Welcome
    ld hl,Welcome
    call PlaySample
    ld a,:GetReady
    ld hl,GetReady
    call PlaySample
  ei
  jr ++
  
+:di
    ld a,:DoingGreat
    ld hl,DoingGreat
    call PlaySample
  ei

++:; Start music
  ld a,(RAM_Unused)
  ld (RAM_MusicControl),a
  ret
.ends

; The new sample player code

.org 0
.section "Replayer" free
; This is the raw player, it needss to be wrapped to support multi-bank samples
.include "../Common/replayer_core_p4_rto3_8kHz.asm"
.ends

.section "Sample players" free
; Player wrapped in di/ei, used for the sound test
PlaySampleDI:
  di
    call PlaySample
  ei
  ret

PSGSampleSettings:
.db $9f $bf $df $ff ; Maximum attenuation on all channels
.db $80 $00 ; Frequency 0 on tone channels
.db $a0 $00 
.db $c0 $00

PlaySample:
  ; page in
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
  
-:; Play a block (from hl)
  push bc
    call PLAY_SAMPLE
  pop bc
  ; Switch to the next bank
  ld hl,$ffff
  inc (hl)
  ld hl,$8000
  ; And repeat
  djnz -
  ret
.ends

; We add our data at the end of the ROM

.include "../Common/addfile.asm"
.define databank 16
.define bankspace $4000
.bank databank slot 2
.org 0
Welcome:    addfile "welcometothefantasyzone.8k.wav.pcmenc"
Aargh:      addfile "aargh.8k.wav.pcmenc"
GetReady:   addfile "getready.8k.wav.pcmenc"
DoingGreat: addfile "youredoinggreat.8k.wav.pcmenc"
