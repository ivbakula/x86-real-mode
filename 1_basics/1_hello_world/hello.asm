[bits 16]
[org 0x7c00]

_start:
            mov ah, 0x0e	; write character interrupt
            mov si, msg 
.loop:       
            lodsb		; fetch byte from si
	    or al, al	        ; check if byte is '\0' 
	    jz .done		; if byte is '\0' we're done
            int 0x10            ; else print byte to the screen
            jne .loop           

.done:
	    mov al, 0xd	        ; print carriage return
	    int 0x10
            mov al, 0xa         ; print newline
            int 0x10

.hang:
	    jmp .hang

msg db 'Hello world'
times 510-($-$$) db 0
db 0x55
db 0xAA
