    org $0300

printidx = $10

vec_print = $7ff0
reset = $7fd0

main:
    lda #<hello
    sta printidx
    lda #>hello
    sta printidx+1
    jsr put_str

    jmp reset

put_str:
    jmp (vec_print)

hello:
    byte $0D, $0A, "Hello, World!", $0D, $0A, $00
