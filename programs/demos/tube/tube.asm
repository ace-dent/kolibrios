; SPDX-License-Identifier: GPL-2.0
; Ported tube demo by VT
; Copyright (C) 2001 Miloš Bazelides <baze@stonline.sk>
; Copyright (C) 2006-2025 KolibriOS team

; Original comments: 
;  256b intro by baze/3SC for Syndeecate 2001
;  loveC: thanks, Serzh: eat my socks dude ;]
;  e-mail: baze@stonline.sk, web: www.3SC.sk

; Original source: https://baze.sk/3sc/files/tube.zip

use32
	org  0
	db   'MENUET01'
	dd   1,START,image_end,memory_end,stacktop,0,0

include '../../macros.inc'
include '../../KOSfuncs.inc'

title db 'Tube - FPU',0

SCREEN_W dd 600-10 ;10 px for borders
SCREEN_H dd 400-10

align 4
START:
	mcall SF_SYS_MISC,SSF_HEAP_INIT
	call OnResize
	call draw_window
	fninit
	fldz
	push ebx

still:
	pop  ebx
	call MAIN
	push ebx

	mcall SF_WAIT_EVENT_TIMEOUT,1

	cmp  eax,EV_REDRAW
	jne  no_red
	call draw_window
	jmp  still
 no_red:

	or   eax,eax
	jz   still

	mcall SF_TERMINATE_PROCESS

align 4
OnResize:
	mov ecx,[SCREEN_W]
	imul ecx,[SCREEN_H]
	;ecx = SCREEN_W*SCREEN_H
	mcall SF_SYS_MISC,SSF_MEM_REALLOC,,[PIXBUF]
	mov [PIXBUF],eax
	lea ecx,[ecx+2*ecx]
	mcall SF_SYS_MISC,SSF_MEM_REALLOC,,[buf2]
	mov [buf2],eax
	ret

align 4
MAIN:
;edx - coord y
;ebp - coord x
;edi - pixel buffer
	add    ebx,10 shl 8
	mov    edi,[PIXBUF]
	fadd   dword [TEXUV-4]
	push   edi
	mov    edx,[SCREEN_H]
	inc    edx ;fix (height%2)==1
	shr    edx,1
	neg    edx ;edx=-SCREEN_H/2
align 4
TUBEY:
	mov    ebp,[SCREEN_W]
	inc    ebp ;fix (width%2)==1
	shr    ebp,1
	neg    ebp ;ebp=-SCREEN_W/2
align 4
TUBEX:
	mov    esi,TEXUV
	fild   dword [SCREEN_W]
	fld1
	fld1
	faddp
	fdivp  ;st0=SCREEN_W/2
	mov    [esi],ebp
	fild   word [esi]
	mov    [esi],edx
	fild   word [esi]
	mov    cl,2

ROTATE:
	fld    st3
	fsincos
	fld    st2
	fmul   st0,st1
	fld    st4
	fmul   st0,st3
	fsubp  st1,st0
	fxch   st3
	fmulp  st2,st0
	fmulp  st3,st0
	faddp  st2,st0
	fxch   st2
	loop   ROTATE

	fld    st1
	fmul   st0,st0
	fld    st1
	fmul   st0,st0
	faddp  st1,st0
	fsqrt
	
	fdivp  st3,st0
	fpatan
	fimul  word [esi-4]
	fistp  word [esi]
	fimul  word [esi-4]
	fistp  word [esi+1]
	mov    esi,[esi]

	lea    eax,[ebx+esi]
	add    al,ah
	and    al,64
	mov    al,-5
	jz     STORE_1

	shl    esi,2
	lea    eax,[ebx+esi]
	sub    al,ah
	mov    al,-16
	jns    STORE_1

	shl    esi,1
	mov    al,-48

STORE_1:
; add    al,[ebx+esi+0x80000]
	add    [edi],al
	inc    edi
	inc    ebp
	mov    eax,[SCREEN_W]
	shr    eax,1 ;eax=SCREEN_W/2
	cmp    ebp,eax

	jnz    TUBEX
	inc    edx
	mov    eax,[SCREEN_H]
	shr    eax,1 ;eax=SCREEN_H/2
	cmp    edx,eax
	jnz    TUBEY

	call   display_image

	pop    esi ;esi=PIXBUF
	mov    ecx,[SCREEN_W]
	imul   ecx,[SCREEN_H]

align 4
BLUR:
	sar    byte [esi],2
	inc    esi
	loop   BLUR
	ret


align 4
display_image:
	pusha

	mov esi,[PIXBUF]
	mov edi,[buf2]
	mov eax,[SCREEN_W]
	imul eax,[SCREEN_H]
	add eax,esi
align 4
newp:
	movzx edx,byte [esi]
	shl edx,4

	mov word [edi],dx ;blue,green
	;shr edx,16
	;mov [edi+2],dl ;red - not used

	add edi,3
	inc esi

	cmp esi,eax
	jb newp

	xor edx,edx
	mov ecx,[SCREEN_W]
	shl ecx,16
	add ecx,[SCREEN_H]
	mcall SF_PUT_IMAGE,[buf2]

	popa
	ret


align 4
draw_window:
	pusha

	mcall SF_REDRAW, SSF_BEGIN_DRAW
	mcall SF_STYLE_SETTINGS, SSF_GET_SKIN_HEIGHT
	add eax,[SCREEN_H]
	lea ecx,[100*65536+4+eax]
	mov ebx,[SCREEN_W]
	add ebx,(100 shl 16)+9
	mcall SF_CREATE_WINDOW,,, 0x73000000,,title
	
	mcall SF_THREAD_INFO,procinfo,-1
	mcall SF_STYLE_SETTINGS, SSF_GET_SKIN_HEIGHT
	add eax,4
	sub eax,[procinfo.box.height]
	neg eax
	cmp eax,[SCREEN_H]
	je .end_h
	cmp eax,32 ;min height
	jge @f
		mov eax,32
	@@:
		mov [SCREEN_H],eax
		xor eax,eax
		mov [SCREEN_W],eax
	.end_h:
	
	mov eax,[procinfo.box.width]
	sub eax,9
	cmp eax,[SCREEN_W]
	je .resize_end
	cmp eax,64 ;min width
	jge @f
		mov eax,64
	@@:
	mov [SCREEN_W],eax

	call OnResize
	.resize_end:

	mcall SF_REDRAW, SSF_END_DRAW
	popa
	ret

align 4
	db 41,0,0xC3,0x3C
TEXUV:
	rd 1

align 4
image_end:

PIXBUF	rd	1
buf2	rd	1
procinfo process_information

		rb	1024
align 4
stacktop:
memory_end:
