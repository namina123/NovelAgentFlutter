$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = Split-Path -Parent $PSScriptRoot

Write-Host ""
Write-Host "==> RRP-06 long task mock probe" -ForegroundColor Cyan
Push-Location $repoRoot
try {
  & dart run apps/novel_agent_app/tool/mock_long_task_probe.dart
  if ($LASTEXITCODE -ne 0) {
    throw "mock long task probe failed"
  }
}
finally {
  Pop-Location
}

Write-Host ""
Write-Host "RRP-06 long task mock probe passed." -ForegroundColor Green
