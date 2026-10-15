@echo off
rem Cap nhat server Chi tieu len ban moi nhat.
rem Nhay dup file nay. Chay update.ps1 bang Windows PowerShell, chi bo qua ExecutionPolicy cho lan chay nay.
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0update.ps1" %*
set "RC=%ERRORLEVEL%"
echo.
pause
exit /b %RC%
