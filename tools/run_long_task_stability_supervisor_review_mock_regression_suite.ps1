$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-TestStep {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Label,
    [Parameter(Mandatory = $true)]
    [string]$WorkingDirectory,
    [Parameter(Mandatory = $true)]
    [string]$Command,
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments
  )

  Write-Host ""
  Write-Host "==> $Label" -ForegroundColor Cyan
  Push-Location $WorkingDirectory
  try {
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
      throw "Command failed in ${WorkingDirectory}: $Command $($Arguments -join ' ')"
    }
  }
  finally {
    Pop-Location
  }
}

$repoRoot = Split-Path -Parent $PSScriptRoot

$steps = @(
  @{
    Label = 'App probe support and LTSR-20 suite tests'
    WorkingDirectory = Join-Path $repoRoot 'apps/novel_agent_app'
    Command = 'flutter'
    Arguments = @(
      'test'
      'test/probe_support_test.dart'
      'test/long_task_stability_mock_regression_suite_test.dart'
    )
  }
  @{
    Label = 'LTSR-20 mainline mock regression suite'
    WorkingDirectory = Join-Path $repoRoot 'apps/novel_agent_app'
    Command = 'dart'
    Arguments = @(
      'run'
      'tool/mock_long_task_stability_regression_suite.dart'
    )
  }
  @{
    Label = 'Long task mock probe regression'
    WorkingDirectory = Join-Path $repoRoot 'apps/novel_agent_app'
    Command = 'dart'
    Arguments = @(
      'run'
      'tool/mock_long_task_probe.dart'
    )
  }
  @{
    Label = 'Expression constraint mock probe regression'
    WorkingDirectory = Join-Path $repoRoot 'apps/novel_agent_app'
    Command = 'dart'
    Arguments = @(
      'run'
      'tool/mock_expression_constraint_policy_probe.dart'
    )
  }
)

foreach ($step in $steps) {
  Invoke-TestStep `
    -Label $step.Label `
    -WorkingDirectory $step.WorkingDirectory `
    -Command $step.Command `
    -Arguments $step.Arguments
}

Write-Host ""
Write-Host "Long task stability supervisor review mock regression suite passed." -ForegroundColor Green
