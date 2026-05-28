@echo off
setlocal EnableExtensions

if /i "%~1"=="--help" goto usage
if /i "%~1"=="-h" goto usage

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "ROOT_DIR=%%~fI"

set "BACKEND_DIR=%ROOT_DIR%\finalAssignmentBackend"
set "FLUTTER_DIR=%ROOT_DIR%\final_assignment_front"

if "%START_LOCAL_SERVICES%"=="" set "START_LOCAL_SERVICES=true"
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
if "%APP_ENV%"=="" set "APP_ENV=dev"
if "%API_BASE_URL%"=="" set "API_BASE_URL=http://localhost:8080"
if "%WS_BASE_URL%"=="" set "WS_BASE_URL=ws://localhost:8081"
if "%BACKEND_PORT%"=="" set "BACKEND_PORT=8080"
if "%BACKEND_WAIT_SECONDS%"=="" set "BACKEND_WAIT_SECONDS=8"
if "%FLUTTER_DEVICE%"=="" set "FLUTTER_DEVICE=web-server"
if "%FLUTTER_ARGS%"=="" set "FLUTTER_ARGS=--web-hostname 127.0.0.1 --web-port 3000"
if "%FLUTTER_DETACHED%"=="" set "FLUTTER_DETACHED=true"

if not exist "%BACKEND_DIR%\pom.xml" (
  echo [ERROR] Spring Boot project not found: "%BACKEND_DIR%"
  exit /b 1
)

if not exist "%FLUTTER_DIR%\pubspec.yaml" (
  echo [ERROR] Flutter project not found: "%FLUTTER_DIR%"
  exit /b 1
)

if "%MVN_CMD%"=="" (
  for /f "delims=" %%I in ('where mvn 2^>nul') do (
    set "MVN_CMD=%%I"
    goto mvn_found
  )
  if exist "%MAVEN_HOME%\bin\mvn.cmd" set "MVN_CMD=%MAVEN_HOME%\bin\mvn.cmd"
)

:mvn_found
if "%MVN_CMD%"=="" (
  echo [ERROR] Maven command "mvn" was not found in PATH. Set MVN_CMD to mvn.cmd.
  exit /b 1
)

if "%FLUTTER_CMD%"=="" (
  for /f "delims=" %%I in ('where flutter 2^>nul') do (
    set "FLUTTER_CMD=%%I"
    goto flutter_found
  )
  if exist "%USERPROFILE%\Flutter\flutter\bin\flutter.bat" set "FLUTTER_CMD=%USERPROFILE%\Flutter\flutter\bin\flutter.bat"
)

:flutter_found
if "%FLUTTER_CMD%"=="" (
  echo [ERROR] Flutter command "flutter" was not found in PATH. Set FLUTTER_CMD to flutter.bat.
  exit /b 1
)

if /i "%START_LOCAL_SERVICES%"=="true" (
  echo Starting local Docker/Ollama environment...
  call "%SCRIPT_DIR%start-env.bat"
  if errorlevel 1 exit /b 1
)

echo Starting Spring Boot backend with profile "%BACKEND_PROFILE%"...
start "Final Assignment Backend" /D "%BACKEND_DIR%" cmd /k ""%MVN_CMD%" spring-boot:run -Dspring-boot.run.profiles=%BACKEND_PROFILE% -Dspring-boot.run.jvmArguments=-Dspring.devtools.restart.enabled=false %BACKEND_ARGS%"

echo Waiting %BACKEND_WAIT_SECONDS% seconds before starting Flutter...
timeout /t %BACKEND_WAIT_SECONDS% /nobreak >nul

echo Resolving Flutter dependencies...
pushd "%FLUTTER_DIR%" >nul
call "%FLUTTER_CMD%" pub get
if errorlevel 1 (
  popd >nul
  echo [ERROR] flutter pub get failed.
  exit /b 1
)

echo Starting Flutter app...
if /i "%FLUTTER_DETACHED%"=="true" (
  if "%FLUTTER_DEVICE%"=="" (
    start "Final Assignment Flutter" /D "%FLUTTER_DIR%" cmd /k call "%FLUTTER_CMD%" run "--dart-define=APP_ENV=%APP_ENV%" "--dart-define=API_BASE_URL=%API_BASE_URL%" "--dart-define=WS_BASE_URL=%WS_BASE_URL%" %FLUTTER_ARGS%
  ) else (
    start "Final Assignment Flutter" /D "%FLUTTER_DIR%" cmd /k call "%FLUTTER_CMD%" run -d "%FLUTTER_DEVICE%" "--dart-define=APP_ENV=%APP_ENV%" "--dart-define=API_BASE_URL=%API_BASE_URL%" "--dart-define=WS_BASE_URL=%WS_BASE_URL%" %FLUTTER_ARGS%
  )
  set "FLUTTER_EXIT=0"
) else (
  if "%FLUTTER_DEVICE%"=="" (
    call "%FLUTTER_CMD%" run "--dart-define=APP_ENV=%APP_ENV%" "--dart-define=API_BASE_URL=%API_BASE_URL%" "--dart-define=WS_BASE_URL=%WS_BASE_URL%" %FLUTTER_ARGS%
  ) else (
    call "%FLUTTER_CMD%" run -d "%FLUTTER_DEVICE%" "--dart-define=APP_ENV=%APP_ENV%" "--dart-define=API_BASE_URL=%API_BASE_URL%" "--dart-define=WS_BASE_URL=%WS_BASE_URL%" %FLUTTER_ARGS%
  )
  set "FLUTTER_EXIT=%ERRORLEVEL%"
)
popd >nul

echo Flutter exited with code %FLUTTER_EXIT%.
exit /b %FLUTTER_EXIT%

:usage
echo Usage: scripts\start-dev.bat
echo.
echo Starts:
echo   1. Spring Boot backend from finalAssignmentBackend
echo   2. Flutter app from final_assignment_front
echo.
echo Optional environment variables:
echo   START_LOCAL_SERVICES  Start Docker services and Ollama before backend. Default: true
echo   BACKEND_PROFILE       Spring profile. Default: dev
echo   BACKEND_ARGS          Extra Maven/Spring Boot plugin arguments.
echo   BACKEND_WAIT_SECONDS  Delay before Flutter starts. Default: 8
echo   JWT_SECRET            Local JWT secret. Default: development-only secret.
echo   APP_DEV_SERVICES_ENABLED  Starts Redis, Redpanda, and Elasticsearch Testcontainers in dev. Default: false
echo   APP_DOCKER_STARTUP_SCRIPT_ENABLED  Let backend run Docker startup scripts. Default: false because scripts\start-env.bat handles it.
echo   APP_OLLAMA_STARTUP_SCRIPT_ENABLED  Let backend run Ollama startup scripts. Default: false because scripts\start-env.bat handles it.
echo   APP_DEV_SERVICES_REDPANDA_ENABLED  Starts Redpanda Testcontainer in dev. Default: false
echo   APP_ELASTICSEARCH_FALLBACK_ENABLED  Fall back to MySQL when ES calls fail. Default: true
echo   SPRING_DEVTOOLS_RESTART_ENABLED  Disable DevTools restart for stable local startup. Default: false
echo   SPRING_KAFKA_LISTENER_AUTO_STARTUP  Starts Kafka listeners. Default: false
echo   SPRING_DATASOURCE_URL Local database JDBC URL. Default: jdbc:mysql://localhost:3306/traffic
echo   APP_ENV               Flutter APP_ENV dart define. Default: dev
echo   API_BASE_URL          Flutter API base URL. Default: http://localhost:8080
echo   WS_BASE_URL           Flutter WebSocket URL. Default: ws://localhost:8081
echo   MVN_CMD               Maven executable path.
echo   FLUTTER_CMD           Flutter executable path. Falls back to %%USERPROFILE%%\Flutter\flutter\bin\flutter.bat
echo   FLUTTER_DEVICE        Flutter device id. Default: web-server
echo   FLUTTER_ARGS          Extra flutter run arguments. Default: --web-hostname 127.0.0.1 --web-port 3000
echo   FLUTTER_DETACHED      Start Flutter in a separate console. Default: true
exit /b 0
