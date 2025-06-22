echo off
set LOCALHOST=%COMPUTERNAME%
set KILL_CMD="C:\PROGRA~1\ANSYSI~1\v241\fluent/ntbin/win64/winkill.exe"

start "tell.exe" /B "C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\tell.exe" Lenovo 62015 CLEANUP_EXITING
timeout /t 1
"C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\kill.exe" tell.exe
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 45628) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 38660) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 45916) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 40728) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 49060) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 39920) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 49128) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 48492) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 38900) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 45356) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 47688) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 2808) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 43644) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 45764) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 42488) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 33136)
del "C:\Users\guill\Documents\chiari\git-chiari\matlab\processing\cleanup-fluent-Lenovo-42488.bat"
