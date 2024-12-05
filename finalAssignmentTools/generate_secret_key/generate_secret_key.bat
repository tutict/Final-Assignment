@echo off
:: 调用 PowerShell 来生成 Base64 编码的 32 字节随机密钥
powershell -Command ^
    "$bytes = New-Object byte[] 32; [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes); $secretKeyBase64 = [Convert]::ToBase64String($bytes); Write-Output 'Generated Base64 Secret Key: ' + $secretKeyBase64"
pause
