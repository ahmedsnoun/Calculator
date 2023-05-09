; --------------------------------- \
; Author: Romain Fauquet            |
; --------------------------------- |
; Name: Input/Output management     |
; --------------------------------- /

	section	.data
prompt:	db	" > "	; Size = 3
nl:	db	10	; New line code

	section	.bss
tmp_int:	resw	1	; Reserver a data word to save temporary integer

	section .text
print_nl:
	; ------- Print new line ------ \
	; Dscrptn:			|
	;	> Just print a new line	|
	; ----------------------------- /
	push	rdi
	push	rsi

	mov	rdi, 1
	mov	rsi, nl
	call	print_text

	pop	rdi
	pop	rsi

	ret

print_text:
	; --------- Print text -------- \
	; Args:				|
	;	> rdi: buffer size	|
	;	> rsi: buffer address	|
	; Dscrptn:			|
	;	> Dsply buffer content	|
	; ----------------------------- /

	; Save used registers
	push	rax
	push	rdx

	; Syscall specs
	; (1) sys_write(int file_dest, char *buf, size_t buf_size)
	;     rax      (rdi          , rsi      , rdx            )
	mov	rax, 1		; Syscall code 1 is for sys_write
	mov	rdx, rdi	; Move buffer_size to correct register for syscall
	mov	rdi, 1		; file_dest = 1 for stdout
	; rsi already have buffer address so no change
	syscall

	; Restore used registers
	pop	rdx
	pop	rax

	ret

print_int:
	; --------- Print int --------- \
	; Args:				|
	;	> rdi: Integer to dspl	|
	; Dscrptn:			|
	;	> Display integer	|
	;  !!! Please be carefull as	|
	;      rdi will be ERASED !!!	|
	; ----------------------------- /

	cmp	rdi, 0
	je	done		; End recursion here as nothing left to display, yes if input is 0 nothing is dislpayed.

	mov	rcx, 10
	mov	rdx, 0		; Prevent div from crashing
	mov	rax, rdi	; rax = rdi, the number to display
	div	rcx		; rax = rax / rcx. Remaining in rdx
	mov	rdi, rax	; Update number to display

	; Recursive is magic !
	push	rdx		; Save the current cha to display
	call	print_int
	pop	rdx		; Here we end recursion and so we start printing our numbers

	; Convert int to it's char ASCII Code and display it
	add	rdx, 48
	mov	[tmp_int], rdx	; Store char to display

	mov	rsi, tmp_int
	mov	rdi, 1		; Only 1 char to display
	call	print_text

	ret

done:
	ret

read_text:
	; --------- Read text --------- \
	; Args:				|
	;	> rdi: buffer size	|
	;	> rsi: buffer address	|
	; Dscrptn:			|
	;	> Read stdin in buffer	|
	; ----------------------------- /

	; Display prompt
	push	rdi
	push	rsi

	mov	rdi, 3
	mov	rsi, prompt
	call	print_text

	pop	rsi
	pop	rdi

	; Preserve used register
	push	rax
	push	rdx
	push	rdi

	; Syscall specs
	; (O) sys_read(int file_dest, char *buf, size_t buf_size)
	;     rax     (rdi          , rsi      , rdx            )
	mov	rax, 0		; Syscall code 0 for sys_read
	mov	rdx, rdi	; Set buffer size
	mov	rdi, 0		; file_dest = 0 for stdin
	; buf address already in rsi
	syscall

	; Restore used registers
	pop	rdi
	pop	rdx
	pop	rax

	ret

size_of_text:
	; ------- Size of text -------- \
	; Args:				|
	;	> rdi: buffer size	|
	;	> rsi: buffer address	|
	; Dscrptn:			|
	;	> rax = size to eof	|
	; ----------------------------- /

	; Preserve used register
	push	rsi
	push	rdx

	mov	rax, 0
	while_size_of_text:
		add	rax, 1
		inc	rsi
		mov	rdx, [rsi]
		cmp	rdx, 32
		jge	while_size_of_text

	; Restore register
	pop	rdx
	pop	rsi

	ret

text_to_int:
	; -------- Text to int -------- \
	; Args:				|
	;	> rdi: buffer size	|
	;	> rsi: buffer address	|
	; Dscrptn:			|
	;	> rax = int from text	|
	; ----------------------------- /

	; Preserve used register
	push	r10
	push	r11
	push	r12

	call	size_of_text		; Count the number of char in rax
	mov	r12, rsi		; Make use or r12 to store current char position
	add	r12, rax		; Put r12 to the last char
	dec	r12			; dec r12 to ignore the last char (eof)

	mov	r10, 1			; r10 will be used as our 10^e reference

	mov	rax, 0			; Set our result as 0 by default
	while_text_to_int:
		movzx	r11, byte [r12]	; Store ascii value in r11
		dec	r12		; Go to previous char
		sub	r11, 48		; Decrease value by 48 (=0 in ascii)

		push	rax		; Push rax because it will be reset for mul

		; Compute currenc har weight/value
		mov	rax, r10	; rax = r10
		mul	r11		; rax = rax * r11
		mov	r11, rax	; Store rax in r11. This is the new value to add to the final one

		; Increase power of 10 in r11

		mov	rax, 10		; rax = 10
		mul	r10		; rax = rax * r10
		mov	r10, rax	; r10 = rax	To update 10^e reference

		pop	rax		; Restore rax to last known int value from text

		add	rax, r11	; Add current char value/weight to result

		cmp	r12, rsi
		jge	while_text_to_int

	; Restore used register
	pop	r12
	pop	r11
	pop	r10

	ret

read_int:
	; ---------- Read int --------- \
	; Args:				|
	;	> rdi: buffer size	|
	;	> rsi: buffer address	|
	; Dscrptn:			|
	;	> rax = int from stdin	|
	; ----------------------------- /

	call	read_text
	call	text_to_int

	ret