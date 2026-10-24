        org 0x7C00
        xor ax, ax
        mov ds, ax
        mov es, ax
        mov ax, 0x0204
        mov cx, 2
        xor dh, dh
        mov bx, 0x600
        int 0x13
        xor ax, ax
        xor bx, bx
        xor cx, cx
        xor dh, dh
        xor si, si
        xor di, di
        jmp 0:0x600
        times 510-($-$$) db 0
        dw 0xAA55
