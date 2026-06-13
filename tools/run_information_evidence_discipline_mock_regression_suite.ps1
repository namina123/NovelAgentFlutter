$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function New-TestScenario {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Id,
    [Parameter(Mandatory = $true)]
    [string]$Label,
    [Parameter(Mandatory = $true)]
    [string]$Layer,
    [Parameter(Mandatory = $true)]
    [string]$ExpectedCategory,
    [Parameter(Mandatory = $true)]
    [string]$WorkingDirectory,
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments,
    [Parameter(Mandatory = $true)]
    [string]$Summary
  )

  return @{
    Id = $Id
    Label = $Label
    Layer = $Layer
    ExpectedCategory = $ExpectedCategory
    WorkingDirectory = $WorkingDirectory
    Arguments = $Arguments
    Summary = $Summary
  }
}

function Invoke-TestScenario {
  param(
    [Parameter(Mandatory = $true)]
    [hashtable]$Scenario
  )

  Write-Host ""
  Write-Host "==> $($Scenario.Id) [$($Scenario.ExpectedCategory)] $($Scenario.Label)" -ForegroundColor Cyan
  Push-Location $Scenario.WorkingDirectory
  try {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $output = & dart @($Scenario.Arguments) 2>&1
    $exitCode = $LASTEXITCODE
    $stopwatch.Stop()
  }
  finally {
    Pop-Location
  }

  foreach ($line in $output) {
    Write-Host $line
  }

  $tail = @($output |
      ForEach-Object { "$_".Trim() } |
      Where-Object { $_ -ne '' })
  $summary = if ($tail.Count -gt 0) {
    $tail[-1]
  }
  else {
    $Scenario.Summary
  }

  return @{
    id = $Scenario.Id
    label = $Scenario.Label
    layer = $Scenario.Layer
    expected_report_category = $Scenario.ExpectedCategory
    working_directory = $Scenario.WorkingDirectory
    command = "dart $($Scenario.Arguments -join ' ')"
    duration_ms = [int]$stopwatch.ElapsedMilliseconds
    ok = ($exitCode -eq 0)
    summary = $summary
    test_summary = $Scenario.Summary
  }
}

function Write-ReportFiles {
  param(
    [Parameter(Mandatory = $true)]
    [string]$RootDirectory,
    [Parameter(Mandatory = $true)]
    [hashtable]$Report
  )

  $jsonPath = Join-Path $RootDirectory 'information_evidence_mock_regression_report.json'
  $markdownPath = Join-Path $RootDirectory 'information_evidence_mock_regression_report.md'

  $report | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding UTF8

  $categoryLines = foreach ($entry in $Report.category_summary.GetEnumerator() | Sort-Object Name) {
    "- $($entry.Name): $($entry.Value)"
  }
  $scenarioLines = foreach ($scenario in $Report.scenarios) {
    "- $($scenario.id) | $($scenario.expected_report_category) | $(if ($scenario.ok) { 'PASS' } else { 'FAIL' }) | $($scenario.label) | $($scenario.summary)"
  }

  $markdown = @(
    '# Information Evidence Discipline Mock Regression Suite'
    ''
    "- generated_at: $($Report.generated_at)"
    "- overall_ok: $($Report.overall_ok)"
    "- scenario_count: $($Report.scenario_count)"
    ''
    '## Category Summary'
    ''
    $categoryLines
    ''
    '## Scenario Results'
    ''
    $scenarioLines
    ''
    '## Artifact Paths'
    ''
    "- json: $jsonPath"
    "- markdown: $markdownPath"
    ''
    '## Notes'
    ''
    '- 场景分类来自 production contracts 已覆盖的测试用例意图，不在脚本层重写业务判定。'
    '- 本套件只跑 fake/mock 路径，不访问真实 provider，也不联网。'
  ) -join [Environment]::NewLine

  Set-Content -Path $markdownPath -Value $markdown -Encoding UTF8

  return @{
    json = $jsonPath
    markdown = $markdownPath
  }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$runId = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH-mm-ss.fffZ')
$artifactsRoot = Join-Path $repoRoot "artifacts/information_evidence_mock_regression_suite/$runId"
New-Item -ItemType Directory -Path $artifactsRoot -Force | Out-Null

$adaptersRoot = Join-Path $repoRoot 'packages/novel_agent_adapters'

$scenarios = @(
  (New-TestScenario `
      -Id 'open_network_auto_execute' `
      -Label '开放权限下 request_external_research 自动执行 fake gateway' `
      -Layer 'tool_execution' `
      -ExpectedCategory 'success' `
      -WorkingDirectory $adaptersRoot `
      -Arguments @(
        'test',
        'test/project_information_domain_tool_executor_test.dart',
        '--plain-name',
        'request_external_research uses host-open context to auto execute gateway research'
      ) `
      -Summary 'open network auto execute'
  ),
  (New-TestScenario `
      -Id 'restricted_network_pending_confirmation' `
      -Label '受限权限下 research request 保持待确认' `
      -Layer 'tool_execution' `
      -ExpectedCategory 'waiting_user' `
      -WorkingDirectory $adaptersRoot `
      -Arguments @(
        'test',
        'test/project_information_domain_tool_executor_test.dart',
        '--plain-name',
        'request_external_research uses host-safe context to override model network grant and preserves raw audit'
      ) `
      -Summary 'restricted network pending confirmation'
  ),
  (New-TestScenario `
      -Id 'import_collection_auto_execute' `
      -Label '导入收集请求在允许导入时自动完成' `
      -Layer 'tool_execution' `
      -ExpectedCategory 'success' `
      -WorkingDirectory $adaptersRoot `
      -Arguments @(
        'test',
        'test/project_information_domain_tool_executor_test.dart',
        '--plain-name',
        'request_external_research auto executes import collection when host allows import'
      ) `
      -Summary 'import collection auto execute'
  ),
  (New-TestScenario `
      -Id 'hybrid_partial_waiting_confirmation' `
      -Label 'hybrid 请求先导入再等待联网确认' `
      -Layer 'coordinator' `
      -ExpectedCategory 'waiting_user' `
      -WorkingDirectory $adaptersRoot `
      -Arguments @(
        'test',
        'test/project_information_research_coordinator_service_test.dart',
        '--plain-name',
        'hybrid request imports first, waits for confirmation, and does not re-import'
      ) `
      -Summary 'hybrid partial import plus waiting confirmation'
  ),
  (New-TestScenario `
      -Id 'gateway_failed_request' `
      -Label 'fake gateway 失败会保留结构化技术失败状态' `
      -Layer 'coordinator' `
      -ExpectedCategory 'technical_failure' `
      -WorkingDirectory $adaptersRoot `
      -Arguments @(
        'test',
        'test/project_information_research_coordinator_service_test.dart',
        '--plain-name',
        'gateway failure is preserved as structured request state'
      ) `
      -Summary 'gateway failed request remains structured'
  ),
  (New-TestScenario `
      -Id 'rigorous_source_insufficient' `
      -Label '严谨来源不足在普通 runtime 中保持 evidence warning' `
      -Layer 'ordinary_runtime' `
      -ExpectedCategory 'information_quality_failure' `
      -WorkingDirectory $adaptersRoot `
      -Arguments @(
        'test',
        'test/project_conversation_draft_runtime_service_test.dart',
        '--plain-name',
        'finalizeDraftRun keeps rigorous source insufficiency as evidence warning in shared result'
      ) `
      -Summary 'rigorous source insufficient remains evidence warning'
  ),
  (New-TestScenario `
      -Id 'ordinary_runtime_auto_research' `
      -Label '普通写作 runtime 会回写自动研究结果摘要' `
      -Layer 'ordinary_runtime' `
      -ExpectedCategory 'success' `
      -WorkingDirectory $adaptersRoot `
      -Arguments @(
        'test',
        'test/project_conversation_draft_runtime_service_test.dart',
        '--plain-name',
        'finalizeDraftRun merges auto research changed paths and reports executed research summary'
      ) `
      -Summary 'ordinary runtime auto research summary'
  ),
  (New-TestScenario `
      -Id 'ordinary_runtime_pending_confirmation' `
      -Label '普通写作 runtime 会把待确认研究映射为 waiting_user' `
      -Layer 'ordinary_runtime' `
      -ExpectedCategory 'waiting_user' `
      -WorkingDirectory $adaptersRoot `
      -Arguments @(
        'test',
        'test/project_conversation_draft_runtime_service_test.dart',
        '--plain-name',
        'finalizeDraftRun reports waiting confirmation when research request remains pending'
      ) `
      -Summary 'ordinary runtime waiting confirmation summary'
  ),
  (New-TestScenario `
      -Id 'long_task_checkpoint_waiting_confirmation' `
      -Label '长任务 checkpoint 把 information awaiting confirmation 映射为 waiting_user' `
      -Layer 'long_task_checkpoint' `
      -ExpectedCategory 'waiting_user' `
      -WorkingDirectory $adaptersRoot `
      -Arguments @(
        'test',
        'test/project_workflow_runtime_service_test.dart',
        '--plain-name',
        'runWorkflowTaskOnce routes information awaiting confirmation to waiting_user checkpoint state'
      ) `
      -Summary 'long task checkpoint waiting confirmation'
  ),
  (New-TestScenario `
      -Id 'long_task_checkpoint_gateway_failed' `
      -Label '长任务 checkpoint 保持 gateway failed 为 repair 而非正文失败' `
      -Layer 'long_task_checkpoint' `
      -ExpectedCategory 'technical_failure' `
      -WorkingDirectory $adaptersRoot `
      -Arguments @(
        'test',
        'test/project_workflow_runtime_service_test.dart',
        '--plain-name',
        'runWorkflowTaskOnce keeps gateway failed information signal as repair instead of technical failure'
      ) `
      -Summary 'long task checkpoint gateway failed'
  )
)

$results = @()
foreach ($scenario in $scenarios) {
  $results += Invoke-TestScenario -Scenario $scenario
}

$failedResults = @($results | Where-Object { -not $_.ok })
$overallOk = $failedResults.Count -eq 0
$categorySummary = @{}
foreach ($scenario in $results) {
  $category = [string]$scenario.expected_report_category
  if (-not $categorySummary.ContainsKey($category)) {
    $categorySummary[$category] = 0
  }
  $categorySummary[$category] += 1
}

$report = @{
  suite_id = 'ied_14_mock_regression_suite'
  generated_at = (Get-Date).ToUniversalTime().ToString('o')
  overall_ok = $overallOk
  scenario_count = $results.Count
  category_summary = $categorySummary
  scenarios = $results
}

$reportPaths = Write-ReportFiles -RootDirectory $artifactsRoot -Report $report

Write-Host ""
Write-Host "Artifacts:" -ForegroundColor Yellow
Write-Host "  JSON: $($reportPaths.json)"
Write-Host "  Markdown: $($reportPaths.markdown)"

if (-not $overallOk) {
  throw "Information Evidence Discipline mock regression suite failed."
}

Write-Host ""
Write-Host "Information Evidence Discipline mock regression suite passed." -ForegroundColor Green
