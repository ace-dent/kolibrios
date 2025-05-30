
if lang eq ru_RU

sz_main_menu_File db '����', 0
sz_main_menu_File_New  db '����', 0
sz_main_menu_File_Open db '������', 0
sz_main_menu_File_Save db '���࠭���', 0
sz_main_menu_File_Save_As db '���࠭��� ���', 0
sz_main_menu_File_Exit db '��室', 0

sz_main_menu_Changes db '���������', 0
sz_main_menu_Changes_Undo  db '�⬥��', 0
sz_main_menu_Changes_Redo  db '�����', 0

sz_main_menu_Buf db '����', 0
sz_main_menu_Buf_Cut   db '��१���', 0
sz_main_menu_Buf_Copy  db '����஢���', 0
sz_main_menu_Buf_Paste db '��⠢���', 0

sz_main_menu_Search db '����', 0
sz_main_menu_Search_Text  db '���� �� ⥪���', 0
sz_main_menu_Search_Keywords db '���� � ���祢�� ᫮���', 0

sz_main_menu_View  db '���', 0
sz_main_menu_Veiw_UseSyntax   db '�ᯮ�짮���� ���ᢥ�� ��⠪��', 0
sz_main_menu_Veiw_ChooseSyntax   db '����� ���ᢥ�� ᨭ⠪��', 0
sz_main_menu_Veiw_LineBreak   db '�����뢠�� ᨬ��� ��७�� ��ப�', 0

sz_main_menu_Encoding db '����஢��', 0
sz_main_menu_Encoding_1251to866  db 'CP1251 ',0x1A,' CP866', 0
sz_main_menu_Encoding_866to1251 db 'CP866 ',0x1A,' CP1251', 0

else
  
sz_main_menu_File db 'File', 0
sz_main_menu_File_New db 'New', 0
sz_main_menu_File_Open db 'Open', 0
sz_main_menu_File_Save db 'Save', 0
sz_main_menu_File_Save_As db 'Save as', 0
sz_main_menu_File_Exit db 'Exit', 0

sz_main_menu_Changes db 'Changes', 0
sz_main_menu_Changes_Undo  db 'Undo', 0
sz_main_menu_Changes_Redo  db 'Redo', 0

sz_main_menu_Buf db 'Buffer', 0
sz_main_menu_Buf_Cut   db 'Cut', 0
sz_main_menu_Buf_Copy  db 'Copy', 0
sz_main_menu_Buf_Paste db 'Paste', 0

sz_main_menu_Search db 'Search', 0
sz_main_menu_Search_Text  db 'Text search', 0
sz_main_menu_Search_Keywords db 'Search in keywords', 0

sz_main_menu_View  db 'View', 0
sz_main_menu_Veiw_UseSyntax   db 'Use syntax highlight', 0
sz_main_menu_Veiw_ChooseSyntax   db 'Choose syntax highlight', 0
sz_main_menu_Veiw_LineBreak   db 'Show line break symbols', 0

sz_main_menu_Encoding db 'Encoding', 0
sz_main_menu_Encoding_1251to866  db 'CP1251 ',0x1A,' CP866', 0
sz_main_menu_Encoding_866to1251 db 'CP866 ',0x1A,' CP1251', 0

end if

align 4
main_menu dd 0
main_menu_file dd 0
main_menu_changes dd 0
main_menu_buf dd 0
main_menu_search dd 0
main_menu_view dd 0
main_menu_encoding dd 0

KMENUITEM_NORMAL equ 0
KMENUITEM_SUBMENU equ 1
KMENUITEM_SEPARATOR equ 2

align 16
tedit_menu_init:
	stdcall [kmenu_init], sc

	stdcall [ksubmenu_new]
	mov [main_menu], eax

	stdcall [ksubmenu_new]
	mov [main_menu_file], eax
	stdcall [kmenuitem_new], KMENUITEM_NORMAL, sz_main_menu_File_New, ID_BUT_NEW
	stdcall [ksubmenu_add], [main_menu_file], eax
	stdcall [kmenuitem_new], KMENUITEM_NORMAL, sz_main_menu_File_Open, ID_BUT_OPEN
	stdcall [ksubmenu_add], [main_menu_file], eax
	stdcall [kmenuitem_new], KMENUITEM_NORMAL, sz_main_menu_File_Save, ID_BUT_SAVE
	stdcall [ksubmenu_add], [main_menu_file], eax
	stdcall [kmenuitem_new], KMENUITEM_NORMAL, sz_main_menu_File_Save_As, ID_BUT_SAVE_AS
	stdcall [ksubmenu_add], [main_menu_file], eax
	stdcall [kmenuitem_new], KMENUITEM_SEPARATOR, 0, 0
	stdcall [ksubmenu_add], [main_menu_file], eax
	stdcall [kmenuitem_new], KMENUITEM_NORMAL, sz_main_menu_File_Exit, 199
	stdcall [ksubmenu_add], [main_menu_file], eax	
	stdcall [kmenuitem_new], KMENUITEM_SUBMENU, sz_main_menu_File, [main_menu_file]
	stdcall [ksubmenu_add], [main_menu], eax

	stdcall [ksubmenu_new]
	mov [main_menu_changes], eax
	stdcall [kmenuitem_new], KMENUITEM_NORMAL, sz_main_menu_Changes_Undo, ID_BUT_UNDO
	stdcall [ksubmenu_add], [main_menu_changes], eax
	stdcall [kmenuitem_new], KMENUITEM_NORMAL, sz_main_menu_Changes_Redo, ID_BUT_REDO
	stdcall [ksubmenu_add], [main_menu_changes], eax
	stdcall [kmenuitem_new], KMENUITEM_SUBMENU, sz_main_menu_Changes, [main_menu_changes]
	stdcall [ksubmenu_add], [main_menu], eax

	stdcall [ksubmenu_new]
	mov [main_menu_buf], eax
	stdcall [kmenuitem_new], KMENUITEM_NORMAL, sz_main_menu_Buf_Cut, ID_BUT_CUT
	stdcall [ksubmenu_add], [main_menu_buf], eax
	stdcall [kmenuitem_new], KMENUITEM_NORMAL, sz_main_menu_Buf_Copy, ID_BUT_COPY
	stdcall [ksubmenu_add], [main_menu_buf], eax
	stdcall [kmenuitem_new], KMENUITEM_NORMAL, sz_main_menu_Buf_Paste, ID_BUT_PASTE
	stdcall [ksubmenu_add], [main_menu_buf], eax	
	stdcall [kmenuitem_new], KMENUITEM_SUBMENU, sz_main_menu_Buf, [main_menu_buf]
	stdcall [ksubmenu_add], [main_menu], eax

	stdcall [ksubmenu_new]
	mov [main_menu_search], eax
	stdcall [kmenuitem_new], KMENUITEM_NORMAL, sz_main_menu_Search_Text, ID_BUT_FIND
	stdcall [ksubmenu_add], [main_menu_search], eax
	stdcall [kmenuitem_new], KMENUITEM_NORMAL, sz_main_menu_Search_Keywords, ID_BUT_KEY_WORDS
	stdcall [ksubmenu_add], [main_menu_search], eax
	stdcall [kmenuitem_new], KMENUITEM_SUBMENU, sz_main_menu_Search, [main_menu_search]
	stdcall [ksubmenu_add], [main_menu], eax

	stdcall [ksubmenu_new]
	mov [main_menu_view], eax
	stdcall [kmenuitem_new], KMENUITEM_NORMAL, sz_main_menu_Veiw_UseSyntax, ID_BUT_SYNTAX_LIST
	stdcall [ksubmenu_add], [main_menu_view], eax
	stdcall [kmenuitem_new], KMENUITEM_NORMAL, sz_main_menu_Veiw_ChooseSyntax, ID_BUT_SYNTAX_MODE
	stdcall [ksubmenu_add], [main_menu_view], eax
	stdcall [kmenuitem_new], KMENUITEM_SEPARATOR, 0, 0
	stdcall [ksubmenu_add], [main_menu_view], eax
	stdcall [kmenuitem_new], KMENUITEM_NORMAL, sz_main_menu_Veiw_LineBreak, ID_BUT_INVISIBLE
	stdcall [ksubmenu_add], [main_menu_view], eax	
	stdcall [kmenuitem_new], KMENUITEM_SUBMENU, sz_main_menu_View, [main_menu_view]
	stdcall [ksubmenu_add], [main_menu], eax

	stdcall [ksubmenu_new]
	mov [main_menu_encoding], eax
	stdcall [kmenuitem_new], KMENUITEM_NORMAL, sz_main_menu_Encoding_1251to866, ID_BUT_CONVERT_1251_866
	stdcall [ksubmenu_add], [main_menu_encoding], eax
	stdcall [kmenuitem_new], KMENUITEM_NORMAL, sz_main_menu_Encoding_866to1251, ID_BUT_CONVERT_866_1251
	stdcall [ksubmenu_add], [main_menu_encoding], eax	
	stdcall [kmenuitem_new], KMENUITEM_SUBMENU, sz_main_menu_Encoding, [main_menu_encoding]
	stdcall [ksubmenu_add], [main_menu], eax
	ret
