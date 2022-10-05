; Macros for adding pcmenc data
; Set the org and bank/slot, and define databank and bankspace accordingly before calling addfile for each file. Add your own labels.

.macro addfilechunks args filename, offset, bytesremaining
  ; calculate the amount to write
  .if bytesremaining > bankspace
    .redefine bytestowrite (bankspace - 2) - ((bankspace - 2) # 3)
  .else
    .redefine bytestowrite bytesremaining
  .endif
  
  .if bytestowrite > 0
    .printv dec bytestowrite
    .printt " bytes @ bank "
    .printv dec databank
    .printt " "
    
    .dw bytestowrite/1.5 ; triplet count
    .incbin filename skip offset read bytestowrite ; data
    .redefine bankspace bankspace - bytestowrite - 2
  .else
    ; ran out of space in bank, start a new one
    .redefine databank databank+1
    .redefine bankspace $4000
    .bank databank slot 2
    .org 0
  .endif

  .if bytesremaining-bytestowrite > 0
    ; recurse for next chunk
    addfilechunks filename offset+bytestowrite bytesremaining-bytestowrite
  .endif
.endm

.macro addfile args filename
  ; get the file size
  .ifdef filesize
    .undefine filesize
  .endif
  .fopen filename fp
  .fsize fp filesize
  .fclose fp
  ; we skip the length count as we regenerate it for each chunk
  .redefine filesize filesize-2
  .printt "Adding "
  .printt filename
  .printt " ("
  .printv dec filesize
  .printt " bytes): "
  
  ; Compute the chunk count
  ; = 1 + ceil((size - free - 3) / (maximum size + 2))
  .printt "needs "
  .printv dec (filesize - bankspace - 3) / 16382 + 2
  .printt " bank(s): "
  .db (filesize - bankspace - 3) / 16382 + 2
  .redefine bankspace bankspace-1
  
  
  ; add as chunks
  addfilechunks filename 2 filesize

  .printt "\n"
.endm
