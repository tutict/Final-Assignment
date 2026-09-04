$ErrorActionPreference = "Stop"

# Interactive startup for the Final Assignment project.
#
# One menu pick selects the backend implementation and the frontend app, then
# starts local dependencies (optional), the backend, and the frontend.
#
# Backends:
#   spring  - finalAssignmentBackend      (main; REST 8080, WS 8081, DB traffic)
#   go      - final_assignment_backend_go (Gin main app; REST 8080, DB cesi)
#   quarkus - final_assignment_backend_quarkus (Gradle/Quarkus; REST 8080, WS 8081, DB cesi)
#   cloud   - finalAssignmentCloud        (Spring Cloud microservices; gateway 8080)
#   none    - skip the backend
#
# Frontends:
#   flutter - final_assignment_front       (web-server, http://127.0.0.1:3000)
#   react   - final_assignment_front_react (Vite,   http://127.0.0.1:5173)
#   none    - skip the frontend
#
# Flags:  -b spring|go|quarkus|cloud|none   skip the menu for the backend
#         -f flutter|react|none             skip the menu for the frontend
#         -e|--no-env                       skip local Docker/Ollama startup
#         -h|--help                         show this usage

function Show-Usage {
    @"
Usage: scripts\start-dev.bat [-b backend] [-f frontend] [-e] [-h]

Starts:
  1. Local Docker/Ollama environment (unless START_LOCAL_SERVICES=false or -e)
  2. The selected backend implementation
  3. The selected frontend app

Backend choices: spring | go | quarkus | cloud | none
Frontend choices: flutter | react | none

Optional flags / environment variables:
  -b, --backend <name>         Backend implementation to start (skips the menu).
  -f, --frontend <name>        Frontend app to start (skips the menu).
  -e, --no-env                 Skip local Docker/Ollama environment startup.
  -h, --help                   Show this usage.

  START_LOCAL_SERVICES         Start Docker services and Ollama before backend. Default: true
  STOP_LOCAL_SERVICES_ON_EXIT  Stop Docker/Ollama on Ctrl-C or script exit. Default: START_LOCAL_SERVICES
  STOP_DOCKER_ON_EXIT          Stop Docker Compose services on exit. Default: STOP_LOCAL_SERVICES_ON_EXIT
  STOP_OLLAMA_ON_EXIT          Stop Ollama started by this script on exit. Default: STOP_LOCAL_SERVICES_ON_EXIT
  STARTUP_LOG_ROOT             Root log directory. Default: artifacts\startup
  BACKEND_PROFILE              Spring profile. Default: dev
  BACKEND_ARGS                 Extra Maven/Spring Boot plugin arguments.
  BACKEND_WAIT_SECONDS         Initial delay before health polling. Default: 8
  BACKEND_HEALTH_WAIT_SECONDS  Backend health timeout. Default: 120
  BACKEND_HEALTH_URL           Health URL. Default: http://127.0.0.1:8080/actuator/health
  DB_URL, DB_USERNAME, DB_PASSWORD  Short aliases used when SPRING_DATASOURCE_* is unset.
  APP_ENV                      Flutter APP_ENV dart define. Default: dev
  API_BASE_URL                 Flutter API base URL. Default: http://localhost:8080
  WS_BASE_URL                  Flutter WebSocket URL. Default: ws://localhost:8081
  MVN_CMD                      Maven executable path.
  GRADLE_CMD                   Gradle executable path.
  GO_CMD                       Go executable path.
  FLUTTER_CMD                  Flutter executable path.
  FLUTTER_DEVICE               Flutter device id. Default: web-server
  FLUTTER_ARGS                 Extra flutter run arguments. Default: --web-hostname 127.0.0.1 --web-port 3000
  FLUTTER_WAIT_SECONDS         Flutter web readiness timeout. Default: 120
  FLUTTER_WEB_URL              Flutter web readiness URL. Default: http://127.0.0.1:3000
  NPM_CMD                      npm executable path.
"@ | Write-Host
}

# ---- arg parsing -----------------------------------------------------------
$menuBackend = $null
$menuFrontend = $null
$skipEnv = $false
for ($i = 0; $i -lt $args.Count; $i++) {
    switch -Regex ($args[$i]) {
        "^-h$|^--help$" { Show-Usage; exit 0 }
        "^-b$|^--backend$" { $menuBackend = $args[++$i]; continue }
        "^-f$|^--frontend$" { $menuFrontend = $args[++$i]; continue }
        "^-e$|^--no-env$" { $skipEnv = $true; continue }
        default {
            Write-Host "[ERROR] Unknown argument: $($args[$i])"
            Show-Usage
            exit 1
        }
    }
}

$script:BackendProcess = $null
$script:FrontendProcess = $null
$script:CleanupStarted = $false
$script:FailureContextShown = $false
$script:ExitCode = 0

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = (Resolve-Path (Join-Path $ScriptDir "..")).Path
$SpringDir = Join-Path $RootDir "finalAssignmentBackend"
$GoDir = Join-Path $RootDir "final_assignment_backend_go"
$QuarkusDir = Join-Path $RootDir "final_assignment_backend_quarkus"
$CloudDir = Join-Path $RootDir "finalAssignmentCloud"
$FlutterDir = Join-Path $RootDir "final_assignment_front"
$ReactDir = Join-Path $RootDir "final_assignment_front_react"
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
if ($skipEnv) { $StartLocalServices = "false" }
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
$ReactDevUrl = Set-DefaultEnv "REACT_DEV_URL" "http://127.0.0.1:5173"
$ReactArgs = Set-DefaultEnv "REACT_ARGS" ""
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
$FrontendLog = Join-Path $StartupLogDir "frontend.log"
$FrontendErrLog = Join-Path $StartupLogDir "frontend.err.log"
$FrontendRunner = Join-Path $StartupLogDir "run-frontend.bat"
$FlutterPubRunner = Join-Path $StartupLogDir "run-flutter-pub-get.bat"
$EnvStopLog = Join-Path $StartupLogDir "environment-stop.log"
$OllamaPidFile = Join-Path $StartupLogDir "ollama.pid"

function Write-Log([string]$Message) {
    Write-Host $Message
    Add-Content -LiteralPath $StartupLog -Encoding ASCII -Value "[$StartupRunId $(Get-Date -Format HH:mm:ss.fff)] $Message"
}

# ---- interactive menu ------------------------------------------------------
function Select-Option {
    param([Parameter(Mandatory = $true)][string]$Prompt, [Parameter(Mandatory = $true)][object[]]$Options)
    for ($idx = 0; $idx -lt $Options.Count; $idx++) {
        Write-Host ("  [{0}] {1}" -f $idx, $Options[$idx].Label)
    }
    while ($true) {
        $choice = Read-Host $Prompt
        if ($choice -match '^\d+$' -and [int]$choice -lt $Options.Count) {
            return $Options[[int]$choice].Value
        }
        Write-Host "  Invalid choice. Enter 0-$($Options.Count - 1)."
    }
}

$BackendChoices = @(
    @{ Label = "Spring Boot (main, finalAssignmentBackend) - REST 8080 / WS 8081 / DB traffic"; Value = "spring" }
    @{ Label = "Go / Gin (final_assignment_backend_go) - REST 8080 / DB cesi"; Value = "go" }
    @{ Label = "Quarkus (final_assignment_backend_quarkus) - REST 8080 / WS 8081 / DB cesi"; Value = "quarkus" }
    @{ Label = "Spring Cloud microservices (finalAssignmentCloud) - gateway 8080"; Value = "cloud" }
    @{ Label = "None (backend only if frontend selected)"; Value = "none" }
)
$FrontendChoices = @(
    @{ Label = "Flutter Web (final_assignment_front) - http://127.0.0.1:3000"; Value = "flutter" }
    @{ Label = "React + Vite (final_assignment_front_react) - http://127.0.0.1:5173"; Value = "react" }
    @{ Label = "None (frontend only if backend selected)"; Value = "none" }
)

# Validate any flag-provided values first (fail fast, before prompting).
if (-not [string]::IsNullOrWhiteSpace($menuBackend)) {
    $BackendChoice = $menuBackend.ToLowerInvariant()
    if ($BackendChoice -notin @("spring", "go", "quarkus", "cloud", "none")) {
        Write-Host "[ERROR] Unknown backend: $menuBackend"
        Show-Usage
        exit 1
    }
}
if (-not [string]::IsNullOrWhiteSpace($menuFrontend)) {
    $FrontendChoice = $menuFrontend.ToLowerInvariant()
    if ($FrontendChoice -notin @("flutter", "react", "none")) {
        Write-Host "[ERROR] Unknown frontend: $menuFrontend"
        Show-Usage
        exit 1
    }
}

# Prompt only for whatever was not provided via flags.
if ([string]::IsNullOrWhiteSpace($menuBackend)) {
    Write-Host ""
    Write-Host "Choose the backend to start:"
    $BackendChoice = Select-Option -Prompt "Backend (0-$($BackendChoices.Count - 1))" -Options $BackendChoices
}
if ([string]::IsNullOrWhiteSpace($menuFrontend)) {
    Write-Host ""
    Write-Host "Choose the frontend to start:"
    $FrontendChoice = Select-Option -Prompt "Frontend (0-$($FrontendChoices.Count - 1))" -Options $FrontendChoices
}

if ($BackendChoice -eq "none" -and $FrontendChoice -eq "none") {
    Write-Host "[ERROR] You must start at least one of backend or frontend."
    exit 1
}

function Write-StartupSummary {
    $summary = @(
        "Final Assignment startup run",
        "Run ID: $StartupRunId",
        "Started at: $StartupRunId $(Get-Date -Format HH:mm:ss.fff)",
        "Root: $RootDir",
        "Log directory: $StartupLogDir",
        "Backend choice: $BackendChoice",
        "Frontend choice: $FrontendChoice",
        "Spring directory: $SpringDir",
        "Go directory: $GoDir",
        "Quarkus directory: $QuarkusDir",
        "Cloud directory: $CloudDir",
        "Flutter directory: $FlutterDir",
        "React directory: $ReactDir",
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
    $ports = @($BackendPort, 8081, 3000, 5173) | Select-Object -Unique
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
    Show-FileTail $FrontendLog 120
    Show-FileTail $FrontendErrLog 120
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
    if ($script:FrontendProcess -and -not $script:FrontendProcess.HasExited) {
        Stop-ProcessTree -ProcessId $script:FrontendProcess.Id -Name "Frontend"
    }
    if ($script:BackendProcess -and -not $script:BackendProcess.HasExited) {
        Stop-ProcessTree -ProcessId $script:BackendProcess.Id -Name "Backend"
    }
    if ($StartLocalServices -ieq "true" -and $StopLocalServicesOnExit -ieq "true") {
        Stop-LocalDependencies
    } else {
        Write-Log "Skipping dependency cleanup. START_LOCAL_SERVICES=$StartLocalServices STOP_LOCAL_SERVICES_ON_EXIT=$StopLocalServicesOnExit"
    }
    Write-Log "Cleanup completed."
}

# ---- backend launcher builders ---------------------------------------------

function New-SpringRunner {
    param([string]$RunnerPath)
    $MavenHome = Get-EnvValue "MAVEN_HOME"
    $MavenFallback = if ([string]::IsNullOrWhiteSpace($MavenHome)) { "" } else { Join-Path $MavenHome "bin\mvn.cmd" }
    $MvnCmd = Get-ExecutablePath -Configured (Get-EnvValue "MVN_CMD") -Candidates @("mvn.cmd", "mvn") -FallbackPath $MavenFallback -Name "Maven"
    $env:MVN_CMD = $MvnCmd
    Write-Log "Using Maven: $MvnCmd"
    Set-Content -LiteralPath $RunnerPath -Encoding ASCII -Value @(
        "@echo off",
        "cd /d `"$SpringDir`"",
        "call `"$MvnCmd`" spring-boot:run -Dspring-boot.run.profiles=$BackendProfile -Dspring-boot.run.jvmArguments=-Dspring.devtools.restart.enabled=false $env:BACKEND_ARGS 1> `"$BackendLog`" 2> `"$BackendErrLog`"",
        "exit /b %ERRORLEVEL%"
    )
    return $true
}

function New-GoRunner {
    param([string]$RunnerPath)
    $GoCmd = Get-ExecutablePath -Configured (Get-EnvValue "GO_CMD") -Candidates @("go") -FallbackPath "" -Name "Go"
    $env:GO_CMD = $GoCmd
    Write-Log "Using Go: $GoCmd"
    # Use the compose-managed localhost services (Redis/Kafka/Elasticsearch)
    # instead of letting the Go app spin up unmanaged Testcontainers.
    # REDIS_ENABLED=false keeps the backend fully bootable even when the
    # compose stack is skipped, without the app crashing on a missing Redis.
    Set-Content -LiteralPath $RunnerPath -Encoding ASCII -Value @(
        "@echo off",
        "cd /d `"$GoDir`"",
        "set REDIS_HOST=localhost",
        "set REDIS_PORT=6379",
        "set REDIS_ENABLED=false",
        "set KAFKA_BOOTSTRAP_SERVERS=localhost:9092",
        "set ELASTICSEARCH_URL=http://localhost:9200",
        "set GO_DOCKER_SERVICES_ENABLED=false",
        "call `"$GoCmd`" run ./project/cmd/app 1> `"$BackendLog`" 2> `"$BackendErrLog`"",
        "exit /b %ERRORLEVEL%"
    )
    return $true
}

function New-QuarkusRunner {
    param([string]$RunnerPath)
    # Prefer the checked-in Gradle wrapper; fall back to a system gradle.
    $WrapperFallback = Join-Path $QuarkusDir "gradlew.bat"
    $GradleHome = Get-EnvValue "GRADLE_HOME"
    $GradleSystemFallback = if ([string]::IsNullOrWhiteSpace($GradleHome)) { "" } else { Join-Path $GradleHome "bin\gradle.bat" }
    $GradleCmd = Get-ExecutablePath -Configured (Get-EnvValue "GRADLE_CMD") -Candidates @("gradle.bat", "gradle") -FallbackPath $WrapperFallback -Name "Gradle"
    if (-not (Test-Path -LiteralPath $GradleCmd) -and -not [string]::IsNullOrWhiteSpace($GradleSystemFallback) -and (Test-Path -LiteralPath $GradleSystemFallback)) {
        $GradleCmd = $GradleSystemFallback
    }
    $env:GRADLE_CMD = $GradleCmd
    Write-Log "Using Gradle: $GradleCmd"
    # Reuse the JWT and datasource credentials the script already resolved for the
    # Spring backend. Quarkus reads these as QUARKUS_* env vars (SmallRye Config).
    # The JDBC URL below hard-codes the "cesi" database (the Quarkus schema), but the
    # username/password come from SPRING_DATASOURCE_USERNAME / _PASSWORD (default root).
    $JwtSecret = Get-EnvValue "JWT_SECRET" "dev-jwt-secret-key-for-local-startup-please-change-1234567890"
    $DbUser = Get-EnvValue "SPRING_DATASOURCE_USERNAME" "root"
    $DbPassword = Get-EnvValue "SPRING_DATASOURCE_PASSWORD" "root"
    # ML-DSA / ML-KEM PQC 密钥本地开发可留空：应用在空值时生成临时密钥。
    # 在 runner .bat 里用单个空格占位（非空、但 isBlank 为真），让 Quarkus 配置
    # 校验视为"存在"，而应用的 isPresent() 返回 false 从而回退到临时密钥，
    # 避免启动时报 SRCFG00014 required。
    # All keys are set as environment variables (not -D system properties) so they
    # pass through the Gradle fork into the app JVM:
    #   - QUARKUS_LANGCHAIN4J_OLLAMA_DEVSERVICES_ENABLED=false is required at build
    #     time: otherwise quarkus-langchain4j-ollama starts a Testcontainers Ollama
    #     container and downloads llama3.2 during quarkusDev, blocking startup.
    #   - QUARKUS_HTTP_PORT=8080 / NETWORK_SERVER_PORT=8081: REST (JAX-RS) on 8080,
    #     Vert.x WebSocket + /api proxy on 8081 (NetWorkHandler).
    #   - BACKEND_URL/BACKEND_PORT: the /api proxy target (the app's own REST server).
    #   - Datasource/Redis/Kafka/ES/JWT: with dev services and the RunDocker
    #     container auto-start disabled, these must come from the environment
    #     (SmallRye Config). DB is "cesi" on the local MySQL; Redis/Kafka/ES are
    #     the dev-compose services, used only when they are actually up.
    Set-Content -LiteralPath $RunnerPath -Encoding ASCII -Value @(
        "@echo off",
        "cd /d `"$QuarkusDir`"",
        "set QUARKUS_DEV_SERVICES_ENABLED=false",
        "set quarkus.dev-services.enabled=false",
        "set QUARKUS_LANGCHAIN4J_OLLAMA_DEVSERVICES_ENABLED=false",
        "set QUARKUS_HTTP_PORT=8080",
        "set NETWORK_SERVER_PORT=8081",
        "set BACKEND_URL=http://127.0.0.1",
        "set BACKEND_PORT=8080",
        "if not defined JWT_SECRET_KEY set `"JWT_SECRET_KEY=$JwtSecret`"",
        "set `"QUARKUS_DATASOURCE_JDBC_URL=jdbc:mysql://localhost:3306/cesi?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true`"",
        "set `"QUARKUS_DATASOURCE_USERNAME=$DbUser`"",
        "set `"QUARKUS_DATASOURCE_PASSWORD=$DbPassword`"",
        "set QUARKUS_REDIS_HOSTS=redis://localhost:6379",
        "set KAFKA_BOOTSTRAP_SERVERS=localhost:9092",
        "set QUARKUS_KAFKA_BOOTSTRAP_SERVERS=localhost:9092",
        "set ELASTICSEARCH_HOST=http://localhost:9200",
        "set `"JWT_ML_DSA_PRIVATE_KEY= `"",
        "set `"JWT_ML_DSA_PUBLIC_KEY= `"",
        "set `"JWT_ML_KEM_PRIVATE_KEY= `"",
        "set `"JWT_ML_KEM_PUBLIC_KEY= `"",
        "call `"$GradleCmd`" quarkusDev 1> `"$BackendLog`" 2> `"$BackendErrLog`"",
        "exit /b %ERRORLEVEL%"
    )
    return $true
}

function New-CloudRunner {
    param([string]$RunnerPath)
    if (-not (Test-Path -LiteralPath (Join-Path $CloudDir "pom.xml"))) { return $false }
    $MavenHome = Get-EnvValue "MAVEN_HOME"
    $MavenFallback = if ([string]::IsNullOrWhiteSpace($MavenHome)) { "" } else { Join-Path $MavenHome "bin\mvn.cmd" }
    $MvnCmd = Get-ExecutablePath -Configured (Get-EnvValue "MVN_CMD") -Candidates @("mvn.cmd", "mvn") -FallbackPath $MavenFallback -Name "Maven"
    $env:MVN_CMD = $MvnCmd
    Write-Log "Using Maven: $MvnCmd"
    $service = "finalassignmentcloud-gateway"
    Set-Content -LiteralPath $RunnerPath -Encoding ASCII -Value @(
        "@echo off",
        "cd /d `"$CloudDir`"",
        "call `"$MvnCmd`" -pl $service -am spring-boot:run -Dspring-boot.run.profiles=$BackendProfile 1> `"$BackendLog`" 2> `"$BackendErrLog`"",
        "exit /b %ERRORLEVEL%"
    )
    return $true
}

# ---- frontend launcher builders --------------------------------------------

function New-FlutterRunner {
    param([string]$RunnerPath, [string]$PubRunnerPath)
    $FlutterFallback = Join-Path (Get-EnvValue "USERPROFILE") "Flutter\flutter\bin\flutter.bat"
    $FlutterCmd = Get-ExecutablePath -Configured (Get-EnvValue "FLUTTER_CMD") -Candidates @("flutter.bat", "flutter") -FallbackPath $FlutterFallback -Name "Flutter"
    $env:FLUTTER_CMD = $FlutterCmd
    Write-Log "Using Flutter: $FlutterCmd"

    Set-Content -LiteralPath $PubRunnerPath -Encoding ASCII -Value @("@echo off", "cd /d `"$FlutterDir`"", "call `"$FlutterCmd`" pub get 1> `"$FlutterPubLog`" 2> `"$FlutterPubErrLog`"", "exit /b %ERRORLEVEL%")
    $pubProcess = Start-RunnerProcess -RunnerPath $PubRunnerPath -WorkingDirectory $FlutterDir
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
    $flutterCommand = "$flutterCommand 1> `"$FrontendLog`" 2> `"$FrontendErrLog`""
    Set-Content -LiteralPath $RunnerPath -Encoding ASCII -Value @("@echo off", "cd /d `"$FlutterDir`"", $flutterCommand, "exit /b %ERRORLEVEL%")
    return $true
}

function New-ReactRunner {
    param([string]$RunnerPath)
    $NpmCmd = Get-ExecutablePath -Configured (Get-EnvValue "NPM_CMD") -Candidates @("npm.cmd", "npm") -FallbackPath "" -Name "npm"
    $env:NPM_CMD = $NpmCmd
    Write-Log "Using npm: $NpmCmd"
    $runDev = "call `"$NpmCmd`" run dev -- --host 127.0.0.1 --port 5173 $ReactArgs"
    if (-not (Test-Path -LiteralPath (Join-Path $ReactDir "node_modules"))) {
        Write-Log "React node_modules not found. Running npm install..."
        Set-Content -LiteralPath $RunnerPath -Encoding ASCII -Value @(
            "@echo off",
            "cd /d `"$ReactDir`"",
            "call `"$NpmCmd`" install 1> `"$FrontendLog`" 2> `"$FrontendErrLog`"",
            "if errorlevel 1 exit /b %ERRORLEVEL%",
            ($runDev + " 1> `"$FrontendLog`" 2> `"$FrontendErrLog`""),
            "exit /b %ERRORLEVEL%"
        )
    } else {
        Set-Content -LiteralPath $RunnerPath -Encoding ASCII -Value @(
            "@echo off",
            "cd /d `"$ReactDir`"",
            ($runDev + " 1> `"$FrontendLog`" 2> `"$FrontendErrLog`""),
            "exit /b %ERRORLEVEL%"
        )
    }
    return $true
}

# ---- main flow --------------------------------------------------------------

Write-StartupSummary

try {
    switch ($BackendChoice) {
        "spring" {
            if (-not (Test-Path -LiteralPath (Join-Path $SpringDir "pom.xml"))) { Fail "Spring Boot project not found: $SpringDir" }
            $backendReady = New-SpringRunner -RunnerPath $BackendRunner
            break
        }
        "go" {
            if (-not (Test-Path -LiteralPath (Join-Path $GoDir "go.mod"))) { Fail "Go project not found: $GoDir" }
            $backendReady = New-GoRunner -RunnerPath $BackendRunner
            break
        }
        "quarkus" {
            if (-not (Test-Path -LiteralPath (Join-Path $QuarkusDir "build.gradle"))) { Fail "Quarkus project not found: $QuarkusDir" }
            $backendReady = New-QuarkusRunner -RunnerPath $BackendRunner
            break
        }
        "cloud" {
            $backendReady = New-CloudRunner -RunnerPath $BackendRunner
            if (-not $backendReady) { Fail "Spring Cloud project not found: $CloudDir" }
            break
        }
        "none" { $backendReady = $false; break }
        default { Fail "Unsupported backend: $BackendChoice" }
    }

    if ($FrontendChoice -eq "flutter") {
        if (-not (Test-Path -LiteralPath (Join-Path $FlutterDir "pubspec.yaml"))) { Fail "Flutter project not found: $FlutterDir" }
        $frontendReady = New-FlutterRunner -RunnerPath $FrontendRunner -PubRunnerPath $FlutterPubRunner
    } elseif ($FrontendChoice -eq "react") {
        if (-not (Test-Path -LiteralPath (Join-Path $ReactDir "package.json"))) { Fail "React project not found: $ReactDir" }
        $frontendReady = New-ReactRunner -RunnerPath $FrontendRunner
    } else {
        $frontendReady = $false
    }

    if ($StartLocalServices -ieq "true" -and ($backendReady -or $frontendReady)) {
        Write-Log "Starting local Docker/Ollama environment..."
        & (Join-Path $ScriptDir "start-env.bat")
        if ($LASTEXITCODE -ne 0) { Fail "Local Docker/Ollama environment startup failed." }
    } else {
        Write-Log "Skipping local Docker/Ollama environment because START_LOCAL_SERVICES=false."
    }

    # Backend health mapping per implementation
    $healthUrl = $BackendHealthUrl
    switch ($BackendChoice) {
        "go" {
            # Go Gin main app serves its health endpoint under /api/actuator/health.
            $healthUrl = "http://127.0.0.1:$BackendPort/api/actuator/health"
            break
        }
        "quarkus" {
            # Quarkus serves REST (JAX-RS) on 8080 and the Vert.x WebSocket + /api
            # proxy (NetWorkHandler) on 8081. There is no smallrye-health extension,
            # so use the public OpenAPI document as the readiness probe.
            $healthUrl = "http://127.0.0.1:8080/q/openapi"
            break
        }
        "cloud" {
            # Spring Cloud gateway exposes actuator health on its own port.
            $healthUrl = "http://127.0.0.1:8080/actuator/health"
            break
        }
    }

    # Working directory for the runner process. The generated .bat runner does
    # `cd /d` into the right directory itself, but the process's initial working
    # directory should still match the selected app (for any relative resolution
    # before the `cd` takes effect).
    $backendWorkDir = switch ($BackendChoice) {
        "spring" { $SpringDir }
        "go" { $GoDir }
        "quarkus" { $QuarkusDir }
        "cloud" { $CloudDir }
        default { $RootDir }
    }
    $frontendWorkDir = if ($FrontendChoice -eq "react") { $ReactDir } else { $FlutterDir }

    if ($backendReady) {
        Write-Log "Starting backend ($BackendChoice)..."
        $script:BackendProcess = Start-RunnerProcess -RunnerPath $BackendRunner -WorkingDirectory $backendWorkDir
        Write-Log "Backend PID: $($script:BackendProcess.Id)"
        Write-Log "Backend stdout: $BackendLog"
        Write-Log "Backend stderr: $BackendErrLog"

        Write-Log "Waiting $BackendWaitSeconds seconds before backend health polling..."
        Start-Sleep -Seconds $BackendWaitSeconds
        Write-Log "Waiting up to $BackendHealthWaitSeconds seconds for $healthUrl..."
        $deadline = (Get-Date).AddSeconds($BackendHealthWaitSeconds)
        $healthy = $false
        while ((Get-Date) -lt $deadline) {
            if (Invoke-HttpOk $healthUrl) {
                Write-Log "Backend ($BackendChoice) is healthy."
                $healthy = $true
                break
            }
            if ($script:BackendProcess.HasExited) {
                Fail "Backend ($BackendChoice) exited before becoming healthy. Exit code: $($script:BackendProcess.ExitCode)"
            }
            Start-Sleep -Seconds 2
        }
        if (-not $healthy) {
            Fail "Backend ($BackendChoice) did not become healthy within $BackendHealthWaitSeconds seconds at $healthUrl."
        }
    }

    if ($frontendReady) {
        Write-Log "Starting frontend ($FrontendChoice)..."
        $script:FrontendProcess = Start-RunnerProcess -RunnerPath $FrontendRunner -WorkingDirectory $frontendWorkDir
        Write-Log "Frontend PID: $($script:FrontendProcess.Id)"
        Write-Log "Frontend stdout: $FrontendLog"
        Write-Log "Frontend stderr: $FrontendErrLog"

        if ($FrontendChoice -eq "flutter" -and $FlutterDevice -ieq "web-server") {
            Write-Log "Waiting up to $FlutterWaitSeconds seconds for $FlutterWebUrl..."
            $flutterDeadline = (Get-Date).AddSeconds($FlutterWaitSeconds)
            $reachable = $false
            while ((Get-Date) -lt $flutterDeadline) {
                if (Invoke-HttpOk $FlutterWebUrl) {
                    Write-Log "Flutter web server is reachable: $FlutterWebUrl"
                    $reachable = $true
                    break
                }
                if ($script:FrontendProcess.HasExited) {
                    Fail "Frontend exited before the web server became reachable. Exit code: $($script:FrontendProcess.ExitCode)"
                }
                Start-Sleep -Seconds 2
            }
            if (-not $reachable) {
                Fail "Flutter web server did not become reachable within $FlutterWaitSeconds seconds."
            }
        } elseif ($FrontendChoice -eq "react") {
            Write-Log "Waiting up to $FlutterWaitSeconds seconds for $ReactDevUrl..."
            $reactDeadline = (Get-Date).AddSeconds($FlutterWaitSeconds)
            $reachable = $false
            while ((Get-Date) -lt $reactDeadline) {
                if (Invoke-HttpOk $ReactDevUrl) {
                    Write-Log "React dev server is reachable: $ReactDevUrl"
                    $reachable = $true
                    break
                }
                if ($script:FrontendProcess.HasExited) {
                    Fail "Frontend exited before the dev server became reachable. Exit code: $($script:FrontendProcess.ExitCode)"
                }
                Start-Sleep -Seconds 2
            }
            if (-not $reachable) {
                Fail "React dev server did not become reachable within $FlutterWaitSeconds seconds."
            }
        }
    }

    Write-Log "Startup flow completed. Press Ctrl-C to stop all started services. Logs are in $StartupLogDir"

    if ($backendReady -and $frontendReady) {
        while (-not $script:FrontendProcess.HasExited) {
            Start-Sleep -Seconds 1
            if ($script:BackendProcess.HasExited) {
                Fail "Backend ($BackendChoice) exited while frontend was still running. Exit code: $($script:BackendProcess.ExitCode)"
            }
        }
        $script:ExitCode = $script:FrontendProcess.ExitCode
    } elseif ($backendReady) {
        $script:BackendProcess.WaitForExit()
        $script:ExitCode = $script:BackendProcess.ExitCode
    } elseif ($frontendReady) {
        $script:FrontendProcess.WaitForExit()
        $script:ExitCode = $script:FrontendProcess.ExitCode
    }
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
