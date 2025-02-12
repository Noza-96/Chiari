echo off
set LOCALHOST=%COMPUTERNAME%
set KILL_CMD="C:\PROGRA~1\ANSYSI~1\v241\fluent/ntbin/win64/winkill.exe"

start "tell.exe" /B "C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\tell.exe" Lenovo 54028 CLEANUP_EXITING
timeout /t 1
"C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\kill.exe" tell.exe
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 28380) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 24292) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 28968) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 27440) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 29840) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 30592) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 23312) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 17884) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 16300) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 19256) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 26168) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 23808)
del "C:\Users\guill\Documents\chiari\git-chiari\matlab\processing\cleanup-fluent-Lenovo-26168.bat"
