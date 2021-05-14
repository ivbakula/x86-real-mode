[bits 16]
[org 0x7c00]

start:
		cli
		xor ax, ax
		mov ds, ax
		mov es, ax

		;set up the stack
		mov ss, ax
		mov sp, 0x7c00
		mov bp, sp
		sti

		mov ah, 0x0  ; change video mode
		mov al, 0x13 ; video mode 0x13 (320x200 8bit)
		int 0x10     ; video services interrupt

		; set offset to the video memory
		push 0x0A000
		pop es

		mov ax, 100	; y coordinate
		mov bx, 160	; x coordinate 

		mov cx, 320
		mul cx

		add ax, bx
		mov di, ax
		mov dl, 7
		mov [es:di], dl
.hang:
		jmp .hang

times 510-($-$$) db 0
db 0x55
db 0xAA
