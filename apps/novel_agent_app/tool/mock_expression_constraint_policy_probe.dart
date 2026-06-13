import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_adapters/src/workflow/chapter_delivery_outcome_projection_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../tools/probe_config_support.dart';
import 'probe_support.dart';

Future<void> main() async {
  final repoRoot = resolveLocalProbeRepoRoot();
  final runId = DateTime.now().toIso8601String();
  final workspaceRoot = buildProbeWorkspaceDirectory(
    repoRoot: repoRoot,
    probeName: 'mock_expression_constraint_policy_probe',
    runId: runId,
  );
  await workspaceRoot.create(recursive: true);

  final scenarios = <JsonMap>[
    await _runOrdinaryDisabledScenario(workspaceRoot),
    await _runOrdinaryAdaptiveMissingReviewScenario(workspaceRoot),
    _runOrdinaryForceRepairScenario(),
    await _runDeconstructionFollowupIntentScenario(workspaceRoot),
    await _runDeconstructionContinuationIntentScenario(workspaceRoot),
    await _runExplainerSummaryForceIntentScenario(workspaceRoot),
    await _runResearchSummaryExclusionScenario(workspaceRoot),
    await _runToolProtocolExclusionScenario(workspaceRoot),
    await _runPathResolutionExclusionScenario(workspaceRoot),
    _runDuplicateChapterPathRegressionScenario(),
    _runWaitingUserScenario(),
    _runTechnicalFailureScenario(),
  ];

  final summary = _summaryForScenarios(scenarios);
  final report = <String, Object?>{
    'probe_id': 'ecp_13_expression_constraint_policy_mock_probe',
    'run_id': runId,
    'repo_root': repoRoot,
    'workspace_root': workspaceRoot.path,
    'started_at': runId,
    'finished_at': DateTime.now().toIso8601String(),
    'summary': summary,
    'scenarios': scenarios,
  };

  final jsonPath =
      '${workspaceRoot.path}${Platform.pathSeparator}mock_expression_constraint_policy_probe_report.json';
  final markdownPath =
      '${workspaceRoot.path}${Platform.pathSeparator}mock_expression_constraint_policy_probe_report.md';
  await File(
    jsonPath,
  ).writeAsString(const JsonEncoder.withIndent('  ').convert(report));
  await File(markdownPath).writeAsString(_renderMarkdown(report));

  stdout.writeln('=== ECP-13 Expression Constraint Mock Probe ===');
  stdout.writeln('workspace: ${workspaceRoot.path}');
  stdout.writeln('report_json: $jsonPath');
  stdout.writeln('report_markdown: $markdownPath');
  stdout.writeln(
    'passed: ${ValueReaders.intValue(summary['passed_scenarios'])}/${ValueReaders.intValue(summary['total_scenarios'])}',
  );
  for (final rawScenario in scenarios) {
    final scenario = ValueReaders.mapValue(rawScenario);
    final prefix = ValueReaders.boolValue(scenario['ok']) ? '[PASS]' : '[FAIL]';
    stdout.writeln(
      '$prefix ${ValueReaders.stringValue(scenario['id'])} '
      '=> ${ValueReaders.stringValue(scenario['report_category'])}',
    );
  }

  if (scenarios.any((scenario) => !ValueReaders.boolValue(scenario['ok']))) {
    exitCode = 1;
  }
}

Future<JsonMap> _runOrdinaryDisabledScenario(Directory workspaceRoot) async {
  final harness = await _DraftRuntimeHarness.create(
    workspaceRoot: workspaceRoot,
    scenarioId: 'ordinary_disabled',
  );
  await _saveExpressionConstraintBinding(
    profileRepository: harness.profileRepository,
    bindingRepository: harness.bindingRepository,
    project: harness.project,
  );
  final preparation = await harness.service.prepareDraftRun(
    harness.project,
    taskType: 'chapter',
    pinnedRelativePaths: const <String>['outline/总纲.md'],
    expressionConstraintPolicyMode:
        ExpressionConstraintExecutionPolicyModes.disabled,
  );
  final artifacts = await harness.service.finalizeDraftRun(
    project: harness.project,
    preparation: preparation,
    result: _chapterDraftResult(harness.project),
    title: '第01章',
  );
  final constraints = ValueReaders.mapValue(
    artifacts.writingExecutionResult['constraints'],
  );
  final projection = const ExpressionConstraintStatusProjectionService()
      .fromWritingExecutionResult(artifacts.writingExecutionResult);
  final scenarioOk =
      ValueReaders.stringValue(
            constraints['expression_constraint_policy_mode'],
          ) ==
          ExpressionConstraintExecutionPolicyModes.disabled &&
      ValueReaders.boolValue(constraints['expression_constraint_disabled']) &&
      !ValueReaders.boolValue(
        constraints['expression_constraint_evidence_missing'],
      ) &&
      ValueReaders.stringValue(
            artifacts.writingExecutionResult['overall_status'],
          ) ==
          WritingExecutionOutcomeStatuses.success &&
      projection.status == 'disabled';
  return <String, Object?>{
    'id': 'ordinary_disabled',
    'layer': 'conversation_runtime_finalize',
    'ok': scenarioOk,
    'report_category': ProbeReportCategories.policyDisabled,
    'expected_report_category': ProbeReportCategories.policyDisabled,
    'policy_mode': ValueReaders.stringValue(
      constraints['expression_constraint_policy_mode'],
    ),
    'status_projection': projection.toJson(),
    'overall_status': ValueReaders.stringValue(
      artifacts.writingExecutionResult['overall_status'],
    ),
    'probe_execution_report': buildExpressionConstraintProbeReport(
      writingExecutionResult: artifacts.writingExecutionResult,
      chapterDelivery: artifacts.chapterDelivery,
    ),
    'summary': ValueReaders.stringValue(
      artifacts.writingExecutionResult['summary'],
    ),
    'changed_paths': artifacts.changedPaths,
  };
}

Future<JsonMap> _runOrdinaryAdaptiveMissingReviewScenario(
  Directory workspaceRoot,
) async {
  final harness = await _DraftRuntimeHarness.create(
    workspaceRoot: workspaceRoot,
    scenarioId: 'ordinary_adaptive_missing_review',
  );
  await _saveExpressionConstraintBinding(
    profileRepository: harness.profileRepository,
    bindingRepository: harness.bindingRepository,
    project: harness.project,
  );
  final preparation = await harness.service.prepareDraftRun(
    harness.project,
    taskType: 'chapter',
    pinnedRelativePaths: const <String>['outline/总纲.md'],
  );
  final artifacts = await harness.service.finalizeDraftRun(
    project: harness.project,
    preparation: preparation,
    result: _chapterDraftResult(harness.project),
    title: '第01章',
  );
  final constraints = ValueReaders.mapValue(
    artifacts.writingExecutionResult['constraints'],
  );
  final projection = const ExpressionConstraintStatusProjectionService()
      .fromWritingExecutionResult(artifacts.writingExecutionResult);
  final scenarioOk =
      ValueReaders.stringValue(
            constraints['expression_constraint_policy_mode'],
          ) ==
          ExpressionConstraintExecutionPolicyModes.adaptive &&
      ValueReaders.boolValue(constraints['expression_constraint_applied']) &&
      ValueReaders.boolValue(
        constraints['expression_constraint_evidence_missing'],
      ) &&
      ValueReaders.stringValue(
            artifacts.writingExecutionResult['overall_status'],
          ) ==
          WritingExecutionOutcomeStatuses.contentQualityIssue &&
      projection.blocksRepair;
  return <String, Object?>{
    'id': 'ordinary_adaptive_missing_review',
    'layer': 'conversation_runtime_finalize',
    'ok': scenarioOk,
    'report_category': ProbeReportCategories.contentQualityFailure,
    'expected_report_category': ProbeReportCategories.contentQualityFailure,
    'policy_mode': ValueReaders.stringValue(
      constraints['expression_constraint_policy_mode'],
    ),
    'status_projection': projection.toJson(),
    'overall_status': ValueReaders.stringValue(
      artifacts.writingExecutionResult['overall_status'],
    ),
    'probe_execution_report': buildExpressionConstraintProbeReport(
      writingExecutionResult: artifacts.writingExecutionResult,
      chapterDelivery: artifacts.chapterDelivery,
    ),
    'hard_gate_reasons': ValueReaders.stringList(
      constraints['hard_gate_reasons'],
    ),
    'summary': ValueReaders.stringValue(
      artifacts.writingExecutionResult['summary'],
    ),
  };
}

JsonMap _runOrdinaryForceRepairScenario() {
  final result = WritingExecutionResultNormalizerService().normalize(
    executionId: 'ordinary_force_repair',
    workflowKind: 'ordinary_project',
    constraintBridgeResult: _forceConstraintBridge(),
    chapterLengthEvaluation: _balancedEvaluation(),
    expressionConstraintReview: const ExpressionConstraintReviewProjection(
      authenticityPassLevel:
          ExpressionConstraintReviewProjection.authenticityAggressive,
      continuityWatchItems: <String>['视角泄漏'],
      miniRecheckItems: <String>['检查是否越过当前角色可知边界'],
    ),
  );
  final constraints = result.constraints.toJson();
  final projection = const ExpressionConstraintStatusProjectionService()
      .fromWritingExecutionResult(result.toJson());
  final scenarioOk =
      result.overallStatus ==
          WritingExecutionOutcomeStatuses.contentQualityIssue &&
      result.constraints.expressionConstraintPolicyMode ==
          ExpressionConstraintExecutionPolicyModes.force &&
      result.constraints.expressionConstraintGate.repairRequired &&
      projection.blocksRepair;
  return <String, Object?>{
    'id': 'ordinary_force_repair',
    'layer': 'core_shared_contract',
    'ok': scenarioOk,
    'report_category': ProbeReportCategories.contentQualityFailure,
    'expected_report_category': ProbeReportCategories.contentQualityFailure,
    'policy_mode': result.constraints.expressionConstraintPolicyMode,
    'overall_status': result.overallStatus,
    'status_projection': projection.toJson(),
    'probe_execution_report': buildExpressionConstraintProbeReport(
      writingExecutionResult: result.toJson(),
    ),
    'hard_gate_reasons': ValueReaders.stringList(
      constraints['hard_gate_reasons'],
    ),
    'summary': result.summary,
  };
}

Future<JsonMap> _runDeconstructionFollowupIntentScenario(
  Directory workspaceRoot,
) async {
  final harness = await _DraftRuntimeHarness.create(
    workspaceRoot: workspaceRoot,
    scenarioId: 'deconstruction_followup_intent',
  );
  await _saveExpressionConstraintBinding(
    profileRepository: harness.profileRepository,
    bindingRepository: harness.bindingRepository,
    project: harness.project,
  );
  final preparation = await harness.service.prepareDraftRun(
    harness.project,
    taskType: 'book_deconstruction_followup',
    pinnedRelativePaths: const <String>['outline/总纲.md'],
  );
  final constraints = preparation.executionConstraints;
  final scenarioOk =
      ValueReaders.stringValue(
            constraints['expression_constraint_injection_strength'],
          ) ==
          ExpressionConstraintInjectionStrengths.brief &&
      ValueReaders.stringValue(
            constraints['expression_constraint_review_requirement'],
          ) ==
          ExpressionConstraintReviewRequirements.whenApplied &&
      ValueReaders.stringList(
        constraints['expression_constraint_applied_reasons'],
      ).contains('deconstruction_turn');
  return <String, Object?>{
    'id': 'deconstruction_followup_intent',
    'layer': 'conversation_runtime_prepare',
    'ok': scenarioOk,
    'report_category': ProbeReportCategories.success,
    'expected_report_category': ProbeReportCategories.success,
    'policy_mode': ValueReaders.stringValue(
      constraints['expression_constraint_policy_mode'],
    ),
    'injection_strength': ValueReaders.stringValue(
      constraints['expression_constraint_injection_strength'],
    ),
    'applied_reasons': ValueReaders.stringList(
      constraints['expression_constraint_applied_reasons'],
    ),
    'summary': ValueReaders.stringValue(
      constraints['session_context_markdown'],
      'deconstruction followup mapped to brief summary intent.',
    ),
  };
}

Future<JsonMap> _runDeconstructionContinuationIntentScenario(
  Directory workspaceRoot,
) async {
  final harness = await _DraftRuntimeHarness.create(
    workspaceRoot: workspaceRoot,
    scenarioId: 'deconstruction_continuation_intent',
  );
  await _saveExpressionConstraintBinding(
    profileRepository: harness.profileRepository,
    bindingRepository: harness.bindingRepository,
    project: harness.project,
  );
  final preparation = await harness.service.prepareDraftRun(
    harness.project,
    taskType: 'book_deconstruction_continuation',
    pinnedRelativePaths: const <String>['outline/总纲.md'],
  );
  final constraints = preparation.executionConstraints;
  final scenarioOk =
      ValueReaders.stringValue(
            constraints['expression_constraint_injection_strength'],
          ) ==
          ExpressionConstraintInjectionStrengths.sections &&
      ValueReaders.stringList(
        constraints['expression_constraint_applied_reasons'],
      ).contains('primary_writing_turn') &&
      !ValueReaders.boolValue(
        constraints['expression_constraint_technical_turn_excluded'],
      );
  return <String, Object?>{
    'id': 'deconstruction_continuation_intent',
    'layer': 'conversation_runtime_prepare',
    'ok': scenarioOk,
    'report_category': ProbeReportCategories.success,
    'expected_report_category': ProbeReportCategories.success,
    'policy_mode': ValueReaders.stringValue(
      constraints['expression_constraint_policy_mode'],
    ),
    'injection_strength': ValueReaders.stringValue(
      constraints['expression_constraint_injection_strength'],
    ),
    'applied_reasons': ValueReaders.stringList(
      constraints['expression_constraint_applied_reasons'],
    ),
    'summary': 'deconstruction continuation stays on primary writing bridge.',
  };
}

Future<JsonMap> _runExplainerSummaryForceIntentScenario(
  Directory workspaceRoot,
) async {
  final harness = await _DraftRuntimeHarness.create(
    workspaceRoot: workspaceRoot,
    scenarioId: 'explainer_summary_force_intent',
  );
  await _saveExpressionConstraintBinding(
    profileRepository: harness.profileRepository,
    bindingRepository: harness.bindingRepository,
    project: harness.project,
  );
  final preparation = await harness.service.prepareDraftRun(
    harness.project,
    taskType: 'book_explainer_summary',
    pinnedRelativePaths: const <String>['outline/总纲.md'],
    expressionConstraintPolicyMode:
        ExpressionConstraintExecutionPolicyModes.force,
  );
  final constraints = preparation.executionConstraints;
  final scenarioOk =
      ValueReaders.stringValue(
            constraints['expression_constraint_injection_strength'],
          ) ==
          ExpressionConstraintInjectionStrengths.full &&
      ValueReaders.stringValue(
            constraints['expression_constraint_violation_disposition'],
          ) ==
          ExpressionConstraintViolationDispositions.repair;
  return <String, Object?>{
    'id': 'explainer_summary_force_intent',
    'layer': 'conversation_runtime_prepare',
    'ok': scenarioOk,
    'report_category': ProbeReportCategories.success,
    'expected_report_category': ProbeReportCategories.success,
    'policy_mode': ValueReaders.stringValue(
      constraints['expression_constraint_policy_mode'],
    ),
    'injection_strength': ValueReaders.stringValue(
      constraints['expression_constraint_injection_strength'],
    ),
    'violation_disposition': ValueReaders.stringValue(
      constraints['expression_constraint_violation_disposition'],
    ),
    'summary': 'explainer summary force mode keeps full constraint injection.',
  };
}

Future<JsonMap> _runResearchSummaryExclusionScenario(
  Directory workspaceRoot,
) async {
  final harness = await _DraftRuntimeHarness.create(
    workspaceRoot: workspaceRoot,
    scenarioId: 'research_summary_exclusion',
  );
  await _saveExpressionConstraintBinding(
    profileRepository: harness.profileRepository,
    bindingRepository: harness.bindingRepository,
    project: harness.project,
  );
  final preparation = await harness.service.prepareDraftRun(
    harness.project,
    taskType: 'book_deconstruction_research_summary',
    pinnedRelativePaths: const <String>['outline/总纲.md'],
    expressionConstraintPolicyMode:
        ExpressionConstraintExecutionPolicyModes.force,
  );
  final constraints = preparation.executionConstraints;
  final skippedReasons = ValueReaders.stringList(
    constraints['expression_constraint_skipped_reasons'],
  );
  final scenarioOk =
      !ValueReaders.boolValue(constraints['expression_constraint_applied']) &&
      ValueReaders.boolValue(
        constraints['expression_constraint_technical_turn_excluded'],
      ) &&
      skippedReasons.contains('research_execution_turn');
  return <String, Object?>{
    'id': 'research_summary_exclusion',
    'layer': 'conversation_runtime_prepare',
    'ok': scenarioOk,
    'report_category': ProbeReportCategories.success,
    'expected_report_category': ProbeReportCategories.success,
    'policy_mode': ValueReaders.stringValue(
      constraints['expression_constraint_policy_mode'],
    ),
    'technical_turn_excluded': ValueReaders.boolValue(
      constraints['expression_constraint_technical_turn_excluded'],
    ),
    'skipped_reasons': skippedReasons,
    'summary':
        'research summary remains under information-discipline priority.',
  };
}

Future<JsonMap> _runToolProtocolExclusionScenario(
  Directory workspaceRoot,
) async {
  final harness = await _DraftRuntimeHarness.create(
    workspaceRoot: workspaceRoot,
    scenarioId: 'tool_protocol_exclusion',
  );
  await _saveExpressionConstraintBinding(
    profileRepository: harness.profileRepository,
    bindingRepository: harness.bindingRepository,
    project: harness.project,
  );
  final constraints = await harness.runtimeService.resolve(
    harness.project,
    appliesTo: ConstraintBindingAppliesTo.writing,
    intent: 'tool',
    taskType: 'tool_only',
    phase: 'tool_protocol',
    stageId: 'tool_protocol',
    expressionConstraintPolicyMode:
        ExpressionConstraintExecutionPolicyModes.force,
  );
  final skippedReasons = ValueReaders.stringList(
    constraints['expression_constraint_skipped_reasons'],
  );
  final scenarioOk =
      !ValueReaders.boolValue(constraints['expression_constraint_applied']) &&
      ValueReaders.boolValue(
        constraints['expression_constraint_technical_turn_excluded'],
      ) &&
      skippedReasons.contains('tool_protocol_turn');
  return <String, Object?>{
    'id': 'tool_protocol_exclusion',
    'layer': 'constraint_runtime_resolve',
    'ok': scenarioOk,
    'report_category': ProbeReportCategories.success,
    'expected_report_category': ProbeReportCategories.success,
    'policy_mode': ValueReaders.stringValue(
      constraints['expression_constraint_policy_mode'],
    ),
    'technical_turn_excluded': ValueReaders.boolValue(
      constraints['expression_constraint_technical_turn_excluded'],
    ),
    'skipped_reasons': skippedReasons,
    'summary': 'tool protocol turn is excluded from expression constraints.',
  };
}

Future<JsonMap> _runPathResolutionExclusionScenario(
  Directory workspaceRoot,
) async {
  final harness = await _DraftRuntimeHarness.create(
    workspaceRoot: workspaceRoot,
    scenarioId: 'path_resolution_exclusion',
  );
  await _saveExpressionConstraintBinding(
    profileRepository: harness.profileRepository,
    bindingRepository: harness.bindingRepository,
    project: harness.project,
  );
  final constraints = await harness.runtimeService.resolve(
    harness.project,
    appliesTo: ConstraintBindingAppliesTo.writing,
    intent: 'draft',
    taskType: 'path_resolution',
    phase: 'path_resolution',
    stageId: 'path_resolution',
    expressionConstraintPolicyMode:
        ExpressionConstraintExecutionPolicyModes.force,
  );
  final skippedReasons = ValueReaders.stringList(
    constraints['expression_constraint_skipped_reasons'],
  );
  final scenarioOk =
      !ValueReaders.boolValue(constraints['expression_constraint_applied']) &&
      ValueReaders.boolValue(
        constraints['expression_constraint_technical_turn_excluded'],
      ) &&
      skippedReasons.contains('path_resolution_turn');
  return <String, Object?>{
    'id': 'path_resolution_exclusion',
    'layer': 'constraint_runtime_resolve',
    'ok': scenarioOk,
    'report_category': ProbeReportCategories.success,
    'expected_report_category': ProbeReportCategories.success,
    'policy_mode': ValueReaders.stringValue(
      constraints['expression_constraint_policy_mode'],
    ),
    'technical_turn_excluded': ValueReaders.boolValue(
      constraints['expression_constraint_technical_turn_excluded'],
    ),
    'skipped_reasons': skippedReasons,
    'summary': 'path resolution turn stays clean and unpolluted.',
  };
}

JsonMap _runDuplicateChapterPathRegressionScenario() {
  final projection = const ChapterDeliveryOutcomeProjectionService()
      .fromPayload(
        toolName: NarrativeDomainToolNames.submitChapterDelivery,
        outcomeStatus: DomainToolOutcomeStatuses.accepted,
        payload: <String, Object?>{
          'delivery_id': 'delivery-004',
          'chapter_path': 'chapters/第04章_第04章.md',
          'requested_chapter_path': 'chapters\\..\\chapters\\第04章_第04章.md',
          'resolved_chapter_path': 'chapters/第04章_第04章.md',
          'title': '',
          'delivery_state': 'delivered',
          'chapter_body_state': 'delivered',
          'sidecar_state': 'accepted',
          'state_result': const <String, Object?>{
            'state': 'delivered',
            'chapter_body_delivered': true,
            'submission_accepted': true,
          },
          'path_resolution': const <String, Object?>{
            'requested_path': 'chapters/第04章_第04章.md',
            'resolved_path': 'chapters/第04章_第04章.md',
            'chapter_number': 4,
          },
          'submission': const <String, Object?>{
            'submission_id': 'submission-004',
            'chapter_ref': <String, Object?>{
              'ref_type': NarrativeRefTypes.chapter,
              'ref_id': 'chapters/第04章_第04章.md',
              'relative_path': 'chapters/第04章_第04章.md',
            },
          },
        },
      );
  final pathResolution = ValueReaders.mapValue(projection['path_resolution']);
  final scenarioOk =
      ValueReaders.stringValue(projection['chapter_path']) ==
          'chapters/第04章.md' &&
      ValueReaders.stringValue(projection['resolved_chapter_path']) ==
          'chapters/第04章.md' &&
      ValueReaders.stringValue(projection['title']) == '第04章' &&
      ValueReaders.boolValue(pathResolution['path_changed']);
  return <String, Object?>{
    'id': 'duplicate_chapter_path_regression',
    'layer': 'chapter_delivery_projection',
    'ok': scenarioOk,
    'report_category': ProbeReportCategories.pathFailure,
    'expected_report_category': ProbeReportCategories.pathFailure,
    'resolved_chapter_path': ValueReaders.stringValue(
      projection['resolved_chapter_path'],
    ),
    'probe_execution_report': buildExpressionConstraintProbeReport(
      chapterDelivery: projection,
    ),
    'path_resolution': pathResolution,
    'summary':
        'duplicate chapter path normalized back to canonical chapter file.',
  };
}

JsonMap _runWaitingUserScenario() {
  final result = WritingExecutionResultNormalizerService().normalize(
    executionId: 'waiting_user_probe',
    workflowKind: 'ordinary_project',
    informationSignal: const <String, Object?>{
      'category': 'checkpoint_user',
      'reason': 'information_waiting_user',
      'summary': '待确认是否继续补研究。',
      'waiting_user': true,
      'changed_paths': <Object?>[
        '.novel_agent/information/research_requests/request_1.json',
      ],
    },
    recoveryPlan: const <String, Object?>{
      'action': 'resume_when_user_confirms',
      'reason': 'information_waiting_user',
      'note': '最近一步要求先等用户确认。',
      'safe_after_crash': true,
    },
  );
  final scenarioOk =
      result.overallStatus ==
          WritingExecutionOutcomeStatuses.userActionRequired &&
      result.requiresUserAction &&
      result.recovery.waitingUser;
  return <String, Object?>{
    'id': 'waiting_user_contract',
    'layer': 'core_shared_contract',
    'ok': scenarioOk,
    'report_category': ProbeReportCategories.waitingUser,
    'expected_report_category': ProbeReportCategories.waitingUser,
    'overall_status': result.overallStatus,
    'probe_execution_report': buildExpressionConstraintProbeReport(
      writingExecutionResult: result.toJson(),
    ),
    'next_action': result.nextAction,
    'summary': result.summary,
  };
}

JsonMap _runTechnicalFailureScenario() {
  final result = WritingExecutionResultNormalizerService().normalize(
    executionId: 'technical_failure_probe',
    workflowKind: 'ordinary_project',
    recoveryPlan: const <String, Object?>{
      'action': 'pause_for_failure',
      'reason': 'failed_task',
      'note': 'mock transport failed',
    },
    transportFailed: true,
  );
  final scenarioOk =
      result.overallStatus ==
          WritingExecutionOutcomeStatuses.technicalFailure &&
      result.blocksProgress &&
      result.retryable;
  return <String, Object?>{
    'id': 'technical_failure_contract',
    'layer': 'core_shared_contract',
    'ok': scenarioOk,
    'report_category': ProbeReportCategories.technicalFailure,
    'expected_report_category': ProbeReportCategories.technicalFailure,
    'overall_status': result.overallStatus,
    'probe_execution_report': buildExpressionConstraintProbeReport(
      writingExecutionResult: result.toJson(),
    ),
    'next_action': result.nextAction,
    'summary': result.summary,
  };
}

JsonMap _summaryForScenarios(List<JsonMap> scenarios) {
  final categoryCounts = <String, int>{};
  var passed = 0;
  for (final scenario in scenarios) {
    if (ValueReaders.boolValue(scenario['ok'])) {
      passed += 1;
    }
    final category = ValueReaders.stringValue(scenario['report_category']);
    categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
  }
  return <String, Object?>{
    'total_scenarios': scenarios.length,
    'passed_scenarios': passed,
    'failed_scenarios': scenarios.length - passed,
    'category_counts': categoryCounts,
  };
}

String _renderMarkdown(JsonMap report) {
  final lines = <String>[
    '# ECP-13 Expression Constraint Mock Probe Report',
    '',
    '- run_id: ${ValueReaders.stringValue(report['run_id'])}',
    '- workspace_root: ${ValueReaders.stringValue(report['workspace_root'])}',
    '- total_scenarios: ${ValueReaders.intValue(ValueReaders.mapValue(report['summary'])['total_scenarios'])}',
    '- passed_scenarios: ${ValueReaders.intValue(ValueReaders.mapValue(report['summary'])['passed_scenarios'])}',
    '- failed_scenarios: ${ValueReaders.intValue(ValueReaders.mapValue(report['summary'])['failed_scenarios'])}',
    '',
    '## Scenarios',
  ];
  for (final rawScenario in ValueReaders.mapList(report['scenarios'])) {
    final scenario = ValueReaders.mapValue(rawScenario);
    lines.add('');
    lines.add(
      '- ${ValueReaders.boolValue(scenario['ok']) ? 'PASS' : 'FAIL'}'
      ' ${ValueReaders.stringValue(scenario['id'])}'
      ' | layer=${ValueReaders.stringValue(scenario['layer'])}'
      ' | report=${ValueReaders.stringValue(scenario['report_category'])}',
    );
    lines.add('  summary: ${ValueReaders.stringValue(scenario['summary'])}');
  }
  return lines.join('\n');
}

class _DraftRuntimeHarness {
  _DraftRuntimeHarness({
    required this.project,
    required this.profileRepository,
    required this.bindingRepository,
    required this.runtimeService,
    required this.service,
  });

  final ProjectDescriptor project;
  final ExpressionConstraintProfileRepository profileRepository;
  final ProjectExpressionConstraintBindingRepository bindingRepository;
  final ProjectDraftExecutionConstraintRuntimeService runtimeService;
  final ProjectConversationDraftRuntimeService service;

  static Future<_DraftRuntimeHarness> create({
    required Directory workspaceRoot,
    required String scenarioId,
  }) async {
    final projectRoot = Directory(
      '${workspaceRoot.path}${Platform.pathSeparator}$scenarioId',
    );
    await projectRoot.create(recursive: true);
    final workspacePort = LocalProjectWorkspacePort();
    final hostPort = ProjectWorkspaceToolHostAdapter(
      workspacePort: workspacePort,
      fileMutationAdapter: LocalProjectFileMutationAdapter(),
    );
    final taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
    final project = ProjectDescriptor(
      id: 'mock_expression_$scenarioId',
      name: 'Mock Expression $scenarioId',
      rootPath: projectRoot.path,
      projectType: 'long_novel',
    );
    await _seedProject(workspacePort: workspacePort, project: project);
    return _DraftRuntimeHarness(
      project: project,
      profileRepository: ExpressionConstraintProfileRepository(
        workspacePort: workspacePort,
      ),
      bindingRepository: ProjectExpressionConstraintBindingRepository(
        workspacePort: workspacePort,
      ),
      runtimeService:
          ProjectDraftExecutionConstraintRuntimeService.fromWorkspacePort(
            workspacePort: workspacePort,
          ),
      service: ProjectConversationDraftRuntimeService(
        workspacePort: workspacePort,
        hostPort: hostPort,
        taskRepository: taskRepository,
      ),
    );
  }
}

Future<void> _seedProject({
  required LocalProjectWorkspacePort workspacePort,
  required ProjectDescriptor project,
}) async {
  await workspacePort.writeTextFile(
    project.rootPath,
    'outline/总纲.md',
    '# 总纲\n第一章是回京夜雨。',
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'styles/default.md',
    '# 风格\n保持冷峻，少解释。',
  );
}

Future<void> _saveExpressionConstraintBinding({
  required ExpressionConstraintProfileRepository profileRepository,
  required ProjectExpressionConstraintBindingRepository bindingRepository,
  required ProjectDescriptor project,
}) async {
  await profileRepository.saveProjectProfiles(
    project,
    const <ExpressionConstraintProfile>[
      ExpressionConstraintProfile(
        id: 'project_natural_expression',
        displayName: '项目自然表达',
        summary: '项目级自然表达约束。',
        kind: ExpressionConstraintKind.naturalExpression,
        rules: <String>['压低解释腔。'],
      ),
    ],
  );
  await bindingRepository
      .saveBindings(project, const <ProjectExpressionConstraintBinding>[
        ProjectExpressionConstraintBinding(
          id: 'project_binding_1',
          profileId: 'project_natural_expression',
          defaultForProject: true,
        ),
      ]);
}

DraftGenerationResult _chapterDraftResult(ProjectDescriptor project) {
  return DraftGenerationResult(
    project: project,
    projectInfo: <String, Object?>{
      'id': project.id,
      'title': project.name,
      'path': project.rootPath,
      'project_type': project.projectType,
    },
    userPrompt: '继续写第一章',
    prompt: '继续写第一章',
    modelId: 'test-model',
    draftMarkdown: '# 第01章\n\n夜雨沿着宫墙流下，回京的人还是回头了。',
    contextPack: const <String, Object?>{},
    selectedPaths: const <String>['outline/总纲.md'],
    executedTools: const <Object?>[
      <String, Object?>{
        'id': 'call_write_1',
        'name': 'write_project_file',
        'arguments': <String, Object?>{
          'content_type': 'chapter',
          'title': '第01章',
          'content': '# 第01章\n\n夜雨沿着宫墙流下，回京的人还是回头了。',
        },
        'result': <String, Object?>{
          'ok': true,
          'relative_path': 'chapters/chapter_01.md',
          'changed_paths': <Object?>['chapters/chapter_01.md'],
        },
        'ok': true,
      },
    ],
    writtenPaths: const <String>['chapters/chapter_01.md'],
    changedPaths: const <String>['chapters/chapter_01.md'],
    transcriptMessages: const <JsonMap>[],
    waitingForUserChoice: false,
    reasoningContent: '',
    stoppedByToolError: false,
    toolErrorSummary: '',
  );
}

WritingExecutionConstraintBridgeResult _forceConstraintBridge() {
  return const WritingExecutionConstraintBridgeResult(
    expressionConstraintProfiles: <ExpressionConstraintProfile>[
      ExpressionConstraintProfile(
        id: 'strict_pov_boundary',
        displayName: '严格 POV 边界',
        summary: '限制未知信息越界。',
        kind: ExpressionConstraintKind.narrativeBoundary,
        rules: <String>['只保留 POV 可知信息。'],
      ),
    ],
    projectExpressionConstraintBindings: <ProjectExpressionConstraintBinding>[
      ProjectExpressionConstraintBinding(
        id: 'binding_1',
        profileId: 'strict_pov_boundary',
        defaultForProject: true,
      ),
    ],
    expressionConstraintPolicyMode:
        ExpressionConstraintExecutionPolicyModes.force,
    expressionConstraintInjectionStrength:
        ExpressionConstraintInjectionStrengths.full,
    expressionConstraintReviewRequirement:
        ExpressionConstraintReviewRequirements.alwaysForWriting,
    expressionConstraintViolationDisposition:
        ExpressionConstraintViolationDispositions.repair,
    expressionConstraintApplied: true,
    expressionConstraintInjectionMode: 'brief_and_sections',
    expressionConstraintReviewRequired: true,
  );
}

ChapterLengthEvaluation _balancedEvaluation() {
  return ChapterLengthEvaluation(
    profile: const ChapterLengthProfile(
      enabled: true,
      targetLength: 2200,
      preferredMin: 1800,
      preferredMax: 2600,
      stage: 'draft',
    ),
    policy: const ChapterLengthDistributionPolicy(),
    currentRecord: const ChapterLengthRecord(
      length: 2180,
      sortOrder: 1,
      taskId: 'chapter_001',
      relativePath: 'chapters/ch01.md',
    ),
    level: 'balanced',
    recommendedAction: 'pass',
    notes: const <String>['当前章长度分布基本稳定，可直接继续。'],
  );
}
