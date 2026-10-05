; constants
file = $0F
warg0 = $10
warg1 = warg0+2
tmp0 = $20

dbg = $FF

disk_window    = $8200
input_buf      = $7D00

command_tail   = $0200
program_target = $0300

    .org $7E00

entry:
    lda #<boot_msg
    sta warg0
    lda #>boot_msg
    sta warg0+1
    jsr string_out

    jsr list_file

    lda #$0d
    jsr char_out
    lda #$0a
    jsr char_out

main:
    lda #$3E
    jsr char_out

    lda #<input_buf
    sta warg0
    lda #>input_buf
    sta warg0+1
    jsr string_in

    ; find first space
    ldy #$00
find_space_loop:
    lda input_buf,y
    beq no_space
    cmp #$20
    beq found_space
    iny
    bra find_space_loop
found_space:
    lda #$00
    sta input_buf,y
    ldx #$00
    iny
copy_tail:
    lda input_buf,y
    sta command_tail,x
    beq copy_tail_done
    inx
    iny
    bra copy_tail

no_space:
    stz command_tail

copy_tail_done:

    jsr find_file
    bcs not_found

    jsr file_read

    ldx #$00
copy_loop:
    lda disk_window,x
    sta program_target,x
    lda disk_window+$100,x
    sta program_target+$100,x
    inx
    bne copy_loop

    jmp program_target

not_found:
    lda #<not_found_msg
    sta warg0
    lda #>not_found_msg
    sta warg0+1
    jsr string_out
    bra main

; list all 32 directory entries (some may be empty)
list_file:
    ldx #$01
    jsr disk_read

    lda #$00
    sta warg0
    lda #$82
    sta warg0+1

    stz tmp0

list_loop:
    jsr string_out

    lda #$20
    jsr char_out

    clc
    lda warg0
    adc #$10
    sta warg0
    lda warg0+1
    adc #0
    sta warg0+1

    inc tmp0
    lda #$20
    cmp tmp0
    bne list_loop

    rts

boot_msg:
    .byte "MicroOS!", $0d, $0a, $00

not_found_msg:
    .byte "File not found", $0d, $0a, $00

; service area

; $10.11 <- string start
string_out:
    lda warg0+1
    pha
    lda warg0
    pha

string_out_loop:
    lda (warg0)
    beq out_done
    jsr char_out

    inc warg0
    bne string_out_loop
    inc warg0+1
    bra string_out_loop

out_done:
    pla
    sta warg0
    pla
    sta warg0+1
    rts

; $10.11 <- buffer start
string_in:
    lda warg0+1
    pha
    lda warg0
    pha

string_in_loop:
    jsr char_in
    bcc string_in_loop
    jsr char_out

    cmp #$0D
    beq in_done

    cmp #$08
    bne no_bksp

    ldx warg0
    bne dec_skip
    dec warg0+1
dec_skip:
    dec warg0
    bra string_in_loop

no_bksp:
    sta (warg0)
    inc warg0
    bne string_in_loop
    inc warg0+1
    bra string_in_loop

in_done:
    lda #$0A
    jsr char_out
    lda #$00
    sta (warg0)      ; null terminate at current position

    pla
    sta warg0
    pla
    sta warg0+1
    rts

char_in:
    jmp ($FF00)
char_out:
    jmp ($FF02)
disk_read:
    jmp ($FF08)
disk_write:
    jmp ($FF0A)

; $10.11 <- file name. Returns A = file id, C=0 found, C=1 not found.
; Uses `file` as index (0..31, or 32 if not found).
find_file:
    stz file
    ldx #$01
    jsr disk_read

    stz warg1
    lda #$82
    sta warg1+1

find_loop:
    jsr strcmp
    bcc find_done

    clc
    lda warg1
    adc #$10
    sta warg1
    lda warg1+1
    adc #0
    sta warg1+1

    inc file
    lda #32
    cmp file
    bne find_loop

    sec
find_done:
    lda file
    rts

; Compare null-terminated strings at $10.11 and $12.13.
; Bounded to 16 bytes. C=0 equal, C=1 not equal. Does not modify warg0/warg1.
strcmp:
    ldy #$00
strcmp_loop:
    lda (warg0),y
    cmp (warg1),y
    bne strcmp_ne
    cmp #$00
    beq strcmp_eq
    iny
    cpy #$10
    bne strcmp_loop
strcmp_eq:
    clc
    rts
strcmp_ne:
    sec
    rts

; Copy null-terminated string from $12.13 to $10.11.
; Bounded to 15 chars + null. Does not modify warg0/warg1.
strcpy:
    ldy #$00
strcpy_loop:
    cpy #$0F
    beq strcpy_term
    lda (warg1),y
    sta (warg0),y
    beq strcpy_done
    iny
    bra strcpy_loop
strcpy_term:
    lda #$00
    sta (warg0),y
strcpy_done:
    rts

; A <- file id
file_read:
    clc
    adc #2
    tax
    jmp disk_read

; A <- file id
file_write:
    clc
    adc #2
    tax
    jmp disk_write

; $10.11 <- new file name. Returns C=0 success (exists or created), C=1 no slot.
; Uses `file` as slot index.
file_create:
    jsr find_file
    bcc file_exist

    ; find free slot
    ldx #$01
    jsr disk_read

    stz file
    stz warg1
    lda #$82
    sta warg1+1

file_create_find_slot:
    lda (warg1)
    cmp #$00
    beq found_slot

    clc
    lda warg1
    adc #$10
    sta warg1
    lda warg1+1
    adc #0
    sta warg1+1

    inc file
    lda #32
    cmp file
    bne file_create_find_slot

    sec
    rts

found_slot:
    ; swap warg0 and warg1 so strcpy copies filename -> slot
    lda warg0
    ldx warg1
    stx warg0
    sta warg1
    lda warg0+1
    ldx warg1+1
    stx warg0+1
    sta warg1+1

    jsr strcpy
    clc
    rts

file_exist:
    clc
    rts

    .org $7FE0
return:
    jmp main

    .org $7FF0
vectors:
    .word string_out
    .word string_in
    .word char_out
    .word char_in
    .word file_write
    .word file_read
    .word find_file
    .word file_create