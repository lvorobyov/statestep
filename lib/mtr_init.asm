; -----------------------------------------------------	;
;	mtr_init.asm										;
;   Определение процедуры инициализации машины Тьбринна ;
; -----------------------------------------------------	;

section .text

global _mtr_init

; -------------- mtr_init ------------- ;
; [ebp+8] -- mtr_tape* tapes
; [ebx] - char* cells
; [ebx+4] - int index
; [ebx+8] - int lenght
; ...
;
_mtr_init:
	push ebp
	mov ebp, esp
	push ebx
	push ecx
	push edi
	
	mov ebx, [ebp+8]
.next_tape:
	mov edi, [ebx]
	test edi, edi
	jz .end
	mov ecx, [ebx+8]
	mov al, 0
	rep stosb
	mov dword [ebx+4], 0
	add ebx, 12
	jmp .next_tape
.end:
	
	pop edi
	pop ecx
	pop ebx
	leave
	ret