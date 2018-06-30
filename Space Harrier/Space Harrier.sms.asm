.memorymap
slotsize $4000
slot 0 $0000
slot 1 $4000
slot 2 $8000
defaultslot 2
.endme

.rombankmap
bankstotal 20 ; multiple of 4 for better compatibility
banksize $4000
banks 20
.endro

.background "Space Harrier [50 & 60 Hz].sms"
.unbackground $40000 $4bfff ; expansion space
.unbackground $1a70a $1bfff ; old samples
.unbackground $1dda $1e03 ; old sample player entry
.unbackground $7e62 $7fef ; old sample player

.bank 1 slot 1
.section "Replayer" free
.include "../Common/replayer_core_p4_rto3_8kHz.asm"
PrepareForSample:
  push hl
  push bc
    ld hl,+
    ld bc,$0b7f
    otir
  pop bc
  pop hl
  ret
+:
.db $9f $bf $df $ff $81 $00 $a1 $00 $00 $c1 $00
++:
.ends
.section "Sample players" free
PlaySampleDI:
  di
    call PlaySample
  ei
  ret

PlaySample:
  call PrepareForSample
  ld a,c
  ld ($ffff),a
  ld b,(hl) ; block count
  inc hl
-:
  push bc
    call PLAY_SAMPLE
  pop bc
  inc c
  ld a,c
  ld ($ffff),a
  ld hl,$8000
  djnz -
  ret
.ends

.bank 0 slot 0
.orga $1dda
.section "Get Ready sound test" force
b1:
  ld c,:GetReady
  ld hl,GetReady
  jp PlaySampleDI
.ends
.orga $1de2
.section "Aargh sound test" force
b2:
  ld c,:Aargh
  ld hl,Aargh
  jp PlaySampleDI
.ends

; 11fb start music in game (3b)
.orga $11fb
.section "Welcome hack part 0" overwrite
  ; don't start music yet
  ld ($c700),a ; not sure if I can use this?
.ends

.orga $12dc
.section "Welcome hack part 1" overwrite
  call WelcomeHack
.ends
/*
.orga $1303
.section "Welcome hack" overwrite
Hack:
call WelcomeHack
.ends
*/
.bank 1 slot 1
.section "WelcomeHack" free
WelcomeHack:
  ; What I replaced to get here
  call $5063
  
  ; We only want to play at the start of the game. We check if the score is zero... (there may be a better way)
  ld hl, $dfba
  ld a,(hl)
  inc hl
  or (hl)
  inc hl
  or (hl)
  inc hl
  or (hl)
  ret nz

  call PrepareForSample
  ld c,:Welcome
  ld hl,Welcome
  call PlaySample
  ld c,:GetReady
  ld hl,GetReady
  call PlaySample
  ; Start music
  ld a,($c700)
  ld ($c000),a
  ret
.ends

.bank 1 slot 1
.orga $7e2a
.section "Aargh in-game" overwrite
b3:
  ld c,:Aargh
  ld hl,Aargh
  jp PlaySample
.ends

.orga $7e4f
.section "Get Ready in-game?" overwrite
b4:
  ld C,:GetReady
  ld hl,GetReady
  call PlaySample
  nop ; to balance space
.ends


; We add our data at the end of the ROM

.include "../Common/addfile.asm"
.define databank 16
.define bankspace $4000
.bank databank slot 2
.org 0
Welcome:  addfile "welcometothefantasyzone.8k.wav.pcmenc"
Aargh:    addfile "aargh.8k.wav.pcmenc"
GetReady: addfile "getready.8k.wav.pcmenc"
