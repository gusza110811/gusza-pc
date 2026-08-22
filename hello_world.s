    org $8200

reset = $f000
vec_echo = $ff02

main:
    ldx #$00

loop:
    lda hello,x
    jsr echo
    inx
    cmp #0
    bne loop

    jmp reset

echo:
    jmp (vec_echo)

hello:
    byte $0D, $0A, "Hello, World!", $0D, $0A, $00

    org $83fe
    byte $55, $aa ; boot signature