echo off
set LOCALHOST=%COMPUTERNAME%
set KILL_CMD="C:\PROGRA~1\ANSYSI~1\v241\fluent/ntbin/win64/winkill.exe"

start "tell.exe" /B "C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\tell.exe" Lenovo 58914 CLEANUP_EXITING
timeout /t 1
"C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\kill.exe" tell.exe
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 30632) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 29868) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 27276) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 31880) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 26388) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 13516) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 11796) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 28436) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 15224) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 15668) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 32624) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 15844) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 31940) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 29400)
del "C:\Users\guill\Documents\chiari\git-chiari\matlab\processing\cleanup-fluent-Lenovo-31940.bat"
