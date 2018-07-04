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
bankstotal 32 ; multiple of 4 for better Everdrive compatibility
banksize $7ff0
banks 1
banksize $0010
banks 1
banksize $4000
banks 30
.endro

.background "Altered Beast.sms"
.unbackground $32cc7 $33fff ; old sample player and old samples

; Because the sample player was in the same bank as its data, and gets invoked from paged code, we want to find some low memory space to put ours...
; Last 297 bytes of bank 1 seem unused... we also take out the header as we want to rewrite it...
.unbackground $7ec7 $7fff
.unbackground $5B $65

; We add an SDSC header...
.sdsctag 1.0, "Altered Beast (Arcade Voices)", "http://www.smspower.org/Hacks/AlteredBeast-SMS-ArcadeVoices-Mod", "Maxim"

; ...and restore the original product code...
.smsheader
  productcode $18, $70, 0 ; 2.5 bytes
.endsms

; RAM mapping
.define RAM_LevelNumber $c08d
.define RAM_FramesPerLetter $c080
.define RAM_ModeControl $c0df
.define RAM_ContinueCount $c088

.bank 0 slot 0
.org 0

.section "Replayer" free
.include "../Common/replayer_core_p4_rto3_8kHz.asm"
.ends

.section "Low code" free
PlaySampleLowCode:
  ld a,($ffff)
  push af
    ld a,c
    ld ($ffff),a
    ld b,(hl) ; block count
    inc hl
-:  push bc
      call PLAY_SAMPLE
    pop bc
    inc c
    ld a,c
    ld ($ffff),a
    ld hl,$8000
    djnz -
  pop af
  ; Restore paging
  ld ($ffff),a
  ret
.ends

; Code hooks
.org $0fb7
.section "Game start hook" overwrite
 call StartHack
.ends

.org $f5e
.section "nop out sound effect start" overwrite
.repeat 5
  nop
.endr
.ends

.org $873
.section "Disable level 1 music start" overwrite
.db 0
.ends

.section "Game start hack" free
StartHack:
  ld a,(RAM_FramesPerLetter)
  cp 4 ; special start value
  jr nz,+
  
  ; Play sample
  ld c,:RiseFromYourGrave
  ld hl,RiseFromYourGrave
  call PlayDI

	ld a, $85 ; level 1 music
	call $85c ; EnqueueMusicControl
	ld a, $9b ; rise from grave sound effect
	call $85c ; EnqueueMusicControl

	; what we replaced to get here 
+:ld hl, RAM_FramesPerLetter
  ret
.ends

.orga $2757
.section "Boss fight hook" overwrite
  jp BossFightHack
.ends

.section "Boss fight hack" free
BossFightHack:
  ; Play sample
  ld c,:WelcomeToYourDoom
  ld hl,WelcomeToYourDoom
  call PlayDI
  
  ; What we replaced to get here
	ld a, $01 ; start fade out (?)
	ld (RAM_ModeControl), a
  ret
.ends

.orga $ea1
.section "Continue hook" overwrite
  call ContinueHack
.ends

.section "Continue hack" free
ContinueHack:
  ; Play sample
  ld c,:NeverGiveUp
  ld hl,NeverGiveUp
  call PlayDI

  ; What we replaced to get here
	ld hl, RAM_ContinueCount
  ret
.ends

.section "Play sample with DI" free
PlayDI:
  ld a,:PlaySample
  ld ($ffff),a
  di
  call PlaySample
  ei
  ret
.ends

.bank 12 slot 2

; Code hooks

.org $2cc7
.section "Power Up" force
PlayPowerUp:
  ld c,:PowerUp
  ld hl,PowerUp
  jp PlaySample
.ends

.org $2cd5
.section "Laugh" force
PlayLaugh:
  ld c,:Hahahahaha
  ld hl,Hahahahaha
  jp PlaySample
.ends

.org $2d3b
.section "PlayDeath" force
PlayDeath:
  ld c,:Aaaaaargh
  ld hl,Aaaaaargh
  jp PlaySample
.ends

.org $2d49
.section "PlayRoar" force
PlayRoar:
  ld a,(RAM_LevelNumber)
  or a
  jp z,+
  dec a
  jp z,++
  dec a
  jp z,++
  dec a
  jp z,++
  ; Stage 5: fall through for wolf again
+:
  ld c,:Wolf
  ld hl,Wolf
  jp PlaySample
++:
  ld c,:Growl4
  ld hl,Growl4
  jp PlaySample
+:
  ld c,:Growl2
  ld hl,Growl2
  jp PlaySample
+:
  ld c,:Growl3
  ld hl,Growl3
  jp PlaySample
.ends

; Supporting code, can go anywhere in this bank

.section "Play sample" free
PlaySample:
  ; Stop music - from original game
  call $888d
  ld a,$81
  out ($7f),a
  xor a
  out ($f2),a
  ; Prepare
  call PrepareForSample
  ; Play it
  call PlaySampleLowCode
  ; Resume music - from original game
  ld a,($df00)
  out ($f2),a
  jp $8372 ; and ret  
.ends

.section "Prepare for sample" free
PrepareForSample:
  ; Set PSG channel settings
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
.ends

; We add our data at the end of the ROM
.include "../Common/addfile.asm"
.define databank 16
.define bankspace $4000
.bank databank slot 2
.org 0
Aaaaaargh:          addfile "Aaaaaargh.wav.pcmenc" ; Player death
Wolf:               addfile "Wolf.wav.pcmenc" ; Transform to wolf (stages 1 and 5)
Growl4:             addfile "Growl 4.wav.pcmenc" ; Transform to dragon (stage 2)
Growl2:             addfile "Growl 2.wav.pcmenc" ; Transform to bear (stage 3)
Growl3:             addfile "Growl 3.wav.pcmenc" ; Transform to tiger (stage 4)
Hahahahaha:         addfile "Hahahahaha.wav.pcmenc" ; Nef takes orbs after boss is defeated
PowerUp:            addfile "Power Up!.wav.pcmenc" ; First two power orbs
RiseFromYourGrave:  addfile "Rise From Your Grave.wav.pcmenc" ; Start of game
WelcomeToYourDoom:  addfile "Welcome To Your Doom!.wav.pcmenc" ; Nef encounter
NeverGiveUp:        addfile "Never Give Up.wav.pcmenc" ; Continue


;Aaaaaaaaaaa:        addfile "Aaaaaaaaaaa.wav.pcmenc" ; Unused?
;Growl1:             addfile "Growl 1.wav.pcmenc" ; Unused?
;Ha:                 addfile "Ha.wav.pcmenc" ; Unused?
;HuhUh:              addfile "Huh,uh.wav.pcmenc" ; Unused?
;Uh:                 addfile "Uh.wav.pcmenc" ; Player damage - unused in this version
