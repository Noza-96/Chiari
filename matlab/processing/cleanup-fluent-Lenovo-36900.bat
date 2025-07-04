echo off
set LOCALHOST=%COMPUTERNAME%
set KILL_CMD="C:\PROGRA~1\ANSYSI~1\v241\fluent/ntbin/win64/winkill.exe"

start "tell.exe" /B "C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\tell.exe" Lenovo 56070 CLEANUP_EXITING
timeout /t 1
"C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\kill.exe" tell.exe
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 6600) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 15272) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 41440) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 9764) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 10696) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 28756) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 29764) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 18660) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 40152) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 1612) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 41580) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 644) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 33060) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 34060) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 36900) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 1860)
del "C:\Users\guill\Documents\chiari\git-chiari\matlab\processing\cleanup-fluent-Lenovo-36900.bat"
