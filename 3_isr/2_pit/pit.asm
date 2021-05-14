PIT_IVT_OFFSET equ 8 * 4
[org 0x7c00]
[bits 16]

_init:
		cli		; disable interrupts
		; initialize segment registers
		xor ax, ax	
		mov ds, ax
		mov ss, ax

		; initialize the stack
		mov sp, 0x7c00
		mov bp, sp

		; set up isr for PIT
		mov word[PIT_IVT_OFFSET], IRQ0_handler 
		mov [PIT_IVT_OFFSET + 2], ax
		
		; Program the PIT channel
		mov al, 00110100b	; channel 0 lobyte/hibyte, rate generator
		out 0x43, al		; write to PIT
		mov ax, 1194		; set up frequency: 1193182/1194 ~= 1000Hz
		out 0x40, al		; write to PIT (low byte first)
		mov al, ah
		out 0x40, al		; write to PIT (high byte)

		mov cl, 0
		sti			; enable interrupts 
.loop:
		push 1000		; sleep 1000 ms
		call sleep	
		add sp, 0x2

		; write '\r\n'
		mov ah, 0xe
		mov al, cl
		add al, 0x30
		int 0x10

		mov al, 0xd
		int 0x10
		mov al, 0xa
		int 0x10

		inc cl
		cmp cl, 10 
		jne .loop

.halt:	
		jmp .halt

; sleep - idle for n milliseconds. Takes arguments from the stack
;	  argument 0 - time to sleep in milliseconds
sleep:
		push bp
		mov bp, sp
		push ax
		mov ax, [bp + 0x4]	; time to sleep
		cli			; disable interrupts 
		mov [countdown], ax	 
		sti			; reenable interrupts
		xor ax, ax
.loop0_sleep:
		hlt			; wait for interrupt
		cli			
		mov ax, [countdown]	; load remaining time to sleep
		sti
		or ax, ax		; check if countdown variable reached 0
		jnz .loop0_sleep	; if not, wait for another interrupt
		
		pop ax
		mov sp, bp
		pop bp
		ret

IRQ0_handler:
		push ax
		mov ax, [countdown]	
		or ax, ax		; check if countdown variable reached 0
		jz .done
;		mov ax, [countdown]
		dec ax			; countdown > 0; decrement 
		mov [countdown], ax

.done:
		mov al, 0x20		; send end of interrupt to interrupt controller
		out 0x20, al
		pop ax
		iret

countdown: db 0
times 510-($-$$) db 0
db 0x55
db 0xAA
