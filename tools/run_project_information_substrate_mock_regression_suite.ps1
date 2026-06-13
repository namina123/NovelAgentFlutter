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
    Label = 'Core information contract suite'
    WorkingDirectory = Join-Path $repoRoot 'packages/novel_agent_core'
    Arguments = @(
      'test'
      'test/project_information_namespace_smoke_test.dart'
      'test/information_policy_contracts_test.dart'
      'test/project_knowledge_card_contracts_test.dart'
      'test/design_element_card_contracts_test.dart'
      'test/research_note_contracts_test.dart'
      'test/reference_work_record_contracts_test.dart'
      'test/information_repository_ports_test.dart'
      'test/information_tool_call_reliability_test.dart'
    )
  },
  @{
    Label = 'Core information workflow suite'
    WorkingDirectory = Join-Path $repoRoot 'packages/novel_agent_core'
    Arguments = @(
      'test'
      'test/semantic_review_information_bridge_service_test.dart'
      'test/long_task_checkpoint_review_service_test.dart'
      'test/book_deconstruction_narrative_bridge_service_test.dart'
    )
  },
  @{
    Label = 'Adapters information storage and tool suite'
    WorkingDirectory = Join-Path $repoRoot 'packages/novel_agent_adapters'
    Arguments = @(
      'test'
      'test/local_project_information_repositories_test.dart'
      'test/project_information_projection_writer_service_test.dart'
      'test/project_information_domain_tool_executor_test.dart'
      'test/project_tool_dispatcher_domain_tools_test.dart'
      'test/project_research_gateway_service_test.dart'
    )
  },
  @{
    Label = 'Adapters information runtime suite'
    WorkingDirectory = Join-Path $repoRoot 'packages/novel_agent_adapters'
    Arguments = @(
      'test'
      'test/project_information_activation_bridge_service_test.dart'
      'test/project_conversation_draft_runtime_service_test.dart'
      'test/project_long_task_checkpoint_review_service_test.dart'
      'test/project_workflow_review_runtime_service_test.dart'
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
Write-Host "Project Information Substrate mock regression suite passed." -ForegroundColor Green
