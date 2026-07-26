import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('continuous task control plane regression suite', () {
    test(
      'covers shared long-task and reference-extraction outcomes using production truth contracts',
      () {
        final report = _runContinuousTaskControlPlaneRegressionSuite();
        final summary = ValueReaders.mapValue(report['summary']);
        final scenarios = ValueReaders.mapList(
          report['scenarios'],
        ).map(ValueReaders.mapValue).toList(growable: false);
        final requiredCoverage = ValueReaders.mapList(
          summary['required_coverage'],
        ).map(ValueReaders.mapValue).toList(growable: false);

        expect(ValueReaders.intValue(summary['total_scenarios']), 8);
        expect(ValueReaders.intValue(summary['passed_scenarios']), 8);
        expect(
          ValueReaders.boolValue(summary['all_required_coverage_passed']),
          isTrue,
        );
        expect(
          requiredCoverage.map(
            (item) => ValueReaders.stringValue(item['requirement']),
          ),
          containsAll(const <String>[
            'technical_failure',
            'waiting_user',
            'coverage_incomplete',
            'content_conflict',
            'normal_completion',
          ]),
        );
        expect(
          scenarios.map((scenario) => ValueReaders.stringValue(scenario['id'])),
          containsAll(const <String>[
            'long_task_technical_failure',
            'long_task_waiting_user',
            'long_task_manual_attention',
            'long_task_normal_completion',
            'reference_coverage_incomplete',
            'reference_mount_waiting_user',
            'reference_content_conflict',
            'reference_normal_completion',
          ]),
        );
      },
    );
  });
}

JsonMap _runContinuousTaskControlPlaneRegressionSuite() {
  const supervisorDecisionService = SupervisorDecisionService();
  const lifecycleResolver = ContinuousTaskLifecycleStateResolverService();
  const extractionSignalService = ReferenceExtractionSupervisorSignalService();

  final scenarios = <JsonMap>[
    _longTaskScenario(
      id: 'long_task_technical_failure',
      decisionService: supervisorDecisionService,
      lifecycleResolver: lifecycleResolver,
      result: _longTaskResult(
        overallStatus: WritingExecutionOutcomeStatuses.technicalFailure,
        summary: 'provider 调用失败。',
        retryable: true,
        recovery: const WritingExecutionRecoverySummary(
          present: true,
          recommendedAction: 'pause_for_failure',
          reason: 'provider_transport_failed',
          note: 'provider 调用失败。',
          retryable: true,
        ),
      ),
      requiredCoverage: const <String>['technical_failure'],
    ),
    _longTaskScenario(
      id: 'long_task_waiting_user',
      decisionService: supervisorDecisionService,
      lifecycleResolver: lifecycleResolver,
      result: _longTaskResult(
        overallStatus: WritingExecutionOutcomeStatuses.userActionRequired,
        summary: '等待用户确认是否继续补研究。',
        requiresUserAction: true,
        information: const WritingExecutionInformationSummary(
          present: true,
          riskCategory: 'checkpoint_user',
          reason: 'information_waiting_user',
          summary: '待确认 1 项。',
          waitingUser: true,
          evidenceGate: InformationEvidenceGateSignal(
            present: true,
            severity: InformationEvidenceGateSeverities.blocking,
            recommendedDisposition:
                InformationEvidenceRecommendedDispositions.checkpointUser,
            waitingUser: true,
          ),
        ),
        recovery: const WritingExecutionRecoverySummary(
          present: true,
          recommendedAction: 'resume_when_user_confirms',
          reason: 'information_waiting_user',
          note: '等待用户确认是否继续补研究。',
          waitingUser: true,
        ),
      ),
      requiredCoverage: const <String>['waiting_user'],
    ),
    _longTaskScenario(
      id: 'long_task_manual_attention',
      decisionService: supervisorDecisionService,
      lifecycleResolver: lifecycleResolver,
      result: _longTaskResult(
        overallStatus: WritingExecutionOutcomeStatuses.contentQualityIssue,
        summary: '本轮输出只剩标题，需人工复核。',
        blocksProgress: true,
        delivery: const WritingExecutionDeliverySummary(
          present: true,
          deliveryId: 'delivery_002',
          state: ChapterDeliveryStateStatuses.invalidOutputRewriteRequired,
          recommendedAction: 'request_chapter_repair',
          suggestedOutcomeStatus: DomainToolOutcomeStatuses.invalidPayload,
          reason: 'title_only_output',
          summary: '本轮输出只剩标题，需人工复核。',
          blocksProgress: true,
        ),
      ),
      requiredCoverage: const <String>['content_conflict'],
    ),
    _longTaskScenario(
      id: 'long_task_normal_completion',
      decisionService: supervisorDecisionService,
      lifecycleResolver: lifecycleResolver,
      result: _longTaskResult(
        overallStatus: WritingExecutionOutcomeStatuses.success,
        summary: '章节交付正常，可继续推进。',
      ),
      stopOutcome: const LongTaskStopOutcome(
        present: true,
        category: LongTaskStopOutcomeCategories.completedNaturally,
        reason: 'completed_naturally',
        legacyStopReason: 'completed',
        summary: '章节交付正常，可继续推进。',
        completionReason: 'completed_naturally',
      ),
      requiredCoverage: const <String>['normal_completion'],
    ),
    _referenceScenario(
      id: 'reference_coverage_incomplete',
      signalService: extractionSignalService,
      result: _referenceResult(
        runStatus: ReferenceExtractionRunStatuses.awaitingSemanticContinuation,
        deliveryStatus: ReferenceExtractionDeliveryStatuses.stagingOnly,
        outputCompletionStatus:
            OutputCompletionStatuses.continuationRecommended,
        publishedSnapshotAvailable: false,
        needsContinuation: true,
        coverageRequiresFollowup: true,
        followupSegmentIds: const <String>['segment-2'],
        uncoveredCoverageDimensionIds: const <String>['world_rules'],
      ),
      requiredCoverage: const <String>['coverage_incomplete'],
    ),
    _referenceScenario(
      id: 'reference_mount_waiting_user',
      signalService: extractionSignalService,
      result: _referenceResult(
        projectMountStatus: ProjectReferenceMountStatuses.denied,
        projectMountWarningCodes: const <String>[
          'explicit_confirmation_required',
        ],
      ),
      requiredCoverage: const <String>['waiting_user'],
    ),
    _referenceScenario(
      id: 'reference_content_conflict',
      signalService: extractionSignalService,
      result: _referenceResult(
        requiresManualContinuityReview: true,
        unresolvedConflictCount: 1,
        reviewAlertCount: 1,
      ),
      requiredCoverage: const <String>['content_conflict'],
    ),
    _referenceScenario(
      id: 'reference_normal_completion',
      signalService: extractionSignalService,
      result: _referenceResult(),
      requiredCoverage: const <String>['normal_completion'],
    ),
  ];

  final requirements = <String, bool>{
    'technical_failure': false,
    'waiting_user': false,
    'coverage_incomplete': false,
    'content_conflict': false,
    'normal_completion': false,
  };

  for (final scenario in scenarios) {
    final passed = ValueReaders.boolValue(scenario['passed']);
    if (!passed) {
      continue;
    }
    for (final requirement in ValueReaders.stringList(
      scenario['covered_requirements'],
    )) {
      if (requirements.containsKey(requirement)) {
        requirements[requirement] = true;
      }
    }
  }

  return <String, Object?>{
    'summary': <String, Object?>{
      'total_scenarios': scenarios.length,
      'passed_scenarios': scenarios
          .where((item) => ValueReaders.boolValue(item['passed']))
          .length,
      'all_required_coverage_passed': requirements.values.every((item) => item),
      'required_coverage': requirements.entries
          .map(
            (entry) => <String, Object?>{
              'requirement': entry.key,
              'passed': entry.value,
            },
          )
          .toList(growable: false),
    },
    'scenarios': scenarios,
  };
}

JsonMap _longTaskScenario({
  required String id,
  required SupervisorDecisionService decisionService,
  required ContinuousTaskLifecycleStateResolverService lifecycleResolver,
  required WritingExecutionResult result,
  required List<String> requiredCoverage,
  LongTaskStopOutcome? stopOutcome,
}) {
  final effectiveStopOutcome =
      stopOutcome ??
      const LongTaskStopOutcomeResolverService().fromWritingExecutionResult(
        result,
      );
  final bundle = SupervisorInputBundle.fromWritingExecutionResult(
    result,
    stopOutcome: effectiveStopOutcome,
  );
  final decision = decisionService.decide(bundle);
  final lifecycle = lifecycleResolver.fromLongTask(
    status: LongTaskRunStatus.fromId(decision.runStatus),
    stopOutcome: decision.stopOutcome,
    legacyStopReason: decision.legacyStopReason,
  );
  final passed = _matchesExpected(
    id: id,
    runPhase: lifecycle.runPhase,
    stopCategory: lifecycle.stopCategory,
  );
  return <String, Object?>{
    'id': id,
    'family': 'long_task',
    'truth_contract':
        'SupervisorDecisionService + ContinuousTaskLifecycleStateResolverService',
    'decision_action': decision.action,
    'decision_reason': decision.reason,
    'run_status': decision.runStatus,
    'stop_outcome': decision.stopOutcome.toJson(),
    'lifecycle_state': lifecycle.toJson(),
    'covered_requirements': requiredCoverage,
    'passed': passed,
  };
}

JsonMap _referenceScenario({
  required String id,
  required ReferenceExtractionSupervisorSignalService signalService,
  required ProjectReferenceExtractionResult result,
  required List<String> requiredCoverage,
}) {
  final signal = signalService.build(result);
  final passed = _matchesExpected(
    id: id,
    runPhase: signal.lifecycleState.runPhase,
    stopCategory: signal.lifecycleState.stopCategory,
  );
  return <String, Object?>{
    'id': id,
    'family': 'reference_extraction',
    'truth_contract': 'ReferenceExtractionSupervisorSignalService',
    'lifecycle_state': signal.lifecycleState.toJson(),
    'metadata': signal.metadata,
    'covered_requirements': requiredCoverage,
    'passed': passed,
  };
}

bool _matchesExpected({
  required String id,
  required String runPhase,
  required String stopCategory,
}) {
  return switch (id) {
    'long_task_technical_failure' =>
      runPhase == ContinuousTaskRunPhases.paused &&
          stopCategory == ContinuousTaskStopCategories.technicalFailure,
    'long_task_waiting_user' =>
      runPhase == ContinuousTaskRunPhases.waitingUser &&
          stopCategory == ContinuousTaskStopCategories.waitingUser,
    'long_task_manual_attention' =>
      runPhase == ContinuousTaskRunPhases.manualAttention &&
          stopCategory == ContinuousTaskStopCategories.manualAttention,
    'long_task_normal_completion' =>
      runPhase == ContinuousTaskRunPhases.running &&
          stopCategory == ContinuousTaskStopCategories.completedNaturally,
    'reference_coverage_incomplete' =>
      runPhase == ContinuousTaskRunPhases.paused &&
          stopCategory == ContinuousTaskStopCategories.constraintGatePause,
    'reference_mount_waiting_user' =>
      runPhase == ContinuousTaskRunPhases.waitingUser &&
          stopCategory == ContinuousTaskStopCategories.waitingUser,
    'reference_content_conflict' =>
      runPhase == ContinuousTaskRunPhases.manualAttention &&
          stopCategory == ContinuousTaskStopCategories.manualAttention,
    'reference_normal_completion' =>
      runPhase == ContinuousTaskRunPhases.stopped &&
          stopCategory == ContinuousTaskStopCategories.completedNaturally,
    _ => false,
  };
}

WritingExecutionResult _longTaskResult({
  required String overallStatus,
  required String summary,
  WritingExecutionDeliverySummary delivery =
      const WritingExecutionDeliverySummary(),
  WritingExecutionConstraintSummary constraints =
      const WritingExecutionConstraintSummary(),
  WritingExecutionInformationSummary information =
      const WritingExecutionInformationSummary(),
  WritingExecutionCollaborationSummary collaboration =
      const WritingExecutionCollaborationSummary(),
  WritingExecutionRecoverySummary recovery =
      const WritingExecutionRecoverySummary(),
  String nextAction = '',
  bool blocksProgress = false,
  bool retryable = false,
  bool requiresUserAction = false,
}) {
  return WritingExecutionResult(
    executionId: 'suite_exec_${overallStatus}_001',
    workflowKind: 'long_task',
    overallStatus: overallStatus,
    summary: summary,
    delivery: delivery,
    constraints: constraints,
    information: information,
    collaboration: collaboration,
    recovery: recovery,
    nextAction: nextAction,
    blocksProgress: blocksProgress,
    retryable: retryable,
    requiresUserAction: requiresUserAction,
  );
}

ProjectReferenceExtractionResult _referenceResult({
  String runStatus = ReferenceExtractionRunStatuses.completedPublishable,
  String deliveryStatus = ReferenceExtractionDeliveryStatuses.publishable,
  String outputCompletionStatus = OutputCompletionStatuses.completed,
  bool publishedSnapshotAvailable = true,
  bool needsContinuation = false,
  bool coverageRequiresFollowup = false,
  bool attachToProjectRequested = true,
  bool projectMountedEntriesRequested = true,
  String projectMountStatus = ProjectReferenceMountStatuses.applied,
  List<String> projectMountWarningCodes = const <String>[],
  bool requiresManualContinuityReview = false,
  int unresolvedConflictCount = 0,
  int reviewAlertCount = 0,
  List<String> followupSegmentIds = const <String>[],
  List<String> uncoveredCoverageDimensionIds = const <String>[],
}) {
  return ProjectReferenceExtractionResult(
    runId: 'reference_suite_run',
    packageId: 'pkg_hp',
    packageVersionId: 'v1',
    sourceFilePath: 'references/harry.txt',
    sourceDecodeMode: 'utf8',
    groupResolutionKind: 'task_family_override',
    selectedGroupId: 'reference_extraction_group',
    strategyProfileId: 'reference_extraction.standard',
    executionConcurrencyMode: ReferenceExtractionConcurrencyModes.single,
    proposalCount: 4,
    acceptedProposalCount: 4,
    finalizedEntryCount: 4,
    batchCount: 2,
    completedBatchCount: 2,
    runStatus: runStatus,
    deliveryStatus: deliveryStatus,
    outputCompletionStatus: outputCompletionStatus,
    needsContinuation: needsContinuation,
    uncoveredCoverageDimensionIds: uncoveredCoverageDimensionIds,
    followupSegmentIds: followupSegmentIds,
    coverageRequiresFollowup: coverageRequiresFollowup,
    reviewAlertCount: reviewAlertCount,
    requiresManualContinuityReview: requiresManualContinuityReview,
    unresolvedConflictCount: unresolvedConflictCount,
    publishedSnapshotAvailable: publishedSnapshotAvailable,
    attachToProjectRequested: attachToProjectRequested,
    projectMountedEntriesRequested: projectMountedEntriesRequested,
    projectMountStatus: projectMountStatus,
    projectMountWarningCodes: projectMountWarningCodes,
  );
}
