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
        mov ax, 34091
        out 0x40, al
        mov al, ah
        out 0x40, al
        mov si, foes
        mov bh, 0x80
        mov cl, 6
.f:     lodsb
        mov bl, al
        mov byte [bx], 40
        loop .f
        push 0xA000
        pop es
        mov esi, 0x78000000
        mov edi, 0x78100000

frame:  hlt
        in al, 0x60
        mov bl, al
        and bx, 0x7F
        cbw
        inc ah
        mov [bx+KEYS], ah
        mov al, [KEYS+0x4D]
        sub al, [KEYS+0x4B]
        cbw
        add [ang], ax
        fild word [ang]
        fidiv word [turn]
        fsincos
        fimul dword [scale]
        fistp dword [C]
        fimul dword [scale]
        fistp dword [S]

        mov eax, [C]
        mov edx, [S]
        mov cl, [KEYS+0x48]
        sub cl, [KEYS+0x50]
        jz .still
        jns .fw
        neg eax
        neg edx
.fw:    sal eax, 2
        sal edx, 2
        add esi, eax
        add edi, edx
        call cell
        jz .still
        sub esi, eax
        sub edi, edx
.still:
        test byte [0x46C], 63
        jnz noai
        call cell
        mov dx, bx
        xor byte [foe], 0x24
        mov ah, [foe]
        mov bx, MAP
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
.p:     mov byte [bx], 0
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
        mov al, 48
        db 0x3D
lose:   mov al, 40
        xor di, di
        mov cx, 64000
        rep stosb
        mov cl, 70
.d:     hlt
        loop .d
        int 0x19
noai:

        xor bp, bp
        mov di, 319
        mov ecx, -160
column: pushad
        mov eax, [C]
        imul eax, ecx
        sar eax, 8
        mov edx, [S]
        sub edx, eax
        mov eax, [S]
        imul eax, ecx
        sar eax, 8
        add eax, [C]
march:  inc bp
        add esi, eax
        add edi, edx
        call cell
        jz march
        test cx, cx
        jnz .na
        cmp [KEYS+0x39], ch
        je .na
        mov [KEYS+0x39], ch
        mov [bx], ch
.na:    mov bl, al
        mov ax, 8192
        xor dx, dx
        div bp
        cmp ax, 100
        jb .h
        mov al, 100
.h:     mov si, ax
        cmp bl, 0xFF
        jne .en
        shr al, 3
        add al, 16
        mov bl, al
.en:    mov dx, -100
.row:   mov ax, dx
        test ax, ax
        jns .abs
        neg ax
.abs:   cmp ax, si
        mov al, bl
        jb .put
        mov al, 0
        test dx, dx
        js .put
        mov al, dl
        shr al, 3
        add al, 16
.put:   stosb
        add di, 319
        inc dx
        cmp dx, 100
        jl .row
        popad
        dec di
        inc ecx
        cmp cx, 160
        jl column
        jmp frame

cell:   mov bx, MAP >> 8
        shld ebx, edi, 4
        shld ebx, esi, 4
wall:   bt [mapbits+0x1000], bx
        salc
        or al, [bx]
        ret

turn:   dw 17
scale:  dd 4194304
foe:    db 40
mapbits: dw 0xFFFF, 0x8001, 0x8C19, 0x8C19, 0x8001, 0x8181, 0xB18D, 0xB00D, 0x8421, 0x8421, 0x8001, 0x8E1D, 0x8001, 0x9861, 0x8001, 0xFFFF
foes:   db 0x12, 0x1D, 0x37, 0x9E, 0x91, 0xC7
code_end:

        times 510-($-$$) db 0
        dw 0xAA55
