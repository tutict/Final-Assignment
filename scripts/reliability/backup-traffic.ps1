param()
$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$out = Join-Path $root "artifacts\backups"
New-Item -ItemType Directory -Force -Path $out | Out-Null
$db = if ($env:DB_NAME) { $env:DB_NAME } else { "traffic" }
$user = if ($env:DB_USERNAME) { $env:DB_USERNAME } else { "root" }
$pass = if ($env:DB_PASSWORD) { $env:DB_PASSWORD } else { "root" }
$hostName = if ($env:DB_HOST) { $env:DB_HOST } else { "127.0.0.1" }
$port = if ($env:DB_PORT) { $env:DB_PORT } else { "3306" }
$known = "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqldump.exe"
if (Test-Path $known) { $dump = $known } else { $cmd = Get-Command mysqldump -ErrorAction SilentlyContinue; if ($cmd) { $dump = $cmd.Source } else { $dump = $null } }
if (-not $dump) { throw "mysqldump was not found" }
$mysql = Join-Path (Split-Path $dump) "mysql.exe"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$file = Join-Path $out ("traffic-" + $stamp + ".sql")
$env:MYSQL_PWD = $pass
$dumpPsi = New-Object System.Diagnostics.ProcessStartInfo
$dumpPsi.FileName = $dump
$dumpPsi.Arguments = "--single-transaction --routines --triggers --no-tablespaces -h $hostName -P $port -u $user $db"
$dumpPsi.RedirectStandardOutput = $true
$dumpPsi.RedirectStandardError = $true
$dumpPsi.UseShellExecute = $false
$dumpProc = [System.Diagnostics.Process]::Start($dumpPsi)
$dumpOut = [System.IO.File]::Create($file)
try { $dumpProc.StandardOutput.BaseStream.CopyTo($dumpOut) } finally { $dumpOut.Close() }
$dumpErr = $dumpProc.StandardError.ReadToEnd()
$dumpProc.WaitForExit()
if ($dumpProc.ExitCode -ne 0) { throw "mysqldump failed: $dumpErr" }
if (-not (Test-Path $file) -or (Get-Item $file).Length -lt 100) { throw "dump file is missing or too small" }
$checksumSql = "SELECT 'payment_record', COUNT(*), COALESCE(MAX(payment_id),0), COALESCE(SUM(payment_amount),0) FROM payment_record UNION ALL SELECT 'fine_record', COUNT(*), COALESCE(MAX(fine_id),0), COALESCE(SUM(fine_amount),0) FROM fine_record UNION ALL SELECT 'deduction_record', COUNT(*), COALESCE(MAX(deduction_id),0), COALESCE(SUM(deducted_points),0) FROM deduction_record UNION ALL SELECT 'appeal_record', COUNT(*), COALESCE(MAX(appeal_id),0), 0 FROM appeal_record;"
$checksumFile = Join-Path $out ("traffic-" + $stamp + ".checksum.txt")
& $mysql -h $hostName -P $port -u $user -N -e $checksumSql $db | Set-Content -Encoding utf8 $checksumFile
if (-not (Test-Path $checksumFile) -or (Get-Item $checksumFile).Length -lt 10) { throw "checksum file was not written" }
$head = "unknown"
try { $head = (& git -C $root rev-parse HEAD).Trim() } catch { $head = "unknown" }
$binlog = "unavailable"
$probe = $null
$oldErrorAction = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try {
  $probe = & $mysql -h $hostName -P $port -u $user -N -e "SHOW BINARY LOG STATUS;" $db 2>$null
  if (-not $probe) { $probe = & $mysql -h $hostName -P $port -u $user -N -e "SHOW MASTER STATUS;" $db 2>$null }
} catch {
  $probe = $null
}
$ErrorActionPreference = $oldErrorAction
if ($probe) { $binlog = ($probe | Out-String).Trim() }
$manifest = Join-Path $out ("traffic-" + $stamp + ".manifest.txt")
Set-Content -Encoding utf8 $manifest -Value ("git=" + $head)
Add-Content -Encoding utf8 $manifest -Value ("dump=" + $file)
Add-Content -Encoding utf8 $manifest -Value ("checksum=" + $checksumFile)
Add-Content -Encoding utf8 $manifest -Value ("binlog=" + $binlog)
Add-Content -Encoding utf8 $manifest -Value (Get-Content $checksumFile)
$size = (Get-Item $file).Length
$name = Split-Path $file -Leaf
function Restrict-ToCurrentUser([string]$path) {
  & icacls $path /inheritance:r /grant:r "${env:USERNAME}:(R,W)" | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "backup file ACL was not restricted: $path" }
}
Restrict-ToCurrentUser $file
Restrict-ToCurrentUser $checksumFile
Restrict-ToCurrentUser $manifest
$insert = "INSERT INTO sys_backup_restore (backup_type, backup_file_name, backup_file_path, backup_file_size, backup_time, backup_handler, status, remarks) VALUES ('Full', '$name', '$file', $size, NOW(), 'reliability-script', 'Success', 'git $head');"
& $mysql -h $hostName -P $port -u $user $db -e $insert
Write-Output $manifest
# Manual only. Do not register this automatically.
# schtasks /Create /TN traffic-backup /SC MINUTE /MO 15 /TR powershell -File scripts/reliability/backup-traffic.ps1 /F
