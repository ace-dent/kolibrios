;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                              ;;
;; Copyright (C) KolibriOS team 2004-2024. All rights reserved. ;;
;; Distributed under terms of the GNU General Public License    ;;
;;                                                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                            ;;
;;                     SYSENTER ENTRY                         ;;
;;                                                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

align 32
sysenter_entry:
        ; Setting up the stack
        mov     esp, [ss:tss._esp0]
        sti
        push    ebp                     ; save app esp + 4
        mov     ebp, [ebp]              ; ebp - original ebp
        ;------------------
        pushad
        cld

        call    protect_from_terminate

        movzx   eax, byte [esp+28]
        mov     edx, dword [esp+20]
        call    dword [servetable2 + eax * 4]

        call    unprotect_from_terminate
        popad
        ;------------------
        xchg    ecx, [ss:esp]           ; in the stack top - app ecx, ecx - app esp + 4
        sub     ecx, 4
        xchg    edx, [ecx]              ; edx - return point, & save original edx
        push    edx
        mov     edx, [ss:esp + 4]
        mov     [ecx + 4], edx          ; save original ecx
        pop     edx
        sysexit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                            ;;
;;                   SYSTEM CALL ENTRY                        ;;
;;                                                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

align 16
i40:
        pushad
        cld
        call    protect_from_terminate
        movzx   eax, byte [esp+28]
        mov     edx, dword [esp+20]
        call    dword [servetable2 + eax * 4]
        call    unprotect_from_terminate
        popad
        iretd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                            ;;
;;                     SYSCALL ENTRY                          ;;
;;                                                            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
align 32
syscall_entry:
  ;     cli                 syscall clear IF
        xchg    esp, [ss:tss._esp0]
        push    ecx
        lea     ecx, [esp+4]
        xchg    ecx, [ss:tss._esp0]
        sti
        push    ecx
        mov     ecx, [ecx]
        ;------------------
        pushad
        cld
        call    protect_from_terminate

        movzx   eax, byte [esp+28]
        mov     edx, dword [esp+20]
        call    dword [servetable2 + eax * 4]

        call    unprotect_from_terminate
        popad
        ;------------------
        mov     ecx, [ss:esp+4]
        pop     esp
        sysret

iglobal
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; SYSTEM FUNCTIONS TABLE ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  align 4
  servetable2:

      dd syscall_draw_window     ; 0-DrawWindow
      dd syscall_setpixel        ; 1-SetPixel
      dd sys_getkey              ; 2-GetKey
      dd sys_clock               ; 3-GetTime
      dd syscall_writetext       ; 4-WriteText
      dd delay_hs_unprotected    ; 5-DelayHs
      dd undefined_syscall       ; 6-deprecated OpenRamdiskFile
      dd syscall_putimage        ; 7-PutImage
      dd syscall_button          ; 8-DefineButton
      dd sys_cpuusage            ; 9-GetProcessInfo
      dd sys_waitforevent        ; 10-WaitForEvent
      dd sys_getevent            ; 11-CheckForEvent
      dd sys_redrawstat          ; 12-BeginDraw and EndDraw
      dd syscall_drawrect        ; 13-DrawRect
      dd syscall_getscreensize   ; 14-GetScreenSize
      dd sys_background          ; 15-bgr
      dd sys_cachetodiskette     ; 16-FlushFloppyCache
      dd sys_getbutton           ; 17-GetButton
      dd sys_system              ; 18-System Services
      dd undefined_syscall       ; 19-reserved
      dd undefined_syscall       ; 20- deprecated ResetMidi and OutputMidi
      dd sys_setup               ; 21-SetKeymap,SetShiftKeymap,.
      dd sys_settime             ; 22-setting date,time,clock and alarm-clock
      dd sys_wait_event_timeout  ; 23-TimeOutWaitForEvent
      dd syscall_cdaudio         ; 24-PlayCdTrack,StopCd and GetCdPlaylist
      dd syscall_putarea_backgr  ; 25-Put Area to background
      dd sys_getsetup            ; 26-GetMidiBase,GetKeymap,GetShiftKeymap,.
      dd undefined_syscall       ; 27-reserved
      dd undefined_syscall       ; 28-reserved
      dd sys_date                ; 29-GetDate
      dd sys_current_directory   ; 30-Get/SetCurrentDirectory
      dd undefined_syscall       ; 31-reserved
      dd undefined_syscall       ; 32-reserved
      dd undefined_syscall       ; 33-reserved
      dd syscall_getpixel_WinMap ; 34-GetPixel WinMap
      dd syscall_getpixel        ; 35-GetPixel
      dd syscall_getarea         ; 36-GetArea
      dd readmousepos            ; 37-GetMousePosition_ScreenRelative,.
      dd syscall_drawline        ; 38-DrawLine
      dd sys_getbackground       ; 39-GetBackgroundSize,ReadBgrData,.
      dd set_app_param           ; 40-WantEvents
      dd undefined_syscall       ; 41- deprecated GetIrqOwner
      dd undefined_syscall       ; 42- deprecated ReadIrqData
      dd undefined_syscall       ; 43- deprecated SendDeviceData
      dd undefined_syscall       ; 44- deprecated ProgramIrqs
      dd undefined_syscall       ; 45- deprecated ReserveIrq and FreeIrq
      dd syscall_reserveportarea ; 46-ReservePortArea and FreePortArea
      dd display_number          ; 47-WriteNum
      dd syscall_display_settings ; 48-SetRedrawType and SetButtonType
      dd sys_apm                 ; 49-Advanced Power Management (APM)
      dd syscall_set_window_shape ; 50-Window shape & scale
      dd syscall_threads         ; 51-Threads
      dd undefined_syscall       ; 52- deprecated Stack driver status
      dd undefined_syscall       ; 53- deprecated Socket interface
      dd sys_clipboard           ; 54-Custom clipboard
      dd sound_interface         ; 55-Sound interface
      dd undefined_syscall       ; 56-reserved
      dd sys_pcibios             ; 57-PCI BIOS32
      dd undefined_syscall       ; 58-deprecated Common file system interface
      dd undefined_syscall       ; 59-reserved
      dd sys_IPC                 ; 60-Inter Process Communication
      dd sys_gs                  ; 61-Direct graphics access
      dd pci_api                 ; 62-PCI functions
      dd sys_msg_board           ; 63-System message board
      dd sys_resize_app_memory   ; 64-Resize application memory usage
      dd sys_putimage_palette    ; 65-PutImagePalette
      dd sys_process_def         ; 66-Process definitions - keyboard
      dd syscall_move_window     ; 67-Window move or resize
      dd f68                     ; 68-Some internal services
      dd sys_debug_services      ; 69-Debug
      dd sys_file_system_lfn     ; 70-Common file system interface, version 2
      dd syscall_window_settings ; 71-Window settings
      dd sys_sendwindowmsg       ; 72-Send window message
      dd blit_32                 ; 73-blitter;
      dd sys_network             ; 74-reserved for new stack
      dd sys_socket              ; 75-reserved for new stack
      dd sys_protocols           ; 76-reserved for new stack
      dd sys_posix               ; posix support
      dd undefined_syscall       ; 78-free
      dd undefined_syscall       ; 79-free
      dd sys_fileSystemUnicode   ; 80-File system interface for different encodings

        times 255 - ( ($-servetable2) /4 )  dd undefined_syscall
      dd sys_end                 ; -1-end application

endg
