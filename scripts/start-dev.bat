@echo off
setlocal EnableExtensions

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-dev.ps1" %*
exit /b %ERRORLEVEL%
