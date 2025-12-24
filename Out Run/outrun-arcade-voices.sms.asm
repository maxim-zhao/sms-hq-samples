; ROM layout

.memorymap
slotsize $4000
slot 0 $0000
slot 1 $4000
slot 2 $8000
defaultslot 2
.endme

.rombankmap
bankstotal 20 ; multiple of 4 for better Everdrive compatibility
banksize $4000
banks 20
.endro

.emptyfill $ff

; The ROM to patch, with certain areas marked as free to use
.background "outrun.sms"
; We don't need to clear all this space - but it's all no longer used
;.unbackground $0e61 $0e71 ; Mark III splash phase 2
.unbackground $0e78 $0eec ; Code for showing Mark III splash
.unbackground $0f15 $0f3a ; Mark III tilemap
.unbackground $0f3b $1022 ; Mark III tiles
.unbackground $7fd5 $7fef ; Space before Sega header, needed for the SDSC tag...
.unbackground $7ff0 $7fff ; Sega header

; Functions in the original that are useful to us
.define EndOfMarkIIILogo $0e72
.define MuteAudio $5c93

; Memory locations
.define HasFM $c002
.define HavePlayedCongratulations $dc00 ; This seems to be an unused memory location

; SMS ports
.define Port_AudioControl $f2

; We add an SDSC header, which rewrites the header so we also restore some values to match the original ROM
.smsheader
  productcode $03, $70, 0
  reservedspace $ff, $ff
.endsms
.sdsctag 1.00, "Out Run (Arcade Voices)", "http://www.smspower.org/Hacks/OutRun-SMS-ArcadeVoices-Mod", "Maxim"

.bank 0 slot 0
; Patch for Mark III logo showing
.org $0010 ; Lookup table for game state
.section "Mark III logo patch" overwrite
  .dw EndOfMarkIIILogo ; patch to where it goes if in export mode
.ends


; Patches to hook to play samples. These all overwrite three bytes in the code, which we need to replace later.
.bank 0 slot 0
.orga $16b3 ; Start line, playing the sound effect before music
.section "Start line patch" overwrite
  call SampleTrampolineGetReady
.ends

.bank 1 slot 1
.orga $5193 ; Checkpoint, about to trigger SFX
.section "Checkpoint patch" overwrite
  call SampleTrampolineCheckpoint
.ends

.bank 0 slot 0
.orga $1e1a ; Frame handler for ending animations. We want to hook the first frame of the animation.
.section "Ending patch" overwrite
  call SampleTrampolineCongratulations
.ends

.bank 0 slot 0
.section "Trampoline 1" free
SampleTrampolineGetReady:
  ; What we replaced to get here
  ld ($c000), a

  push hl
  push bc
    ld hl, GetReady 
    ld c, :GetReady
    call PlaySample

    ; Wait for VBlank before continuing to avoid a timing issue
-:  in a, ($7e)
    sub 192
    jr nz, -

    ; Later on we want to play Congratulations only once, using a flag.
    ; This is a good place to clear the flag as a is zero.
    ld (HavePlayedCongratulations), a
  pop bc
  pop hl
  ret
.ends

.section "Trampoline 2" free
SampleTrampolineCheckpoint:
  ; What we replaced to get here
  ld hl, $c000

  push hl
  push bc
    ld hl, Checkpoint
    ld c, :Checkpoint
    ; Disable interrupts else the sample is chopped up
PlaySampleWithInterruptsOff:
    ; Other samples can reuse these bytes...
    di
      call PlaySample
    ei
  pop bc
  pop hl
  ret
.ends

.section "Trampoline 3" free
SampleTrampolineCongratulations:
  ; This is called repeatedly, we want to only hook the first call
  push af
    ld a, (HavePlayedCongratulations)
    or a
    call z, PlayCongratulations
  pop af
  ; What we replaced to get here
  jp $25a2
.ends

.section "Play congratulations" free
PlayCongratulations:
  ; Set the flag
  ld a, 1
  ld (HavePlayedCongratulations), a
  push hl
  push bc
    ld hl, Congratulations
    ld c, :Congratulations
    jp PlaySampleWithInterruptsOff
.ends

; The new sample player code
.section "Sample multi-bank player" free
.include "../Common/replayer_core_p4_rto3_8kHz.asm"
.ends

.section "PSG settings for sample" free
PSGSampleSettings:
.db $9f $bf $df $ff ; Maximum attenuation on all channels
.db $80 $00 ; Frequency 0 on tone channels
.db $a0 $00 
.db $c0 $00
.ends

.section "Sample player" free
PlaySample:
  ; Mute music/SFX
  call MuteAudio
  ; Disable FM (regardless of whether it was enabled)
  xor a
  out (Port_AudioControl),a
  ; Set PSG channel settings
  push hl
  push bc
    ld hl,PSGSampleSettings
    ld bc,$0a7f
    otir
  pop bc
  pop hl
  ; Page sample into slot 2
  ld a,($ffff)
  push af
    ld a,c
    ld ($ffff),a
    ld b,(hl) ; block count
    inc hl
-:  push bc
      call PLAY_SAMPLE
    pop bc
    ld hl,$ffff
    inc (hl)
    ld hl,$8000
    djnz -
  pop af
  ; Restore paging
  ld ($ffff),a
  ; Restore FM mode
  ld a,(HasFM) ; 1 for FM, 0 for PSG
  out (Port_AudioControl),a 
  ret
.ends

; We add our data at the end of the ROM
.include "../Common/addfile.asm"
.define databank 16
.define bankspace $4000
.bank databank slot 2
.org 0
GetReady:        addfile "getready.wav.pcmenc"
Checkpoint:      addfile "checkpoint.wav.pcmenc"
Congratulations: addfile "congratulations.wav.pcmenc"


; Debugging:
; de01 = time