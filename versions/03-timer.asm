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
code_end:

        times 510-($-$$) db 0
        dw 0xAA55
