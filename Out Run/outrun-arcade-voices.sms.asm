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
;.unbackground $0e78 $0eec ; Code for showing Mark III splash
;.unbackground $0f15 $0f3a ; Mark III tilemap
.unbackground $0f3b $1022 ; Mark III tiles
.unbackground $7fd5 $7fef ; Space before Sega header, at least room for the SDSC tag...
.unbackground $7ff0 $7fff ; Sega header

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
  .dw $0e72 ; patch to where it goes if in export mode
.ends


; Patches to hook to play samples
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
.orga $1e1a
.section "Ending patch" overwrite
  call SampleTrampolineCongratulations
.ends

.bank 0 slot 0
.section "Trampolines" free
_PlaySample:
  ; Page in the sample player
  ld a, ($ffff)
  push af
    ; Now play the sample
    ld a, :PlaySample
    ld ($ffff), a
    call PlaySample
  pop af
  ld ($ffff), a
  ret

SampleTrampolineGetReady:
  ; What we replaced to get here
  ld ($c000), a
  push hl
  push bc
    ld hl, GetReady 
    ld c, :GetReady
    call _PlaySample
    ; Wait for VBlank before continuing to avoid a timing issue
-:  in a, ($7e)
    cp 192
    jr nz, -
  pop bc
  pop hl
  ret

SampleTrampolineCheckpoint:
  ; What we replaced to get here
  ld hl, $c000
  push hl
  push bc
    ld hl, Checkpoint
    ld c, :Checkpoint
    ; Disable interrupts else the sample is chopped up
    di
      call _PlaySample
    ei
  pop bc
  pop hl
  ret

SampleTrampolineCongratulations:
  ; This is called repeatedly, we want to only hook the first call
  push af
    ld a, ($dc00) ; This seems to be an unused memory location, zero-initialised
    or a
    call z, +
  pop af
  ; What we replaced to get here
  jp $25a2
  
+:push bc
    ld hl, Congratulations
    ld c, :Congratulations
    di
    call _PlaySample
    ei
  pop bc
  ld a, 1
  ld ($dc00), a
  ret
    
.ends

; The new sample player code

.section "Replayer" superfree
.include "../Common/replayer_core_p4_rto3_8kHz.asm"
.ends
.section "Sample multi-bank player" superfree
PSGSampleSettings:
.db $9f $bf $df $ff ; Maximum attenuation on all channels
.db $80 $00 ; Frequency 0 on tone channels
.db $a0 $00 
.db $c0 $00

PlaySample:
  ; Pause music
  call $5c93
  ; Disable FM (regardless of whether it was enabled)
  xor a
  out ($f2),a
  ; Set PSG channel settings
  push hl
  push bc
    ld hl,PSGSampleSettings
    ld bc,$0a7f
    otir
  pop bc
  pop hl
  ; Page sample into slot 1
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
  ; Restore FM mode
  ld a,($c002) ; 1 for FM, 0 for PSG
  out ($f2),a 
  ret
.ends

; We add our data at the end of the ROM
.include "../Common/addfile.asm"
.define databank 16
.define bankspace $4000
.bank databank slot 1
.org 0
GetReady:        addfile "getready.wav.pcmenc"
Checkpoint:      addfile "checkpoint.wav.pcmenc"
Congratulations: addfile "congratulations.wav.pcmenc"


; Debugging:
; de01 = time