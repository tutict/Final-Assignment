param(
    [switch]$Wait,
    [switch]$SkipBuild,
    [switch]$IncludeAi,
    [string]$LogDir = "",
    [string]$Profile = "dev",
    [int]$GatewayPort = 0
)

$ErrorActionPreference = "Stop"
$RootDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$CloudDir = Join-Path $RootDir "finalAssignmentCloud"
$Script:ExitCode = 0
$Script:Processes = @()
$Script:CleanupStarted = $false

if (-not (Test-Path -LiteralPath (Join-Path $CloudDir "pom.xml"))) {
    throw "Spring Cloud project not found: $CloudDir"
}

function Get-EnvOrDefault([string]$Name, [string]$Default) {
    $value = [Environment]::GetEnvironmentVariable($Name, "Process")
    if ([string]::IsNullOrWhiteSpace($value)) { return $Default }
    return $value
}

function Set-EnvDefault([string]$Name, [string]$Default) {
    $value = Get-EnvOrDefault $Name $Default
    [Environment]::SetEnvironmentVariable($Name, $value, "Process")
    return $value
}

function Write-CloudLog([string]$Message) {
    $line = "[{0}] {1}" -f (Get-Date -Format "HH:mm:ss.fff"), $Message
    Write-Host $line
}

function Convert-ToBase64([string]$Text) {
    return [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Text))
}

function Test-HttpOk([string]$Url) {
    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 3
        return [int]$response.StatusCode -ge 200 -and [int]$response.StatusCode -lt 500
    } catch {
        return $false
    }
}

function Test-PortListening([int]$Port) {
    try {
        if (@(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue).Count -gt 0) { return $true }
    } catch {}
    return $false
}

function Stop-CloudTree([int]$ProcessId, [string]$Name) {
    if ($ProcessId -le 0) { return }
    try {
        $children = @(Get-CimInstance Win32_Process -Filter "ParentProcessId=$ProcessId" -ErrorAction SilentlyContinue)
        foreach ($child in $children) {
            Stop-CloudTree -ProcessId ([int]$child.ProcessId) -Name "$Name child"
        }
    } catch {}
    try { Stop-Process -Id $ProcessId -Force -ErrorAction SilentlyContinue } catch {}
}

function Stop-CloudStack {
    if ($Script:CleanupStarted) { return }
    $Script:CleanupStarted = $true
    Write-CloudLog "Stopping Cloud services..."
    foreach ($entry in @($Script:Processes | Sort-Object { if ($_.Last) { 0 } else { 1 } })) {
        Stop-CloudTree -ProcessId $entry.Process.Id -Name $entry.Name
    }
}

if ([string]::IsNullOrWhiteSpace($LogDir)) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $LogDir = Join-Path $RootDir "artifacts\startup\cloud-$stamp"
}
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$JwtSecret = Set-EnvDefault "JWT_SECRET" "dev-jwt-secret-key-for-local-startup-please-change-1234567890"
$existingJwtKey = Get-EnvOrDefault "JWT_SECRET_KEY" ""
if ([string]::IsNullOrWhiteSpace($existingJwtKey)) {
    # Cloud TokenProvider Base64-decodes jwt.secret.key. Encode the shared local secret once.
    try {
        [Convert]::FromBase64String($JwtSecret) | Out-Null
        $jwtKey = $JwtSecret
    } catch {
        $jwtKey = Convert-ToBase64 $JwtSecret
    }
    [Environment]::SetEnvironmentVariable("JWT_SECRET_KEY", $jwtKey, "Process")
}

Set-EnvDefault "INTERNAL_SERVICE_TOKEN" "dev-internal-service-token-32bytes-ok" | Out-Null
Set-EnvDefault "SPRING_PROFILES_ACTIVE" $Profile | Out-Null
Set-EnvDefault "SPRING_DATASOURCE_URL" "jdbc:mysql://localhost:3306/traffic?useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true" | Out-Null
Set-EnvDefault "SPRING_DATASOURCE_USERNAME" "root" | Out-Null
Set-EnvDefault "SPRING_DATASOURCE_PASSWORD" "root" | Out-Null
Set-EnvDefault "SPRING_DATASOURCE_DRIVER_CLASS_NAME" "com.mysql.cj.jdbc.Driver" | Out-Null
Set-EnvDefault "AUTH_DB_URL" $env:SPRING_DATASOURCE_URL | Out-Null
Set-EnvDefault "AUTH_DB_USERNAME" $env:SPRING_DATASOURCE_USERNAME | Out-Null
Set-EnvDefault "AUTH_DB_PASSWORD" $env:SPRING_DATASOURCE_PASSWORD | Out-Null
Set-EnvDefault "RAG_DB_URL" $env:SPRING_DATASOURCE_URL | Out-Null
Set-EnvDefault "RAG_DB_USERNAME" $env:SPRING_DATASOURCE_USERNAME | Out-Null
Set-EnvDefault "RAG_DB_PASSWORD" $env:SPRING_DATASOURCE_PASSWORD | Out-Null
Set-EnvDefault "SPRING_DATA_REDIS_HOST" "localhost" | Out-Null
Set-EnvDefault "SPRING_DATA_REDIS_PORT" "6379" | Out-Null
Set-EnvDefault "SPRING_KAFKA_LISTENER_AUTO_STARTUP" "false" | Out-Null
Set-EnvDefault "SPRING_KAFKA_BOOTSTRAP_SERVERS" "localhost:9092" | Out-Null
Set-EnvDefault "MANAGEMENT_HEALTH_ELASTICSEARCH_ENABLED" "false" | Out-Null
Set-EnvDefault "SPRING_DATA_ELASTICSEARCH_SKIP_REPOSITORY_INIT" "false" | Out-Null
Set-EnvDefault "RAG_RETRIEVAL_ENABLED" "true" | Out-Null
Set-EnvDefault "RAG_ENABLED" "true" | Out-Null
Set-EnvDefault "RAG_SQL_INIT_MODE" "always" | Out-Null
Set-EnvDefault "RAG_EMBEDDING_ENABLED" "false" | Out-Null
Set-EnvDefault "RAG_INDEXING_ENABLED" "false" | Out-Null
Set-EnvDefault "RAG_BACKFILL_ENABLED" "false" | Out-Null
Set-EnvDefault "OLLAMA_ENABLED" "false" | Out-Null
Set-EnvDefault "ELASTICSEARCH_URIS" "http://localhost:9200" | Out-Null
Set-EnvDefault "OLLAMA_MODEL" "llama3.2" | Out-Null
Set-EnvDefault "OLLAMA_CHAT_MODEL" "llama3.2" | Out-Null
Set-EnvDefault "SPRING_AI_OLLAMA_CHAT_OPTIONS_MODEL" "llama3.2" | Out-Null
Set-EnvDefault "SPRING_AI_OLLAMA_EMBEDDING_OPTIONS_MODEL" "nomic-embed-text" | Out-Null
Set-EnvDefault "AI_AGENT_DRAFT_STORE" "memory" | Out-Null
Set-EnvDefault "NACOS_SERVER" "localhost:8848" | Out-Null
Set-EnvDefault "CLOUD_NACOS_DISCOVERY" "false" | Out-Null
Set-EnvDefault "CLOUD_AUTH_PORT" "8081" | Out-Null
Set-EnvDefault "CLOUD_USER_PORT" "18082" | Out-Null
Set-EnvDefault "CLOUD_TRAFFIC_PORT" "18083" | Out-Null
Set-EnvDefault "CLOUD_AUDIT_PORT" "8084" | Out-Null
Set-EnvDefault "CLOUD_SYSTEM_PORT" "8085" | Out-Null
Set-EnvDefault "CLOUD_AI_PORT" "8086" | Out-Null
Set-EnvDefault "CLOUD_SEARCH_PORT" "8087" | Out-Null
Set-EnvDefault "CLOUD_RAG_PORT" "8088" | Out-Null
if ($GatewayPort -gt 0) {
    [Environment]::SetEnvironmentVariable("CLOUD_GATEWAY_PORT", [string]$GatewayPort, "Process")
} else {
    Set-EnvDefault "CLOUD_GATEWAY_PORT" "8080" | Out-Null
}

$localDevConfig = Join-Path $CloudDir "config\local-dev.yml"
[Environment]::SetEnvironmentVariable("SPRING_CONFIG_ADDITIONAL_LOCATION", "optional:file:$localDevConfig", "Process")

$UseNacos = (Get-EnvOrDefault "CLOUD_USE_NACOS" "false").ToLowerInvariant() -in @("1", "true", "yes")
if ($UseNacos) {
    $docker = Get-Command docker -ErrorAction SilentlyContinue
    if ($docker) {
        Write-CloudLog "Starting Nacos from finalAssignmentCloud/compose.yaml"
        $composeFile = Join-Path $CloudDir "compose.yaml"
        $previous = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        & $docker.Source compose -f $composeFile up -d finalassignmentcloud-nacos
        $nacosExit = $LASTEXITCODE
        $ErrorActionPreference = $previous
        if ($nacosExit -eq 0) {
            $nacosDeadline = (Get-Date).AddSeconds(90)
            $nacosReady = $false
            while ((Get-Date) -lt $nacosDeadline) {
                if (Test-HttpOk "http://127.0.0.1:8848/nacos/") { $nacosReady = $true; break }
                Start-Sleep -Seconds 2
            }
            if ($nacosReady) {
                [Environment]::SetEnvironmentVariable("CLOUD_NACOS_DISCOVERY", "true", "Process")
                Write-CloudLog "Nacos is reachable at localhost:8848"
            } else {
                Write-CloudLog "Nacos did not become reachable; falling back to static discovery"
            }
        } else {
            Write-CloudLog "Nacos compose start failed (exit $nacosExit); using static discovery"
        }
    } else {
        Write-CloudLog "docker not found; using static discovery"
    }
}

$modules = @(
    @{ Name = "finalassignmentcloud-user"; Port = [int]$env:CLOUD_USER_PORT; Critical = $true; Optional = $false; Last = $false; Xmx = "384m" },
    @{ Name = "finalassignmentcloud-auth"; Port = [int]$env:CLOUD_AUTH_PORT; Critical = $true; Optional = $false; Last = $false; Xmx = "384m" },
    @{ Name = "finalassignmentcloud-traffic"; Port = [int]$env:CLOUD_TRAFFIC_PORT; Critical = $true; Optional = $false; Last = $false; Xmx = "384m" },
    @{ Name = "finalassignmentcloud-audit"; Port = [int]$env:CLOUD_AUDIT_PORT; Critical = $false; Optional = $false; Last = $false; Xmx = "256m" },
    @{ Name = "finalassignmentcloud-system"; Port = [int]$env:CLOUD_SYSTEM_PORT; Critical = $false; Optional = $false; Last = $false; Xmx = "256m" },
    @{ Name = "finalassignmentcloud-search"; Port = [int]$env:CLOUD_SEARCH_PORT; Critical = $false; Optional = $false; Last = $false; Xmx = "256m" },
    @{ Name = "finalassignmentcloud-rag"; Port = [int]$env:CLOUD_RAG_PORT; Critical = $true; Optional = $false; Last = $false; Xmx = "768m" },
    @{ Name = "finalassignmentcloud-ai"; Port = [int]$env:CLOUD_AI_PORT; Critical = $false; Optional = $true; Last = $false; Xmx = "768m" },
    @{ Name = "finalassignmentcloud-gateway"; Port = [int]$env:CLOUD_GATEWAY_PORT; Critical = $true; Optional = $false; Last = $true; Xmx = "256m" }
)

$includeAiEnv = (Get-EnvOrDefault "CLOUD_INCLUDE_AI" "false").ToLowerInvariant() -in @("1", "true", "yes")
if ($IncludeAi) { $includeAiEnv = $true }

$MvnCmd = Get-EnvOrDefault "MVN_CMD" ""
if ([string]::IsNullOrWhiteSpace($MvnCmd)) {
    $mvn = Get-Command mvn.cmd -ErrorAction SilentlyContinue
    if (-not $mvn) { $mvn = Get-Command mvn -ErrorAction SilentlyContinue }
    if (-not $mvn) { throw "Maven not found. Set MVN_CMD." }
    $MvnCmd = $mvn.Source
}
$JavaCmd = Get-EnvOrDefault "JAVA_CMD" ""
if ([string]::IsNullOrWhiteSpace($JavaCmd)) {
    $java = Get-Command java -ErrorAction SilentlyContinue
    if (-not $java) { throw "Java not found. Set JAVA_CMD." }
    $JavaCmd = $java.Source
}

$skipBuildEnv = (Get-EnvOrDefault "CLOUD_SKIP_BUILD" "false").ToLowerInvariant() -in @("1", "true", "yes")
if ($SkipBuild) { $skipBuildEnv = $true }

try {
    if (-not $skipBuildEnv) {
        Write-CloudLog "Packaging Cloud modules (skip tests)..."
        $packageLog = Join-Path $LogDir "mvn-package.log"
        $packageArgs = @("-f", (Join-Path $CloudDir "pom.xml"), "-DskipTests", "package")
        $old = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        & $MvnCmd @packageArgs 1> $packageLog 2>&1
        $packageExit = $LASTEXITCODE
        $ErrorActionPreference = $old
        if ($packageExit -ne 0) {
            throw "Cloud Maven package failed with exit code $packageExit. See $packageLog"
        }
        Write-CloudLog "Cloud modules packaged."
        if ($includeAiEnv) {
            Write-CloudLog "Packaging optional AI module..."
            $aiLog = Join-Path $LogDir "mvn-package-ai.log"
            $ErrorActionPreference = "Continue"
            & $MvnCmd -f (Join-Path $CloudDir "pom.xml") -pl finalassignmentcloud-ai -am -DskipTests package 1> $aiLog 2>&1
            $aiExit = $LASTEXITCODE
            $ErrorActionPreference = $old
            if ($aiExit -ne 0) {
                Write-CloudLog "AI module package failed (exit $aiExit); continuing without it. See $aiLog"
                $includeAiEnv = $false
            }
        }
    }

    function Get-CloudJar([string]$Module) {
        $target = Join-Path $CloudDir "$Module\target"
        if (-not (Test-Path -LiteralPath $target)) { return $null }
        $jars = @(Get-ChildItem -LiteralPath $target -Filter "$Module-*.jar" | Where-Object {
            $_.Name -notmatch '(original|sources|javadoc|tests)'
        } | Sort-Object LastWriteTime -Descending)
        if ($jars.Count -eq 0) { return $null }
        return $jars[0].FullName
    }

    $toStart = New-Object System.Collections.Generic.List[object]
    foreach ($module in $modules) {
        if ($module.Optional -and -not $includeAiEnv) { continue }
        $jar = Get-CloudJar $module.Name
        if (-not $jar) {
            if ($module.Optional -or -not $module.Critical) {
                Write-CloudLog "Skipping $($module.Name); jar not found"
                continue
            }
            throw "Missing executable jar for $($module.Name)"
        }
        $clone = $module.Clone()
        $clone.Jar = $jar
        [void]$toStart.Add($clone)
    }

    $firstWave = @($toStart | Where-Object { -not $_.Last })
    $lastWave = @($toStart | Where-Object { $_.Last })

    function Start-CloudModule($module) {
        $stdout = Join-Path $LogDir "$($module.Name).log"
        $stderr = Join-Path $LogDir "$($module.Name).err.log"
        $javaOpts = Get-EnvOrDefault "CLOUD_JAVA_OPTS" ""
        $args = @()
        if (-not [string]::IsNullOrWhiteSpace($javaOpts)) {
            $args += ($javaOpts -split '\s+' | Where-Object { $_ })
        }
        $args += @("-Xms128m", "-Xmx$($module.Xmx)", "-jar", $module.Jar, "--spring.profiles.active=$Profile", "--server.port=$($module.Port)")
        Write-CloudLog "Starting $($module.Name) on $($module.Port)"
        $proc = Start-Process -FilePath $JavaCmd -ArgumentList $args -WorkingDirectory $CloudDir -RedirectStandardOutput $stdout -RedirectStandardError $stderr -WindowStyle Hidden -PassThru
        $Script:Processes += [pscustomobject]@{ Name = $module.Name; Process = $proc; Port = $module.Port; Critical = $module.Critical; Last = $module.Last; Log = $stdout; ErrLog = $stderr }
        return $proc
    }

    foreach ($module in $firstWave) { Start-CloudModule $module | Out-Null }

    $pidFile = Join-Path $LogDir "cloud-pids.txt"
    function Write-PidFile {
        $lines = @($Script:Processes | ForEach-Object { "{0}={1}" -f $_.Name, $_.Process.Id })
        Set-Content -LiteralPath $pidFile -Encoding ASCII -Value $lines
    }
    Write-PidFile

    function Wait-CloudHealth($module, [int]$Seconds) {
        $url = "http://127.0.0.1:$($module.Port)/actuator/health"
        $deadline = (Get-Date).AddSeconds($Seconds)
        while ((Get-Date) -lt $deadline) {
            $entry = @($Script:Processes | Where-Object { $_.Name -eq $module.Name } | Select-Object -First 1)
            if ($entry -and $entry.Process.HasExited) {
                return "exited:$($entry.Process.ExitCode)"
            }
            if (Test-HttpOk $url) { return "ok" }
            Start-Sleep -Seconds 2
        }
        return "timeout"
    }

    $healthWait = [int](Get-EnvOrDefault "CLOUD_SERVICE_HEALTH_WAIT_SECONDS" "180")
    foreach ($module in $firstWave) {
        $result = Wait-CloudHealth $module $healthWait
        if ($result -eq "ok") {
            Write-CloudLog "$($module.Name) healthy on $($module.Port)"
        } elseif ($module.Critical) {
            throw "$($module.Name) failed health check ($result). See $(Join-Path $LogDir "$($module.Name).log")"
        } else {
            Write-CloudLog "$($module.Name) not healthy ($result); continuing"
        }
    }

    foreach ($module in $lastWave) { Start-CloudModule $module | Out-Null }
    Write-PidFile

    $gatewayWait = [int](Get-EnvOrDefault "CLOUD_GATEWAY_HEALTH_WAIT_SECONDS" "180")
    foreach ($module in $lastWave) {
        $result = Wait-CloudHealth $module $gatewayWait
        if ($result -eq "ok") {
            Write-CloudLog "$($module.Name) healthy on $($module.Port)"
        } else {
            throw "$($module.Name) failed health check ($result). See $(Join-Path $LogDir "$($module.Name).log")"
        }
    }

    $gatewayUrl = "http://127.0.0.1:$($env:CLOUD_GATEWAY_PORT)"
    Write-CloudLog "Cloud stack is up. Gateway: $gatewayUrl"
    Write-CloudLog "Logs: $LogDir"

    if ($Wait) {
        Write-CloudLog "Waiting until stopped. Press Ctrl-C to shut down Cloud services."
        while ($true) {
            $dead = @($Script:Processes | Where-Object { $_.Critical -and $_.Process.HasExited })
            if ($dead.Count -gt 0) {
                $names = ($dead | ForEach-Object { "{0}(exit {1})" -f $_.Name, $_.Process.ExitCode }) -join ", "
                throw "Critical Cloud process exited: $names"
            }
            Start-Sleep -Seconds 2
        }
    }
} catch {
    $Script:ExitCode = 1
    Write-CloudLog ("[ERROR] " + $_.Exception.Message)
    throw
} finally {
    if ($Wait -or $Script:ExitCode -ne 0) {
        Stop-CloudStack
    }
}

exit $Script:ExitCode
