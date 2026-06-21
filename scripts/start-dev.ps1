$ErrorActionPreference = "Stop"

function Show-Usage {
    @"
Usage: scripts\start-dev.bat

Starts:
  1. Local Docker/Ollama environment, unless START_LOCAL_SERVICES=false
  2. Spring Boot backend from finalAssignmentBackend
  3. Flutter app from final_assignment_front

Ctrl-C cleanup:
  Stops Flutter, Spring Boot, and child processes.
  If START_LOCAL_SERVICES=true, also stops Docker Compose services and Ollama by default.

Optional environment variables:
  START_LOCAL_SERVICES         Start Docker services and Ollama before backend. Default: true
  STOP_LOCAL_SERVICES_ON_EXIT  Stop Docker/Ollama on Ctrl-C or script exit. Default: START_LOCAL_SERVICES
  STOP_DOCKER_ON_EXIT          Stop Docker Compose services on exit. Default: STOP_LOCAL_SERVICES_ON_EXIT
  STOP_OLLAMA_ON_EXIT          Stop Ollama started by this script on exit. Default: STOP_LOCAL_SERVICES_ON_EXIT
  STARTUP_LOG_ROOT             Root log directory. Default: artifacts\startup
  BACKEND_PROFILE              Spring profile. Default: dev
  BACKEND_ARGS                 Extra Maven/Spring Boot plugin arguments.
  BACKEND_WAIT_SECONDS         Initial delay before health polling. Default: 8
  BACKEND_HEALTH_WAIT_SECONDS  Backend health timeout. Default: 120
  BACKEND_HEALTH_URL           Health URL. Default: http://127.0.0.1:%BACKEND_PORT%/actuator/health
  DB_URL, DB_USERNAME, DB_PASSWORD  Short aliases used when SPRING_DATASOURCE_* is unset.
  APP_ENV                      Flutter APP_ENV dart define. Default: dev
  API_BASE_URL                 Flutter API base URL. Default: http://localhost:8080
  WS_BASE_URL                  Flutter WebSocket URL. Default: ws://localhost:8081
  MVN_CMD                      Maven executable path.
  FLUTTER_CMD                  Flutter executable path.
  FLUTTER_DEVICE               Flutter device id. Default: web-server
  FLUTTER_ARGS                 Extra flutter run arguments. Default: --web-hostname 127.0.0.1 --web-port 3000
  FLUTTER_WAIT_SECONDS         Flutter web readiness timeout. Default: 120
  FLUTTER_WEB_URL              Flutter web readiness URL. Default: http://127.0.0.1:3000
"@ | Write-Host
}

if ($args -contains "--help" -or $args -contains "-h") {
    Show-Usage
    exit 0
}

$script:BackendProcess = $null
$script:FlutterProcess = $null
$script:CleanupStarted = $false
$script:FailureContextShown = $false
$script:ExitCode = 0

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = (Resolve-Path (Join-Path $ScriptDir "..")).Path
$BackendDir = Join-Path $RootDir "finalAssignmentBackend"
$FlutterDir = Join-Path $RootDir "final_assignment_front"
$ComposeFile = Join-Path $ScriptDir "dev-compose.yml"

function Get-EnvValue([string]$Name, [string]$Default = "") {
    $value = [Environment]::GetEnvironmentVariable($Name, "Process")
    if ([string]::IsNullOrWhiteSpace($value)) { return $Default }
    return $value
}

function Set-DefaultEnv([string]$Name, [string]$Default) {
    $value = [Environment]::GetEnvironmentVariable($Name, "Process")
    if ([string]::IsNullOrWhiteSpace($value)) {
        [Environment]::SetEnvironmentVariable($Name, $Default, "Process")
        return $Default
    }
    return $value
}

$StartLocalServices = Set-DefaultEnv "START_LOCAL_SERVICES" "true"
$BackendProfile = Set-DefaultEnv "BACKEND_PROFILE" "dev"
Set-DefaultEnv "JWT_SECRET" "dev-jwt-secret-key-for-local-startup-please-change-1234567890" | Out-Null
Set-DefaultEnv "APP_DEV_SERVICES_ENABLED" "false" | Out-Null
Set-DefaultEnv "APP_DOCKER_STARTUP_SCRIPT_ENABLED" "false" | Out-Null
Set-DefaultEnv "APP_OLLAMA_STARTUP_SCRIPT_ENABLED" "false" | Out-Null
Set-DefaultEnv "APP_DEV_SERVICES_REDPANDA_ENABLED" "false" | Out-Null
Set-DefaultEnv "APP_ELASTICSEARCH_FALLBACK_ENABLED" "true" | Out-Null
Set-DefaultEnv "APP_ELASTICSEARCH_SYNC_ENABLED" "false" | Out-Null
Set-DefaultEnv "SPRING_DATA_ELASTICSEARCH_SKIP_REPOSITORY_INIT" "true" | Out-Null
Set-DefaultEnv "SPRING_DEVTOOLS_RESTART_ENABLED" "false" | Out-Null
Set-DefaultEnv "SPRING_KAFKA_LISTENER_AUTO_STARTUP" "false" | Out-Null
Set-DefaultEnv "MANAGEMENT_HEALTH_ELASTICSEARCH_ENABLED" "false" | Out-Null
Set-DefaultEnv "SPRING_AI_OLLAMA_INIT_PULL_MODEL_STRATEGY" "never" | Out-Null

if ([string]::IsNullOrWhiteSpace($env:SPRING_DATASOURCE_URL) -and -not [string]::IsNullOrWhiteSpace($env:DB_URL)) { $env:SPRING_DATASOURCE_URL = $env:DB_URL }
if ([string]::IsNullOrWhiteSpace($env:SPRING_DATASOURCE_USERNAME) -and -not [string]::IsNullOrWhiteSpace($env:DB_USERNAME)) { $env:SPRING_DATASOURCE_USERNAME = $env:DB_USERNAME }
if ([string]::IsNullOrWhiteSpace($env:SPRING_DATASOURCE_PASSWORD) -and -not [string]::IsNullOrWhiteSpace($env:DB_PASSWORD)) { $env:SPRING_DATASOURCE_PASSWORD = $env:DB_PASSWORD }
Set-DefaultEnv "SPRING_DATASOURCE_URL" "jdbc:mysql://localhost:3306/traffic" | Out-Null
Set-DefaultEnv "SPRING_DATASOURCE_USERNAME" "root" | Out-Null
Set-DefaultEnv "SPRING_DATASOURCE_PASSWORD" "root" | Out-Null
Set-DefaultEnv "SPRING_DATASOURCE_DRIVER_CLASS_NAME" "com.mysql.cj.jdbc.Driver" | Out-Null
Set-DefaultEnv "SPRING_DATA_REDIS_HOST" "localhost" | Out-Null
Set-DefaultEnv "SPRING_DATA_REDIS_PORT" "6379" | Out-Null
Set-DefaultEnv "SPRING_KAFKA_BOOTSTRAP_SERVERS" "localhost:9092" | Out-Null

$AppEnv = Set-DefaultEnv "APP_ENV" "dev"
$ApiBaseUrl = Set-DefaultEnv "API_BASE_URL" "http://localhost:8080"
$WsBaseUrl = Set-DefaultEnv "WS_BASE_URL" "ws://localhost:8081"
$BackendPort = Set-DefaultEnv "BACKEND_PORT" "8080"
$BackendWaitSeconds = [int](Set-DefaultEnv "BACKEND_WAIT_SECONDS" "8")
$BackendHealthWaitSeconds = [int](Set-DefaultEnv "BACKEND_HEALTH_WAIT_SECONDS" "120")
$BackendHealthUrl = Set-DefaultEnv "BACKEND_HEALTH_URL" "http://127.0.0.1:$BackendPort/actuator/health"
$FlutterDevice = Set-DefaultEnv "FLUTTER_DEVICE" "web-server"
$FlutterArgs = Set-DefaultEnv "FLUTTER_ARGS" "--web-hostname 127.0.0.1 --web-port 3000"
$FlutterWaitSeconds = [int](Set-DefaultEnv "FLUTTER_WAIT_SECONDS" "120")
$FlutterWebUrl = Set-DefaultEnv "FLUTTER_WEB_URL" "http://127.0.0.1:3000"
$StopLocalServicesOnExit = Set-DefaultEnv "STOP_LOCAL_SERVICES_ON_EXIT" $StartLocalServices
$StopDockerOnExit = Set-DefaultEnv "STOP_DOCKER_ON_EXIT" $StopLocalServicesOnExit
$StopOllamaOnExit = Set-DefaultEnv "STOP_OLLAMA_ON_EXIT" $StopLocalServicesOnExit

$StartupLogRoot = Set-DefaultEnv "STARTUP_LOG_ROOT" (Join-Path $RootDir "artifacts\startup")
$StartupRunId = Set-DefaultEnv "STARTUP_RUN_ID" (Get-Date -Format "yyyyMMdd-HHmmss")
$StartupLogDir = Set-DefaultEnv "STARTUP_LOG_DIR" (Join-Path $StartupLogRoot $StartupRunId)
New-Item -ItemType Directory -Force -Path $StartupLogDir | Out-Null

$StartupLog = Join-Path $StartupLogDir "startup.log"
$BackendLog = Join-Path $StartupLogDir "backend.log"
$BackendErrLog = Join-Path $StartupLogDir "backend.err.log"
$BackendRunner = Join-Path $StartupLogDir "run-backend.bat"
$FlutterPubLog = Join-Path $StartupLogDir "flutter-pub-get.log"
$FlutterPubErrLog = Join-Path $StartupLogDir "flutter-pub-get.err.log"
$FlutterLog = Join-Path $StartupLogDir "flutter.log"
$FlutterErrLog = Join-Path $StartupLogDir "flutter.err.log"
$FlutterRunner = Join-Path $StartupLogDir "run-flutter.bat"
$FlutterPubRunner = Join-Path $StartupLogDir "run-flutter-pub-get.bat"
$EnvStopLog = Join-Path $StartupLogDir "environment-stop.log"
$OllamaPidFile = Join-Path $StartupLogDir "ollama.pid"

function Write-Log([string]$Message) {
    Write-Host $Message
    Add-Content -LiteralPath $StartupLog -Encoding ASCII -Value "[$StartupRunId $(Get-Date -Format HH:mm:ss.fff)] $Message"
}

function Write-StartupSummary {
    $summary = @(
        "Final Assignment startup run",
        "Run ID: $StartupRunId",
        "Started at: $StartupRunId $(Get-Date -Format HH:mm:ss.fff)",
        "Root: $RootDir",
        "Log directory: $StartupLogDir",
        "Backend directory: $BackendDir",
        "Flutter directory: $FlutterDir",
        "START_LOCAL_SERVICES=$StartLocalServices",
        "STOP_LOCAL_SERVICES_ON_EXIT=$StopLocalServicesOnExit",
        "STOP_DOCKER_ON_EXIT=$StopDockerOnExit",
        "STOP_OLLAMA_ON_EXIT=$StopOllamaOnExit",
        "BACKEND_PROFILE=$BackendProfile",
        "BACKEND_HEALTH_URL=$BackendHealthUrl",
        "BACKEND_WAIT_SECONDS=$BackendWaitSeconds",
        "BACKEND_HEALTH_WAIT_SECONDS=$BackendHealthWaitSeconds",
        "SPRING_DATASOURCE_URL=$env:SPRING_DATASOURCE_URL",
        "SPRING_DATASOURCE_USERNAME=$env:SPRING_DATASOURCE_USERNAME",
        "SPRING_DATASOURCE_PASSWORD=<redacted>",
        "SPRING_DATA_REDIS_HOST=$env:SPRING_DATA_REDIS_HOST",
        "SPRING_DATA_REDIS_PORT=$env:SPRING_DATA_REDIS_PORT",
        "SPRING_KAFKA_BOOTSTRAP_SERVERS=$env:SPRING_KAFKA_BOOTSTRAP_SERVERS",
        "APP_ENV=$AppEnv",
        "API_BASE_URL=$ApiBaseUrl",
        "WS_BASE_URL=$WsBaseUrl",
        "FLUTTER_DEVICE=$FlutterDevice",
        "FLUTTER_ARGS=$FlutterArgs",
        "FLUTTER_WAIT_SECONDS=$FlutterWaitSeconds",
        "FLUTTER_WEB_URL=$FlutterWebUrl"
    )
    Set-Content -LiteralPath $StartupLog -Encoding ASCII -Value $summary
}

function Get-ExecutablePath([string]$Configured, [string[]]$Candidates, [string]$FallbackPath, [string]$Name) {
    if (-not [string]::IsNullOrWhiteSpace($Configured)) {
        if (Test-Path -LiteralPath $Configured) { return (Resolve-Path -LiteralPath $Configured).Path }
        $found = Get-Command $Configured -ErrorAction SilentlyContinue
        if ($found) { return $found.Source }
        throw "$Name command was not found or is not executable: $Configured"
    }
    foreach ($candidate in $Candidates) {
        $found = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($found) { return $found.Source }
    }
    if (-not [string]::IsNullOrWhiteSpace($FallbackPath) -and (Test-Path -LiteralPath $FallbackPath)) {
        return (Resolve-Path -LiteralPath $FallbackPath).Path
    }
    throw "$Name command was not found in PATH."
}

function Show-FileTail([string]$Path, [int]$Lines = 80) {
    Write-Host ""
    Write-Host "----- $Path (last $Lines lines) -----"
    if (Test-Path -LiteralPath $Path) {
        Get-Content -LiteralPath $Path -Tail $Lines -ErrorAction SilentlyContinue
    } else {
        Write-Host "[missing] $Path"
    }
    Write-Host "----- end $Path -----"
}

function Show-PortDiagnostics {
    Write-Host ""
    Write-Host "----- Port diagnostics -----"
    $ports = @($BackendPort, 8081, 3000) | Select-Object -Unique
    foreach ($port in $ports) {
        $connections = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
        foreach ($connection in $connections) {
            $process = Get-Process -Id $connection.OwningProcess -ErrorAction SilentlyContinue
            $name = if ($process) { $process.ProcessName } else { "unknown" }
            $endpoint = "{0}:{1}" -f $connection.LocalAddress, $connection.LocalPort
            Write-Host ("{0} PID={1} Process={2}" -f $endpoint, $connection.OwningProcess, $name)
        }
    }
    Write-Host "----- end Port diagnostics -----"
}

function Show-DockerState {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { return }
    Write-Host ""
    Write-Host "----- Docker compose services -----"
    $previousPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        & docker compose -f $ComposeFile ps 2>$null | ForEach-Object { Write-Host $_ }
    } catch {
        Write-Host "Docker status unavailable: $($_.Exception.Message)"
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    Write-Host "----- end Docker compose services -----"
}

function Show-FailureContext {
    Write-Host ""
    Write-Host "Startup log directory: $StartupLogDir"
    Show-FileTail $StartupLog 80
    Show-FileTail $BackendLog 120
    Show-FileTail $BackendErrLog 120
    Show-FileTail $FlutterPubLog 80
    Show-FileTail $FlutterPubErrLog 80
    Show-FileTail $FlutterLog 120
    Show-FileTail $FlutterErrLog 120
    Show-PortDiagnostics
    Show-DockerState
}

function Fail([string]$Message) {
    Write-Host ""
    Write-Host "[ERROR] $Message"
    Add-Content -LiteralPath $StartupLog -Encoding ASCII -Value "[$StartupRunId $(Get-Date -Format HH:mm:ss.fff)] [ERROR] $Message"
    Show-FailureContext
    $script:FailureContextShown = $true
    $script:ExitCode = 1
    throw $Message
}

function Invoke-HttpOk([string]$Url) {
    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if (-not $curl) { $curl = Get-Command curl -ErrorAction SilentlyContinue }
    if ($curl) {
        $previousPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = "Continue"
            & $curl.Source -fsS --max-time 3 $Url > $null 2> $null
            return $LASTEXITCODE -eq 0
        } catch {
            return $false
        } finally {
            $ErrorActionPreference = $previousPreference
        }
    }
    try {
        $response = Invoke-WebRequest -UseBasicParsing $Url -TimeoutSec 3
        return $response.StatusCode -ge 200 -and $response.StatusCode -lt 300
    } catch {
        return $false
    }
}

function Get-ChildProcessIds([int]$ProcessId) {
    @(Get-CimInstance Win32_Process -Filter "ParentProcessId=$ProcessId" -ErrorAction SilentlyContinue | ForEach-Object { [int]$_.ProcessId })
}

function Start-RunnerProcess([string]$RunnerPath, [string]$WorkingDirectory) {
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = "cmd.exe"
    $psi.Arguments = "/d /c call `"$RunnerPath`""
    $psi.WorkingDirectory = $WorkingDirectory
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true


    return [System.Diagnostics.Process]::Start($psi)
}
function Stop-ProcessTree([int]$ProcessId, [string]$Name) {
    if ($ProcessId -le 0) { return }
    $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    if (-not $process) { return }
    foreach ($childId in Get-ChildProcessIds $ProcessId) {
        Stop-ProcessTree -ProcessId $childId -Name "$Name child"
    }
    Write-Log "Stopping $Name process tree at PID $ProcessId..."
    Stop-Process -Id $ProcessId -Force -ErrorAction SilentlyContinue
}

function Stop-LocalDependencies {
    if ($StopOllamaOnExit -ieq "true" -and (Test-Path -LiteralPath $OllamaPidFile)) {
        $pidText = (Get-Content -LiteralPath $OllamaPidFile -ErrorAction SilentlyContinue | Select-Object -First 1)
        if ($pidText -match '^\d+$') {
            Stop-ProcessTree -ProcessId ([int]$pidText) -Name "Ollama"
        }
    }

    if ($StopDockerOnExit -ieq "true" -and (Get-Command docker -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath $ComposeFile)) {
        Write-Log "Stopping Docker Compose services from $ComposeFile..."
        $previousPreference = $ErrorActionPreference
        try {
            $ErrorActionPreference = "Continue"
            & docker compose -f $ComposeFile down --remove-orphans *> $EnvStopLog
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Docker Compose cleanup exited with code $LASTEXITCODE. See $EnvStopLog"
            } else {
                Write-Log "Docker Compose services stopped. Log: $EnvStopLog"
            }
        } catch {
            Write-Log "Docker Compose cleanup failed: $($_.Exception.Message). See $EnvStopLog"
        } finally {
            $ErrorActionPreference = $previousPreference
        }
    }
}

function Cleanup {
    if ($script:CleanupStarted) { return }
    $script:CleanupStarted = $true
    Write-Log "Cleanup started."
    if ($script:FlutterProcess -and -not $script:FlutterProcess.HasExited) {
        Stop-ProcessTree -ProcessId $script:FlutterProcess.Id -Name "Flutter"
    }
    if ($script:BackendProcess -and -not $script:BackendProcess.HasExited) {
        Stop-ProcessTree -ProcessId $script:BackendProcess.Id -Name "Spring Boot"
    }
    if ($StartLocalServices -ieq "true" -and $StopLocalServicesOnExit -ieq "true") {
        Stop-LocalDependencies
    } else {
        Write-Log "Skipping dependency cleanup. START_LOCAL_SERVICES=$StartLocalServices STOP_LOCAL_SERVICES_ON_EXIT=$StopLocalServicesOnExit"
    }
    Write-Log "Cleanup completed."
}

Write-StartupSummary

try {
    if (-not (Test-Path -LiteralPath (Join-Path $BackendDir "pom.xml"))) { Fail "Spring Boot project not found: $BackendDir" }
    if (-not (Test-Path -LiteralPath (Join-Path $FlutterDir "pubspec.yaml"))) { Fail "Flutter project not found: $FlutterDir" }

    $MavenHome = Get-EnvValue "MAVEN_HOME"
    $MavenFallback = if ([string]::IsNullOrWhiteSpace($MavenHome)) { "" } else { Join-Path $MavenHome "bin\mvn.cmd" }
    $MvnCmd = Get-ExecutablePath -Configured (Get-EnvValue "MVN_CMD") -Candidates @("mvn.cmd", "mvn") -FallbackPath $MavenFallback -Name "Maven"
    $FlutterFallback = Join-Path (Get-EnvValue "USERPROFILE") "Flutter\flutter\bin\flutter.bat"
    $FlutterCmd = Get-ExecutablePath -Configured (Get-EnvValue "FLUTTER_CMD") -Candidates @("flutter.bat", "flutter") -FallbackPath $FlutterFallback -Name "Flutter"
    $env:MVN_CMD = $MvnCmd
    $env:FLUTTER_CMD = $FlutterCmd

    Write-Log "Using Maven: $MvnCmd"
    Write-Log "Using Flutter: $FlutterCmd"

    if ($StartLocalServices -ieq "true") {
        Write-Log "Starting local Docker/Ollama environment..."
        & (Join-Path $ScriptDir "start-env.bat")
        if ($LASTEXITCODE -ne 0) { Fail "Local Docker/Ollama environment startup failed." }
    } else {
        Write-Log "Skipping local Docker/Ollama environment because START_LOCAL_SERVICES=false."
    }

    Set-Content -LiteralPath $BackendRunner -Encoding ASCII -Value @(
        "@echo off",
        "cd /d `"$BackendDir`"",
        "call `"$MvnCmd`" spring-boot:run -Dspring-boot.run.profiles=$BackendProfile -Dspring-boot.run.jvmArguments=-Dspring.devtools.restart.enabled=false $env:BACKEND_ARGS 1> `"$BackendLog`" 2> `"$BackendErrLog`"",
        "exit /b %ERRORLEVEL%"
    )

    Write-Log "Starting Spring Boot backend with profile $BackendProfile..."
    $script:BackendProcess = Start-RunnerProcess -RunnerPath $BackendRunner -WorkingDirectory $BackendDir
    Write-Log "Spring Boot PID: $($script:BackendProcess.Id)"
    Write-Log "Backend stdout: $BackendLog"
    Write-Log "Backend stderr: $BackendErrLog"

    Write-Log "Waiting $BackendWaitSeconds seconds before backend health polling..."
    Start-Sleep -Seconds $BackendWaitSeconds
    Write-Log "Waiting up to $BackendHealthWaitSeconds seconds for $BackendHealthUrl..."
    $deadline = (Get-Date).AddSeconds($BackendHealthWaitSeconds)
    while ((Get-Date) -lt $deadline) {
        if (Invoke-HttpOk $BackendHealthUrl) {
            Write-Log "Spring Boot backend is healthy."
            break
        }
        if ($script:BackendProcess.HasExited) {
            Fail "Spring Boot backend exited before becoming healthy. Exit code: $($script:BackendProcess.ExitCode)"
        }
        Start-Sleep -Seconds 2
    }
    if (-not (Invoke-HttpOk $BackendHealthUrl)) {
        Fail "Spring Boot backend did not become healthy within $BackendHealthWaitSeconds seconds."
    }

    Write-Log "Resolving Flutter dependencies..."
    Set-Content -LiteralPath $FlutterPubRunner -Encoding ASCII -Value @("@echo off", "cd /d `"$FlutterDir`"", "call `"$FlutterCmd`" pub get 1> `"$FlutterPubLog`" 2> `"$FlutterPubErrLog`"", "exit /b %ERRORLEVEL%")
    $pubProcess = Start-RunnerProcess -RunnerPath $FlutterPubRunner -WorkingDirectory $FlutterDir
    $pubProcess.WaitForExit()
    if ($pubProcess.ExitCode -ne 0) {
        Show-FileTail $FlutterPubLog 120
        Show-FileTail $FlutterPubErrLog 120
        Fail "flutter pub get failed with exit code $($pubProcess.ExitCode)."
    }
    Write-Log "flutter pub get completed. Log: $FlutterPubLog"

    $flutterCommand = if ([string]::IsNullOrWhiteSpace($FlutterDevice)) {
        "call `"$FlutterCmd`" run --dart-define=APP_ENV=$AppEnv --dart-define=API_BASE_URL=$ApiBaseUrl --dart-define=WS_BASE_URL=$WsBaseUrl $FlutterArgs"
    } else {
        "call `"$FlutterCmd`" run -d `"$FlutterDevice`" --dart-define=APP_ENV=$AppEnv --dart-define=API_BASE_URL=$ApiBaseUrl --dart-define=WS_BASE_URL=$WsBaseUrl $FlutterArgs"
    }
    $flutterCommand = "$flutterCommand 1> `"$FlutterLog`" 2> `"$FlutterErrLog`""
    Set-Content -LiteralPath $FlutterRunner -Encoding ASCII -Value @("@echo off", "cd /d `"$FlutterDir`"", $flutterCommand, "exit /b %ERRORLEVEL%")

    Write-Log "Starting Flutter app..."
    $script:FlutterProcess = Start-RunnerProcess -RunnerPath $FlutterRunner -WorkingDirectory $FlutterDir
    Write-Log "Flutter PID: $($script:FlutterProcess.Id)"
    Write-Log "Flutter stdout: $FlutterLog"
    Write-Log "Flutter stderr: $FlutterErrLog"

    if ($FlutterDevice -ieq "web-server") {
        Write-Log "Waiting up to $FlutterWaitSeconds seconds for $FlutterWebUrl..."
        $flutterDeadline = (Get-Date).AddSeconds($FlutterWaitSeconds)
        while ((Get-Date) -lt $flutterDeadline) {
            if (Invoke-HttpOk $FlutterWebUrl) {
                Write-Log "Flutter web server is reachable: $FlutterWebUrl"
                break
            }
            if ($script:FlutterProcess.HasExited) {
                Fail "Flutter exited before the web server became reachable. Exit code: $($script:FlutterProcess.ExitCode)"
            }
            Start-Sleep -Seconds 2
        }
        if (-not (Invoke-HttpOk $FlutterWebUrl)) {
            Fail "Flutter web server did not become reachable within $FlutterWaitSeconds seconds."
        }
    }

    Write-Log "Startup flow completed. Press Ctrl-C to stop all started services. Logs are in $StartupLogDir"
    while (-not $script:FlutterProcess.HasExited) {
        Start-Sleep -Seconds 1
        if ($script:BackendProcess.HasExited) {
            Fail "Spring Boot backend exited while Flutter was still running. Exit code: $($script:BackendProcess.ExitCode)"
        }
    }
    $script:ExitCode = $script:FlutterProcess.ExitCode
} catch [System.Management.Automation.PipelineStoppedException] {
    Write-Log "Ctrl-C received. Stopping started services..."
    $script:ExitCode = 130
} catch {
    if ($script:ExitCode -eq 0) { $script:ExitCode = 1 }
    if (-not $script:FailureContextShown) {
        $message = $_.Exception.Message
        if ($_.InvocationInfo -and $_.InvocationInfo.PositionMessage) { $message = "$message`n$($_.InvocationInfo.PositionMessage)" }
        Write-Host ""
        Write-Host "[ERROR] $message"
        Add-Content -LiteralPath $StartupLog -Encoding ASCII -Value "[$StartupRunId $(Get-Date -Format HH:mm:ss.fff)] [ERROR] $message"
        Show-FailureContext
        $script:FailureContextShown = $true
    }
} finally {
    Cleanup
}

exit $script:ExitCode
