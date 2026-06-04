$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-TestStep {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Label,
    [Parameter(Mandatory = $true)]
    [string]$WorkingDirectory,
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments
  )

  Write-Host ""
  Write-Host "==> $Label" -ForegroundColor Cyan
  Push-Location $WorkingDirectory
  try {
    & dart @Arguments
    if ($LASTEXITCODE -ne 0) {
      throw "Command failed in ${WorkingDirectory}: dart $($Arguments -join ' ')"
    }
  }
  finally {
    Pop-Location
  }
}

$repoRoot = Split-Path -Parent $PSScriptRoot

$steps = @(
  @{
    Label = 'Core mock regression suite'
    WorkingDirectory = Join-Path $repoRoot 'packages/novel_agent_core'
    Arguments = @(
      'test'
      'test/draft_generation_use_case_test.dart'
      'test/submit_chapter_delivery_handler_test.dart'
      'test/chapter_delivery_state_machine_test.dart'
      'test/narrative_supervisor_risk_policy_service_test.dart'
      'test/draft_generation_tool_call_reliability_test.dart'
    )
  },
  @{
    Label = 'Adapters mock regression suite'
    WorkingDirectory = Join-Path $repoRoot 'packages/novel_agent_adapters'
    Arguments = @(
      'test'
      'test/project_conversation_draft_runtime_service_test.dart'
      'test/project_narrative_domain_tool_executor_test.dart'
      'test/project_workflow_review_runtime_service_test.dart'
      'test/project_workflow_runtime_service_test.dart'
    )
  }
)

foreach ($step in $steps) {
  Invoke-TestStep `
    -Label $step.Label `
    -WorkingDirectory $step.WorkingDirectory `
    -Arguments $step.Arguments
}

Write-Host ""
Write-Host "Open Narrative mock regression suite passed." -ForegroundColor Green
