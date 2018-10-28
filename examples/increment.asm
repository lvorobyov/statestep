section .text

state_1:
	cmp  al, '1'
	jne	 .else1
	mov  eax, 00320000h
	ret
.else1:
	cmp  al, 0
	jne	 .else2
	mov  eax, 0FF200031h
	ret
.else2:
	mov  eax,00800000h
	ret

section .data
global _increment

_increment
	dd $+4
	dd 1	; количество лент
	dd state_1