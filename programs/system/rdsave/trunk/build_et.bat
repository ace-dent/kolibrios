@erase lang.inc
@echo lang fix et_EE >lang.inc
@fasm rdsave.asm rdsave
@kpack rdsave
@erase lang.inc
@pause
