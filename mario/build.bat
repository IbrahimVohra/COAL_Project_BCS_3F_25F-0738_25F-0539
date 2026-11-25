@echo off
set DOSBOX=C:\Program Files (x86)\DOSBox-0.74-3\DOSBox.exe

nasm mario.asm -o MARIO.COM
if errorlevel 1 goto failed
echo Built MARIO.COM
"%DOSBOX%" -c "mount c ." -c "c:" -c "MARIO.COM"
goto end

:failed
echo NASM reported errors - MARIO.COM was not built.
:end
