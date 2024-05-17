@echo off

set c1541=e:\emulators\SDL2VICE-3.8-win64
set disk=e:\emulators\c64\disk\mydisk.d64

if not exist %c1541%\c1541.exe (
	echo file c1541.exe not exists in directory %c1541%
	exit /B 1
) 

if not exist %disk% (
	echo file %disk% not exists
	exit /B 1
)

for %%a in (*.seq) do (
	%c1541%\c1541.exe -attach %disk% -write "%%a" "%%a,s"
)