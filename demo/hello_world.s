    org $0300

printidx = $10

vec_print = $7ff0
vec_reset = $7ffe

main:
    lda #<hello
    sta printidx
    lda #>hello
    sta printidx+1
    jsr put_str

    jmp reset

put_str:
    jmp (vec_print)

reset:
    jmp (vec_reset)

hello:
    byte $0D, $0A, "Hello, World!", $0D, $0A, $00
