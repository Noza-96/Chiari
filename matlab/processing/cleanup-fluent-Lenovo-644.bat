echo off
set LOCALHOST=%COMPUTERNAME%
set KILL_CMD="C:\PROGRA~1\ANSYSI~1\v241\fluent/ntbin/win64/winkill.exe"

start "tell.exe" /B "C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\tell.exe" Lenovo 55010 CLEANUP_EXITING
timeout /t 1
"C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\kill.exe" tell.exe
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 27404) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 36456) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 39764) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 33316) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 28332) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 1740) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 29632) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 30292) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 38532) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 22524) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 29520) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 12316) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 18736) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 18376) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 644) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 23948)
del "C:\Users\guill\Documents\chiari\git-chiari\matlab\processing\cleanup-fluent-Lenovo-644.bat"
