Write-Host "==> Reference source document probe" -ForegroundColor Cyan

Push-Location "apps/novel_agent_app"
try {
  & dart run tool/reference_source_document_probe.dart
  if ($LASTEXITCODE -ne 0) {
    throw "reference source document probe failed"
  }
}
finally {
  Pop-Location
}

Write-Host "Reference source document probe passed." -ForegroundColor Green
