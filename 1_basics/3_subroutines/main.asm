[org 0x7c00]
[bits 16]

_start:
		cli		; disable interrupts 
		xor ax, ax	; clear ax
		mov ds, ax	; initialize segment registers
		mov es, ax

		; set up the stack
		mov ss, ax
		mov sp, 0x7c00
		mov bp, sp

	        ; subroutine takes 4 arguments from the stack
		push 1
		push 2
		push 3
		push 4
		call subroutine
		add sp, 0x8
.hang:
		jmp .hang


subroutine:
		push bp		; save base register
		mov bp, sp	
		pusha	        ; save all general purpose registers

		mov ah, 0xe
		mov dx, word[bp + 0xa]  ; take first argument 
		mov al, dl
		add al, 0x30
		int 0x10

		mov dx, word[bp + 0x8]	; take second argument
		mov al, dl
		add al, 0x30
		int 0x10

		mov dx, word[bp + 0x6]  ; take third argument
		mov al, dl
		add al, 0x30
		int 0x10

		mov dx, word[bp + 0x4]  ; take fourth argument
		mov al, dl
		add al, 0x30
		int 0x10

		popa			; restore gp registers
		mov sp, bp		
		pop bp			; restore base pointer
		ret
times 510-($-$$) db 0
db 0x55
db 0xAA
