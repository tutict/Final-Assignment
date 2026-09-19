@echo off
rem Unified Windows entry for local startup. Delegates to start-dev.ps1.
rem Examples:
rem   scripts\start-all.bat -b go -f react
rem   scripts\start-all.bat -b spring -f flutter -e
rem   scripts\start-all.bat --stop
rem Optional env:
rem   SMOKE_LOGIN=true          POST /api/auth/login after backend health
rem   OPEN_BROWSER=false        skip opening a browser
rem See scripts\README.md
call "%~dp0start-dev.bat" %*
