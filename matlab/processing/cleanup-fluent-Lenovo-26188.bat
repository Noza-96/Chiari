echo off
set LOCALHOST=%COMPUTERNAME%
set KILL_CMD="C:\PROGRA~1\ANSYSI~1\v241\fluent/ntbin/win64/winkill.exe"

start "tell.exe" /B "C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\tell.exe" Lenovo 53685 CLEANUP_EXITING
timeout /t 1
"C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\kill.exe" tell.exe
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 29552) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 8104) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 27460) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 10436) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 27704) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 21084) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 2228) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 27572) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 18228) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 26484) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 26672) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 19284) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 26188) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 19020)
del "C:\Users\guill\Documents\chiari\git-chiari\matlab\processing\cleanup-fluent-Lenovo-26188.bat"
