; this program reads char from the keyboard 
; and writes it to the screen

[bits 16]
[org 0x7c00]

_start:
.loop:
            mov ah, 0x00	; read keyboard input
            int 0x16
            mov ah, 0xe		; write char to the screen
            int 0x10
            jmp .loop 

.halt:
            jmp .halt

times 510-($-$$) db 0
db 0x55
db 0xAA
