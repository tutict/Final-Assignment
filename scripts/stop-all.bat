@echo off
rem Stop leftover local backend/frontend processes started by this repo.
rem Also stops Docker Compose / Ollama unless STOP_LOCAL_SERVICES_ON_EXIT=false.
rem Examples:
rem   scripts\stop-all.bat
rem   set STOP_DOCKER_ON_EXIT=false && scripts\stop-all.bat
call "%~dp0start-dev.bat" --stop %*
