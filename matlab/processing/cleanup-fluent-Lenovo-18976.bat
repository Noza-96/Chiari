echo off
set LOCALHOST=%COMPUTERNAME%
set KILL_CMD="C:\PROGRA~1\ANSYSI~1\v241\fluent/ntbin/win64/winkill.exe"

start "tell.exe" /B "C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\tell.exe" Lenovo 63514 CLEANUP_EXITING
timeout /t 1
"C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\kill.exe" tell.exe
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 37560) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 26952) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 13424) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 24148) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 14164) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 37748) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 33580) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 18940) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 36812) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 13096) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 18976) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 25328)
del "C:\Users\guill\Documents\chiari\git-chiari\matlab\processing\cleanup-fluent-Lenovo-18976.bat"
