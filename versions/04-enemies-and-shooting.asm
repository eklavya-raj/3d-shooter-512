        bits 16
        cpu 386
        org 0x7C00

MAP     equ 0x8000
KEYS    equ 0x7E80
cs_     equ 0x7E00
sn      equ 0x7E04
rx      equ 0x7E08
ry      equ 0x7E0C
frames  equ 0x7E10
aim     equ 0x7E14
foe     equ 0x7E16

start:
        xor ax, ax
        mov ds, ax
        mov es, ax
        mov al, 0x13
        int 0x10
        mov al, 0xFE
        out 0x21, al
        cld
        mov ax, 34091
        out 0x40, al
        mov al, ah
        out 0x40, al
        mov si, mapbits
        mov di, MAP
.e:     test di, 15
        jnz .b
        lodsw
        xchg ax, dx
.b:     shr dx, 1
        salc
        stosb
        cmp di, MAP+256
        jb .e
        xor bx, bx
.f:     lodsb
        mov bl, al
        mov byte [bx+MAP], 40
        cmp si, code_end
        jb .f
        mov byte [foe], 40
        push 0x1000
        pop es
        fninit

frame:
        hlt
        inc word [frames]
        in al, 0x60
        mov bl, al
        and bx, 0x7F
        mov [bx+KEYS], al

        cmp byte [KEYS+0x39], 0x39
        jne .nf
        mov byte [KEYS+0x39], 0
        mov bx, [aim]
        cmp byte [bx+MAP], 0xFF
        je .nf
        mov byte [bx+MAP], 0
.nf:
        test byte [frames], 63
        jnz .noai
        mov esi, [px]
        mov edi, [py]
        call cell
        mov dx, bx
        xor byte [foe], 0x24
        mov ah, [foe]
        xor bp, bp
        xor bx, bx
.scan:  mov al, [bx+MAP]
        xor al, ah
        cmp al, 0x24
        jne .next
        inc bp
        mov al, bl
        mov ch, dl
        and al, 15
        and ch, 15
        mov cl, 1
        cmp al, ch
        jne .x
        mov cl, 16
        cmp bl, dl
.x:     jb .p
        neg cl
.p:     movsx di, cl
        add di, bx
        cmp di, dx
        je lose
        mov byte [bx+MAP], 0
        cmp byte [di+MAP], 0
        je .go
        mov di, bx
.go:    mov [di+MAP], ah
.next:  inc bl
        jnz .scan
        test bp, bp
        jz win
.noai:

        fld dword [pa]
        cmp byte [KEYS+0x4B], 0x4B
        jne .nl
        fsub dword [turn]
.nl:    cmp byte [KEYS+0x4D], 0x4D
        jne .nr
        fadd dword [turn]
.nr:    fst dword [pa]
        fsincos
        fimul dword [scale]
        fistp dword [cs_]
        fimul dword [scale]
        fistp dword [sn]

        mov eax, [cs_]
        mov edx, [sn]
        cmp byte [KEYS+0x48], 0x48
        je .fw
        cmp byte [KEYS+0x50], 0x50
        jne .still
        neg eax
        neg edx
.fw:    sal eax, 4
        sal edx, 4
        mov esi, [px]
        add esi, eax
        mov edi, [py]
        add edi, edx
        call cell
        jnz .still
        sar eax, 2
        sar edx, 2
        add [px], eax
        add [py], edx
.still:

        xor cx, cx
column:
        mov dx, cx
        sub dx, 160
        movsx edx, dx
        mov eax, [sn]
        imul eax, edx
        sar eax, 8
        neg eax
        add eax, [cs_]
        mov [rx], eax
        mov eax, [cs_]
        imul eax, edx
        sar eax, 8
        add eax, [sn]
        mov [ry], eax
        mov esi, [px]
        mov edi, [py]
        xor bp, bp
march:  inc bp
        add esi, [rx]
        add edi, [ry]
        call cell
        jz march
        cmp cx, 160
        jne .na
        mov [aim], bx
.na:    mov bh, [bx+MAP]

        mov ax, 8192
        xor dx, dx
        div bp
        cmp ax, 100
        jb .h
        mov ax, 100
.h:     mov si, ax
        mov ax, bp
        shr ax, 5
        cmp al, 15
        jb .s
        mov al, 15
.s:     mov bl, 31
        sub bl, al
        cmp bh, 0xFF
        je .w
        mov bl, bh
.w:

        mov di, cx
        mov dx, -100
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
.put:   mov [es:di], al
        add di, 320
        inc dx
        cmp dx, 100
        jl .row

        inc cx
        cmp cx, 320
        jb column

        push es
        push ds
        push es
        pop ds
        push 0xA000
        pop es
        xor si, si
        xor di, di
        mov cx, 16000
        rep movsd
        pop ds
        pop es
        jmp frame

lose:   mov al, 40
        jmp over
win:    mov al, 48
over:   push 0xA000
        pop es
        xor di, di
        mov cx, 64000
        rep stosb
        mov cl, 70
.d:     hlt
        loop .d
        int 0x19

cell:   xor ebx, ebx
        shld ebx, edi, 4
        shld ebx, esi, 4
        cmp byte [bx+MAP], 0
        ret

turn:   dd 0.06
scale:  dd 4194304
pa:     dd -1.2
px:     dd 0x78000000
py:     dd 0xC0000000
mapbits:
        dw 0xFFFF, 0x8001, 0x8C19, 0x8C19, 0x8001, 0x8181, 0xB18D, 0xB00D, 0x8421, 0x8421, 0x8001, 0x8E1D, 0x8001, 0x9861, 0x8001, 0xFFFF
        db 0x12, 0x1D, 0x37, 0x9E, 0x91, 0x87
code_end:

        times 510-($-$$) db 0
        dw 0xAA55
