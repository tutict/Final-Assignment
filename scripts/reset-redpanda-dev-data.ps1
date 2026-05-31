param(
    [switch]$Force,
    [int]$WaitTimeoutSeconds = 180
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ComposeFile = Join-Path $Root "scripts\dev-compose.yml"
$ComposeProject = "final-assignment-dev"
$RedpandaVolume = "${ComposeProject}_redpanda-data"

Write-Host "This will reset the local Redpanda development data volume only:"
Write-Host "  Compose file : $ComposeFile"
Write-Host "  Compose name : $ComposeProject"
Write-Host "  Volume       : $RedpandaVolume"
Write-Host ""
Write-Host "MySQL, Redis, and Elasticsearch data volumes are not touched."
Write-Host "Debezium Connect will be recreated because it depends on Redpanda topics."
Write-Host ""

if (-not $Force) {
    $Confirmation = Read-Host "Type RESET-REDPANDA to continue"
    if ($Confirmation -ne "RESET-REDPANDA") {
        Write-Host "Canceled."
        exit 1
    }
}

Push-Location $Root
try {
    docker compose -f $ComposeFile stop debezium-connect redpanda
    docker compose -f $ComposeFile rm -f debezium-connect redpanda

    $ExistingVolume = docker volume ls --format "{{.Name}}" | Where-Object { $_ -eq $RedpandaVolume }
    if ($ExistingVolume) {
        docker volume rm $RedpandaVolume | Out-Host
    } else {
        Write-Host "Volume $RedpandaVolume was not present; continuing."
    }

    docker compose -f $ComposeFile up -d redpanda debezium-connect --wait --wait-timeout $WaitTimeoutSeconds
    docker compose -f $ComposeFile ps redpanda debezium-connect
} finally {
    Pop-Location
}
