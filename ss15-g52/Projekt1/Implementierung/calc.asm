; -----------------------------------------------------------------------
; Copyright (C) 2015, Mahdi Sellami, Christoph Pflüger, Niklas Rosenstein
; All rights reserved.
; -----------------------------------------------------------------------

; -----------------------------------------------------------------------
; Global Definitions
; -----------------------------------------------------------------------
global calc

; -----------------------------------------------------------------------
; Extern Definitions
; -----------------------------------------------------------------------
extern printf

; -----------------------------------------------------------------------
; Pop *n* bytes from the stack.
; -----------------------------------------------------------------------
%define stack_pop(n) add esp, n

; -----------------------------------------------------------------------
; Reserve *n* bytes on the stack.
; -----------------------------------------------------------------------
%define stack_reserve(n) sub esp, n

; -----------------------------------------------------------------------
; Computes the address of the *nth* agument on the current stack
; frame, assuming all arguments are 4 bytes wide.
; -----------------------------------------------------------------------
%define farg(n) ebp + 8 + n * 4

; -----------------------------------------------------------------------
; Computes the address of the *nth* local variable on the stack frame,
; assuking all variables are 4 bytes wide.
; -----------------------------------------------------------------------
%define fvar(n) ebp - 4 - 4 * n

; -----------------------------------------------------------------------
; \macro do_printf data_name, fmt_string
; A little macro to printf(). The first argument must be the name of a
; sublabel that is unique to the current label where the fmt_string will
; be saved.
; -----------------------------------------------------------------------
%macro do_printf 2
section .data
  .str_%1 db %2, 10, 0
section .text
  push .str_%1
  call printf
  stack_pop(4)
%endmacro

; -----------------------------------------------------------------------
; Code Section
; -----------------------------------------------------------------------
section .text

global calc
extern printf

; -----------------------------------------------------------------------
; extern void calc(int* nlines, float* data1, float* data2,
;           float* result1, float* result2)
; -----------------------------------------------------------------------
calc:
  enter 0, 0

  ; nlines = *nlines; (dereference)
  mov eax, [farg(0)]
  mov eax, [eax]
  mov [farg(0)], eax

  ; Calculate the density of each value based on data1 and data2
  ; and fill it into results1.
  mov ecx, 0
.density_loop:
  ; if (ecx >= nlines)
  cmp ecx, [farg(0)]  ; nlines
  jge .density_loop_end

  ; eax = 4 * ecx
  mov eax, 4
  mul ecx

  ; st0 = data1[ecx]
  mov esi, [farg(1)]  ; data1
  add esi, eax
  fld dword [esi]

  ; esi = data2[ecx]
  mov esi, [farg(2)]  ; data2
  add esi, eax

  ; data1[ecx] / data2[ecx]
  fdiv dword [esi]

  ; results1[ecx] = st0, pop st0
  mov esi, [farg(3)]  ; results1
  add esi, eax
  fstp dword [esi]

  ; ecx++
  add ecx, 1
  jmp .density_loop
.density_loop_end:

  ; Sort results1 using an insertion sort algorithm.
  push dword [farg(3)]  ; results1
  push dword [farg(0)]  ; nlines
  call sort
  stack_pop(8)

  ; Compute the average of all values, ignoring the 10 lowest and
  ; 10 highest values.
  mov ecx, 10                  ; ecx = 10
  mov edx, [farg(0)]           ; edx = nlines
  sub edx, 10                  ; edx = edx - 10
  dec ecx
  fldz
.avg_loop:
  inc ecx                      ; ecx++
  cmp ecx, edx
  jge .avg_end                 ; if (ecx >= edx) goto .avg_end

  ; eax = ecx * 4 + result1
  mov eax, ecx
  imul eax, 4
  add eax, [farg(3)]

  fld dword [eax]              ; st0 = result1[ecx]
  fadd to st1                  ; st1 = st0 + st1
  ffreep st0                   ; pop st0
  jmp .avg_loop
.avg_end:

  ; st0 = st0 / (nlines - 20)
  mov eax, [farg(0)]           ; eax = nlines
  sub eax, 20                  ; eax = eax - 20
  stack_reserve(4)
  mov [esp], eax
  fidiv dword [esp]
  stack_pop(4)

  ; result2[0] = st0
  mov eax, [farg(4)]
  fst dword [eax]

  ; Compute dmax
  ; result2[1] = result1[nlines - 10] - avg
  mov eax, [farg(0)]           ; eax = nlines
  sub eax, 10                  ; eax = eax - 10
  imul eax, 4                  ; eax = eax * 4
  add eax, [farg(3)]           ; eax = eax + result1
  fld dword [eax]              ; st0 = result1[nlines - 10]
  fsub st1                     ; st0 = st0 - st1 (avg)

  mov ebx, [farg(4)]           ; ebx = result2
  add ebx, 4                   ; ebx = ebx + 4
  fstp dword [ebx]

  ; Compute dmin
  ; result2[0] = avg - result1[10]
  mov eax, 10 * 4              ; eax = 10 * 4
  add eax, [farg(3)]           ; eax = eax + result1
  fld dword [eax]              ; st0 = result1[10]
  fsub st1                     ; st0 = st0 - st1 (avg)
  fchs                         ; st0 = -st0

  mov ebx, [farg(4)]           ; ebx = result2
  add ebx, 8                   ; ebx = ebx + 8
  fstp dword [ebx]

  leave
  ret

; -----------------------------------------------------------------------
; void sort(int nlines, float* data)
; -----------------------------------------------------------------------
sort:
  enter 0, 0
  stack_reserve(16)
  ; fvar(0) : i
  ; fvar(1) : j
  ; fvar(2) : i_addr = i * 4 + data
  ; fvar(3) : j_addr = j * 4 + data

  mov dword [fvar(0)], -1      ; i = -1
  fldz
.inner1:
  ffreep st0
  inc dword [fvar(0)]          ; i++
  mov ecx, [fvar(0)]           ; ecx = i
  cmp ecx, [farg(0)]           ; if (i >= nlines)
  jge .end                     ; goto .end
  ; st0 = data[ecx]
  mov eax, 4                   ; eax = 4
  mul ecx                      ; eax = eax * ecx (i)
  add eax, [farg(1)]           ; eax = eax + data
  fld dword [eax]              ; st0 = data[i]
  mov dword [fvar(2)], eax     ; i_addr

  mov dword [fvar(1)], ecx     ; j = i
.inner2:
  inc dword [fvar(1)]          ; j++
  mov ecx, [fvar(1)]           ; ecx = j
  cmp ecx, [farg(0)]           ; test i, nlines
  jge .inner1                  ; if (j >= nlines) goto .inner1
  ; st1 = data[edx]
  mov eax, 4                   ; eax = 4
  mul ecx                      ; eax = eax * ecx (j)
  add eax, [farg(1)]           ; eax = eax + data
  fld dword [eax]              ; st0 = data[j]
  mov dword [fvar(3)], eax     ; j_addr

  fcomi                        ; compare st0 (data[j]) with st1 (data[i])
  jc .swap                     ; if (data[j] < data[i]) goto .swap
  ffreep st0                   ; pop st0 (data[j])
  jmp .inner2
.swap:
  mov eax, [fvar(2)]           ; eax = i_addr
  fstp dword [eax]             ; data[i] = st0 (data[j]), pop
  mov eax, [fvar(3)]           ; eax = j_addr
  fstp dword [eax]             ; data[j] = st0 (data[i]), pop
  mov eax, [fvar(2)]           ; eax = i_addr
  fld dword [eax]              ; st0 = data[i]
  jmp .inner2
.end:
  leave
  ret
