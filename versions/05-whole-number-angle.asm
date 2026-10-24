        bits 16
        cpu 386
        org 0x7C00

MAP     equ 0x8000
KEYS    equ 0x7E80
C       equ 0x7E00
S       equ 0x7E04
ang     equ 0x7E08
aim     equ 0x7E0A
foe     equ 0x7E0C

start:  xor ax, ax
        mov ds, ax
        mov es, ax
        mov al, 0x13
        int 0x10
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
        mov cx, 6
.f:     lodsb
        mov bl, al
        mov byte [bx+MAP], 40
        loop .f
        mov byte [foe], 40
        push 0xA000
        pop es

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
        fmul dword [turn]
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
        mov esi, [px]
        add esi, eax
        mov edi, [py]
        add edi, edx
        call cell
        jnz .still
        mov [px], esi
        mov [py], edi
.still:
        cmp byte [KEYS+0x39], 0
        je .nf
        mov byte [KEYS+0x39], 0
        mov bx, [aim]
        cmp byte [bx+MAP], 0xFF
        je .nf
        mov byte [bx+MAP], 0
.nf:
        test byte [0x46C], 63
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

        xor cx, cx
column: mov dx, cx
        sub dx, 160
        movsx edx, dx
        mov eax, [S]
        imul eax, edx
        sar eax, 8
        neg eax
        add eax, [C]
        mov ebx, [C]
        imul ebx, edx
        sar ebx, 8
        add ebx, [S]
        xchg ebx, edx
        mov esi, [px]
        mov edi, [py]
        xor bp, bp
march:  inc bp
        add esi, eax
        add edi, edx
        call cell
        jz march
        cmp cx, 160
        jne .na
        mov [aim], bx
.na:    mov bl, [bx+MAP]
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
.en:
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
.put:   stosb
        add di, 319
        inc dx
        cmp dx, 100
        jl .row

        inc cx
        cmp cx, 320
        jb column
        jmp frame

lose:   mov al, 40
        jmp over
win:    mov al, 48
over:   xor di, di
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
px:     dd 0x78000000
py:     dd 0xC0000000
mapbits:
        dw 0xFFFF, 0x8001, 0x8C19, 0x8C19, 0x8001, 0x8181, 0xB18D, 0xB00D, 0x8421, 0x8421, 0x8001, 0x8E1D, 0x8001, 0x9861, 0x8001, 0xFFFF
        db 0x12, 0x1D, 0x37, 0x9E, 0x91, 0x87
code_end:

        times 510-($-$$) db 0
        dw 0xAA55
