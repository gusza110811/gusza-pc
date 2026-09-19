file = $0F

warg0 = $10
warg1 = warg0+2

tmp0 = $20

dbg = $ff

disk_window = $8200
input_buf = $7D00
program_target = $0300

    .org $7E00 ; kernel area

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
    jsr find_file
    bcs not_found

    jsr file_read

    ldx #$00
    ldy #$00

copy_loop1:
    lda disk_window,x
    sta program_target,y
    inx
    iny
    bne copy_loop1
copy_loop2:
    lda disk_window+$100,x
    sta program_target+$100,y
    inx
    iny
    bne copy_loop2

    jmp program_target


not_found:
    lda #<not_found_msg
    sta warg0
    lda #>not_found_msg
    sta warg0+1
    jsr string_out
    bra main

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

; $10.11 <- string start
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

    sta (warg0)
    inc warg0
    bne string_in_loop
    inc warg0+1
    bra string_in_loop

in_done:
    jsr char_out
    lda #$0A
    jsr char_out
    lda #0
    sta (warg0)
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
    jmp ($FF04)

disk_write:
    jmp ($FF06)

; $10.11 <- file name
; Carry -> not found
find_file:
    stz file

    ldx #$01
    jsr disk_read

    stz warg1
    lda #$82
    sta warg1+1

find_loop:
    lda warg0+1
    pha
    lda warg0
    pha
    lda warg1+1
    pha
    lda warg1
    pha

    jsr strcmp

    pla
    sta warg1
    pla
    sta warg1+1
    pla
    sta warg0
    pla
    sta warg0+1

    bcc find_done

    clc
    lda warg1
    adc #$10
    sta warg1
    lda warg1+1
    adc #0
    sta warg1+1

    clc
    inc file
    lda #32
    cmp file
    sec
    bne find_loop
    sec

find_done:
    lda file
    rts

; string 0 <- $10.11
; string 1 <- $12.13
; string 0 end -> $10.11
; string 1 end -> $12.13
strcmp:

strcmp_loop:
    lda (warg0)
    cmp (warg1)
    bne strcmp_not_equal
    cmp #0
    beq strcmp_equal

    inc warg0
    bne strcmp_no_carry
    inc warg0+1

strcmp_no_carry:
    inc warg1
    bne strcmp_loop
    inc warg1+1

    bra strcmp_loop

strcmp_not_equal:
    sec
    rts
strcmp_equal:
    clc
    rts

; string 0 <- $10.11
; string 1 <- $12.13
strcpy:
    lda (warg1)
    sta (warg0)
    cmp #0
    beq strcpy_done

    inc warg0
    bne strcpy_no_carry
    inc warg0+1
strcpy_no_carry:
    inc warg1
    bne strcpy
    inc warg1+1
    bra strcpy
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

; $10.11 <- new file name
file_create:

    jsr find_file
    bcc file_exist

    ; find free file slot
    ldx #$01
    jsr disk_read

    ldx #$00
file_create_find_slot:
    lda $8200, x
    cmp #$00
    beq found_slot
    inx
    cpx #$20
    bne file_create_find_slot

no_slot:
    sec
    rts

found_slot:
    stx warg1
    lda #$80
    sta $warg1+1
    jsr strcpy

    rts

file_exist:
    rts


    .org $7FE0
reset:
    jmp main

    .org $7FF0
vectors:
    .word string_out    ; 7FF0
    .word string_in     ; 7FF2
    .word char_out      ; 7FF4
    .word char_in       ; 7FF6
    .word file_write    ; 7FF8
    .word file_read     ; 7FFA
    .word find_file     ; 7FFC
    .word file_create   ; 7FFE
