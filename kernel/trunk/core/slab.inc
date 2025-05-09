;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                              ;;
;; Copyright (C) KolibriOS team 2013-2024. All rights reserved. ;;
;; Distributed under terms of the GNU General Public License    ;;
;;                                                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Memory management for slab structures.
; The allocator meets special requirements:
; * memory blocks are properly aligned
; * memory blocks do not cross page boundary
; The allocator manages fixed-size blocks.
; Thus, the specific allocator works as follows:
; allocate one page, split into blocks, maintain the single-linked
; list of all free blocks in each page.

; Note: size must be a multiple of required alignment.

; Data for one pool: dd pointer to the first page, MUTEX lock.

; Allocator for fixed-size blocks: allocate a block.
; [ebx-4] = pointer to the first page, ebx = pointer to MUTEX structure.
proc slab_alloc
        push    edi     ; save used register to be stdcall
virtual at esp
        dd      ?       ; saved edi
        dd      ?       ; return address
.size   dd      ?
end virtual
; 1. Take the lock.
        mov     ecx, ebx
        call    mutex_lock
; 2. Find the first allocated page with a free block, if any.
; 2a. Initialize for the loop.
        mov     edx, ebx
.pageloop:
; 2b. Get the next page, keeping the current in eax.
        mov     eax, edx
        mov     edx, [edx-4]
; 2c. If there is no next page, we're out of luck; go to 4.
        test    edx, edx
        jz      .newpage
        add     edx, 0x1000
@@:
; 2d. Get the pointer to the first free block on this page.
; If there is no free block, continue to 2b.
        mov     eax, [edx-8]
        test    eax, eax
        jz      .pageloop
; 2e. Get the pointer to the next free block.
        mov     ecx, [eax]
; 2f. Update the pointer to the first free block from eax to ecx.
; Normally [edx-8] still contains eax, if so, atomically set it to ecx
; and proceed to 3.
; However, the price of simplicity of slab_free (in particular, it doesn't take
; the lock) is that [edx-8] could (rarely) be changed while we processed steps
; 2d+2e. If so, return to 2d and retry.
        lock cmpxchg [edx-8], ecx
        jnz     @b
.return:
; 3. Release the lock taken in step 1 and return.
        push    eax
        mov     ecx, ebx
        call    mutex_unlock
        pop     eax
        pop     edi     ; restore used register to be stdcall
        ret     4
.newpage:
; 4. Allocate a new page.
        push    eax
        stdcall kernel_alloc, 0x1000
        pop     edx
; If failed, say something to the debug board and return zero.
        test    eax, eax
        jz      .nomemory
; 5. Add the new page to the tail of list of allocated pages.
        mov     [edx-4], eax
; 6. Initialize two service dwords in the end of page:
; first free block is (start of page) + (block size)
; (we will return first block at (start of page), so consider it allocated),
; no next page.
        mov     edx, eax
        lea     edi, [eax+0x1000-8]
        add     edx, [.size]
        mov     [edi], edx
        and     dword [edi+4], 0
; 7. All blocks starting from edx are free; join them in a single-linked list.
@@:
        mov     ecx, edx
        add     edx, [.size]
        mov     [ecx], edx
        cmp     edx, edi
        jbe     @b
        sub     ecx, [.size]
        and     dword [ecx], 0
; 8. Return (start of page).
        jmp     .return
.nomemory:
        dbgstr 'no memory for slab allocation'
        xor     eax, eax
        jmp     .return
endp

; Allocator for fixed-size blocks: free a block.
proc slab_free
        push    ecx edx
virtual at esp
        rd      2       ; saved registers
        dd      ?       ; return address
.block  dd      ?
end virtual
; Insert the given block to the head of free blocks in this page.
        mov     ecx, [.block]
        mov     edx, ecx
        or      edx, 0xFFF
@@:
        mov     eax, [edx+1-8]
        mov     [ecx], eax
        lock cmpxchg [edx+1-8], ecx
        jnz     @b
        pop     edx ecx
        ret     4
endp
