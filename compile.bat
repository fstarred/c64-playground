@echo off
set input=%1
set crunching=1
set program_start_address=$5000

if defined input goto setexec
set input="D:\Other\C64\Repositories\c64-playground\asm\demo\nightly-city\nightly-city.asm"

:setexec
set exec=x64sc.exe

set vice_path=D:\Other\C64\Emulators\GTK3VICE-3.5-win64
set vice_exe=%exec%
set vice="%vice_path%\bin\%vice_exe%"
set output=out.prg
set packed_output=packedout.prg

set repo="D:\Other\C64\Repositories\c64-playground\asm\demo\nightly-city\resources"
rem options=--tasm-compatible

del %output%
64tass.exe %input% --vice-labels -l labels.txt %options% --case-sensitive -I %repo% -o out.prg

set exomizer_path="D:\Other\C64\Utilities\exomizer-3.0.1"

if %crunching%==1 (
    %exomizer_path%\win32\exomizer.exe sfx %program_start_address% %output% -o %packed_output%
    set output=%packed_output%
)

if exist %output% %vice%  -moncommands labels.txt %output%
exit /B 0

exomizer.exe sfx $5000 ..\..\..\CrossAsm\64tass-1.55.2200\out.prg -o compressed.prg

:noinput
echo no input file specified
exit /B 1
