    .org $c000

; basic_init:
;     ldy #end-vector
; copy:
;     lda vector-1,y
;     sta VEC_IN-1,y
;     dey
;     bne copy

    ;.include "basic.s"

;IRQ_vec = VEC_SV+(end-vector)

    .org $f000

acia_data   = $9000
acia_status = $9001
acia_cmd    = $9002
acia_ctrl   = $9003

return:
    jmp     escape  ; skip to wozmon

reset:
    lda     #$0b           ; no parity, no echo, no interrupts.
    sta     acia_cmd
    lda #$00
    ldx #$00

bank_init_loop:     ; initialize 
    sta $8000,x
    ina
    inx
    inx
    bne bank_init_loop

boot:
    stz $8100
    lda #$55
    cmp $83fe
    bne escape         ; boot signature not found, go to monitor.
    asl
    cmp $83ff
    bne escape         ; boot signature not found, go to monitor.

    ldx #$00           ; boot signature found, load bootsector
    ldy #$00
copy_loop1:
    lda $8200,x
    sta $4000,y
    inx
    iny
    bne copy_loop1
copy_loop2:
    lda $8300,x
    sta $4100,y
    inx
    iny
    bne copy_loop2

    jmp $4000       ; jump

    .include "wozmon.s"

input:
    pha
    lda acia_status
    and #$08            ; key ready?
    beq input_not_ready
    pla
    lda acia_data       ; load character
    sec
    rts
input_not_ready:
    pla
    clc
    rts

read_sector:
    stx $8100
    sty $8101
    rts

write_sector:
    stx $8100
    sty $8101
    rts


none:
    rts

irq_handler:
    

nmi_handler:
    jmp escape


    .org $ff00
vector:
    .word input ; $ff00
    .word echo  ; $ff02
    .word read_sector  ; $ff04
    .word write_sector ; $ff06
end:


    .org $fffa

    .word  nmi_handler      ; nmi vector
    .word  reset            ; reset vector
    .word  irq_handler      ; irq vector