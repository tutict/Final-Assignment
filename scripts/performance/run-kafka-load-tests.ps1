param(
    [string]$K6RestUrl = "http://127.0.0.1:8082",
    [string]$WrkRestUrl = "http://host.docker.internal:8082",
    [string]$Topic = "perf-kafka-http",
    [string]$Duration = "20s",
    [int]$Partitions = 6,
    [int]$K6Vus = 16,
    [int]$K6MaxVus = 64,
    [int]$K6Rate = 20,
    [int]$WrkThreads = 4,
    [int]$WrkConnections = 32,
    [int]$BatchSize = 10,
    [int]$PayloadBytes = 256,
    [switch]$ResetTopic,
    [switch]$Strict
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$K6Dir = Join-Path $Root "artifacts\k6"
$WrkDir = Join-Path $Root "artifacts\wrk"
$DockerConfigDir = Join-Path $Root "artifacts\docker-config"
New-Item -ItemType Directory -Force -Path $K6Dir, $WrkDir, $DockerConfigDir | Out-Null
[Environment]::SetEnvironmentVariable("DOCKER_CONFIG", $DockerConfigDir, "Process")
Set-Location $Root

function Write-Step([string]$Message) {
    Write-Host ""
    Write-Host "==> $Message"
}

function Set-ProcessEnv([hashtable]$Values) {
    foreach ($key in $Values.Keys) {
        [Environment]::SetEnvironmentVariable($key, [string]$Values[$key], "Process")
    }
}

Write-Step "Start Redpanda and Debezium"
docker compose -f "$Root\scripts\dev-compose.yml" up -d redpanda debezium-connect --wait --wait-timeout 180

Write-Step "Ensure Kafka topic exists"
if ($ResetTopic) {
    $deleteOutput = docker exec final-assignment-redpanda rpk topic delete $Topic 2>&1
    $deleteText = $deleteOutput -join "`n"
    if ($LASTEXITCODE -ne 0 -and ($deleteText -notmatch "does not exist|UNKNOWN_TOPIC_OR_PARTITION")) {
        $deleteOutput | Write-Host
        throw "Failed to delete Kafka topic $Topic"
    }
    $deleteOutput | Write-Host
}
$createOutput = docker exec final-assignment-redpanda rpk topic create $Topic --partitions $Partitions --replicas 1 2>&1
$createText = $createOutput -join "`n"
if ($LASTEXITCODE -ne 0 -and ($createText -notmatch "already exists|TOPIC_ALREADY_EXISTS")) {
    $createOutput | Write-Host
    throw "Failed to create Kafka topic $Topic"
}
$createOutput | Write-Host

Write-Step "Check Pandaproxy and Debezium HTTP APIs"
Invoke-RestMethod -Uri "$K6RestUrl/topics" | Out-Null
Invoke-RestMethod -Uri "http://127.0.0.1:8083/connectors" | Out-Null

Write-Step "k6 Kafka Pandaproxy produce"
Set-ProcessEnv @{
    KAFKA_REST_URL = $K6RestUrl
    KAFKA_TOPIC = $Topic
    PERF_DURATION = $Duration
    PERF_KAFKA_RATE = $K6Rate
    PERF_KAFKA_VUS = $K6Vus
    PERF_KAFKA_MAX_VUS = $K6MaxVus
    PERF_KAFKA_BATCH_SIZE = $BatchSize
    PERF_KAFKA_PAYLOAD_BYTES = $PayloadBytes
    PERF_STRICT = if ($Strict) { "true" } else { "false" }
}
$k6Output = Join-Path $K6Dir "kafka-pandaproxy-load.txt"
$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
& k6 run "$Root\scripts\k6\kafka-pandaproxy-load.js" 2>&1 | Tee-Object -FilePath $k6Output
$k6ExitCode = $LASTEXITCODE
$ErrorActionPreference = $oldErrorActionPreference
if ($k6ExitCode -ne 0) {
    Write-Warning "k6 Kafka scenario exited with code $k6ExitCode. See $k6Output"
}

Write-Step "wrk Kafka Pandaproxy produce"
$wrkOutput = Join-Path $WrkDir "kafka-pandaproxy-produce.txt"
$dockerArgs = @(
    "run", "--rm",
    "-e", "KAFKA_TOPIC=$Topic",
    "-e", "PERF_KAFKA_BATCH_SIZE=$BatchSize",
    "-e", "PERF_KAFKA_PAYLOAD_BYTES=$PayloadBytes",
    "-v", "$Root\scripts\wrk:/scripts:ro",
    "williamyeh/wrk",
    "-t$WrkThreads",
    "-c$WrkConnections",
    "-d$Duration",
    "-s", "/scripts/kafka-pandaproxy-produce.lua",
    $WrkRestUrl
)
$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
& docker @dockerArgs 2>&1 | Tee-Object -FilePath $wrkOutput
$wrkExitCode = $LASTEXITCODE
$ErrorActionPreference = $oldErrorActionPreference
if ($wrkExitCode -ne 0) {
    Write-Warning "wrk Kafka scenario exited with code $wrkExitCode. See $wrkOutput"
}

Write-Step "Kafka topic summary"
docker exec final-assignment-redpanda rpk topic describe $Topic -p | Tee-Object -FilePath (Join-Path $WrkDir "kafka-topic-describe.txt")

Write-Step "Kafka load tests finished"
Write-Host "k6 output: $k6Output"
Write-Host "wrk output: $wrkOutput"
Write-Host "topic summary: $(Join-Path $WrkDir "kafka-topic-describe.txt")"

if ($k6ExitCode -ne 0 -or $wrkExitCode -ne 0) {
    exit 1
}
