@echo off

set "PS_SCRIPT=darkmode.ps1"

:: Default for dark mode
set "MODE_VAL=0" 

:: Default for dark mode
set "MODE_NAME=Dark" 

:: Processing parameters

IF /I "%1" EQU "/l" (
    :: Value for light mode
    set "MODE_VAL=1" 

    :: Name for light mode
    set "MODE_NAME=Light" 
)

:: Administrator check

NET SESSION >NUL 2>&1
IF %ERRORLEVEL% NEQ 0 (
    goto notAdministrator
)

:: Main script

echo. 
echo Welcome to Win11DarkMode, applying %MODE_NAME% mode to your system...
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0%PS_SCRIPT%" %MODE_VAL%

IF %ERRORLEVEL% NEQ 0 (
    goto notSuccessful
)

echo %MODE_NAME% mode has been successfully set, please restart your computer for changes to take an effect.
set /p RestartChoice="Restart your computer NOW? (y/n): "
echo.

IF /I "%RestartChoice%" EQU "y" (
    echo Restarting your computer in 5 seconds...
    shutdown /r /t 5
) ELSE (
    echo OK. Don't forget to restart your computer manually later.
)

pause
exit

:: Error sections

:notSuccessful
echo An error occurred while rewriting registry, try:
echo 1) Ensuring the '%PS_SCRIPT%' file is 'Unblocked' (Right-click -> Properties -> Unblock).
echo 2) Running %~nx0 again as administrator.
pause
exit

:notAdministrator
echo For assuring correct function, please run this script as an administrator.
pause
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~dp0%~nx0' -Verb RunAs"
exit
