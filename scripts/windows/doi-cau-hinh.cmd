@echo off
rem Xem va doi cau hinh da luu: authtoken / ten mien ngrok, khoa SePay, token bot va Chat ID Telegram, Gmail,
rem tao APP_TOKEN moi... Nhay dup file nay. Giong setup.cmd nhung hoi lai tung gia tri (setup.ps1 -Review);
rem Enter = giu nguyen gia tri cu. Chi bo qua ExecutionPolicy cho lan chay nay.
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" -Review %*
set "RC=%ERRORLEVEL%"
echo.
pause
exit /b %RC%
