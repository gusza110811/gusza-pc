    .org $4000

dbg = $ff

warg0 = $10
warg1 = warg0+2

kernelID = $20

main:
    stz kernelID

    lda #<boot_msg
    sta warg0
    lda #>boot_msg
    sta warg0+1
    jsr string_out  ; print splash

    ; map page 7F, 7E and 7D to FFFF, FFFE and FFFD
    lda #$FF
    sta $7D*2+$8001
    sta $7E*2+$8001
    sta $7F*2+$8001

    lda #$FD
    sta $7D*2+$8000
    ina
    sta $7E*2+$8000
    ina
    sta $7F*2+$8000

    ldy #0
    ldx #1
    jsr disk_read   ; read sector 1 (file table)

find_kernel:

    lda #$82
    sta warg1
    lda #$00
    sta warg1+1

find_loop:
    lda #<match_name
    sta warg0
    lda #>match_name
    sta warg0+1

    jsr strcmp
    bcc found

    inc warg1
    bne find_loop
    inc warg1+1
    bra find_loop

    inc kernelID
    lda #32
    cmp kernelID
    beq not_found

found:
    clc
    ldx kernelID
    inx
    inx
    jsr disk_read
    sta dbg
    ldx #0
    ldy #0

copy_loop1:
    lda $8200,x
    sta $7e00,y
    inx
    iny
    bne copy_loop1
copy_loop2:
    lda $8300,x
    sta $7f00,y
    inx
    iny
    bne copy_loop2

    jmp $7e00

not_found:
    lda #<no_kernel_msg
    sta warg0
    lda #>no_kernel_msg
    sta warg0+1
    jsr string_out
    jmp $f000

; string 0 <- $10.11
; string 1 <- $12.13
strcmp:
    lda (warg0)
    cmp (warg1)
    bne not_equal
    cmp #0
    beq equal

    inc warg0
    bne strcmp_no_carry
    inc warg0+1

    strcmp_no_carry:
    inc warg1
    bne strcmp
    inc warg1+1

    bra strcmp

equal:
    clc
    rts

not_equal:
    sec
    rts

; start <- $10.11
string_out:
    lda (warg0)
    beq done
    jsr char_out

    inc warg0
    bne string_out
    inc warg0+1
    bra string_out
done:
    rts

char_out:
    jmp ($FF02)

disk_read:
    jmp ($FF04)

boot_msg:
    .byte "MicroOS Boot", $0D, $0A, $00
no_kernel_msg:
    .byte "No Kernel", $0D, $0A, $00

match_name:
    .byte "KERNEL", $00

    .org $41fe
    .byte $55, $aa
