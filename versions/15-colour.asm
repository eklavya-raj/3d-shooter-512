        bits 16
        cpu 386
        org 0x7C00

MAP     equ 0x8000
KEYS    equ 0x7F80
C       equ 0x7E00
S       equ 0x7E04
ang     equ 0x7E08

start:  xor ax, ax
        mov di, 0x7E00
        mov ch, 4
        rep stosb
        mov al, 0x13
        int 0x10
        mov dx, 0x3C9
.pal:   mov al, bl
        aam 64
        jnz .s
        out dx, al
.s:     mov cl, ah
        out dx, al
        shr al, cl
        out dx, al
        out dx, al
        inc bl
        jnz .pal
        mov al, 0x85
        out 0x40, al
        out 0x40, al
level:  mov si, foe
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
        mov [bx+KEYS-0x8000], ah
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
        mov bl, [KEYS+0x48]
        sub bl, [KEYS+0x50]
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
        push cx
        xor di, di
        call cell
        mov dx, bx
        xor byte [foe], 0x04
        mov ah, [foe]
        mov bl, 0
.scan:  mov al, [bx]
        xor al, ah
        cmp al, 0x04
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
        pop cx
        test dh, dh
        jns noai
        shr byte [aimask], 1
        db 0xB9
lose:   mov al, 0xBF
        mov ch, 0xFA
        rep stosb
        mov cl, 70
.d:     hlt
        loop .d
        jc level
        int 0x19
noai:   neg ecx
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
        mov di, 199*320+159
        sub di, cx
        mov si, fs
        mov fs, bx
        cmp si, bx
        je .s
        mov gs, di
.s:     mov si, gs
        sub si, di
        imul si, bp
        shr si, 11
        cmp si, 8
        jb .in
        xor si, si
.in:
        test cx, cx
        movzx ecx, byte [si+spr]
        jnz .na
        shr byte [KEYS+0x39], 1
        jnc .na
        test cl, 16
        jz .na
        mov [bx], ch
.na:    cmp al, 0xFF
        jne .en
        mov cl, al
.en:    and al, 0xBB
        mov bx, bp
        shr bx, 4
        sub al, bl
        xchg ax, bx
        mov dx, 99
.row:   mov ax, dx
        imul ax, bp
        jo .out
        sar ax, 11
        add al, 4
        bt ecx, eax
        mov al, bl
        jc .put
.out:   mov al, dl
        or al, 4
        shr al, 1
.put:   stosb
        sub di, 321
        dec dx
        jnc .row
        popad
nextc:  inc ecx
        cmp cx, 160
        jl column
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
foe:    db 0x3F
foes:   db 0x12, 0x1D, 0x37, 0x9E, 0x91, 0xC5, 0x41, 0x4E, 0xE2, 0xED
code_end:

        times 510-($-$$) db 0
        dw 0xAA55
