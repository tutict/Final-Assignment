@echo off
setlocal EnableExtensions

if /i "%~1"=="--help" goto usage
if /i "%~1"=="-h" goto usage

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "ROOT_DIR=%%~fI"

set "BACKEND_DIR=%ROOT_DIR%\finalAssignmentBackend"
set "FLUTTER_DIR=%ROOT_DIR%\final_assignment_front"

if "%BACKEND_PROFILE%"=="" set "BACKEND_PROFILE=dev"
if "%JWT_SECRET%"=="" set "JWT_SECRET=dev-jwt-secret-key-for-local-startup-please-change-1234567890"
if "%APP_DEV_SERVICES_ENABLED%"=="" set "APP_DEV_SERVICES_ENABLED=false"
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
if "%APP_ENV%"=="" set "APP_ENV=dev"
if "%API_BASE_URL%"=="" set "API_BASE_URL=http://localhost:8080"
if "%WS_BASE_URL%"=="" set "WS_BASE_URL=ws://localhost:8081"
if "%BACKEND_WAIT_SECONDS%"=="" set "BACKEND_WAIT_SECONDS=8"

if not exist "%BACKEND_DIR%\pom.xml" (
  echo [ERROR] Spring Boot project not found: "%BACKEND_DIR%"
  exit /b 1
)

if not exist "%FLUTTER_DIR%\pubspec.yaml" (
  echo [ERROR] Flutter project not found: "%FLUTTER_DIR%"
  exit /b 1
)

where mvn >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Maven command "mvn" was not found in PATH.
  exit /b 1
)

where flutter >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Flutter command "flutter" was not found in PATH.
  exit /b 1
)

echo Starting Spring Boot backend with profile "%BACKEND_PROFILE%"...
start "Final Assignment Backend" /D "%BACKEND_DIR%" cmd /k "mvn spring-boot:run -Dspring-boot.run.profiles=%BACKEND_PROFILE% -Dspring-boot.run.jvmArguments=-Dspring.devtools.restart.enabled=false %BACKEND_ARGS%"

echo Waiting %BACKEND_WAIT_SECONDS% seconds before starting Flutter...
timeout /t %BACKEND_WAIT_SECONDS% /nobreak >nul

echo Resolving Flutter dependencies...
pushd "%FLUTTER_DIR%" >nul
flutter pub get
if errorlevel 1 (
  popd >nul
  echo [ERROR] flutter pub get failed.
  exit /b 1
)

echo Starting Flutter app...
if "%FLUTTER_DEVICE%"=="" (
  flutter run "--dart-define=APP_ENV=%APP_ENV%" "--dart-define=API_BASE_URL=%API_BASE_URL%" "--dart-define=WS_BASE_URL=%WS_BASE_URL%" %FLUTTER_ARGS%
) else (
  flutter run -d "%FLUTTER_DEVICE%" "--dart-define=APP_ENV=%APP_ENV%" "--dart-define=API_BASE_URL=%API_BASE_URL%" "--dart-define=WS_BASE_URL=%WS_BASE_URL%" %FLUTTER_ARGS%
)
set "FLUTTER_EXIT=%ERRORLEVEL%"
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
echo   BACKEND_PROFILE       Spring profile. Default: dev
echo   BACKEND_ARGS          Extra Maven/Spring Boot plugin arguments.
echo   BACKEND_WAIT_SECONDS  Delay before Flutter starts. Default: 8
echo   JWT_SECRET            Local JWT secret. Default: development-only secret.
echo   APP_DEV_SERVICES_ENABLED  Starts Redis, Redpanda, and Elasticsearch Testcontainers in dev. Default: false
echo   APP_DOCKER_STARTUP_SCRIPT_ENABLED  Starts local Docker Desktop/Engine and compose services before Spring context. Default: true in dev profile
echo   APP_OLLAMA_STARTUP_SCRIPT_ENABLED  Starts local Ollama before Spring context. Default: true in dev profile
echo   APP_DEV_SERVICES_REDPANDA_ENABLED  Starts Redpanda Testcontainer in dev. Default: false
echo   APP_ELASTICSEARCH_FALLBACK_ENABLED  Fall back to MySQL when ES calls fail. Default: true
echo   SPRING_DEVTOOLS_RESTART_ENABLED  Disable DevTools restart for stable local startup. Default: false
echo   SPRING_KAFKA_LISTENER_AUTO_STARTUP  Starts Kafka listeners. Default: false
echo   SPRING_DATASOURCE_URL Local database JDBC URL. Default: jdbc:mysql://localhost:3306/traffic
echo   APP_ENV               Flutter APP_ENV dart define. Default: dev
echo   API_BASE_URL          Flutter API base URL. Default: http://localhost:8080
echo   WS_BASE_URL           Flutter WebSocket URL. Default: ws://localhost:8081
echo   FLUTTER_DEVICE        Flutter device id, such as windows, chrome, android.
echo   FLUTTER_ARGS          Extra flutter run arguments.
exit /b 0
