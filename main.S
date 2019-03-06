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
		.equ	_sysbase,0x4f2
	
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
		move.l	d0,a4

| Check for TOS version
		move.l	_sysbase.w,a6
		cmpi.l	#0x45544F53,0x2c(a6)	| 'ETOS' = EmuTOS
		beq		notneeded
		move.w	2(a6),d2
		cmpi.w	#0x200,d2				| TOS 2.0x
		bge		notneeded
		cmpi.w	#0x100,d2				| TOS 1.00
		bne		tos102
		move.l	#0x0029AA,d1
		bra		install
		
tos102:	cmpi.w	#0x102,d2				| TOS 1.02: we have to check the date for this
		bne		tos104
		move.l	24(a6),d3
		cmpi.l	#0x04221987,d3			| LANG = 0...3
		bne		tos102a
		move.l	#0x002B5C,d1
		bra		install
tos102a:cmpi.l	#0x09151987,d3			| LANG = 6
		bne		tos102b
		move.l	#0x0029DC,d1
		bra		install
tos102b:cmpi.l	#0x09161987,d3			| LANG = 8
		bne		tos102c
		move.l	#0x0029DC,d1
		bra		install
tos102c:cmpi.l	#0x05111988,d3			| LANG = 4
		bne		unsupported
		move.l	#0x0029D4,d1
		bra		install

tos104:	cmpi.w	#0x104,d2				| TOS 1.04
		bne		tos106
		move.l	#0x003C70,d1
		bra		install

tos106:	cmpi.w	#0x0106,d2				| TOS 1.06
		beq		tos16x
		cmpi.w	#0x0162,d2				| TOS 1.62
		bne		unsupported
tos16x:	move.l	#0x003E24,d1

install:
		add.l	8(a6),d1				| address of TOS start
		move.l	#0x4B494E4A,d0			| 'KINJ'
		jsr		CK_WriteJar

		move.l	a4,-(sp)				| Super
		move.w	#32,-(sp)
		trap	#1
		addq.l	#6,sp

		move.w	#0,-(sp)				| Ptermres
		sub.l	#STACK_SIZE,d6			| resident SW doesn't need the stack
		move.l	d6,-(sp)
		move.w	#49,-(sp)
		trap	#1

unsupported:
		pea		unsup_str				| Cconws
fail:	move.w	#9,-(sp)
		trap	#1
		addq.l	#6,sp

		move.l	a4,-(sp)				| Super
		move.w	#32,-(sp)
		trap	#1
		addq.l	#6,sp

		move.w	#1,-(sp)				| Pterm
		move.w	#76,-(sp)
		trap	#1

notneeded:
		pea		notneed_str
		bra		fail

.data
unsup_str:
		.asciz "This TOS version is not supported!\r\n"
notneed_str:
		.asciz "Not needed for this TOS version!\r\n"