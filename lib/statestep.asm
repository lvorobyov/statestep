; -----------------------------------------------------	;
;	statestep.asm										;
;	Generic Turing Emulator Assembler Source File		;
;														;
;	Общий эмулятор для машин Тьюринга					;
;														;
;	Для компиляции вызовите команду:					;
;	yasm -f win32 -o statestep.obj statestep.asm		;
;														;
;	Для использования в С / С++							;
;	#include <statestep.h>								;
;														;
;	Copyright (c)   2015-2016    Lev Vorobuev			;
; ----------------------------------------------------- ;

section .text

global _mtr_process

; ------------------ mtr_process ----------------- ;

_mtr_process:
	push ebp
	mov ebp, esp
	push ecx
	push ebx
	push edx
	push esi
	push edi
	
	xor edx, edx ; edx = 0 -- int state
	mov ebx, [ebp+12] ; ebx -- struct* tapes
	
.next_step:
	mov ecx, edx
	inc ecx				; ecx = state + 1
	jecxz .mtr_stop
	call mtr_read_tapes	; al = tape1[i], ah = tape2[i]
	call mtr_get_rule	; get_rule(edx, ax)
	
	test eax, 00c00000h
	jz .not_flags
	bt eax, 22
	jc .f_repeat
	bt eax, 23
	jc .error
	
.f_repeat:
	push dword [ebp+8]
	call mtr_step_multi
	add ebp, 4
	bt eax, 23
	jc .error
	jmp .next_step

.not_flags:
	call mtr_step_single
	jmp .next_step
	
.error:
	mov eax, edx
	inc eax		 ; return state + 1
	jmp .end
.mtr_stop:
	xor eax, eax ; return 0
.end:
	
	pop edi
	pop esi
	pop edx
	pop ebx
	pop ecx
	leave
	ret

; TODO: итак, необходима многоленточная реализация
; если установлен 22 бит eax, то последний байт eax имеет смысл, понятный только для _get_rule
; а именно: он заключает в себе номер пары лент, отсчитанный от 0. 0 : ax=#1,#2 1 : ax=#3,#4
; в случае, если значений на первых лентах недостаточно для того, чтобы получить правило перехода,
; mtr_get_rule возвращает пустое правило перехода с установленым флагом 22 и 23 бита. 
; тогда старший байт eax имеет смысл номера пары лент, которые mtr_get_rule запрашивает в регистр ax.
; при этом mtr_get_rule должна складывать полученные значения регистров eax в стек, а после получения
; значения на последней ленте возврящать поочередно правила перехода для каждой пары лент


; ------ mtr_step_multi ------ ;
; ebx - struct* tapes
; edx - int state
; eax - rule_info
; [ebp+8] - mtr_handle
;
mtr_step_multi:
	push ebp
	mov ebp, esp
	push ebx
	
.pushing_tape:
	bt eax, 23
	jnc .implement_rules
	bt eax, 22
	jnc .end
	mov ecx, eax
	shr ecx, 24
	lea ecx, [ecx + ecx*2]
	shl ecx, 3
	add ebx, ecx		; ebx = ebx + 24*(eax >> 24)
	call mtr_read_tapes
	mov ebx, [ebp-4]	; restore ebx from stack
	push eax
	
	call mtr_get_rule	; get_rule(edx, ax)
	
	jmp .pushing_tape
.implement_rules:
	
.next_rule:
	bt eax, 22
	jnc .end_implement
	bt eax, 23
	jc .pushing_tape
	
	call mtr_step_single
	mov ebx, [ebp-4]	; restore ebx from stack
	mov ecx, eax
	shr ecx, 24
	lea ecx, [ecx + ecx*2]
	shl ecx, 3
	add ebx, ecx		; ebx = ebx + 24*(eax >> 24)
	call mtr_read_tapes
	call mtr_get_rule	; get_rule(edx, ax)
	
	jmp .next_rule
.end_implement:
	
	call mtr_step_single
	
.end:
	pop ebx
	leave
	ret

; -------- mtr_read_tapes -------- ;
; al = tape1[index1]
; ah = tape2[index2]
;
mtr_read_tapes:
	xor ax, ax
	mov esi, [ebx]		; cells
	mov edi, [ebx+4]	; index
	mov al, [esi+edi]
	mov esi, [ebx+12]	; cells
	test esi, esi
	jz .skip
	mov edi, [ebx+16]	; index
	mov ah, [esi+edi]
.skip:
	ret

; --------------- mtr_get_rule -------------- ;
; [ebp+8] - mtr_handle
; edx - state
;
mtr_get_rule:
	mov esi, [ebp+8]
	call [esi+edx*4+4]
	ret
	
; --------------- mtr_step_single ----------- ;
; eax  - rule info
; ebx - struct* types
; [ebx] - type[0].cells
; [ebx+4] - type[0].index
; [ebx+8] - type[0].lenght
; [ebx+12] - type[1].cells
; ...
; edx - current state


mtr_step_single:
	
	; обработка опереатора "write ..."
	
	bt eax, 20
	jc .a_fst_const
	mov edi, [ebx]
	mov ecx, [ebx+4]
	mov [edi+ecx], al
.a_fst_const:
	bt eax, 21
	jc .a_sec_const
	mov edi, [ebx+12]
	mov ecx, [ebx+16]
	mov [edi+ecx], ah
.a_sec_const:
	
	ror eax, 16
	mov ecx, eax
	and ecx, 0fh
	
	; обработка оператора "move ..."
	
	lea ecx, [.begin_switch + ecx*4]
	mov esi, [ebx+4]
	mov edi, [ebx+12]
	sub edi, 2
	cmp edi, -2
	je .second_null_1
	mov edi, [ebx+16]
.second_null_1:
	jmp ecx	; 1..9 
.begin_switch :
					;	dir = 0
	nop				;	first tape - E
	nop 			;	second tape - E
	jmp .end_switch
					;	dir = 1
	inc esi			;	first tape - R
	nop				;	second tape - E
	jmp .end_switch
					;	dir = 2
	dec esi			;	first tape - L
	nop				;	second tape - E
	jmp .end_switch
					;	dir = 3
	nop				;	first tape - E
	inc edi 		;	second tape - R
	jmp .end_switch
					;	dir = 4
	inc esi			;	first tape - R
	inc edi			;	second tape - R
	jmp .end_switch
					;	dir = 5
	dec esi			;	first tape - L
	inc edi			;	second tape - R
	jmp .end_switch
					;	dir = 6
	nop				;	first tape - E
	dec edi			;	second tape - L
	jmp .end_switch
					;	dir = 7
	inc esi			;	first tape - R
	dec edi			;	second tape - L
	jmp .end_switch
					;	dir = 8
	dec esi			;	first tape - L
	dec edi			;	second tape - L
	nop
	nop

.end_switch:

	mov ecx, eax
	cmp esi, 0
	jge .skip_shift1
	push dword [ebx+8]
	push dword [ebx]
	call _str_shift_right
	inc esi
.skip_shift1:
	cmp edi, -2
	je .skip_shift2
	cmp edi, 0
	jge .skip_shift2
	push dword [ebx+20]
	push dword [ebx+12]
	call _str_shift_right
	inc edi
.skip_shift2:
	mov eax, ecx
	mov [ebx+4], esi
	cmp edi, -2
	je .second_null_2
	mov [ebx+16], edi
.second_null_2:
	
	
	; если установлен флаг f_repeat
	bt eax, 6
	jnc .not_f_repeat
	ror eax, 16
	ret
.not_f_repeat:
	
	; обработка оператора "goto ..."
	ror eax, 8
	
	cmp al, 0ffh
	jne .not_q_end
	mov edx, -1
	jmp .end
	
.not_q_end:
	
	shr edx, 6
	bt eax, 6
	jnc .not_jmp_to_next_group
	inc edx
	jmp .end_change_group
.not_jmp_to_next_group:
	bt eax, 7
	jnc .end_change_group
	dec edx
.end_change_group:
	shl edx, 6
	
	mov cl, al
	and cl, 3Fh
	and dl, cl
	
.end:
	ror eax, 8
	ret

; -------------- str_shift_right ---------------- ;
; используется для сдвига ленты, когда указатель выходит на нижнюю границу
;
_str_shift_right
	push ebp
	mov ebp, esp
	push edi
	push esi
	push ecx

	mov ecx, [ebp+12]	;	ecx - lenght
	mov edi, [ebp+8]	;	edi - cells
	mov al, 0
	repne scasb			;	going to end of tape
	std					;	reverse direction
	mov esi, edi		
	dec esi				
	mov eax, [ebp+12]	
	sub eax, ecx		
	mov ecx, eax	
	rep movsb			;	shift right tape
	mov byte [edi], 0	;	first - null symbol
	cld					;	restore direction
	
	mov eax, edi		;	eax - cells
	pop ecx
	pop esi
	pop edi
	leave
	ret 8
	