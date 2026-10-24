        bits 16
        cpu 386
        org 0x7C00

start:
        xor ax, ax
        mov ds, ax
        mov ax, 0x13
        int 0x10
        push 0xA000
        pop es

        xor cx, cx
column:
        fninit
        mov [x], cx
        fild word [x]
        fisub word [half]
        fmul dword [fov]
        fadd dword [pa]
        fsincos
        fmul dword [stp]
        fxch
        fmul dword [stp]
        fxch
        fld dword [px]
        fld dword [py]
        xor bp, bp
march:
        inc bp
        fxch
        fadd st0, st2
        fxch
        fadd st0, st3
        fist word [iy]
        fxch
        fist word [ix]
        fxch
        mov bx, [iy]
        add bx, bx
        mov ax, [map+bx]
        mov bx, [ix]
        bt ax, bx
        jnc march

        mov ax, 5000
        xor dx, dx
        div bp
        cmp ax, 100
        jb .ok
        mov ax, 100
.ok:
        mov si, ax
        mov di, cx
        mov dx, -100
.row:
        mov ax, dx
        test ax, ax
        jns .abs
        neg ax
.abs:
        mov bl, 7
        cmp ax, si
        jb .put
        mov bl, 0
        test dx, dx
        js .put
        mov bl, 8
.put:
        mov [es:di], bl
        add di, 320
        inc dx
        cmp dx, 100
        jl .row

        inc cx
        cmp cx, 320
        jb column
        jmp $

half:   dw 160
fov:    dd 0.004
stp:    dd 0.02
pa:     dd -1.2
px:     dd 7.5
py:     dd 12.0
map:    dw 0xFFFF, 0x8001, 0x8C19, 0x8C19, 0x8001, 0x8181, 0xB18D, 0xB00D, 0x8421, 0x8421, 0x8001, 0x8E1D, 0x8001, 0x9861, 0x8001, 0xFFFF
code_end:
x:      equ 0x7E00
ix:     equ 0x7E02
iy:     equ 0x7E04

        times 510-($-$$) db 0
        dw 0xAA55
