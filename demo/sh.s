; a sane shell with some built-ins
; barely better than the kernel's built-in shell

relocated_addr = $7A00

    org relocated_addr
init:
    ; relocate self to $7D00
    ldx #$00
relocate_loop0:
    lda init,x
    sta relocated_addr,x
    inx
    cpx #$FF
    bne relocate_loop0

relocate_loop1:
    lda init+256,x
    sta relocated_addr+256,x
    inx
    cpx #$FF
    bne relocate_loop1

    jmp main

input_buf = relocated_addr-256
program_target = $0300

tmp0 = $80

main:
    lda #<return
    sta saved_return
    lda #>return
    sta saved_return+1

    lda #<main_loop
    sta return
    lda #>main_loop
    sta return+1

main_loop:
    lda #<input_buf
    sta warg0
    lda #>input_buf
    sta warg0+1
    jsr string_in

    ; check for built-in commands
    lda #<ls_tok
    sta warg1
    lda #>ls_tok
    sta warg1+1
    jsr strcmp
    beq do_ls

    lda #<cat_tok
    sta warg1
    lda #>cat_tok
    sta warg1+1
    jsr strcmp
    beq do_cat

    lda #<exit_tok
    sta warg1
    lda #>exit_tok
    sta warg1+1
    jsr strcmp
    beq do_exit

    ; if not a built-in, try to find the file and execute it
    jsr find_file
    bcs not_found
    lda #<program_target
    sta warg0
    lda #>program_target
    sta warg0+1
    jsr file_read
    jmp program_target

do_ls:
    ldx #$01
    jsr file_read

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

    jmp main_loop

do_cat:
    jsr find_file
    bcs not_found
    jsr file_read

    jmp main_loop

do_exit:
    lda #<saved_return
    sta return
    lda #>saved_return
    sta return+1
    jmp return

not_found:
    lda #<not_found_msg
    sta warg0
    lda #>not_found_msg
    sta warg0+1
    jsr string_out
    jmp main_loop

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

; builtins' token
ls_tok: .byte "ls",0
cat_tok: .byte "cat",0
exit_tok: .byte "exit",0

; hard-coded messages
not_found_msg: .byte "file not found", $0d, $0a, 0

warg0 = $10
warg1 = warg0+1

vec_strout = $7ff0
vec_strin = vec_strout+2
vec_charout = vec_strin+2
vec_charin = vec_charout+2
vec_filewrite = vec_charin+2
vec_fileread = vec_filewrite+2
vec_findfile = vec_fileread+2
vec_filecreate = vec_findfile+2

return = $7fe0

saved_return = $fe

string_out:
    jmp (vec_strout)
string_in:
    jmp (vec_strin)
char_out:
    jmp (vec_charout)
char_in:
    jmp (vec_charin)
file_write:
    jmp (vec_filewrite)
file_read:
    jmp (vec_fileread)
find_file:
    jmp (vec_findfile)
file_create:
    jmp (vec_filecreate)
