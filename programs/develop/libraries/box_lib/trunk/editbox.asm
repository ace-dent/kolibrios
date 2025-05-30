SCAN_LWIN_RELEASE = 0xDB
SCAN_RWIN_RELEASE = 0xDC

align 16
edit_box_draw:
	pushad
	mov	edi,[esp+36]
	and	dword ed_text_color,17FFFFFFh
	mov	ecx,ed_text_color
	mov	ebx,ecx
	shr	ecx,28
	shl	ebx,4
	shr	ebx,28
	inc	ebx
	mov	eax,6
	jecxz	@f
	mov	al, 8
@@:
	mul	bl
	mov	ed_char_width,eax
	mov	al, 9
	jecxz	@f
	mov	al, 16
@@:
	mul	bl
	add	eax,4
	mov	ed_height,eax
	call	.border
.bg_cursor_text:
	;test    word ed_flags,ed_focus ; for unfocused controls =>
	;jz      .skip_offset           ; do not recalculate offset
	call	edit_box.check_offset
;.skip_offset:
	call	edit_box_draw.bg
	test	word ed_flags,ed_focus ; do not draw selection(named shift)
	jz	.cursor_text      ;
	call	.shift
.cursor_text:
	call	.text
	test	word ed_flags,ed_focus ; and dosn`t draw cursor
	jz	edit_box_exit
	call	.cursor
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;��騩 ��室 �� editbox ��� ��� �㭪権 � ���� ��ࠡ��稪��;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
edit_box_exit:
	popad
	ret 4

;description:
; void edit_box_key_safe(edit_box *e, ksys_oskey_t ch)
;input:
; e - edit struct
; ch - key code
align 16
edit_box_key_safe:
	push eax
	mov eax,[esp+12]
	push dword[esp+8]
	call edit_box_key
	pop eax
	ret 8

;==========================================================
;=== ��ࠡ�⪠ ���������� =================================
;==========================================================
align 16
edit_box_key:
	pushad
	mov	edi,[esp+36]
	test	word ed_flags,ed_focus ; �᫨ �� � 䮪��, ��室��
	jz	edit_box_exit
	test	word ed_flags,ed_mouse_on or ed_disabled
	jnz	edit_box_exit
;--------------------------------------
; this code for Win-keys, works with
; kernel SVN r.3356 or later
	mcall	SF_KEYBOARD,SSF_GET_CONTROL_KEYS
	test	ah,$06	      ; LWin ($02) & RWin ($04)
	jnz	edit_box_exit
;--------------------------------------
;�஢�ઠ ����� shift ?
	test	al,$03
	je	@f
	or	word ed_flags,ed_shift	 ;��⠭���� 䫠� Shift
@@:
	and	word ed_flags,ed_ctrl_off ; ���⨬ 䫠� Ctrl
	test	al,$0C
	je	@f
	or	word ed_flags,ed_ctrl_on   ;��⠭���� 䫠� Ctrl
@@:
	and	word ed_flags,ed_alt_off ; ���⨬ 䫠� Alt
	test	al,$30
	je	@f
	or	word ed_flags,ed_alt_on   ;��⠭���� 䫠� Alt
@@:
;----------------------------------------------------------
;--- �஢��塞, �� ����� --------------------------------
;----------------------------------------------------------
	mov	eax,[esp+28]
; get scancode in ah
	ror	eax,8
; check for ctrl+ combinations
	test	word ed_flags,ed_ctrl_on
	jz	@f
	cmp	ah,SCAN_CODE_X ; Ctrl + X
	je	edit_box_key.ctrl_x
	cmp	ah,SCAN_CODE_C ; Ctrl + C
	je	edit_box_key.ctrl_c
	cmp	ah,SCAN_CODE_V ; Ctrl + V
	je	edit_box_key.ctrl_v
	cmp	ah,SCAN_CODE_A ; Ctrl + A
	je	edit_box_key.ctrl_a
	jmp	edit_box_exit
@@:
	cmp	ah,SCAN_CODE_SPACE
	ja	@F
	cmp	al,ASCII_KEY_BACK
	jz	edit_box_key.backspace
	cmp	ah,SCAN_CODE_ESCAPE
	jz	edit_box_exit
	cmp	ah,SCAN_CODE_TAB
	jz	edit_box_exit
	cmp	ah,SCAN_CODE_RETURN
	jz	edit_box_exit
	jmp	.printable_character
@@:
	cmp	ah,SCAN_CODE_DELETE
	ja	edit_box_exit
	cmp	ah,SCAN_CODE_HOME
	jb	edit_box_exit
	cmp	ax,SCAN_CODE_CLEAR shl 8 + ASCII_KEY_CLEAR ; not operate numpad unlocked 5
	jz	edit_box_exit
;here best place to filter up,down,pgup,pgdown
	cmp	al,ASCII_KEY_LEFT
	jb	.printable_character
	and	eax,$F
	mov	ebx,.unlock_numpad_filtration
	jmp	dword[ebx+eax*4]
      .unlock_numpad_filtration       \
	     dd edit_box_key.left,    \ ; LEFT
		edit_box_exit,\ ; DOWN
		edit_box_exit,\ ; UP
		edit_box_key.right,   \ ; RIGHT
		edit_box_key.home,    \ ; HOME
		edit_box_key.end,     \ ; END
		edit_box_key.delete,  \ ; DELETE
		edit_box_exit,\ ; PGDN
		edit_box_exit,\ ; PGUP
		edit_box_key.insert	; INSERT

.printable_character:
	test	word ed_flags,ed_figure_only  ; ⮫쪮 ����?
	jz	@f
	cmp	al,'0'
	jb	edit_box_exit
	cmp	al,'9'
	ja	edit_box_exit
@@:
; restore ascii code
	rol	eax,8

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;�஢�ઠ �� shift, �� �� �����
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	test	word ed_flags,ed_shift_on
	je	@f
; edx = ed_size, ecx = ed_pos
	push	eax
	mov	edx,ed_size
	mov	ecx, ed_pos
	pusha
; clear input area
	mov	ebp,ed_color
	movzx	ebx, word ed_shift_pos
	call	edit_box_key.sh_cl_
	mov	ebp,ed_size
	call	edit_box_key.clear_bg
	popa
	call	edit_box_key.del_char
	mov	ebx,ed_size
	sub	bx,ed_shift_pos
	mov	ed_size,ebx
	pop	eax
@@:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; �஢��塞, ��室���� �� ����� � ���� + ���쭥��� ��ࠡ�⪠
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov	ecx,ed_size
	mov	edx, ed_max
	test	word ed_flags,ed_insert
	jne	@f
	cmp	ecx,edx
	jae	edit_box_exit
@@:	mov	ebx, ed_pos
	cmp	ebx,edx
	jnl	edit_box_exit
	mov	ecx,ed_size
	push	edi eax
	mov	ebp,edi
	mov	esi,ed_text
	add	esi,ecx
	mov	edi,esi
	cmp	ecx,ebx
	je	edit_box_key.In_k
	test	dword bp_flags,ed_insert
	jne	edit_box_key.ins_v
	pusha
	mov	edi,ebp
	mov	ebp,ed_size
	call	edit_box_key.clear_bg
	popa
	sub	ecx,ebx
	inc	edi
	std
	inc	ecx
@@:
	lodsb
	stosb
	loop	@b
edit_box_key.In_k:
	cld
	pop	eax
	mov	al,ah
	stosb
	pop	edi
	inc	dword ed_size
	inc	dword ed_pos
	call	edit_box_key.draw_all2
	jmp	edit_box_key.shift

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;��ࠡ�⪠ ������ insert,delete,backspace,home,end,left,right
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
edit_box_key.insert:
	xor	word ed_flags,ed_insert
	jmp	edit_box_exit

edit_box_key.ins_v:
	dec	dword bp_size
	sub	esi,ecx
	add	esi,ebx
	mov	edi,esi
	pusha
	mov	edi,ebp
	mov	ebp,ed_pos
	call	edit_box_key.clear_bg
	popa
	jmp	edit_box_key.In_k

edit_box_key.delete:
	mov	edx,ed_size
	mov	ecx,ed_pos
	cmp	edx,ecx
	jg	edit_box_key.bac_del
	test	word ed_flags,ed_shift_on
	jne	edit_box_key.del_bac
	popad
	ret	4

edit_box_key.bac_del:
	call	edit_box_key.del_char
	jmp	edit_box_key.draw_all

edit_box_key.backspace:
	test	word ed_flags,ed_shift_on
	jne	edit_box_key.delete
	mov	ecx,ed_pos
	test	ecx,ecx
	jnz	edit_box_key.del_bac
	popad
	ret	4

edit_box_key.del_bac:
	mov	edx,ed_size
	cmp	edx,ecx ;if ed_pos=ed_size
	je	@f
	dec	ecx
	call	edit_box_key.del_char
@@:	test	word ed_flags,ed_shift_on
	jne	edit_box_key.bac_del
	dec	dword ed_pos
edit_box_key.draw_all:
	push	edit_box_key.shift
	test	word ed_flags,ed_shift_on
	je	@f
	movzx	eax, word ed_shift_pos
	mov	ebx,ed_size
	sub	ebx,eax
	mov	ed_size,ebx
	mov	ebp,ed_color
	call	edit_box.clear_cursor
	call	edit_box.check_offset
	and	word ed_flags,ed_shift_cl
	jmp	edit_box_draw.bg

@@:	dec	dword ed_size
edit_box_key.draw_all2:
	and	word ed_flags,ed_shift_cl
	mov	ebp,ed_color
	call	edit_box.clear_cursor
	call	edit_box.check_offset
	mov	ebp,ed_size
	jmp	edit_box_key.clear_bg

;--- ����� ������ left ---
edit_box_key.left:
	mov	ebx,ed_pos
	test	ebx,ebx
	jz	edit_box_key.sh_st_of
	or	word ed_flags,ed_left_fl
	call	edit_box_key.sh_first_sh
	dec	dword ed_pos
	call	edit_box_draw.bg
	call	edit_box_draw.shift
	call	edit_box_key.sh_enable
	jmp	edit_box_draw.cursor_text

;--- ����� ������ right ---
edit_box_key.right:
	mov	ebx,ed_pos
	cmp	ebx,ed_size
	je	edit_box_key.sh_st_of
	and	word ed_flags,ed_right_fl
	call	edit_box_key.sh_first_sh
	inc	dword ed_pos
	call	edit_box_draw.bg
	call	edit_box_draw.shift
	call	edit_box_key.sh_enable
	jmp	edit_box_draw.cursor_text

edit_box_key.home:
	mov	ebx,ed_pos
	test	ebx,ebx
	jz	edit_box_key.sh_st_of
	call	edit_box_key.sh_first_sh
	xor	eax,eax
	mov	ed_pos,eax
	call	edit_box_draw.bg
	call	edit_box_draw.shift
	call	edit_box_key.sh_home_end
	jmp	edit_box_draw.cursor_text

;--- ����� ������ end ---
edit_box_key.end:
	mov	ebx,ed_pos
	cmp	ebx,ed_size
	je	edit_box_key.sh_st_of
	call	edit_box_key.sh_first_sh
	mov	eax,ed_size
	mov	ed_pos,eax
	call	edit_box_draw.bg
	call	edit_box_draw.shift
	call	edit_box_key.sh_home_end
	jmp	edit_box_draw.cursor_text
;----------------------------------------
StrInsert:
; SizeOf(TmpBuf) >= StrLen(Src) + StrLen(Dst) + 1
Dst    equ [esp + 16] ; - destination buffer
Src    equ [esp + 12] ; - source to insert from
Pos    equ [esp + 8] ; - position for insert
DstMax equ [esp + 4]  ; - maximum Dst length(exclude terminating null)
SrcCount equ [esp - 4]
DstCount equ [esp - 8]
TmpBuf	 equ [esp - 12]  ; - temporary buffer
	mov    edi, Src
	mov    ecx, -1
	xor    eax, eax
	repne scasb
	mov    eax, -2
	sub    eax, ecx
	mov    SrcCount, eax
	mov    edi, Dst
	add    edi, Pos
	mov    ecx, -1
	xor    eax, eax
	repne scasb
	mov    eax, -2
	sub    eax, ecx
	inc    eax
	mov    DstCount, eax
	mov    ecx, eax
	add    ecx, SrcCount
	add    ecx, Pos
	mcall	SF_SYS_MISC,SSF_MEM_ALLOC
	mov    TmpBuf, eax
	mov    esi, Dst
	mov    edi, TmpBuf
	mov    ecx, Pos
	mov    edx, ecx
	rep movsb
	mov    esi, Src
	mov    edi, TmpBuf
	add    edi, Pos
	mov    ecx, SrcCount
	add    edx, ecx
	rep movsb
	mov    esi, Pos
	add    esi, Dst
	mov    ecx, DstCount
	add    edx, ecx
	rep movsb
	mov    esi, TmpBuf
	mov    edi, Dst
; ecx = MIN(edx, DstSize)
	cmp    edx, DstMax
	sbb    ecx, ecx
	and    edx, ecx
	not    ecx
	and    ecx, DstMax
	add    ecx, edx
	mov    eax, ecx ; return total length
	rep movsb
	mov    ecx, TmpBuf
	mcall	SF_SYS_MISC,SSF_MEM_FREE
	ret    16
restore Dst
restore Src
restore Pos
restore DstSize
restore TmpBuf
restore SrcCount
restore DstCount
;----------------------------------------
edit_box_key.ctrl_x:
	test   word ed_flags,ed_shift_on
	jz     edit_box_exit
	push	dword 'X'  ; this value need below to determine which action is used
	jmp	edit_box_key.ctrl_c.pushed

edit_box_key.ctrl_c:
	test   word ed_flags,ed_shift_on
	jz     edit_box_exit
	push	dword 'C'  ; this value need below to determine which action is used
.pushed:
; add memory area
	mov	ecx,ed_size
	add	ecx,3*4
	mcall	SF_SYS_MISC,SSF_MEM_ALLOC
; building the clipboard slot header
	xor	ecx,ecx
	mov	[eax+4],ecx ; type 'text'
	inc	ecx
	mov	[eax+8],ecx ; cp866 text encoding
	mov	ecx,ed_pos
	movzx	ebx,word ed_shift_pos
	sub	ecx,ebx
.abs: ; make ecx = abs(ecx)
	       neg     ecx
	       jl	     .abs
	add	ecx,3*4
	mov	[eax],ecx
	sub	ecx,3*4
	mov	edx,ed_pos
	movzx	ebx,word ed_shift_pos
	cmp	edx,ebx
	jle	@f
	mov	edx,ebx
@@:
; copy data
	mov	esi,ed_text
	add	esi,edx
	push	edi
	mov	edi,eax
	add	edi,3*4
	cld
	rep	movsb
	pop	edi
; put slot to the kernel clipboard
	mov	edx,eax
	mov	ecx,[edx]
	push	eax
	mcall	SF_CLIPBOARD,SSF_WRITE_CB
	pop	ecx
; remove unnecessary memory area
	mcall	SF_SYS_MISC,SSF_MEM_FREE
.exit:
	pop	eax	   ; determine current action (ctrl+X or ctrl+C)
	cmp	eax, 'X'
	je	edit_box_key.delete
	jmp	edit_box_exit

edit_box_key.ctrl_v:
	mcall	SF_CLIPBOARD,SSF_GET_SLOT_COUNT
; no slots of clipboard ?
	test	eax,eax
	jz	.exit
; main list area not found ?
	inc	eax
	test	eax,eax
	jz	.exit
	sub	eax,2
	mov	ecx,eax
	mcall	SF_CLIPBOARD,SSF_READ_CB
; main list area not found ?
	inc	eax
	test	eax,eax
	jz	.exit
; error ?
	sub	eax,2
	test	eax,eax
	jz	.exit
	inc	eax
; check contents of container
	mov	ebx,[eax+4]
; check for text
	test	ebx,ebx
	jnz	.no_valid_text
	mov	ebx,[eax+8]
; check for cp866
	cmp	bl,1
	jnz	.no_valid_text
; if something selected then need to delete it
	test   word ed_flags,ed_shift_on
	jz     .selected_done
	push   eax; dummy parameter ; need to
	push   dword .selected_done ; correctly return
	pushad			    ; from edit_box_key.delete
	jmp    edit_box_key.delete
.selected_done:
	mov	ecx,[eax]
	sub	ecx,3*4
	push	ecx
; in ecx size of string to insert
	add	ecx,ed_size
	mov	edx,ed_max
	cmp	ecx,edx
	jb	@f
	mov	ecx,edx
@@:
	mov	esi,eax
	add	esi,3*4
	push	eax edi
;---------------------------------------;
	mov	ed_size,ecx

	push   dword ed_text ; Dst
	push   esi	     ; Src
	push   dword ed_pos  ; Pos in Dst
	push   dword ed_max  ; DstMax
	call   StrInsert
;---------------------------------------;
;        mov     edi,ed_text
;        cld
;@@:
;        lodsb
;        cmp     al,0x0d ; EOS (end of string)
;        je      .replace
;        cmp     al,0x0a ; EOS (end of string)
;        jne     .continue
;.replace:
;        mov     al,0x20 ; space
;.continue:
;        stosb
;        dec     ecx
;        jnz     @b
	pop    edi eax
;move cursor to the end of the inserted string          
	pop    ecx
	add    ecx,ed_pos
	cmp    ecx,ed_max
	jbe    @f
	mov    ecx,ed_max
@@:
		mov    ed_pos, ecx
.no_valid_text:
; remove unnecessary memory area
	mov	ecx,eax
	mcall	SF_SYS_MISC,SSF_MEM_FREE
.exit:
	jmp	edit_box_draw.bg_cursor_text

edit_box_key.ctrl_a:
	mov	eax,ed_size
	mov	ed_pos,eax
	xor	eax,eax
	mov	ed_shift_pos,eax
	or	word ed_flags,ed_shift_bac+ed_shift_on
	jmp	edit_box_draw.bg_cursor_text

;==========================================================
;=== ��ࠡ�⪠ ��� =======================================
;==========================================================
;save for stdcall ebx,esi,edi,ebp
align 16
edit_box_mouse:
	pushad
	mov	edi,[esp+36]
	test	word ed_flags,ed_disabled
	jnz	edit_box_exit

;----------------------------------------------------------
;--- ����砥� ���ﭨ� ������ ��� -----------------------
;----------------------------------------------------------
	mcall	SF_MOUSE_GET,SSF_BUTTON
;----------------------------------------------------------
;--- �஢��塞 ���ﭨ� ----------------------------------
;----------------------------------------------------------
	test	eax,1
	jnz	edit_box_mouse.mouse_left_button
	and	word ed_flags,ed_mouse_on_off
	mov	ebx,ed_mouse_variable
	or	ebx,ebx
	jz	edit_box_exit
	push	0
	pop	dword [ebx]
	jmp	edit_box_exit

.mouse_left_button:
;----------------------------------------------------------
;--- �����஢�� �� 䮪��஢�� � ��㣨� ����� �� ��������� �� ��� �����
;----------------------------------------------------------
	mov	eax,ed_mouse_variable
	test	eax,eax
	jz	@f ;�᫨ ed_mouse_variable=0
	push	dword [eax]
	pop	eax
	test	eax,eax
	jz	@f ;�᫨ [ed_mouse_variable]=0
	cmp	eax,edi
	jne	edit_box_mouse._blur
;----------------------------------------------------------
;--- ����砥� ���न���� ��� �⭮�⥫쭮 0 �.� �ᥩ ������ ��࠭�
;----------------------------------------------------------
@@:
	mcall	SF_MOUSE_GET,SSF_WINDOW_POSITION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;�㭪�� ��ࠡ�⪨  ��誨 ����祭�� ���न��� � �஢�ઠ �� + �뤥�����
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; �� 㤥ন���� �� �� ������� ��誨, ��६��� �����?
	test	word ed_flags,ed_mouse_on
	jne	edit_box_mouse.mouse_wigwag
; �஢��塞, �������� �� ����� � edit box
	mov	ebx,ed_top
	cmp	ax,bx
	jl	edit_box_mouse._blur
	add	ebx,ed_height
	cmp	ax,bx
	jg	edit_box_mouse._blur
	shr	eax,16
	mov	ebx,ed_left
	cmp	ax,bx
	jl	edit_box_mouse._blur
	add	ebx,ed_width
	cmp	ax,bx
	jg	edit_box_mouse._blur
; �����塞 ������ �����
	push	eax
	mov	ebp,ed_color
	call	edit_box.clear_cursor
	pop	eax
edit_box_mouse._mvpos:
	xor	edx,edx
	sub	eax,ed_left
	div	word ed_char_width
	add	eax,ed_offset
	cmp	eax,ed_size
	jna	edit_box_mouse._mshift
	mov	eax,ed_size
edit_box_mouse._mshift:
; ᥪ�� ��ࠡ�⪨ shift � �뤥����� �� shift
	test	word ed_flags,ed_shift_bac
	je	@f
	mov	ebp,ed_color
	movzx	ebx, word ed_shift_pos
	push	eax
	call	edit_box_key.sh_cl_
	and	word ed_flags,ed_shift_bac_cl
	pop	eax
@@:
	test	word ed_flags,ed_mouse_on
	jne	@f
	mov	ed_shift_pos,ax
	or	word  ed_flags,ed_mouse_on
	mov	ed_pos,eax
	mov	ebx,ed_mouse_variable
	or	ebx,ebx
	jz	edit_box_mouse.mv_end
	push	edi
	pop	dword [ebx]
edit_box_mouse.mv_end:
	bts	word ed_flags,1
	call	edit_box_draw.bg
	jmp	edit_box_mouse.m_sh

@@:	cmp	ax,ed_shift_pos
	je	edit_box_exit
	mov	ed_pos,eax
	call	edit_box_draw.bg
	mov	ebp,shift_color
	movzx	ebx, word ed_shift_pos
	call	edit_box_key.sh_cl_
	or	word ed_flags,ed_mous_adn_b
edit_box_mouse.m_sh:
	call	edit_box_draw.text
	call	edit_box_draw.cursor
; ��楤�� ��⠭���� 䮪��
	jmp	edit_box_mouse.drc
	
edit_box_mouse._remove_selection:
	and	word ed_flags,ed_shift_cl
	jmp	edit_box_draw.bg_cursor_text

edit_box_mouse._blur:
	test	word ed_flags,ed_always_focus
	jne	edit_box_mouse._remove_selection
	btr	word ed_flags, bsf ed_focus ;if focused then remove focus, otherwise exit
	jnc	edit_box_mouse._remove_selection
	mov	ebp,ed_color
	call	edit_box.clear_cursor
edit_box_mouse.drc:
	call	edit_box_draw.border
	jmp	edit_box_mouse._remove_selection

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;��騥 �㭪樨 ��ࠡ�⪨
;----------------------------------------------------------
;--- ��楤�� ���ᮢ�� �뤥������ ��� ----------------
;----------------------------------------------------------
edit_box_draw.shift:
	test	word ed_flags,ed_shift_bac ;��⠭���� 䫠��, �뤥������ ������
	jz	@f
	mov	ebp,shift_color
	movzx	ebx, word ed_shift_pos
	call	edit_box_key.sh_cl_
@@:	ret
;----------------------------------------------------------
;--- ��楤�� ���ᮢ�� ⥪�� --------------------------
;----------------------------------------------------------
edit_box_draw.text:
	call	edit_box.get_n
	mov	esi,ed_size
	sub	esi,ed_offset
	cmp	eax,esi
	jae	@f
	mov	esi,eax
@@:
	test	esi,esi
	jz	@f
	mov	eax,SF_DRAW_TEXT
	mov	ebx,ed_left
	add	ebx,2
	shl	ebx,16
	add	ebx,ed_top
	add	ebx,3
	mov	ecx,ed_text_color
	test	dword ed_flags,ed_pass
	jnz	.password
	mov	edx,ed_text
	add	edx,ed_offset
	mcall
@@:
	ret

.password:
	mov	ebp,esi
	mov	esi,1
	mov	edx,txt_pass
@@:
	mcall
	rol	ebx,16
	add	ebx,ed_char_width
	rol	ebx,16
	dec	ebp
	jnz	@b
	ret

txt_pass db '*'
;----------------------------------------------------------
;--- ��楤�� ���ᮢ�� 䮭� ----------------------------
;----------------------------------------------------------
edit_box_draw.bg:
	mov	ebx,ed_left
	inc	ebx
	shl	ebx,16
	add	ebx,ed_width
	dec	ebx
	mov	edx,ed_color
	test	word ed_flags, ed_disabled
	jz	edit_box_draw.bg_eax
	mov	edx, 0xCACACA	; TODO: add disabled_color field to editbox struct
edit_box_draw.bg_eax:
	mov	ecx,ed_top
	inc	ecx
	shl	ecx,16
	add	ecx,ed_height
	mcall	SF_DRAW_RECT
	ret

;----------------------------------------------------------
;--- ��楤�� ����祭�� ������⢠ ᨬ����� � ⥪�饩 �ਭ� ���������
;----------------------------------------------------------
align 4
edit_box.get_n:
	mov	eax,ed_width
	sub	eax,4
	xor	edx,edx
	cmp word ed_char_width,0
	jne @f
	xor eax,eax
	ret
	@@:
	div	word ed_char_width
	ret

;----------------------------------------------------------
;------------------ Draw Cursor Procedure -----------------
;----------------------------------------------------------
; in: ebp = Color
edit_box.clear_cursor:
	movzx	ebx, word cl_curs_x
	cmp	ebx, ed_left ;�������� �� ����� ⥪�⮢�� ����?
	jle	@f
	mov	edx, ebp
	movzx	ecx, word cl_curs_y
	cmp	ecx, ed_top
	jg	edit_box_draw.curs
@@:
	ret

edit_box_draw.cursor:
	mov	edx, ed_text_color
	mov	eax, ed_pos
	sub	eax, ed_offset
	mul	dword ed_char_width
	mov	ebx, eax
	add	ebx, ed_left
	inc	ebx
	mov	ecx, ed_top
	add	ecx, 2
	mov	cl_curs_x, bx
	mov	cl_curs_y, cx
edit_box_draw.curs:
	mov	eax, ebx
	shl	ebx, 16
	or	ebx, eax
	mov	eax, ecx
	shl	ecx, 16
	or	ecx, eax
	add	ecx, ed_height
	sub	ecx, 3
	mcall	SF_DRAW_LINE
	ret

;----------------------------------------------------------
;--- ��楤�� �ᮢ���� ࠬ�� ----------------------------
;----------------------------------------------------------
edit_box_draw.border:
	test	word ed_flags,ed_focus
	mov	edx,ed_focus_border_color
	jne	@f
	mov	edx,ed_blur_border_color
@@:
       ;mov     edx,$808080
	mov	ebx,ed_left
	mov	eax,ebx
	shl	ebx,16
	add	ebx,eax
	;add     ebx,ed_width
	mov	ecx,ed_top
	mov	eax,ecx
	shl	ecx,16
	add	ecx,eax
	push	ecx
	inc	ecx
	add	ecx,ed_height
	mcall	SF_DRAW_LINE ; left
	xchg	ecx,[esp]
	add	ebx,ed_width
	mcall		     ; top
       ;or      edx,-1
	pop	ecx
	push	cx
	push	cx
	push	ebx
	push	bx
	push	bx
	pop	ebx
	mcall		     ; right
	pop	ebx
	pop	ecx
	mcall		     ; bottom
	ret

;----------------------------------------------------------
;--- �஢�ઠ, ��襫 �� ����� �� �࠭��� �, �᫨ ����, ---
;--- �����塞 ᬥ饭�� ------------------------------------
;--- �᫨ ᬥ饭�� �뫮, ��⠭���� 䫠�� ed_offset_cl, ����,
; �᫨ ��祣� �� ����������, � ���⠢����� ed_offset_fl
; � ��饩 ��⮢�� ����� ���ﭨ� ��������⮢ word ed_flags
;----------------------------------------------------------
edit_box.check_offset:
	pushad
	mov	ecx,ed_pos
	mov	ebx,ed_offset
	cmp	ebx,ecx
	ja	edit_box.sub_8
	push	ebx
	call	edit_box.get_n
	pop	ebx
	mov	edx,ebx
	add	edx,eax
	inc	edx	;����室��� ��� ��ଠ�쭮�� ��������� ����� � �ࠩ��� ����� ����樨
	cmp	edx,ecx
	ja	@f
	mov	edx,ed_size
	cmp	edx,ecx
	je	edit_box.add_end
	sub	edx,ecx
	cmp	edx,8
	jbe	edit_box.add_8
	add	ebx,8
	jmp	edit_box.chk_d

@@:	or	word ed_flags,ed_offset_fl
	popad
	ret

edit_box.sub_8:
	test	ecx,ecx
	jz	@f
	sub	ebx,8	;ebx=ed_offset
	ja	edit_box.chk_d
@@:
	xor	ebx,ebx
	jmp	edit_box.chk_d

edit_box.add_end:
	sub	edx,eax
	mov	ebx,edx
	jmp	edit_box.chk_d

edit_box.add_8:
	add	ebx,edx
edit_box.chk_d:
	mov	ed_offset,ebx
	call	edit_box_draw.bg
	and	word ed_flags,ed_offset_cl
	popad
	ret

align 4
proc edit_box_set_text, edit:dword, text:dword
	pushad
	mov	edi,[edit]
	mov	ecx,ed_max
	inc	ecx
	mov	edi,[text]
	xor	al,al
	cld
	repne scasb
	mov	ecx,edi
	mov	edi,[edit]
	mov	esi,[text]
	sub	ecx,esi
	dec	ecx
	mov	ed_size,ecx
	mov	ed_pos,ecx
	and	word ed_flags,ed_shift_cl
	mov	edi,ed_text
	repne movsb
	mov	byte[edi],0
	popad
	ret
endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;�㭪樨 ��� ࠡ��� � key
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;��ࠡ�⪠ Shift ��� ���� �뤥����� �������⭮� ������
edit_box_key.shift:
	call	edit_box_draw.bg
	test	word ed_flags,ed_shift
	je	edit_box_key.f_exit
	mov	ebp,shift_color
	or	word ed_flags,ed_shift_bac ;��⠭���� 䫠��, �뤥������ ������
	movzx	ebx, word ed_shift_pos
	call	edit_box_key.sh_cl_
	jmp	edit_box_draw.cursor_text

edit_box_key.f_exit:
	call	edit_box.check_offset
	and	word ed_flags,ed_shift_cl
	call	edit_box_key.enable_null
	jmp	edit_box_draw.cursor_text

edit_box_key.sh_cl_:
;��ࠡ�⪠ ���⪨, �� ����� - �ࠢ�� �������� �뤥�����
;��� ��ࠡ�⪨ ���� �뤥�����
;�室�� ��ࠬ���� ebp=color ebx=ed_shift_pos
	mov	eax,ed_pos
	cmp	eax,ebx
	jae	edit_box_key.sh_n
	push	eax  ;����襥 � eax
	push	ebx  ;����襥
	jmp	edit_box_key.sh_n1

edit_box_key.sh_n:
	push	ebx
	push	eax
edit_box_key.sh_n1:
	call	edit_box.check_offset
	call	edit_box.get_n
	mov	ecx,ed_offset
	add	eax,ecx ;eax = w_off= ed_offset+width
	mov	edx,eax ;save
	pop	ebx	;����襥
	pop	eax	;����襥
	cmp	eax,ecx 	;�ࠢ����� ����襣� � offset.
	jae	edit_box_key.f_f	    ;�᫨ �����
	xor	eax,eax
	cmp	edx,ebx 	;cࠢ��� ࠧ��� w_off � ����訬
	jnb	@f
	mov	ebx,edx
@@:
	sub	ebx,ecx
	jmp	edit_box_key.nxt_f

edit_box_key.f_f:
	sub	eax,ecx
	cmp	edx,ebx 	;cࠢ��� ࠧ��� w_off � ����訬
	jle	@f
	sub	ebx,ecx
	sub	ebx,eax
	jmp	edit_box_key.nxt_f

@@:	mov	ebx,edx
	sub	ebx,ecx
	sub	ebx,eax
edit_box_key.nxt_f:
	mul	dword ed_char_width
	xchg	eax,ebx
	mul	dword ed_char_width
	add	ebx,ed_left
	inc	ebx
	shl	ebx,16
	inc	eax
	mov	bx, ax
	mov	edx,ebp ;shift_color
	call	edit_box_draw.bg_eax
	jmp	edit_box_key.enable_null

;��⠭����- ��⨥ �뤥����� � ���� ᨬ���
edit_box_key.drw_sim:
	mov	eax,ed_pos
	call	edit_box_key.draw_rectangle
	jmp	edit_box_key.enable_null

;�㭪�� ��⠭���� �뤥����� �� �������� ����� � ��ࠢ� � ����⨨ shift
edit_box_key.draw_wigwag:
	mov	ebp,shift_color
	call	edit_box.clear_cursor
	or	word ed_flags,ed_shift_bac ;��⠭���� 䫠�� �뤥������ ������
	mov	ebp,shift_color
	mov	eax,ed_pos
	test	word ed_flags,ed_left_fl
	jnz	edit_box_key.draw_rectangle
	dec	eax
	jmp	edit_box_key.draw_rectangle

;�㭪�� 㤠����� �뤥����� �� �������� ����� � ��ࠢ� � ����⨨ shift
edit_box_key.draw_wigwag_cl:
	mov	ebp,ed_color
	call	edit_box.clear_cursor
	mov	ebp,ed_color
	mov	eax,ed_pos
	test	word ed_flags,ed_left_fl
	jnz	edit_box_key.draw_rectangle
	dec	eax
	jmp	edit_box_key.draw_rectangle

;�室��� ��ࠬ��� ebx - ed_pos
edit_box_key.sh_first_sh:
	test	word ed_flags,ed_shift
	je	@f
	mov	ed_shift_pos_old,bx
	test	word ed_flags,ed_shift_on
	jne	@f
	mov	ed_shift_pos,bx
	or	word ed_flags,ed_shift_on
@@:	ret
;��ࠡ�⪠ �ࠩ��� ��������� � editbox �� ����⮬ shift
;�ந������ ��⨥ �뤥�����, �᫨ ��� shift
;���� ����� ��室��
edit_box_key.sh_st_of:
	test	word ed_flags,ed_shift
	jne	@f
	test	word ed_flags,ed_shift_bac
	je	@f
	call	edit_box_draw.bg
	mov	ebp,ed_color
	movzx	ebx, word ed_shift_pos
	call	edit_box_key.sh_cl_  ;���⪠ �뤥������ �ࠣ����
	and	word ed_flags,ed_shift_cl ; ���⪠ �� ⮣�, �� �ࠫ� �뤥�����
	jmp	edit_box_draw.cursor_text

@@:	and	word ed_flags,ed_shift_off
	popad
	ret	4
;�஢�ઠ ���ﭨ� shift, �� �� �� ����� ࠭��?
edit_box_key.sh_enable:
	test	word ed_flags,ed_shift
	jne	edit_box_key.sh_ext_en ;���ᮢ��� ����襭�� ��אַ㣮�쭨�
	test	word ed_flags,ed_shift_bac
	je	@f
	call	edit_box.check_offset
	mov	ebp,ed_color
	movzx	ebx, word ed_shift_pos
	call	edit_box_key.sh_cl_  ;���⪠ �뤥������� �ࠣ����
	call	edit_box_key.draw_wigwag_cl
	and	word ed_flags,ed_shift_cl ; 1��� �� �㦭�
	ret

@@:	mov	ebp,ed_color
	call	edit_box.clear_cursor
	jmp	edit_box.check_offset

edit_box_key.sh_ext_en:
	call	edit_box.check_offset
	test	word ed_flags,ed_offset_fl
	je	@f
;��ᮢ���� ����襭��� ��אַ㣮�쭨��� � �� ���⪠
	movzx	eax, word ed_shift_pos
	mov	ebx,ed_pos
	movzx	ecx, word ed_shift_pos_old
;�஢�ઠ � �ᮢ���� ����襭��� �����⥩
	cmp	eax,ecx
	je	edit_box_key.1_shem
	jb	edit_box_key.smaller
	cmp	ecx,ebx
	ja	edit_box_key.1_shem
	call	edit_box_key.draw_wigwag_cl ;clear
	jmp	edit_box_key.sh_e_end

edit_box_key.smaller:
	cmp	ecx,ebx
	jb	edit_box_key.1_shem
	call	edit_box_key.draw_wigwag_cl ;clear
	jmp	edit_box_key.sh_e_end

edit_box_key.1_shem:
	call	edit_box_key.draw_wigwag
edit_box_key.sh_e_end:
	and	word ed_flags,ed_shift_off
	ret

@@:	mov	ebp,shift_color
	movzx	ebx, word ed_shift_pos
	call	edit_box_key.sh_cl_
	jmp	edit_box_key.sh_e_end
;�㭪�� ��� ��ࠡ�⪨ shift �� ����⨨ home and end
edit_box_key.sh_home_end:
	mov	ebp,ed_color
	call	edit_box.clear_cursor
	test	word ed_flags,ed_shift_bac
	je	@f
	mov	ebp,ed_color
	movzx	ebx, word ed_shift_pos_old
	call	edit_box_key.sh_cl_
@@:
	test	word ed_flags,ed_shift
	je	edit_box_key.sh_exit_ ;���
	mov	ebp,shift_color
	movzx	ebx, word ed_shift_pos
	call	edit_box_key.sh_cl_
	or	word ed_flags,ed_shift_bac ;��⠭���� 䫠��, �뤥������ ������
	jmp	edit_box_key.sh_e_end

edit_box_key.sh_exit_:
	call	edit_box_draw.bg
	jmp	edit_box.check_offset

;�㭪�� ���ᥭ�� 0 �� ����� ed_size+1
edit_box_key.enable_null:
	pusha
	mov	eax,ed_size
	mov	ebx,ed_text
	test	eax,eax
	add	eax,ebx
	jne	@f
	inc	eax
@@:	xor	ebx,ebx
	mov	[eax],bl
	popad
	ret

;- 㤠����� ᨬ����
;�室�� ����� edx=ed_size;ecx=ed_pos
edit_box_key.del_char:
	mov	esi,ed_text
	test	word ed_flags,ed_shift_on
	je	@f
	movzx	eax, word ed_shift_pos
	mov	ebx,esi
	cmp	eax,ecx
	jae	edit_box_key.dh_n
	mov	ed_pos,eax	;�⮡� �� �뫮 㡥����� �����
	mov	ebp,ecx
	sub	ebp,eax
	add	ebx,eax  ;eax �����
	sub	edx,ecx
	add	esi,ecx
	mov	ed_shift_pos,bp
	jmp	edit_box_key.del_ch_sh

edit_box_key.dh_n:
	mov	ebp,eax
	sub	ebp,ecx
	add	ebx,ecx
	sub	edx,eax
	add	esi,eax
	mov	ed_shift_pos,bp
	jmp	edit_box_key.del_ch_sh

@@:	add	esi,ecx ;㪠��⥫� + ᬥ饭�� � ॠ�쭮�� �����
	mov	ebx,esi
	inc	esi
	cld
	sub	edx,ecx
edit_box_key.del_ch_sh:
	push	edi
	mov	edi,ebx
@@:
	lodsb
	stosb
	dec	edx
	jns	@b
	pop	edi
	ret
;���᫨�� ����訢����� �������
;ᮣ��襭�� � ebp - ��।����� ed_size
edit_box_key.clear_bg:
	call	edit_box.get_n	;������� ࠧ��� � ᨬ����� �ਭ� ���������
	push	eax
	mov	ebx,ed_offset
	add	eax,ebx ;eax = w_off= ed_offset+width
	mov	ebx,ebp ;ed_size
	cmp	eax,ebx
	jb	@f
	mov	eax,ed_pos
	sub	ebx,eax
	sub	eax,ed_offset
	jmp	edit_box_key.nxt

@@:	mov	ebx,ed_pos
	push	ebx
	sub	eax,ebx
	mov	ebx,eax ;It is not optimal
	pop	eax	;ed_pos
	sub	eax,ed_offset
edit_box_key.nxt:
	mov	ebp,eax  ;�஢�ઠ �� ��室 ����訢����� ������ �� �।��� �����
	add	ebp,ebx
	pop	edx
	cmp	ebp,edx
	je	@f
	inc	ebx
@@:
	mul	dword ed_char_width
	xchg	eax,ebx
	mul	dword ed_char_width
	add	ebx,ed_left
	inc	ebx
	shl	ebx,16
	inc	eax
	mov	bx, ax
	mov	edx,ed_color
	jmp	edit_box_draw.bg_eax

;;;;;;;;;;;;;;;;;;;
;;; ��ࠡ�⪠ �ਬ�⨢��
;;;;;;;;;;;;;;;;;;;;
;���ᮢ��� ��אַ㣮�쭨�, 梥� ��।����� � ebp
;�室�� ��ࠬ����:
;eax=dword ed_pos
;ebp=-梥� ed_color or shift_color
edit_box_key.draw_rectangle:
	sub	eax,ed_offset
	mul	dword ed_char_width
	add	eax,ed_left
	inc	eax
	shl	eax,16
	add	eax,ed_char_width
	mov	ebx,eax
	mov	edx,ebp
	jmp	edit_box_draw.bg_eax

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;�㭪樨 ��� ࠡ��� � mouse
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
edit_box_mouse.mouse_wigwag:
	push	eax
	call	edit_box_draw.bg
	call	edit_box_draw.shift
	pop	eax
	or	word ed_flags,ed_shift_bac+ed_shift_on+ed_shift
;��ࠡ�⪠ ��������� �뤥������� ⥪��, ����� �ந�室�� ��室 �� �।��� editbox
	test	eax,eax
	js	edit_box_mouse.mleft
	shr	eax,16
	sub	eax,ed_left
	jc	edit_box_mouse.mleft
	cmp	ed_width,eax
	jc	edit_box_mouse.mright
	xor	edx,edx
	div	word ed_char_width
;��ࠡ�⪠ ��������� �뤥������� ⥪��, � �।���� ������ editbox
;����稫� ���न���� � eax ��誨, �.�. �㤠 ��� ��६��⨫���
;��ᮢ���� ����襭��� ��אַ㣮�쭨��� � �� ���⪠
	add	eax,ed_offset
	cmp	eax,ed_size
	ja	edit_box_mouse.mwigvag
edit_box_mouse.mdraw:
	mov	ed_pos,eax
;��ᮢ���� ����襭��� ��אַ㣮�쭨��� � �� ���⪠
	movzx	ecx, word ed_shift_pos
	movzx	ebx, word ed_shift_pos_old
	mov	ed_shift_pos_old,ax
;�஢�ઠ � �ᮢ���� ����襭��� �����⥩
	cmp	ecx,ebx
	je	edit_box_mouse.m1_shem	;�������� �� �뫮 ࠭��
	jb	edit_box_mouse.msmaller ;�뫮 �������� ->
	cmp	ebx,eax
	ja	edit_box_mouse.m1_shem	;�뫮 �������� <-
	je	edit_box_mouse.mwigvag
	mov	ebp,ed_color
	call	edit_box_key.sh_cl_	;������ ������� c ed_pos ed_shift_pos_old
	jmp	edit_box_mouse.mwigvag

edit_box_mouse.msmaller:
	cmp	ebx,eax
	jb	edit_box_mouse.m1_shem
	mov	ebp,ed_color
	call	edit_box_key.sh_cl_
	jmp	edit_box_mouse.mwigvag

edit_box_mouse.m1_shem:
	mov	ebp,shift_color
	mov	ebx,ecx
	call	edit_box_key.sh_cl_
edit_box_mouse.mwigvag:
	and	word ed_flags,ed_shift_mcl
	jmp	edit_box_draw.cursor_text

edit_box_mouse.mleft:
	mov	eax,ed_pos
	cmp	eax,0
	jbe	edit_box_mouse.mwigvag
	dec	eax
	call	edit_box.check_offset
	push	eax
	movzx	ebx, word ed_shift_pos
	mov	ebp,shift_color
	call	edit_box_key.sh_cl_
	pop	eax
	jmp	edit_box_mouse.mdraw

edit_box_mouse.mright:
	mov	eax,ed_pos
	mov	ebx,ed_size
	cmp	eax,ebx
	jae	edit_box_mouse.mwigvag
	inc	eax
	call	edit_box.check_offset
	movzx	ebx, word ed_shift_pos
	mov	ebp,shift_color
	push	eax
	call	edit_box_key.sh_cl_
	pop	eax
	jmp	edit_box_mouse.mdraw


ed_struc_size=84
