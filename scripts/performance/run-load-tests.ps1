param(
    [ValidateSet("spring", "cloud", "go", "quarkus")]
    [string]$Backend = "spring",
    [string]$BaseUrl = "",
    [string]$Duration = "20s",
    [int]$DriverVus = 8,
    [int]$AdminVus = 6,
    [int]$SuperVus = 2,
    [int]$LoginRate = 1,
    [int]$WrkThreads = 4,
    [int]$WrkDriverConnections = 32,
    [int]$WrkAdminConnections = 48,
    [int]$WrkSuperConnections = 32,
    [int]$WrkAiConnections = 8,
    [string]$DriverUsername = "ce@ce.com",
    [string]$DriverPassword = "123456",
    [string]$AdminUsername = "admin",
    [string]$AdminPassword = "Admin@123456",
    [string]$SuperUsername = "superadmin",
    [string]$SuperPassword = "SuperAdmin@123456",
    [switch]$IncludeModel
)

$ErrorActionPreference = "Stop"

# k6 and wrk emit UTF-8; without this Windows PowerShell decodes their CJK output as GBK
# and every captured Chinese summary line turns into mojibake.
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

if ([string]::IsNullOrWhiteSpace($BaseUrl)) {
    $BaseUrl = "http://127.0.0.1:8080"
}
$BaseUrl = $BaseUrl.TrimEnd("/")

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$K6Dir = Join-Path $Root "artifacts\k6"
$WrkDir = Join-Path $Root "artifacts\wrk"
$DockerConfigDir = Join-Path $Root "artifacts\docker-config"
$RagDatasetPath = Join-Path $Root "scripts\performance\rag-real-dataset.json"
New-Item -ItemType Directory -Force -Path $K6Dir, $WrkDir, $DockerConfigDir | Out-Null
[Environment]::SetEnvironmentVariable("DOCKER_CONFIG", $DockerConfigDir, "Process")
Set-Location $Root

function Write-Step([string]$Message) {
    Write-Host ""
    Write-Host "==> $Message"
}

function ConvertFrom-CodePoints([int[]]$CodePoints) {
    return -join ($CodePoints | ForEach-Object { [char]$_ })
}

function Get-HttpStatus($exception) {
    if ($exception.Response) { return [int]$exception.Response.StatusCode }
    return $null
}

function Get-AccessToken([string]$Username, [string]$Password) {
    $payload = @{ username = $Username; password = $Password } | ConvertTo-Json -Compress
    for ($attempt = 0; $attempt -lt 4; $attempt++) {
        try {
            $response = Invoke-RestMethod -Method Post -ContentType "application/json" -Body $payload -Uri "$BaseUrl/api/auth/login"
            return @{
                token = if ($response.accessToken) { $response.accessToken } else { $response.jwtToken }
                driverId = $response.driverId
            }
        } catch {
            $status = Get-HttpStatus $_.Exception
            if ($status -ne 429 -or $attempt -ge 3) { throw }
            $retryAfter = 30
            $header = $_.Exception.Response.Headers["Retry-After"]
            $parsed = 0
            if ($header -and [int]::TryParse([string]$header, [ref]$parsed) -and $parsed -gt 0) {
                $retryAfter = $parsed
            }
            $wait = [Math]::Min([Math]::Max($retryAfter, 1), 130)
            Write-Warning "Login for $Username is rate limited; retrying in $wait seconds"
            Start-Sleep -Seconds $wait
        }
    }
}

function Invoke-K6([string]$Name, [string]$ScriptPath, [hashtable]$Env) {
    Write-Step "k6: $Name"
    foreach ($key in $Env.Keys) {
        [Environment]::SetEnvironmentVariable($key, [string]$Env[$key], "Process")
    }
    $outputPath = Join-Path $K6Dir "$Name.txt"
    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & k6 run $ScriptPath 2>&1 | Tee-Object -FilePath $outputPath
    $ErrorActionPreference = $oldErrorActionPreference
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "k6 scenario $Name exited with code $LASTEXITCODE. See $outputPath"
    }
}

function Invoke-Wrk([string]$Name, [string]$LuaScript, [string]$Url, [int]$Connections, [hashtable]$Env) {
    Write-Step "wrk: $Name"
    $outputPath = Join-Path $WrkDir "$Name.txt"
    $args = @("run", "--rm")
    foreach ($key in $Env.Keys) {
        $args += @("-e", "$key=$($Env[$key])")
    }
    $args += @(
        "-v", "$Root\scripts\wrk:/scripts:ro",
        "williamyeh/wrk",
        "-t$WrkThreads",
        "-c$Connections",
        "-d$Duration",
        "-s", "/scripts/$LuaScript",
        $Url
    )
    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & docker @args 2>&1 | Tee-Object -FilePath $outputPath
    $ErrorActionPreference = $oldErrorActionPreference
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "wrk scenario $Name exited with code $LASTEXITCODE. See $outputPath"
    }
}

function Write-MemorySnapshot([string]$Label) {
    try {
        $samples = Get-Counter -Counter "\Memory\Available MBytes", "\Memory\Committed Bytes", "\Memory\Commit Limit" -ErrorAction Stop | Select-Object -ExpandProperty CounterSamples
        $parts = foreach ($sample in $samples) {
            switch -Wildcard ($sample.Path) {
                '*available mbytes*' { "available_mb={0:N0}" -f $sample.CookedValue }
                '*committed bytes*' { "committed_mb={0:N0}" -f ($sample.CookedValue / 1MB) }
                '*commit limit*' { "commit_limit_mb={0:N0}" -f ($sample.CookedValue / 1MB) }
            }
        }
        Write-Host ("memory[{0}] {1}" -f $Label, ($parts -join " "))
    } catch {
        Write-Warning "Memory snapshot unavailable: $($_.Exception.Message)"
    }
}

function Invoke-AiWarmup([string]$Token, [string]$Message) {
    $headers = @{ Authorization = "Bearer $Token" }
    # Mirror the k6 model stage: ragEnabled must live inside metadata for every backend,
    # and pure generation is what the model stage actually measures.
    $payload = @{ message = $Message; metadata = @{ ragEnabled = $false; webSearch = $false } } | ConvertTo-Json -Depth 3 -Compress
    $body = [System.Text.Encoding]::UTF8.GetBytes($payload)
    for ($attempt = 1; $attempt -le 2; $attempt++) {
        $watch = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $response = Invoke-WebRequest -Method Post -Uri "$BaseUrl/api/ai/chat/stream" `
                -Headers $headers -ContentType "application/json; charset=utf-8" -Body $body `
                -UseBasicParsing -TimeoutSec 300
            # A tool result event is not proof that the model answered; only a token event is.
            $hasToken = $response.Content -match '"type"\s*:\s*"token"'
            Write-Host ("AI model warm-up attempt {0} finished in {1:N0} ms (stream bytes={2}, token={3})" -f $attempt, $watch.ElapsedMilliseconds, $response.RawContentLength, $hasToken)
            if ($hasToken) { return }
        } catch {
            Write-Warning ("AI model warm-up attempt {0} failed after {1:N0} ms: {2}" -f $attempt, $watch.ElapsedMilliseconds, $_.Exception.Message)
        }
    }
    Write-Warning "AI model warm-up produced no token event; the model stage may time out."
}

function Test-Health([string]$Url) {
    $paths = @(
        "/actuator/health/liveness",
        "/actuator/health",
        "/q/health/live",
        "/api/health",
        "/api/actuator/health",
        "/readyz"
    )
    foreach ($path in $paths) {
        try {
            Invoke-RestMethod -Uri "$Url$path" | Out-Null
            return
        } catch {
            continue
        }
    }
    throw "Backend health check failed at $Url"
}

Write-Step "Check backend health ($Backend $BaseUrl)"
Test-Health $BaseUrl
Write-MemorySnapshot "start"

$ragDataset = Get-Content -LiteralPath $RagDatasetPath -Raw -Encoding UTF8 | ConvertFrom-Json
$ragQuery = [string]$ragDataset.query
if ([string]::IsNullOrWhiteSpace($ragQuery)) {
    $ragQuery = ConvertFrom-CodePoints @(0x9a7e,0x9a76,0x5458,0x4ea4,0x901a,0x8fdd,0x6cd5,0x7533,0x8bc9,0x6750,0x6599,0x3001,0x7f5a,0x6b3e,0x7f34,0x7eb3,0x3001,0x4e8b,0x6545,0x5feb,0x5904,0x548c,0x8f66,0x8f86,0x767b,0x8bb0,0x529e,0x7406,0x6307,0x5357)
}
$aiActionMessage = ConvertFrom-CodePoints @(0x5e2e,0x6211,0x6253,0x5f00,0x4ea4,0x901a,0x8fdd,0x6cd5,0x7533,0x8bc9,0x529e,0x7406,0x9875,0x9762,0xff0c,0x5e76,0x8bf4,0x660e,0x4e0b,0x4e00,0x6b65,0x9700,0x8981,0x586b,0x5199,0x4ec0,0x4e48)
$aiModelMessage = ConvertFrom-CodePoints @(0x8bf7,0x7528,0x4e09,0x53e5,0x8bdd,0x8bf4,0x660e,0x8d85,0x901f,0x3001,0x75b2,0x52b3,0x9a7e,0x9a76,0x548c,0x5360,0x7528,0x5e94,0x6025,0x8f66,0x9053,0x7684,0x5904,0x7f5a,0x6807,0x51c6)

Write-Step "Fetch load-test account tokens"
$driver = Get-AccessToken $DriverUsername $DriverPassword
$admin = Get-AccessToken $AdminUsername $AdminPassword
$super = Get-AccessToken $SuperUsername $SuperPassword
$driverId = if ($driver.driverId) { $driver.driverId } else { "6" }

Write-Step "Seed real RAG retrieval dataset"
try {
    & "$Root\scripts\performance\seed-rag-load-dataset.ps1" `
        -BaseUrl $BaseUrl `
        -Token $super.token `
        -DatasetPath $RagDatasetPath
} catch {
    Write-Error "RAG 压测数据集预热失败。请确认后端已启用 RAG 检索，例如以 RAG_RETRIEVAL_ENABLED=true 启动；原始错误：$($_.Exception.Message)"
    throw
}

Invoke-K6 "full-api-load" "$Root\scripts\k6\full-api-load.js" @{
    BASE_URL = $BaseUrl
    PERF_DURATION = $Duration
    PERF_USER_VUS = $DriverVus
    PERF_ADMIN_VUS = $AdminVus
    PERF_SUPER_VUS = $SuperVus
    PERF_LOGIN_RATE = $LoginRate
    PERF_USERNAME = $DriverUsername
    PERF_PASSWORD = $DriverPassword
    PERF_REGISTER_USER = "false"
    PERF_ADMIN_USERNAME = $AdminUsername
    PERF_ADMIN_PASSWORD = $AdminPassword
    PERF_SUPER_USERNAME = $SuperUsername
    PERF_SUPER_PASSWORD = $SuperPassword
    PERF_INCLUDE_AI = "false"
    BACKEND = $Backend
    PERF_BACKEND = $Backend
    PERF_SUMMARY_JSON = "artifacts/k6/full-api-load-summary.json"
}
Write-MemorySnapshot "after-k6-full-api"

$wrkPort = ([Uri]$BaseUrl).Port
if ($wrkPort -le 0) { $wrkPort = 8080 }
$wrkBase = "http://host.docker.internal:$wrkPort"

Invoke-Wrk "driver-read-mix" "driver-read-mix.lua" $wrkBase $WrkDriverConnections @{
    PERF_TOKEN = $driver.token
    PERF_DRIVER_ID = $driverId
}

Invoke-Wrk "admin-read-mix" "read-mix.lua" $wrkBase $WrkAdminConnections @{
    PERF_TOKEN = $admin.token
}

Invoke-Wrk "super-read-mix" "super-read-mix.lua" $wrkBase $WrkSuperConnections @{
    PERF_TOKEN = $super.token
}

Invoke-Wrk "rag-query" "rag-query.lua" "$wrkBase/api/rag/query" $WrkAiConnections @{
    PERF_TOKEN = $admin.token
    PERF_QUERY = $ragQuery
}

Invoke-Wrk "rag-admin-preview" "rag-admin-preview.lua" "$wrkBase/api/rag/admin/preview" $WrkAiConnections @{
    PERF_TOKEN = $super.token
    PERF_QUERY = $ragQuery
}

Invoke-Wrk "ai-actions" "ai-actions.lua" $wrkBase $WrkAiConnections @{
    PERF_TOKEN = $admin.token
    PERF_MESSAGE = $aiActionMessage
}

# The AI stage makes real model calls and is the only stage that can push a single-host
# Ollama setup into VRAM or commit exhaustion. Run it after the HTTP suites, once the
# model is warm, so a capacity failure there cannot invalidate the read/write results.
Write-MemorySnapshot "before-ai"
Test-Health $BaseUrl
Invoke-AiWarmup $admin.token $aiModelMessage
Write-MemorySnapshot "after-warmup"

Invoke-K6 "ai-rag-staged-load" "$Root\scripts\k6\ai-rag-staged-load.js" @{
    BASE_URL = $BaseUrl
    PERF_DURATION = $Duration
    PERF_ADMIN_USERNAME = $AdminUsername
    PERF_ADMIN_PASSWORD = $AdminPassword
    PERF_SUPER_USERNAME = $SuperUsername
    PERF_SUPER_PASSWORD = $SuperPassword
    PERF_USERNAME = $DriverUsername
    PERF_PASSWORD = $DriverPassword
    PERF_AI_ACTION_RATE = "1"
    PERF_RAG_RATE = "1"
    PERF_INCLUDE_MODEL = if ($IncludeModel) { "true" } else { "false" }
    PERF_INCLUDE_AGENT = "true"
    PERF_MODEL_RATE = "1"
    BACKEND = $Backend
    PERF_BACKEND = $Backend
    PERF_RAG_QUERY = $ragQuery
    PERF_ACTION_MESSAGE = $aiActionMessage
    PERF_MODEL_MESSAGE = $aiModelMessage
    PERF_STRICT = "true"
    PERF_SUMMARY_JSON = "artifacts/k6/ai-rag-staged-load-summary.json"
}
Write-MemorySnapshot "after-ai"

# Fail loudly instead of reporting a clean login stage against a stack that died.
Test-Health $BaseUrl

# Run login pressure last so the login rate-limit window does not affect token fetching or read tests.
Invoke-Wrk "login" "login.lua" "$wrkBase/api/auth/login" 16 @{
    PERF_USERNAME = $AdminUsername
    PERF_PASSWORD = $AdminPassword
}

Write-Step "Load tests finished"
Write-Host "k6 output: $K6Dir"
Write-Host "wrk output: $WrkDir"
