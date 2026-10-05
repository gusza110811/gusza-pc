
warg0 = $10
warg1 = warg0+1
command_tail = $0200

disk_window = $8200

vec_strout = $7ff0
vec_strin = vec_strout+2
vec_charout = vec_strin+2
vec_charin = vec_charout+2
vec_filewrite = vec_charin+2
vec_fileread = vec_filewrite+2
vec_findfile = vec_fileread+2
vec_filecreate = vec_findfile+2

return = $7fe0

    org $0300
entry:
    lda #<command_tail
    sta warg0
    lda #>command_tail
    sta warg0+1
    jsr file_find

    jsr file_read

    lda #<disk_window
    sta warg0
    lda #>disk_window
    sta warg0+1
    jsr file_read

    jmp return

string_out:
    jmp (vec_strout)
file_read:
    jmp (vec_fileread)
file_find:
    jmp (vec_findfile)