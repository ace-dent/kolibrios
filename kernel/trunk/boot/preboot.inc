;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                                              ;;
;; Copyright (C) KolibriOS team 2004-2024. All rights reserved. ;;
;; Distributed under terms of the GNU General Public License    ;;
;;                                                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


display_modechg     db  0 ; display mode change for text, yes/no (0 or 2)
                          ;
                          ; !! Important note !!
                          ;
                          ; Must be set to 2, to avoid two screenmode
                          ; changes within a very short period of time.

display_atboot      db  0 ; show boot screen messages ( 2-no )

preboot_graph       dw  0 ; graph mode
x_save              dw  0 ; x
y_save              dw  0 ; y
number_vm           dw  0 ;
;pixel_save          dw  0 ; per to pixel
preboot_gprobe      db  0 ; probe vesa3 videomodes (1-no, 2-yes)
preboot_debug       db  0 ; load kernel in debug mode? (1-yes, 2-no)
preboot_launcher    db  0 ; start launcher after kernel is loaded? (1-yes, 2-no)
preboot_dma         db  0 ; use DMA for access to HDD (1-always, 2-only for read, 3-never)
preboot_device      db  0 ; device to load ramdisk from
                          ;   1-floppy 2-harddisk 3-kernel restart
                          ;   4-format ram disk 5-don't use ramdisk
                          ; !!!! 0 - autodetect !!!!

; use V86 to access disks through BIOS (1-yes, 2-no)
if defined pretest_build
  preboot_biosdisk  db  1
else
  preboot_biosdisk  db  0
end if

preboot_syspath     db  '/RD/1',0 ; path to /sys dir
                    rb  20-($-preboot_syspath)
if defined extended_primary_loader
; timeout in 1/18th of second for config settings screen
preboot_timeout     dw  PREBOOT_TIMEOUT*18
end if

      if $>0x200
ERROR:
       prebooting parameters must fit in first sector!!!
      end if
hdsysimage          db  'KOLIBRI.IMG',0 ; load from
image_save          db  'KOLIBRI.IMG',0 ; save to
