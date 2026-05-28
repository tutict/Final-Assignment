@echo off
setlocal EnableExtensions

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "ROOT_DIR=%%~fI"
set "BACKEND_DIR=%ROOT_DIR%\finalAssignmentBackend"

if "%BACKEND_PROFILE%"=="" set "BACKEND_PROFILE=dev"
if "%JWT_SECRET%"=="" set "JWT_SECRET=dev-jwt-secret-key-for-local-startup-please-change-1234567890"
if "%APP_DEV_SERVICES_ENABLED%"=="" set "APP_DEV_SERVICES_ENABLED=false"
if "%APP_DOCKER_STARTUP_SCRIPT_ENABLED%"=="" set "APP_DOCKER_STARTUP_SCRIPT_ENABLED=false"
if "%APP_OLLAMA_STARTUP_SCRIPT_ENABLED%"=="" set "APP_OLLAMA_STARTUP_SCRIPT_ENABLED=false"
if "%APP_DEV_SERVICES_REDPANDA_ENABLED%"=="" set "APP_DEV_SERVICES_REDPANDA_ENABLED=false"
if "%APP_ELASTICSEARCH_FALLBACK_ENABLED%"=="" set "APP_ELASTICSEARCH_FALLBACK_ENABLED=true"
if "%APP_ELASTICSEARCH_SYNC_ENABLED%"=="" set "APP_ELASTICSEARCH_SYNC_ENABLED=false"
if "%SPRING_DATA_ELASTICSEARCH_SKIP_REPOSITORY_INIT%"=="" set "SPRING_DATA_ELASTICSEARCH_SKIP_REPOSITORY_INIT=true"
if "%SPRING_DEVTOOLS_RESTART_ENABLED%"=="" set "SPRING_DEVTOOLS_RESTART_ENABLED=false"
if "%SPRING_KAFKA_LISTENER_AUTO_STARTUP%"=="" set "SPRING_KAFKA_LISTENER_AUTO_STARTUP=false"
if "%MANAGEMENT_HEALTH_ELASTICSEARCH_ENABLED%"=="" set "MANAGEMENT_HEALTH_ELASTICSEARCH_ENABLED=false"
if "%SPRING_AI_OLLAMA_INIT_PULL_MODEL_STRATEGY%"=="" set "SPRING_AI_OLLAMA_INIT_PULL_MODEL_STRATEGY=never"
if "%SPRING_DATASOURCE_URL%"=="" set "SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/traffic"
if "%SPRING_DATASOURCE_USERNAME%"=="" set "SPRING_DATASOURCE_USERNAME=root"
if "%SPRING_DATASOURCE_PASSWORD%"=="" set "SPRING_DATASOURCE_PASSWORD=root"
if "%SPRING_DATASOURCE_DRIVER_CLASS_NAME%"=="" set "SPRING_DATASOURCE_DRIVER_CLASS_NAME=com.mysql.cj.jdbc.Driver"
if "%SPRING_DATA_REDIS_HOST%"=="" set "SPRING_DATA_REDIS_HOST=localhost"
if "%SPRING_DATA_REDIS_PORT%"=="" set "SPRING_DATA_REDIS_PORT=6379"
if "%SPRING_KAFKA_BOOTSTRAP_SERVERS%"=="" set "SPRING_KAFKA_BOOTSTRAP_SERVERS=localhost:9092"
if "%BACKEND_PORT%"=="" set "BACKEND_PORT=8080"

if not exist "%BACKEND_DIR%\pom.xml" (
  echo [ERROR] Spring Boot project not found: "%BACKEND_DIR%"
  exit /b 1
)

if "%MVN_CMD%"=="" (
  for /f "delims=" %%I in ('where mvn.cmd 2^>nul') do (
    set "MVN_CMD=%%I"
    goto mvn_found
  )
  for /f "delims=" %%I in ('where mvn 2^>nul') do (
    set "MVN_CMD=%%I"
    goto mvn_found
  )
)

:mvn_found
if "%MVN_CMD%"=="" (
  echo [ERROR] Maven command was not found in PATH. Set MVN_CMD to mvn.cmd.
  exit /b 1
)

echo Starting Spring Boot backend with profile "%BACKEND_PROFILE%"...
pushd "%BACKEND_DIR%" >nul
call "%MVN_CMD%" spring-boot:run -Dspring-boot.run.profiles=%BACKEND_PROFILE% -Dspring-boot.run.jvmArguments=-Dspring.devtools.restart.enabled=false %BACKEND_ARGS%
set "BACKEND_EXIT=%ERRORLEVEL%"
popd >nul

echo Backend exited with code %BACKEND_EXIT%.
exit /b %BACKEND_EXIT%
