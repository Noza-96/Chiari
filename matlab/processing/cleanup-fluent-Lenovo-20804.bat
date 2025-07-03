echo off
set LOCALHOST=%COMPUTERNAME%
set KILL_CMD="C:\PROGRA~1\ANSYSI~1\v241\fluent/ntbin/win64/winkill.exe"

start "tell.exe" /B "C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\tell.exe" Lenovo 62586 CLEANUP_EXITING
timeout /t 1
"C:\PROGRA~1\ANSYSI~1\v241\fluent\ntbin\win64\kill.exe" tell.exe
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 34364) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 22308) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 39100) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 20952) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 37088) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 38204) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 5344) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 21180) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 29628) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 24360) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 26172) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 20444) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 28792) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 9796) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 20804) 
if /i "%LOCALHOST%"=="Lenovo" (%KILL_CMD% 6224)
del "C:\Users\guill\Documents\chiari\git-chiari\matlab\processing\cleanup-fluent-Lenovo-20804.bat"
