; simple boot sector pong game.
; Controls:
;
; left pedal: j - down
;	      k - up
; 
; right pedal: s - down
;	       d - up
;

PIT_IVT_OFFSET equ 8 * 4 

ROWLEN   equ 320
BALL_RADIUS:  equ 6 
PEDAL_SPEED:  equ 10 
HEIGHT:  equ 40 
WIDTH:   equ 8 
INIT_BALL_X:	equ 152
INIT_BALL_Y:	equ 92 
PLAYER1_X:	equ 10
PLAYER2_X:	equ 300

; ball variables
x_coord: dw INIT_BALL_X 
y_coord: dw INIT_BALL_Y 
x_vel: dw 4 
y_vel: dw 4

; player_1 variables
x_p1: dw PLAYER1_X 
y_p1: dw 76 

; player_2 variables
x_p2: dw PLAYER2_X
y_p2: dw 76

; score
p1_score: db 0
p2_score: db 0

%macro rect 4
	mov ax, word[%1]
	mov bx, word[%2]
	mov cx, %4
	mov dx, %3
	call draw_rect 
%endmacro

%macro clear 0
	xor ax, ax
	xor di, di
	mov cx, 320*200
	rep stosb	
%endmacro

; argument - time to sleep in ms
%macro sleep 1
	push %1
	call slp
	add sp, 0x2
%endmacro

%macro print_int 1
	push %1
	call prnt_int
	add sp, 0x2
%endmacro

%macro eol 0
	mov ah, 0xe	
	mov al, 0xd
	int 0x10

	mov al, 0xa
	int 0x10
%endmacro
[org 0x7c00]
[bits 16]

__init:
		cli
		xor ax, ax		; initialize segment regs
		mov ds, ax
		mov ss, ax	

		mov sp, 0x7c00		; stack at the 0x7c00
		mov bp, sp		; set base pointer 

		mov ah, 0x0		; set vga mode
		mov al, 0x13		; vga mode 320x200 8bit colors
		int 0x10
		mov ax, 0x0a000
		mov es, ax		; video memory segment

	        ; set timer interrupt service routine
		mov word[PIT_IVT_OFFSET], IRQ0_handler
		mov word[PIT_IVT_OFFSET + 2], 0x0
		
		; initialize PIT (programmable interrupt counter - IRQ0)
		mov al, 00110100b	;channel 0, lobyte/hibyte, rate generator
		out 0x43, al		
		mov ax, 1194		; PIT reload value (for 1000Hz)
		out 0x40, al		; write lobyte of PIT reload value
		mov al, ah		; write hibyte of PIT reload value
		out 0x40, al		; write hibyte of PIT reload value
		sti

.main_loop:
		clear					; clear screen
		rect x_coord, y_coord, BALL_RADIUS, BALL_RADIUS; draw rectangle
		rect x_p1, y_p1, WIDTH, HEIGHT
		rect x_p2, y_p2, WIDTH, HEIGHT		

		; draw vertical line
		mov al, 7		; gray
		mov di, 160		; middle of the screen 160th column 
		mov cx, 100		; dashed line 
.vline:
		stosw
		add di, 2*320-2
		loop .vline

		; check for input
		mov ah, 0x1				; keyboard status
		int 0x16
		jz .check				; no key pressed

		cbw					; mov ah, 0
		int 0x16				; get char in al register 
		cmp al, 'j'
		push y_p1				; push pointer on variable
		je .down				; on the stack
		cmp al, 'k'
		je .up

		pop di					; it is not player 1 to
							; change, so pop pointer and clear ax
		xor di,di 
		push y_p2				; push pointer on player 2
		cmp al, 'd'
		je .down
		cmp al, 's'
		je .up
		pop ax					; it is not player 2 to change
		xor ax, ax
		jmp .check

.up:
		pop di					; get pointer on variable 
		cmp word[di], PEDAL_SPEED		; don't cross the border
		jl .fix_up
		sub word[di], PEDAL_SPEED
		jmp .check
.down:
		pop di 
		cmp word[di], 200 - PEDAL_SPEED - HEIGHT ; don't cross the border
		jg .fix_down
		add word[di], PEDAL_SPEED
		jmp .check
.fix_up:
		mov word[di], 0
		jmp .check
.fix_down:
		mov word [di], 200 - HEIGHT
.check:
		; move rectangle in x direction
		cmp word[x_coord], PLAYER1_X + WIDTH
		jle .chk_coll_1
		cmp word[x_coord], PLAYER2_X-BALL_RADIUS
		jge .chk_coll_2
		jmp .update_x

.chk_coll_1:
		mov bx, word[y_p1]
		jmp .chk_coll
.chk_coll_2:
		mov bx, word[y_p2]
.chk_coll:
		mov ax, word[y_coord]
		add ax, BALL_RADIUS
		cmp ax, bx
		jl .out
		sub ax, BALL_RADIUS	
		add bx, HEIGHT
		cmp ax, bx
		jg .out
		mov dx, word[x_vel]
		neg dx
		mov word[x_vel], dx
		jmp .update_x
.out:		
		cmp word[x_coord], 0
		jle .reset
		cmp word[x_coord], 315 - BALL_RADIUS
		jge .reset

.update_x:	
		mov ax, word[x_vel]
		add word[x_coord], ax
		
		; move rectangle in y direction
		mov ax, word[y_coord]			; check for collisions in y direction
		mov bx, word[y_vel]		
		cmp ax, 200 - BALL_RADIUS		; does lower side touch bottom border?
		jge .flip_y				; yes 
		cmp ax, 4				; does upper side touch upper border?
		jg .update_y				; no -> continue with preset direction
.flip_y:
		neg bx					; flip sign bit of y component in velocity vector 
		mov word[y_vel], bx			; update y component of velocity vector
.update_y:
		add ax, word[y_vel]
		mov word[y_coord], ax			; update y_coord

		sleep 60				; display frame for 60ms

		jmp .main_loop
.reset:
		mov ax, word[x_vel]
		neg ax
		mov word[x_vel], ax
		mov word[x_coord], INIT_BALL_X
		mov word[y_coord], INIT_BALL_Y
		jmp .main_loop
.hang:
		jmp .hang

draw_rect:
		imul di, bx, ROWLEN 
		mov bx, ax
		xor ax, ax
		mov al, 7
.v:	
		push cx
		push di
		add di, bx
		mov cx, dx		
		cld
		rep stosb
		pop di
		pop cx
		add di, ROWLEN
		loop .v

		ret


; slp - idle for n milliseconds. Takes argument n from stack
;	argument - time to sleep (in milliseconds)

slp:
		push bp
		mov bp, sp
		push ax
		mov ax, [bp + 0x4]	; time to sleep
		cli
		mov [countdown], ax
		sti
		xor ax, ax
.loop0_sleep:
		hlt
		cli
		mov ax, word[countdown]
		sti
		or ax, ax
		jnz .loop0_sleep
		
		pop ax
		mov sp, bp
		pop bp
		ret

IRQ0_handler:
		push ax
		mov ax, [countdown]
		or ax, ax
		jz .irq0_done
		mov ax, [countdown]
		dec ax
		mov [countdown], ax

.irq0_done:
		mov al, 0x20
		out 0x20, al
		pop ax
		iret

countdown: dw 0

times 510-($-$$) db 0	
db 0x55
db 0xAA
