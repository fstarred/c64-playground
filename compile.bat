@echo off
set input=%1
set crunching=1
set program_start_address=$5000
set tass_path=D:\software\64tass-1.56.2625
set exomizer_path="D:\software\exomizer-3.1.2"

if defined input goto setexec
set input="E:\emulators\c64\c64-playground\asm\demo\nightly-city\nightly-city.asm"

:setexec
set exec=x64sc.exe

set vice_path=E:\emulators\SDL2VICE-3.8-win64
set vice_exe=%exec%
set vice="%vice_path%\%vice_exe%"
set output=out.prg
set packed_output=packedout.prg

set repo="E:\emulators\c64\c64-playground\asm\demo\nightly-city\resources"
rem options=--tasm-compatible

del %output%
%tass_path%\64tass.exe %input% --vice-labels -l labels.txt %options% --case-sensitive -I %repo% -o out.prg


if %crunching%==1 (
    %exomizer_path%\exomizer.exe sfx %program_start_address% %output% -o %packed_output%
    set output=%packed_output%
)

if exist %output% %vice%  -moncommands labels.txt %output%
exit /B 0

%exomizer_path%\exomizer.exe sfx $5000 %tass_path%\out.prg -o compressed.prg

:noinput
echo no input file specified
exit /B 1
