param(
    [ValidateSet("cloud", "go", "quarkus", "all")]
    [string]$Backend = "all",
    [string]$CloudUrl = $(if ($env:BASE_URL_CLOUD) { $env:BASE_URL_CLOUD } else { "http://127.0.0.1:8080" }),
    [string]$GoUrl = $(if ($env:BASE_URL_GO) { $env:BASE_URL_GO } else { "http://127.0.0.1:8080" }),
    [string]$QuarkusUrl = $(if ($env:BASE_URL_QUARKUS) { $env:BASE_URL_QUARKUS } else { "http://127.0.0.1:8080" }),
    [string]$Ramp = "30s",
    [string]$Hold = "2m",
    [string]$Down = "20s",
    [int]$DriverVus = 160,
    [int]$AdminVus = 120,
    [int]$SuperVus = 40,
    [int]$RagRate = 25,
    [int]$AgentRate = 6,
    [int]$WrkConnections = 128,
    [int]$WrkThreads = 8,
    [switch]$SkipWrk,
    [switch]$SkipAgent,
    [string]$DriverUsername = "ce@ce.com",
    [string]$DriverPassword = "123456",
    [string]$AdminUsername = "admin",
    [string]$AdminPassword = "Admin@123456",
    [string]$SuperUsername = "superadmin",
    [string]$SuperPassword = "SuperAdmin@123456"
)

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$K6Dir = Join-Path $Root "artifacts\k6"
$WrkDir = Join-Path $Root "artifacts\wrk"
New-Item -ItemType Directory -Force -Path $K6Dir, $WrkDir | Out-Null
Set-Location $Root

function Write-Step([string]$Message) {
    Write-Host ""
    Write-Host "==> $Message"
}

function Test-Health([string]$Url) {
    $paths = @(
        "/actuator/health/liveness",
        "/actuator/health",
        "/q/health/live",
        "/api/health"
    )
    foreach ($path in $paths) {
        try {
            Invoke-RestMethod -Uri "$Url$path" | Out-Null
            return $true
        } catch {
            continue
        }
    }
    return $false
}

function Get-AccessToken([string]$Url, [string]$Username, [string]$Password) {
    $payload = @{ username = $Username; password = $Password } | ConvertTo-Json -Compress
    $response = Invoke-RestMethod -Method Post -ContentType "application/json" -Body $payload -Uri "$Url/api/auth/login"
    return @{
        token = if ($response.accessToken) { $response.accessToken } elseif ($response.jwtToken) { $response.jwtToken } else { $response.token }
        driverId = $response.driverId
    }
}

function Invoke-K6High([string]$Name, [string]$Url) {
    Write-Step "k6 high concurrency: $Name @ $Url"
    if (-not (Test-Health $Url)) {
        Write-Warning "Skip $Name because $Url is not healthy"
        return
    }
    $envMap = @{
        BACKEND = $Name
        PERF_BACKEND = $Name
        BASE_URL = $Url
        PERF_RAMP = $Ramp
        PERF_HOLD = $Hold
        PERF_DOWN = $Down
        PERF_USER_VUS = "$DriverVus"
        PERF_ADMIN_VUS = "$AdminVus"
        PERF_SUPER_VUS = "$SuperVus"
        PERF_RAG_RATE = "$RagRate"
        PERF_AGENT_RATE = "$AgentRate"
        PERF_INCLUDE_AGENT = $(if ($SkipAgent) { "false" } else { "true" })
        PERF_USERNAME = $DriverUsername
        PERF_PASSWORD = $DriverPassword
        PERF_ADMIN_USERNAME = $AdminUsername
        PERF_ADMIN_PASSWORD = $AdminPassword
        PERF_SUPER_USERNAME = $SuperUsername
        PERF_SUPER_PASSWORD = $SuperPassword
        PERF_SUMMARY_JSON = "artifacts/k6/high-concurrency-$Name-summary.json"
    }
    foreach ($key in $envMap.Keys) {
        [Environment]::SetEnvironmentVariable($key, [string]$envMap[$key], "Process")
    }
    $outputPath = Join-Path $K6Dir "high-concurrency-$Name.txt"
    $old = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & k6 run "$Root\scripts\k6\high-concurrency-load.js" 2>&1 | Tee-Object -FilePath $outputPath
    $ErrorActionPreference = $old
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "k6 $Name exited with code $LASTEXITCODE. See $outputPath"
    }
}

function Invoke-WrkHigh([string]$Name, [string]$Url, [string]$Token) {
    if ($SkipWrk) { return }
    Write-Step "wrk high concurrency mix: $Name"
    $parsed = [Uri]$Url
    $port = $parsed.Port
    if ($port -le 0) { $port = 8080 }
    $wrkBase = "http://host.docker.internal:$port"
    $outputPath = Join-Path $WrkDir "high-concurrency-$Name.txt"
    $old = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & docker run --rm `
        -e "PERF_TOKEN=$Token" `
        -v "$Root\scripts\wrk:/scripts:ro" `
        williamyeh/wrk `
        "-t$WrkThreads" `
        "-c$WrkConnections" `
        "-d$Hold" `
        -s /scripts/read-mix.lua `
        $wrkBase 2>&1 | Tee-Object -FilePath $outputPath
    $ErrorActionPreference = $old
}

$targets = @()
if ($Backend -eq "all") {
    $targets = @(
        @{ Name = "cloud"; Url = $CloudUrl.TrimEnd("/") },
        @{ Name = "go"; Url = $GoUrl.TrimEnd("/") },
        @{ Name = "quarkus"; Url = $QuarkusUrl.TrimEnd("/") }
    )
} else {
    $url = switch ($Backend) {
        "cloud" { $CloudUrl }
        "go" { $GoUrl }
        "quarkus" { $QuarkusUrl }
    }
    $targets = @(@{ Name = $Backend; Url = $url.TrimEnd("/") })
}

foreach ($target in $targets) {
    Write-Step "High concurrency target $($target.Name) $($target.Url)"
    Invoke-K6High $target.Name $target.Url
    if (-not $SkipWrk -and (Test-Health $target.Url)) {
        try {
            $admin = Get-AccessToken $target.Url $AdminUsername $AdminPassword
            Invoke-WrkHigh $target.Name $target.Url $admin.token
        } catch {
            Write-Warning "Skip wrk for $($target.Name): $($_.Exception.Message)"
        }
    }
}

Write-Step "High concurrency finished"
Write-Host "k6 summaries: $K6Dir\high-concurrency-*-summary.json"
Write-Host "k6 logs:      $K6Dir\high-concurrency-*.txt"
