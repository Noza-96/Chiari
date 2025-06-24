echo off
set LOCALHOST=%COMPUTERNAME%
set KILL_CMD="C:\PROGRA~1\ANSYSI~1\v241\fluent/ntbin/win64/winkill.exe"

start "tell.exe" /B "C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\tell.exe" Lenovo 54201 CLEANUP_EXITING
timeout /t 1
"C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\kill.exe" tell.exe
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 33112) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 33956) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 33592) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 26908) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 45576) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 30116) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 49200) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 50540) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 45268) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 47012) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 39424) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 46748) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 38508) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 45284) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 50800) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 42064)
del "C:\Users\guill\Documents\chiari\git-chiari\matlab\processing\cleanup-fluent-Lenovo-50800.bat"
