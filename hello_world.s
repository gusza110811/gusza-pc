    org $0300

reset = $f000
echo = $ff00

main:
    ldx #$00

loop:
    lda hello,x
    jsr echo
    inx
    cmp #0
    bne loop

    jmp reset


hello:
    byte $0D
    byte $0A
    text "Hello, World!"
    byte $0D
    byte $0A
    byte $00
