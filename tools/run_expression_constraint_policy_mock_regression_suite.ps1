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
    Label = 'Core expression constraint contract suite'
    WorkingDirectory = Join-Path $repoRoot 'packages/novel_agent_core'
    Command = 'dart'
    Arguments = @(
      'test'
      'test/expression_constraint_execution_policy_contracts_test.dart'
      'test/expression_constraint_execution_policy_resolver_service_test.dart'
      'test/expression_constraint_injection_policy_service_test.dart'
      'test/writing_execution_constraint_bridge_service_test.dart'
      'test/writing_execution_result_contracts_test.dart'
      'test/chapter_output_path_policy_service_test.dart'
    )
  }
  @{
    Label = 'Adapters expression constraint runtime suite'
    WorkingDirectory = Join-Path $repoRoot 'packages/novel_agent_adapters'
    Command = 'dart'
    Arguments = @(
      'test'
      'test/expression_constraint_status_projection_service_test.dart'
      'test/project_conversation_draft_runtime_service_test.dart'
      'test/project_workflow_runtime_service_test.dart'
      'test/project_long_task_station_detail_service_test.dart'
      'test/chapter_delivery_outcome_projection_service_test.dart'
    )
  }
  @{
    Label = 'App probe support tests'
    WorkingDirectory = Join-Path $repoRoot 'apps/novel_agent_app'
    Command = 'flutter'
    Arguments = @(
      'test'
      'test/probe_support_test.dart'
    )
  }
  @{
    Label = 'Long task mock regression probe'
    WorkingDirectory = Join-Path $repoRoot 'apps/novel_agent_app'
    Command = 'dart'
    Arguments = @(
      'run'
      'tool/mock_long_task_probe.dart'
    )
  }
  @{
    Label = 'Expression constraint mock regression probe'
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
Write-Host "Expression constraint policy mock regression suite passed." -ForegroundColor Green
