@echo off
rem Cai dat / cai lai server Chi tieu (Docker + ngrok + Telegram).
rem Nhay dup file nay. Chay setup.ps1 bang Windows PowerShell, chi bo qua ExecutionPolicy cho lan chay nay.
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" %*
set "RC=%ERRORLEVEL%"
echo.
pause
exit /b %RC%
