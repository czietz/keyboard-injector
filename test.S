|	Copyright (c) 2019 Christian Zietz <czietz@gmx.net>
|	
|	Permission is hereby granted, free of charge, to any person obtaining a copy
|	of this software and associated documentation files (the "Software"), to deal
|	in the Software without restriction, including without limitation the rights
|	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
|	copies of the Software, and to permit persons to whom the Software is
|	furnished to do so, subject to the following conditions:
|	
|	The above copyright notice and this permission notice shall be included in all
|	copies or substantial portions of the Software.
|	
|	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
|	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
|	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
|	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
|	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
|	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
|	SOFTWARE.

		.equ 	BASEPAGE_SIZE,0x100
		.equ	STACK_SIZE,0x1000

		.text

start:
		move.l	4(sp),a5				| address to basepage
		move.l	0x0c(a5),d6				| length of text segment
		add.l	0x14(a5),d6				| length of data segment
		add.l	0x1c(a5),d6				| length of bss segment
		add.l	#STACK_SIZE+BASEPAGE_SIZE,d6		| length of stackpointer+basepage
		move.l	a5,d1					| address to basepage
		add.l	d6,d1					| end of program
		and.l	#0xfffffff0,d1			| align stack
		move.l	d1,sp					| new stackspace

		move.l	d6,-(sp)				| Mshrink()
		move.l	a5,-(sp)
		clr.w	-(sp)
		move.w	#0x4a,-(sp)
		trap	#1
		lea.l	12(sp),sp

		pea		0						| Super
		move.w	#32,-(sp)
		trap	#1
		addq.l	#6,sp
		move.l	d0,oldsp

		move.w	#1,-(sp)				| Iorec
		move.w	#14,-(sp)
		trap	#14
		addq.l	#4,sp
		move.l	d0,iorec

| Find cookie
		move.l	#0x4B494E4A,d0			| 'KINJ'
		move.l	#kinj_vector,a0
		bsr		CK_ReadJar
		tst.w	d0
		bne		dotest
		pea		no_cookie
		bra		finish

dotest:
| Clear input queue
		move.w	#2,-(sp)				| Bconstat
		move.w	#1,-(sp)
		trap	#13
		addq.l	#4,sp
		tst.w	d0
		beq		simkey
		move.w	#2,-(sp)				| Bconin
		move.w	#2,-(sp)
		trap	#13
		addq.l	#4,sp
		bra dotest

simkey:
| Simulate 'X' press and release
		move.l	kinj_vector,a2
		suba.l	a5,a5
		move.l	#45,d0
		movea.l	iorec,a0
		jsr		(a2)

		move.l	kinj_vector,a2
		suba.l	a5,a5
		move.l	#45+128,d0
		movea.l	iorec,a0
		jsr		(a2)

| Read back
		move.w	#2,-(sp)				| Bconstat
		move.w	#1,-(sp)
		trap	#13
		addq.l	#4,sp
		tst.w	d0
		bne		readkey
		pea		no_key
		bra		finish
		
readkey:move.w	#2,-(sp)				| Bconin
		move.w	#2,-(sp)
		trap	#13
		addq.l	#4,sp
		
		cmp.b	#'x',d0
		beq		readok
		pea		wrong_key
		bra		finish
readok:	pea		test_passed

finish:	
		move.l	(sp),a0					| message
strlen:	tst.b	(a0)+
		bne		strlen
		sub.l	(sp),a0
		sub.l	#2,a0
		move.l	(sp),-(sp)				| Midiws
		move.w	a0,-(sp)
		move.w	#12,-(sp)
		trap	#14
		addq.l	#8,sp

		move.w	#9,-(sp)				| Cconws
		trap	#1
		addq.l	#6,sp

		move.l	oldsp,-(sp)				| Super
		move.w	#32,-(sp)
		trap	#1
		addq.l	#6,sp

		pea		hatari_quit				| Hataricontrol: terminate Hatari
		move.w	#255,-(sp)
		trap	#14

		move.w	#1,-(sp)				| Pterm
		move.w	#76,-(sp)
		trap	#1

.data
no_cookie:
		.asciz "KINJ cookie not found\r\n"
no_key:
		.asciz "No key press registered\r\n"
wrong_key:
		.asciz "Wrong key press registered\r\n"
test_passed:
		.asciz "Test passed\r\n"
hatari_quit:
		.asciz "hatari-debug q\n"
.bss
kinj_vector:
		ds.l 1
iorec:
		ds.l 1
oldsp:
		ds.l 1