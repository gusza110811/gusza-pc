    .org $7E00

print_idx = $10

main:
    lda #<boot_msg
    sta print_idx
    lda #>boot_msg
    sta print_idx+1
    jsr string_out

    jmp $f000

string_out:     ; start <- $10.11
    lda (print_idx)
    beq done
    jsr char_out

    inc print_idx
    bne string_out
    inc print_idx+1
    bra string_out
done:
    rts

char_in:
    jmp ($FF00)

char_out:
    jmp ($FF02)

disk_read:
    jmp ($FF04)

boot_msg:
    .byte "MicroOS!", $0D, $0A, $00
