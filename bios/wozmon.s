xaml  = $24                            ; last "opened" location low
xamh  = $25                            ; last "opened" location high
stl   = $26                            ; store address low
sth   = $27                            ; store address high
l     = $28                            ; hex value parsing low
h     = $29                            ; hex value parsing high
ysav  = $2a                            ; used to see if hex value is given
mode  = $2b                            ; $00=xam, $7f=stor, $ae=block xam

in    = $0200                          ; input buffer

notcr:
    cmp     #$08           ; backspace key?
    beq     backspace      ; yes.
    cmp     #$1b           ; esc?
    beq     escape         ; yes.
    iny                    ; advance text index.
    bpl     nextchar       ; auto esc if line longer than 127.

escape:
    lda     #$5c           ; "\".
    jsr     echo           ; output it.

getline:
    lda     #$0d           ; send cr
    jsr     echo
    lda     #$0a           ; send lf
    jsr     echo

    ldy     #$01           ; initialize text index.
backspace:
    dey                    ; back up text index.
    bmi     getline        ; beyond start of line, reinitialize.

nextchar:
    lda     acia_status    ; check status.
    and     #$08           ; key ready?
    beq     nextchar       ; loop until ready.
    lda     acia_data      ; load character. b7 will be '0'.
    sta     in,y           ; add to text buffer.
    jsr     echo           ; display character.
    cmp     #$0d           ; cr?
    bne     notcr          ; no.

    ldy     #$ff           ; reset text index.
    lda     #$00           ; for xam mode.
    tax                    ; x=0.
setblock:
    asl
setstor:
    asl                    ; leaves $7b if setting stor mode.
    sta     mode           ; $00 = xam, $74 = stor, $b8 = blok xam.
blskip:
    iny                    ; advance text index.
nextitem:
    lda     in,y           ; get character.
    cmp     #$0d           ; cr?
    beq     getline        ; yes, done this line.
    cmp     #$2e           ; "."?
    bcc     blskip         ; skip delimiter.
    beq     setblock       ; set block xam mode.
    cmp     #$3a           ; ":"?
    beq     setstor        ; yes, set stor mode.
    cmp     #$52           ; "r"?
    beq     run            ; yes, run user program.
    stx     l              ; $00 -> l.
    stx     h              ;    and h.
    sty     ysav           ; save y for comparison

nexthex:
    lda     in,y           ; get character for hex test.
    eor     #$30           ; map digits to $0-9.
    cmp     #$0a           ; digit?
    bcc     dig            ; yes.
    adc     #$88           ; map letter "a"-"f" to $fa-ff.
    cmp     #$fa           ; hex letter?
    bcc     nothex         ; no, character not hex.
dig:
    asl
    asl                    ; hex digit to msd of a.
    asl
    asl

    ldx     #$04           ; shift count.
hexshift:
    asl                    ; hex digit left, msb to carry.
    rol     l              ; rotate into lsd.
    rol     h              ; rotate into msd's.
    dex                    ; done 4 shifts?
    bne     hexshift       ; no, loop.
    iny                    ; advance text index.
    bne     nexthex        ; always taken. check next character for hex.

nothex:
    cpy     ysav           ; check if l, h empty (no hex digits).
    beq     escape         ; yes, generate esc sequence.

    bit     mode           ; test mode byte.
    bvc     notstor        ; b6=0 is stor, 1 is xam and block xam.

    lda     l              ; lsd's of hex data.
    sta     (stl,x)        ; store current 'store index'.
    inc     stl            ; increment store index.
    bne     nextitem       ; get next item (no carry).
    inc     sth            ; add carry to 'store index' high order.
tonextitem:
    bra     nextitem       ; get next command item.

run:
    jmp     (xaml)         ; run at current xam index.

notstor:
    bmi     xamnext        ; b7 = 0 for xam, 1 for block xam.

    ldx     #$02           ; byte count.
setadr:
    lda     l-1,x          ; copy hex data to
    sta     stl-1,x        ;  'store index'.
    sta     xaml-1,x       ; and to 'xam index'.
    dex                    ; next of 2 bytes.
    bne     setadr         ; loop unless x = 0.

nxtprnt:
    bne     prdata         ; ne means no address to print.
    lda     #$0d           ; cr.
    jsr     echo           ; output it.
    lda     #$0a           ; lf.
    jsr     echo           ; output it.
    lda     xamh           ; 'examine index' high-order byte.
    jsr     prbyte         ; output it in hex format.
    lda     xaml           ; low-order 'examine index' byte.
    jsr     prbyte         ; output it in hex format.
    lda     #$3a           ; ":".
    jsr     echo           ; output it.

prdata:
    lda     #$20           ; blank.
    jsr     echo           ; output it.
    lda     (xaml,x)       ; get data byte at 'examine index'.
    jsr     prbyte         ; output it in hex format.
xamnext:
    stx     mode           ; 0 -> mode (xam mode).
    lda     xaml
    cmp     l              ; compare 'examine index' to hex data.
    lda     xamh
    sbc     h
    bcs     tonextitem     ; not less, so no more data to output.

    inc     xaml
    bne     mod8chk        ; increment 'examine index'.
    inc     xamh

mod8chk:
    lda     xaml           ; check low-order 'examine index' byte
    and     #$07           ; for mod 8 = 0
    bpl     nxtprnt        ; always taken.

prbyte:
    pha                    ; save a for lsd.
    lsr
    lsr
    lsr                    ; msd to lsd position.
    lsr
    jsr     prhex          ; output hex digit.
    pla                    ; restore a.

prhex:
    and     #$0f           ; mask lsd for hex print.
    ora     #$30           ; add "0".
    cmp     #$3a           ; digit?
    bcc     echo           ; yes, output it.
    adc     #$06           ; add offset for letter.

echo:
    sta     acia_data      ; output character.
    rts                    ; return.