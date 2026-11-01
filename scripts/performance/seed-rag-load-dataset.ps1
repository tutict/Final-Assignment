param(
    [string]$BaseUrl = "http://127.0.0.1:8080",
    [Parameter(Mandatory = $true)]
    [string]$Token,
    [string]$DatasetPath = "",
    [int]$EmbeddingBatches = 4,
    [int]$EmbeddingBatchSize = 50
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($DatasetPath)) {
    $DatasetPath = Join-Path $PSScriptRoot "rag-real-dataset.json"
}

$BaseUrl = $BaseUrl.TrimEnd("/")
$authValue = if ($Token.StartsWith("Bearer ")) { $Token } else { "Bearer $Token" }
$headers = @{
    Authorization = $authValue
    Accept = "application/json"
}

function Invoke-JsonPost([string]$Uri, [string]$JsonBody) {
    Invoke-RestMethod `
        -Method Post `
        -Uri $Uri `
        -Headers $headers `
        -ContentType "application/json; charset=utf-8" `
        -Body ([System.Text.Encoding]::UTF8.GetBytes($JsonBody))
}

function Get-HttpStatus($exception) {
    if ($exception.Response) { return [int]$exception.Response.StatusCode }
    return $null
}

function Get-ResponseData($response) {
    if ($null -ne $response -and $null -ne $response.data) { return $response.data }
    return $response
}

function Invoke-EmbeddingRun($Limit) {
    try {
        $body = Invoke-RestMethod `
            -Method Post `
            -Uri "$BaseUrl/api/rag/admin/embedding/run?limit=$Limit" `
            -Headers $headers
        return [pscustomobject]@{ Ok = $true; Status = 200; Body = (Get-ResponseData $body); Error = $null }
    } catch {
        return [pscustomobject]@{
            Ok = $false
            Status = Get-HttpStatus $_.Exception
            Body = $null
            Error = $_.Exception.Message
        }
    }
}

function Invoke-EmbeddingBatches([int]$MaxBatches, [string]$Phase) {
    $succeeded = 0
    $failure = $null
    for ($i = 0; $i -lt $MaxBatches; $i++) {
        $run = Invoke-EmbeddingRun $EmbeddingBatchSize
        if (-not $run.Ok) {
            $failure = $run
            Write-Warning "RAG embedding $Phase batch $($i + 1) failed (status=$($run.Status)): $($run.Error)"
            break
        }
        $body = $run.Body
        if ($null -ne $body.enabled -and -not $body.enabled) {
            $failure = [pscustomobject]@{ Ok = $false; Status = 409; Error = "backend reports RAG embedding disabled" }
            Write-Warning "RAG embedding ${Phase}: backend reports embedding disabled."
            break
        }
        if ($body.alreadyRunning) {
            Start-Sleep -Milliseconds 500
            continue
        }
        $selected = if ($null -ne $body.selectedTasks) { [int]$body.selectedTasks } else { 0 }
        $succeeded += [int]$body.succeededTasks
        if ($selected -le 0) { break }
        Start-Sleep -Milliseconds 300
    }
    return [pscustomobject]@{ Succeeded = $succeeded; Failure = $failure }
}

function Wait-RagQueryHits([int]$Attempts) {
    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        try {
            Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:9200/_refresh" | Out-Null
        } catch {
            # Elasticsearch refresh is best-effort; query retry still covers delayed visibility.
        }
        $queryResult = Invoke-JsonPost "$BaseUrl/api/rag/query" ($queryPayload | ConvertTo-Json -Compress -Depth 8)
        $results = $queryResult.results
        if (-not $results -and $queryResult.data) { $results = $queryResult.data.results }
        if (-not $results -and $queryResult.data -and ($queryResult.data -is [System.Array])) { $results = $queryResult.data }
        $count = if ($results) { @($results).Count } else { 0 }
        if ($count -gt 0) { return $count }
        Start-Sleep -Milliseconds 500
    }
    return 0
}

if (-not (Test-Path -LiteralPath $DatasetPath)) {
    throw "RAG load dataset not found: $DatasetPath"
}

$dataset = Get-Content -LiteralPath $DatasetPath -Raw -Encoding UTF8 | ConvertFrom-Json
$documents = @($dataset.documents)
if ($documents.Count -eq 0) {
    throw "RAG load dataset has no documents: $DatasetPath"
}

foreach ($document in $documents) {
    $metadata = @{
        perfDataset = $true
        retrievalShape = @("document", "chunk", "embedding", "rerank")
        tags = @($document.tags)
    } | ConvertTo-Json -Compress -Depth 8

    $payload = @{
        sourceId = $document.sourceId
        sourceVersion = $document.sourceVersion
        title = $document.title
        content = $document.content
        aclScope = $document.aclScope
        route = $document.route
        metadataJson = $metadata
    } | ConvertTo-Json -Compress -Depth 12

    try {
        Invoke-JsonPost "$BaseUrl/api/rag/admin/documents/manual" $payload | Out-Null
    } catch {
        $status = $null
        if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
        if ($status -eq 409) {
            Write-Host "RAG document already present: $($document.sourceId)"
            continue
        }
        throw
    }
}

$queryPayload = @{
    query = $dataset.query
    topK = 5
    roles = @($dataset.roles)
}

$initial = Invoke-EmbeddingBatches $EmbeddingBatches "initial"
$resultCount = Wait-RagQueryHits 12
$requeueStatus = $null
$recovery = $null

if ($resultCount -le 0) {
    # 各后端使用独立 ES 索引；文档已存在于共享 MySQL 时手动创建会 409，
    # 必须 requeue 让当前后端把自己的索引从 chunk 重建出来。
    Write-Host "RAG query returned no hits; rebuilding this backend's vector index from existing chunks."
    $requeue = $null
    try {
        $requeue = Invoke-RestMethod `
            -Method Post `
            -Uri "$BaseUrl/api/rag/admin/embedding/requeue?limit=1000" `
            -Headers $headers
    } catch {
        $requeueStatus = Get-HttpStatus $_.Exception
        Write-Warning "RAG embedding requeue failed (status=$($requeueStatus)): $($_.Exception.Message)"
    }
    if ($requeue) {
        $requeueData = Get-ResponseData $requeue
        Write-Host "RAG embedding requeued: chunks=$($requeueData.requeuedChunks) tasks=$($requeueData.requeuedTasks) newTasks=$($requeueData.createdTasks)"
        $recovery = Invoke-EmbeddingBatches ([Math]::Max(8, $EmbeddingBatches * 4)) "recovery"
        $resultCount = Wait-RagQueryHits 12
    }
}

if ($resultCount -le 0) {
    $details = @()
    if ($initial.Failure) {
        $details += "initial embedding: status=$($initial.Failure.Status) $($initial.Failure.Error)"
    }
    if ($requeueStatus -ne $null) {
        $details += "requeue: status=$requeueStatus"
    }
    if ($recovery -and $recovery.Failure) {
        $details += "recovery embedding: status=$($recovery.Failure.Status) $($recovery.Failure.Error)"
    }
    $detailText = if ($details.Count -gt 0) { " Details: " + ($details -join "; ") } else { "" }
    throw "RAG load dataset was seeded, but /api/rag/query returned no hits.$detailText"
}

Write-Host "RAG load dataset ready: documents=$($documents.Count), queryHits=$resultCount"
