rem @echo off
rem example: compile.bat <file.asm>
set input=%1

if not defined input goto noinput

set tass64_path=D:\Other\C64\CrossAsm\64tass-1.54.1900
set vice_path=D:\Other\C64\Emulators\GTK3VICE-3.3-win64-r36165
set vice_exe=x64sc.exe
set vice="%vice_path%\%vice_exe%"
set output=%tass64_path%\out.prg

set repo="resources"

del %output%
%tass64_path%\64tass.exe %input% -l %tass64_path%\labels.txt --tasm-compatible --case-sensitive -I %repo% -o %output%
if exist %output% %vice% %output%

exit /B 0

:noinput
echo no 64tass input file specified
exit /B 1
