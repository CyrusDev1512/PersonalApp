@echo off
cd /d "%~dp0"
if exist "%~dp0CommentLab.exe" (
  start "" "%~dp0CommentLab.exe"
  exit /b 0
)
echo Khong tim thay CommentLab.exe. Hay giai nen day du ban desktop.
pause
exit /b 1
