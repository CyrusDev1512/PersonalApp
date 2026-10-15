@echo off
rem Gui webhook SePay gia de thu duong di SePay - server - Telegram.
rem Nhay dup file nay. Chay test-sepay.ps1 bang Windows PowerShell, chi bo qua ExecutionPolicy cho lan chay nay.
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0test-sepay.ps1" %*
set "RC=%ERRORLEVEL%"
echo.
pause
exit /b %RC%
