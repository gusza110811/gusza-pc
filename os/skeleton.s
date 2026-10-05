    org $0300

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

main:
    jmp return

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
file_find:
    jmp (vec_findfile)
file_create:
    jmp (vec_filecreate)
