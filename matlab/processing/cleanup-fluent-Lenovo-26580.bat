echo off
set LOCALHOST=%COMPUTERNAME%
set KILL_CMD="C:\PROGRA~1\ANSYSI~1\v241\fluent/ntbin/win64/winkill.exe"

start "tell.exe" /B "C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\tell.exe" Lenovo 53492 CLEANUP_EXITING
timeout /t 1
"C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\kill.exe" tell.exe
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 13652) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 27664) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 24116) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 12244) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 23740) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 28112) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 16928) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 7216) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 24880) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 14684) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 4716) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 26260) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 26580) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 8828)
del "C:\Users\guill\Documents\chiari\git-chiari\matlab\processing\cleanup-fluent-Lenovo-26580.bat"
