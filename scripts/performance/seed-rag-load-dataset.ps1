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

for ($i = 0; $i -lt $EmbeddingBatches; $i++) {
    try {
        Invoke-RestMethod `
            -Method Post `
            -Uri "$BaseUrl/api/rag/admin/embedding/run?limit=$EmbeddingBatchSize" `
            -Headers $headers | Out-Null
    } catch {
        Write-Warning "RAG embedding batch $($i + 1) could not run: $($_.Exception.Message)"
        break
    }
    Start-Sleep -Milliseconds 500
}

$queryPayload = @{
    query = $dataset.query
    topK = 5
    roles = @($dataset.roles)
} | ConvertTo-Json -Compress -Depth 8

$resultCount = 0
$queryResult = $null
$results = $null
for ($attempt = 1; $attempt -le 12; $attempt++) {
    try {
        Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:9200/_refresh" | Out-Null
    } catch {
        # Elasticsearch refresh is best-effort; query retry still covers delayed visibility.
    }
    $queryResult = Invoke-JsonPost "$BaseUrl/api/rag/query" $queryPayload
    $results = $queryResult.results
    if (-not $results -and $queryResult.data) { $results = $queryResult.data.results }
    if (-not $results -and $queryResult.data -and ($queryResult.data -is [System.Array])) { $results = $queryResult.data }
    $resultCount = if ($results) { @($results).Count } else { 0 }
    if ($resultCount -gt 0) { break }
    Start-Sleep -Milliseconds 500
}
if ($resultCount -le 0) {
    throw "RAG load dataset was seeded, but /api/rag/query returned no hits."
}

Write-Host "RAG load dataset ready: documents=$($documents.Count), queryHits=$resultCount"
