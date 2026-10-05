    org $0300

warg0 = $10
warg1 = warg0+2

command_tail = $0200

vec_filecreate = $7ffe

return = $7fe0

entry:
    lda #<command_tail
    sta warg0
    lda #>command_tail
    sta warg0+1

    jsr file_create

    jmp return

file_create:
    jmp (vec_filecreate)
