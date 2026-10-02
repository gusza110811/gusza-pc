    org $0300

warg0 = $10
warg1 = warg0+2

vec_putstr = $7ff0
vec_getstr = $7ff2
vec_charout = $7ff4
vec_filecreate = $7ffe

reset = $7fe0

buffer = $400

entry:
    lda #$4E
    jsr char_out

    lda #<buffer
    sta warg0
    lda #>buffer
    sta warg0+1
    jsr get_str

    jsr file_create

    jmp reset


put_str:
    jmp (vec_putstr)
get_str:
    jmp (vec_getstr)
char_out:
    jmp (vec_charout)
file_create:
    jmp (vec_filecreate)
