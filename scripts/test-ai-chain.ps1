param(
    [string]$FrontendBase = "http://127.0.0.1:3000",
    [string]$BackendBase = "http://127.0.0.1:8080",
    [string]$Origin = "http://127.0.0.1:3000",
    [int]$TimeoutSec = 25,
    [switch]$StrictProvider
)

$ErrorActionPreference = "Stop"

$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Detail = "",
        [bool]$Critical = $false
    )

    $script:results.Add([pscustomobject]@{
        name = $Name
        status = $Status
        critical = $Critical
        detail = $Detail
    }) | Out-Null
}

function Invoke-Checked {
    param(
        [string]$Name,
        [bool]$Critical,
        [scriptblock]$Check
    )

    try {
        $detail = & $Check
        Add-Result -Name $Name -Status "PASS" -Detail ([string]$detail) -Critical $Critical
    }
    catch {
        Add-Result -Name $Name -Status "FAIL" -Detail $_.Exception.Message -Critical $Critical
    }
}

function Invoke-JsonPost {
    param(
        [string]$Uri,
        [hashtable]$Body,
        [hashtable]$Headers = @{}
    )

    $json = $Body | ConvertTo-Json -Depth 8 -Compress
    return Invoke-WebRequest `
        -UseBasicParsing `
        -Method Post `
        -Uri $Uri `
        -Headers $Headers `
        -ContentType "application/json" `
        -Body $json `
        -TimeoutSec $TimeoutSec
}

function Test-Contains {
    param(
        [string]$Name,
        [string]$Content,
        [string[]]$Needles
    )

    foreach ($needle in $Needles) {
        if (-not $Content.Contains($needle)) {
            throw "$Name is missing expected marker: $needle"
        }
    }
}

$frontendRoot = $FrontendBase.TrimEnd("/")
$backendRoot = $BackendBase.TrimEnd("/")
$token = $null
$testUser = "ai-chain-$([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())@test.com"
$testPassword = "pass12345"
$aiContent = $null
$aiProvider = $null

Invoke-Checked -Name "Frontend root" -Critical $true -Check {
    $resp = Invoke-WebRequest -UseBasicParsing -Uri $frontendRoot -TimeoutSec 10
    if ($resp.StatusCode -ne 200) {
        throw "status $($resp.StatusCode)"
    }
    if ([string]::IsNullOrWhiteSpace($resp.Content) -or $resp.Content.Length -lt 100) {
        throw "empty or too small frontend HTML"
    }
    "status=200 bytes=$($resp.Content.Length)"
}

Invoke-Checked -Name "Frontend AI modules" -Critical $true -Check {
    $chatUri = "$frontendRoot/packages/final_assignment_front/features/dashboard/controllers/chat_controller.dart.lib.js"
    $apiUri = "$frontendRoot/packages/final_assignment_front/features/ai/ai_chat_api.dart.lib.js"
    $chat = Invoke-WebRequest -UseBasicParsing -Uri $chatUri -TimeoutSec 10
    $api = Invoke-WebRequest -UseBasicParsing -Uri $apiUri -TimeoutSec 10
    Test-Contains -Name "chat_controller" -Content $chat.Content -Needles @(
        "AI response timed out",
        "_removeThinkingMessages"
    )
    Test-Contains -Name "ai_chat_api" -Content $api.Content -Needles @(
        "client_factory",
        "text/event-stream",
        "Authorization"
    )
    "frontend AI code markers found"
}

try {
    $health = Invoke-WebRequest -UseBasicParsing -Uri "$backendRoot/actuator/health" -TimeoutSec 8
    Add-Result -Name "Backend health endpoint" -Status "PASS" -Detail "status=$($health.StatusCode)" -Critical $false
}
catch {
    $resp = $_.Exception.Response
    if ($resp -and [int]$resp.StatusCode -eq 503) {
        Add-Result -Name "Backend health endpoint" -Status "WARN" -Detail "actuator health is DOWN, usually because optional local dependencies are not healthy" -Critical $false
    }
    else {
        Add-Result -Name "Backend health endpoint" -Status "FAIL" -Detail $_.Exception.Message -Critical $true
    }
}

Invoke-Checked -Name "Ollama tags" -Critical $false -Check {
    $ollama = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:11434/api/tags" -TimeoutSec 8
    if ($ollama.StatusCode -ne 200) {
        throw "status $($ollama.StatusCode)"
    }
    if ($ollama.Content -notmatch "deepseek-for-my-bishe") {
        throw "expected local model not listed"
    }
    "local model listed"
}

Invoke-Checked -Name "AI CORS preflight" -Critical $true -Check {
    $headers = @{
        Origin = $Origin
        "Access-Control-Request-Method" = "POST"
        "Access-Control-Request-Headers" = "authorization,content-type,accept"
    }
    $resp = Invoke-WebRequest -UseBasicParsing -Method Options -Uri "$backendRoot/api/ai/chat/stream" -Headers $headers -TimeoutSec 10
    if ($resp.StatusCode -lt 200 -or $resp.StatusCode -ge 300) {
        throw "status $($resp.StatusCode)"
    }
    $allowOrigin = $resp.Headers["Access-Control-Allow-Origin"]
    if ($allowOrigin -ne $Origin) {
        throw "unexpected allow-origin: $allowOrigin"
    }
    "status=$($resp.StatusCode) allow-origin=$allowOrigin"
}

Invoke-Checked -Name "Register test user" -Critical $true -Check {
    $body = @{
        username = $testUser
        password = $testPassword
        role = "USER"
        idempotencyKey = [guid]::NewGuid().ToString()
    }
    $resp = Invoke-JsonPost -Uri "$backendRoot/api/auth/register" -Headers @{ Origin = $Origin } -Body $body
    if ($resp.StatusCode -lt 200 -or $resp.StatusCode -ge 300) {
        throw "status $($resp.StatusCode)"
    }
    "username=$testUser"
}

Invoke-Checked -Name "Login test user" -Critical $true -Check {
    $body = @{
        username = $testUser
        password = $testPassword
    }
    $resp = Invoke-JsonPost -Uri "$backendRoot/api/auth/login" -Headers @{ Origin = $Origin } -Body $body
    if ($resp.StatusCode -lt 200 -or $resp.StatusCode -ge 300) {
        throw "status $($resp.StatusCode)"
    }
    $data = $resp.Content | ConvertFrom-Json
    $script:token = $data.accessToken
    if ([string]::IsNullOrWhiteSpace($script:token)) {
        throw "login response has no accessToken"
    }
    "token received"
}

Invoke-Checked -Name "Current user profile" -Critical $true -Check {
    $headers = @{
        Origin = $Origin
        Authorization = "Bearer $script:token"
    }
    $resp = Invoke-WebRequest -UseBasicParsing -Method Get -Uri "$backendRoot/api/auth/me" -Headers $headers -TimeoutSec $TimeoutSec
    if ($resp.StatusCode -ne 200) {
        throw "status $($resp.StatusCode)"
    }
    $envelope = $resp.Content | ConvertFrom-Json
    if (-not $envelope.success -or $null -eq $envelope.data) {
        throw "unexpected profile envelope"
    }
    $profile = $envelope.data
    if ($profile.username -ne $testUser) {
        throw "unexpected username: $($profile.username)"
    }
    $roles = ""
    if ($profile.roles) {
        $roles = [string]::Join(",", $profile.roles)
    }
    "roles=$roles driverId=$($profile.driverId)"
}

Invoke-Checked -Name "AI SSE stream" -Critical $true -Check {
    $headers = @{
        Origin = $Origin
        Authorization = "Bearer $script:token"
        Accept = "text/event-stream"
    }
    $body = @{
        message = "hi"
        metadata = @{
            conversationWindow = @()
        }
    }
    $resp = Invoke-JsonPost -Uri "$backendRoot/api/ai/chat/stream" -Headers $headers -Body $body
    if ($resp.StatusCode -ne 200) {
        throw "status $($resp.StatusCode)"
    }
    $contentType = [string]$resp.Headers["Content-Type"]
    if ($contentType -notmatch "text/event-stream") {
        throw "unexpected content-type: $contentType"
    }
    $script:aiContent = $resp.Content
    Test-Contains -Name "AI stream" -Content $script:aiContent -Needles @(
        "event:token",
        "event:done"
    )
    if ($script:aiContent -match '"provider":"([^"]+)"') {
        $script:aiProvider = $Matches[1]
    }
    "content-type=$contentType provider=$script:aiProvider bytes=$($script:aiContent.Length)"
}

if ($aiProvider -eq "mock") {
    $status = "WARN"
    if ($StrictProvider) {
        $status = "FAIL"
    }
    Add-Result -Name "AI provider" -Status $status -Detail "backend is currently using mock provider; set AI_PROVIDER=ollama for real model testing" -Critical ([bool]$StrictProvider)
}
elseif ([string]::IsNullOrWhiteSpace($aiProvider)) {
    Add-Result -Name "AI provider" -Status "WARN" -Detail "provider was not found in stream payload" -Critical $false
}
else {
    Add-Result -Name "AI provider" -Status "PASS" -Detail "provider=$aiProvider" -Critical $false
}

$results | Format-Table -AutoSize

$criticalFailures = @($results | Where-Object { $_.critical -and $_.status -eq "FAIL" })
if ($criticalFailures.Count -gt 0) {
    Write-Host ""
    Write-Host "Critical failures: $($criticalFailures.Count)"
    exit 1
}

Write-Host ""
Write-Host "AI chain test completed without critical failures."
exit 0
