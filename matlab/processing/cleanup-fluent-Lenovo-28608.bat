echo off
set LOCALHOST=%COMPUTERNAME%
set KILL_CMD="C:\PROGRA~1\ANSYSI~1\v241\fluent/ntbin/win64/winkill.exe"

start "tell.exe" /B "C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\tell.exe" Lenovo 53896 CLEANUP_EXITING
timeout /t 1
"C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\kill.exe" tell.exe
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 5536) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 13916) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 17204) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 28768) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 14256) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 29640) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 26716) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 24068) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 27212) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 12648) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 27888) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 26420) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 28608) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 3520)
del "C:\Users\guill\Documents\chiari\git-chiari\matlab\processing\cleanup-fluent-Lenovo-28608.bat"
