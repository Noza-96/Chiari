echo off
set LOCALHOST=%COMPUTERNAME%
set KILL_CMD="C:\PROGRA~1\ANSYSI~1\v241\fluent/ntbin/win64/winkill.exe"

start "tell.exe" /B "C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\tell.exe" Lenovo 64025 CLEANUP_EXITING
timeout /t 1
"C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\kill.exe" tell.exe
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 22408) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 26856) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 24496) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 23564) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 20176) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 24956) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 28664) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 23968) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 23008) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 24428) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 4748) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 25168)
del "C:\Users\guill\Documents\chiari\git-chiari\matlab\processing\cleanup-fluent-Lenovo-4748.bat"
