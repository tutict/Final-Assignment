param([Parameter(Mandatory=$true)][string]$DumpFile)
$ErrorActionPreference = "Stop"
if ($DumpFile -notmatch "traffic-") { throw "Refusing a dump whose name does not look like a traffic backup" }
$dumpCmd = Get-Command mysqldump -ErrorAction SilentlyContinue
if (-not $dumpCmd) { $found = Get-ChildItem "C:\Program Files\MySQL" -Filter mysql.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1; if (-not $found) { throw "mysql client was not found" }; $mysql = $found.FullName } else { $mysql = Join-Path (Split-Path $dumpCmd.Source) "mysql.exe" }
$user = if ($env:DB_USERNAME) { $env:DB_USERNAME } else { "root" }
$pass = if ($env:DB_PASSWORD) { $env:DB_PASSWORD } else { "root" }
$hostName = if ($env:DB_HOST) { $env:DB_HOST } else { "127.0.0.1" }
$port = if ($env:DB_PORT) { $env:DB_PORT } else { "3306" }
$env:MYSQL_PWD = $pass
$checksumSql = "SELECT COUNT(*) FROM payment_record;"
$before = & $mysql -h $hostName -P $port -u $user -N -e "SELECT COUNT(*) FROM payment_record" traffic
& $mysql -h $hostName -P $port -u $user -e "DROP DATABASE IF EXISTS traffic_restore_drill; CREATE DATABASE traffic_restore_drill;"
$rewritten = Join-Path $env:TEMP "traffic-restore-drill.sql"
$bytes = [System.IO.File]::ReadAllBytes($DumpFile)
$offset = 0
if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) { $offset = 3 }
$sql = [System.Text.Encoding]::UTF8.GetString($bytes, $offset, $bytes.Length - $offset)
$sql = $sql.Replace("USE ``traffic``;", "USE ``traffic_restore_drill``;")
$noBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($rewritten, $sql, $noBom)
$importErrorFile = Join-Path $env:TEMP "traffic-restore-drill.err"
if (Test-Path $importErrorFile) { Remove-Item $importErrorFile -Force }
$cmd = "call `"$mysql`" -h $hostName -P $port -u $user --binary-mode traffic_restore_drill < `"$rewritten`" 2> `"$importErrorFile`""
cmd.exe /c $cmd
if ($LASTEXITCODE -ne 0) {
  $importError = if (Test-Path $importErrorFile) { Get-Content -Raw $importErrorFile } else { "" }
  throw "mysql import failed: $LASTEXITCODE $importError"
}
$checksumSql = "SELECT 'payment_record', COUNT(*), COALESCE(MAX(payment_id),0), COALESCE(SUM(payment_amount),0) FROM payment_record UNION ALL SELECT 'fine_record', COUNT(*), COALESCE(MAX(fine_id),0), COALESCE(SUM(fine_amount),0) FROM fine_record UNION ALL SELECT 'deduction_record', COUNT(*), COALESCE(MAX(deduction_id),0), COALESCE(SUM(deducted_points),0) FROM deduction_record UNION ALL SELECT 'appeal_record', COUNT(*), COALESCE(MAX(appeal_id),0), 0 FROM appeal_record;"
$restored = & $mysql -h $hostName -P $port -u $user -N -e $checksumSql traffic_restore_drill
$expectedFile = [IO.Path]::ChangeExtension($DumpFile, ".checksum.txt")
if (Test-Path $expectedFile) {
  $expected = (Get-Content $expectedFile | ForEach-Object { $_.Trim() }) -join "`n"
  $actual = ($restored | ForEach-Object { $_.Trim() }) -join "`n"
  if ($expected -ne $actual) { throw "restore checksum mismatch`n$actual" }
}
$after = & $mysql -h $hostName -P $port -u $user -N -e "SELECT COUNT(*) FROM payment_record" traffic
if ($before.Trim() -ne $after.Trim()) { throw "live traffic payment_record count changed" }
Write-Output "restored traffic_restore_drill; live payment_record count $after"
