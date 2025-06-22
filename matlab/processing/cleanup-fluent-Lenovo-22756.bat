echo off
set LOCALHOST=%COMPUTERNAME%
set KILL_CMD="C:\PROGRA~1\ANSYSI~1\v241\fluent/ntbin/win64/winkill.exe"

start "tell.exe" /B "C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\tell.exe" Lenovo 61372 CLEANUP_EXITING
timeout /t 1
"C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\kill.exe" tell.exe
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 25704) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 44324) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 49976) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 48600) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 48136) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 48528) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 2220) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 49252) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 49560) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 47508) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 41640) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 48868) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 3680) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 49568) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 22756) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 47680)
del "C:\Users\guill\Documents\chiari\git-chiari\matlab\processing\cleanup-fluent-Lenovo-22756.bat"
