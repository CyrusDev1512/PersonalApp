@echo off
rem Xem tinh trang server Chi tieu.
rem Nhay dup file nay. Chay status.ps1 bang Windows PowerShell, chi bo qua ExecutionPolicy cho lan chay nay.
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0status.ps1" %*
set "RC=%ERRORLEVEL%"
echo.
pause
exit /b %RC%
