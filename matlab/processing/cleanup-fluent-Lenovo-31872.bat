echo off
set LOCALHOST=%COMPUTERNAME%
set KILL_CMD="C:\PROGRA~1\ANSYSI~1\v241\fluent/ntbin/win64/winkill.exe"

start "tell.exe" /B "C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\tell.exe" Lenovo 58735 CLEANUP_EXITING
timeout /t 1
"C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\kill.exe" tell.exe
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 32608) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 30068) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 11236) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 29512) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 26628) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 31980) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 32092) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 27916) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 31072) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 31332) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 30976) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 19028) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 31872) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 31892)
del "C:\Users\guill\Documents\chiari\git-chiari\matlab\processing\cleanup-fluent-Lenovo-31872.bat"
