echo off
set LOCALHOST=%COMPUTERNAME%
set KILL_CMD="C:\PROGRA~1\ANSYSI~1\v241\fluent/ntbin/win64/winkill.exe"

start "tell.exe" /B "C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\tell.exe" Lenovo 50942 CLEANUP_EXITING
timeout /t 1
"C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\kill.exe" tell.exe
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 45676) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 48868) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 48336) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 12584) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 5628) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 50036) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 28564) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 47168) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 49868) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 45752) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 45284) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 47016) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 47784) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 13568) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 42292) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 48852)
del "C:\Users\guill\Documents\chiari\git-chiari\matlab\processing\cleanup-fluent-Lenovo-42292.bat"
