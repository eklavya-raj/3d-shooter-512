        bits 16
        cpu 386
        org 0x7C00

MAP     equ 0x8000
KEYS    equ 0x7E80
C       equ 0x7E00
S       equ 0x7E04
ang     equ 0x7E08

start:  xor ax, ax
        mov ds, ax
        mov es, ax
        mov di, 0x7E00
        mov ch, 4
        rep stosb
        mov al, 0x13
        int 0x10
        mov al, 0x85
        out 0x40, al
        out 0x40, al
        mov si, foe
        lodsb
        xchg ax, dx
        mov bh, 0x80
        mov cl, 10
.f:     lodsb
        mov bl, al
        mov [bx], dl
        loop .f
        push 0xA000
        pop es
        shl esi, 16
        mov edi, esi

frame:  hlt
        in al, 0x60
        cbw
        inc ah
        and al, 0x7F
        mov bl, al
        mov [bx+KEYS-0x8300], ah
        mov al, [KEYS+0x4D]
        sub al, [KEYS+0x4B]
        cbw
        add [ang], ax
        fild word [ang]
        fidiv word [turn]
        fsincos
        fimul word [nextc]
        fistp dword [C]
        fimul word [nextc]
        fistp dword [S]

        imul eax, [C-1], 4
        imul edx, [S-1], 4
        mov cl, [KEYS+0x48]
        sub cl, [KEYS+0x50]
        jz .still
        jns .fw
        neg eax
        neg edx
.fw:    add esi, eax
        add edi, edx
        call cell
        jz .still
        sub esi, eax
        sub edi, edx
.still:
        test byte [0x46C], 63
aimask  equ $-1
        jnz noai
        xor di, di
        call cell
        mov dx, bx
        xor byte [foe], 0x24
        mov ah, [foe]
        mov bl, 0
.scan:  mov al, [bx]
        xor al, ah
        cmp al, 0x24
        jne .next
        dec dh
        push bx
        mov al, bl
        xor al, dl
        test al, 0xF0
        mov cl, 1
        jz .r
        mov cl, 16
.r:     cmp bl, dl
        jb .p
        neg cl
.p:     mov [bx], ch
        add bl, cl
        cmp bl, dl
        je lose
        call wall
        jz .free
        sub bl, cl
.free:  mov [bx], ah
        pop bx
.next:  inc bl
        jnz .scan
        test dh, dh
        jns noai
        shr byte [aimask], 1
        mov al, 48
        db 0xB9
lose:   mov al, 40
        mov ch, 0xFA
        rep stosb
        mov cl, 70
.d:     hlt
        loop .d
        jc start
        int 0x19
noai:   xor bp, bp
        mov ecx, -160
column: pushad
        mov eax, [C]
        imul eax, ecx
        mov edx, [S-1]
        sub edx, eax
        mov eax, [S]
        imul eax, ecx
        add eax, [C-1]
march:  inc bp
        add esi, eax
        add edi, edx
        call cell
        jz march
        add esi, edi
        shr esi, 25
        and si, 7
        mov di, 159
        sub di, cx
        test cx, cx
        movzx ecx, byte [si+spr]
        jnz .na
        shr byte [KEYS+0x39], 1
        jnc .na
        test cl, 16
        jz .na
        mov [bx], ch
.na:    mov bl, al
        cmp al, 0xFF
        jne .en
        mov cl, al
        mov ax, bp
        shl ax, 1
        mov bl, 28
        sub bl, ah
.en:    ror ecx, 4
        mov dx, -100
.row:   mov ax, dx
        imul ax, bp
        jo .out
        sar ax, 11
        bt ecx, eax
        mov al, bl
        jc .put
.out:   mov al, dl
        shr al, 3
        add al, 16
        or al, dh
.put:   stosb
        add di, 319
        inc dx
        cmp dx, 100
        jl .row
        popad
nextc:  inc ecx
        cmp cx, 160
        jl column
        mov al, 15
        mov di, 100*320+155
        mov bx, 96*320+159
        mov cl, 9
.x:     stosb
        mov [es:bx], al
        add bx, 320
        loop .x
        jmp frame

cell:   mov bl, MAP >> 8
        shld ebx, edi, 4
        shld ebx, esi, 4
wall:   bt [mapbits+0x1000], bx
        salc
        or al, [bx]
        ret

spr:    db 0x00, 0x18, 0xCC, 0x3F, 0x3F, 0xCC
turn:   db 0x18, 0x00
mapbits: dw 0xFFFF, 0x8001, 0x8C19, 0x8C19, 0x8001, 0x8181, 0xB18D, 0xB00D, 0x8421, 0x8421, 0x8001, 0x8E1D, 0x8001, 0x9861, 0x8001, 0xFFFF
foe:    db 40
foes:   db 0x12, 0x1D, 0x37, 0x9E, 0x91, 0xC5, 0x41, 0x4E, 0xE2, 0xED
code_end:

        times 510-($-$$) db 0
        dw 0xAA55
