KBD_IVT_OFFSET equ 9*4
[org 0x7c00]
[bits 16]
_init:
		; initialize segment registers
		xor ax, ax
		mov ds, ax
		mov ss, ax

		; initialize stack
		mov sp, 0x7c00
		mov bp, sp

		cli					
		; set up isr for keyboard		
		; keyboard IVT offset  - 0x024  
		mov word[KBD_IVT_OFFSET], kbd_isr
		mov [KBD_IVT_OFFSET + 2], ax 
		sti

.loop:
		xor ax, ax
		mov [char], al 
		hlt		; wait for interrupt
		mov al, [char]
		cmp al, 0x0
		je .loop
		; it should print out some gibberish 
		; because ps/2 scancodes are not translated
		; to ascii
		mov ah, 0xe
		int 0x10
		jmp .loop
kbd_isr:
		push ax
		in al, 0x60
		mov [char], al
		mov al, 0x20
		out 0x20, al
		pop ax
		iret

align 2
char: db 0
times 510-($-$$) db 0
db 0x55
db 0xAA
