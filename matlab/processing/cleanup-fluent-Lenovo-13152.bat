echo off
set LOCALHOST=%COMPUTERNAME%
set KILL_CMD="C:\PROGRA~1\ANSYSI~1\v241\fluent/ntbin/win64/winkill.exe"

start "tell.exe" /B "C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\tell.exe" Lenovo 62803 CLEANUP_EXITING
timeout /t 1
"C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\kill.exe" tell.exe
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 2328) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 30464) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 10236) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 33108) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 17808) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 34632) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 21056) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 34532) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 25192) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 31548) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 38232) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 29396) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 11876) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 2580) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 13152) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 3212)
del "C:\Users\guill\Documents\chiari\git-chiari\matlab\processing\cleanup-fluent-Lenovo-13152.bat"
