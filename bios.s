    .org $c000

BASIC_INIT:
    LDY #END-VECTOR   ; set index/count
COPY:
    LDA VECTOR-1,Y     ; get byte from interrupt code
    STA VEC_IN-1,Y      ; save to RAM
    DEY                 ; decrement index/count
    BNE COPY            ; loop if more to do

    .include "basic.s"

IRQ_vec = VEC_SV+(END-VECTOR)

    .org $f000

ACIA_DATA   = $9000
ACIA_STATUS = $9001
ACIA_CMD    = $9002
ACIA_CTRL   = $9003

RETURN:
    JMP     ESCAPE  ; Skip to WOZMON

RESET:
    LDA     #$0B           ; No parity, no echo, no interrupts.
    STA     ACIA_CMD
    LDX #$00

BANK_INIT_LOOP:     ; Initialize 
    STA $8000,X
    INA
    INX
    INX
    BNE BANK_INIT_LOOP

BOOT:
    LDA #$55
    CMP $83FE
    BNE ESCAPE         ; Boot signature not found, go to monitor.
    ASL
    CMP  $83FF
    BNE  ESCAPE         ; Boot signature not found, go to monitor.
    JMP  $8200          ; Boot signature found, jump to user program.

    .include "wozmon.s"

INPUT:
    LDA ACIA_STATUS
    AND #$08            ; Key ready?
    BEQ INPUT_NOT_READY
    LDA ACIA_DATA       ; Load character
    SEC
    RTS
INPUT_NOT_READY:
    CLC
    RTS


NONE:
    RTS

IRQ_HANDLER:
    RTI

NMI_HANDLER:
    JMP ESCAPE


    .org $FF00
VECTOR:
    .word INPUT                   ; $FF00
    .word ECHO                    ; $FF02
    .word NONE                    ; $FF04
    .word NONE                    ; $FF06

    .org $FF80
END:


    .org $FFFA

    word  NMI_HANDLER      ; NMI vector
    word  RESET            ; RESET vector
    word  IRQ_HANDLER      ; IRQ vector
