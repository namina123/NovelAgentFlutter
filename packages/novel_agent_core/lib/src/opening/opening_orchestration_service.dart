import '../modes/mode_guidance_state.dart';
import '../project/project_descriptor.dart';
import '../project/project_fact_acquisition_contract_service.dart';
import '../project/project_type_catalog_service.dart';
import 'opening_intent_snapshot.dart';
import 'opening_next_action_resolver.dart';
import 'opening_orchestration_result.dart';
import 'opening_readiness_assessment.dart';
import 'opening_readiness_evaluator.dart';
import 'opening_session_state.dart';
import 'opening_stage_record_builder_service.dart';
import 'opening_stage_record.dart';

class OpeningOrchestrationService {
  OpeningOrchestrationService({
    ProjectTypeCatalogService? projectTypeCatalogService,
    OpeningReadinessEvaluator? readinessEvaluator,
    OpeningNextActionResolver? nextActionResolver,
    OpeningStageRecordBuilderService? stageRecordBuilderService,
    ProjectFactAcquisitionContractService? factAcquisitionContractService,
  }) : _projectTypeCatalogService =
           projectTypeCatalogService ?? const ProjectTypeCatalogService(),
       _readinessEvaluator = readinessEvaluator ?? OpeningReadinessEvaluator(),
       _nextActionResolver = nextActionResolver ?? OpeningNextActionResolver(),
       _stageRecordBuilderService =
           stageRecordBuilderService ?? OpeningStageRecordBuilderService(),
       _factAcquisitionContractService =
           factAcquisitionContractService ??
           const ProjectFactAcquisitionContractService();

  final ProjectTypeCatalogService _projectTypeCatalogService;
  final OpeningReadinessEvaluator _readinessEvaluator;
  final OpeningNextActionResolver _nextActionResolver;
  final OpeningStageRecordBuilderService _stageRecordBuilderService;
  final ProjectFactAcquisitionContractService _factAcquisitionContractService;

  OpeningOrchestrationResult orchestrate({
    required ProjectDescriptor project,
    required OpeningIntentSnapshot intent,
    ModeGuidanceState? modeGuidanceState,
    OpeningSessionState? previousState,
    String now = '',
  }) {
    // 中文注释: orchestration 负责把项目事实、opening 意图与模式引导收束成一个稳定快照，供 app 后续直接消费。
    final timestamp = now.trim().isNotEmpty
        ? now.trim()
        : DateTime.now().toIso8601String();
    final normalizedProjectType = _projectTypeCatalogService.normalize(
      project.projectType,
    );
    final normalizedIntent = _normalizeIntent(project, intent);
    final baseState = OpeningSessionState(
      projectTypeId: normalizedProjectType,
      status: OpeningSessionState.statusCollecting,
      intent: normalizedIntent,
      stageRecords: const <OpeningStageRecord>[],
      createdAt: previousState?.createdAt ?? timestamp,
      updatedAt: timestamp,
      modeGuidanceState: modeGuidanceState,
      metadata: <String, Object?>{
        'fact_acquisition_contract': _factAcquisitionContractService
            .build(
              workflowId: normalizedProjectType == 'long_novel'
                  ? 'long_task_opening'
                  : 'interactive_opening',
              projectTypeId: normalizedProjectType,
              intent: normalizedIntent.sessionGoalModeId,
            )
            .toJsonMap(),
      },
    );
    final readiness = _readinessEvaluator.evaluate(baseState);
    final stageRecords = _stageRecordBuilderService.build(
      baseState,
      readiness: readiness,
    );
    final finalState = baseState.copyWith(
      status: _statusFromReadiness(readiness),
      stageRecords: stageRecords,
      updatedAt: timestamp,
    );
    final actions = _nextActionResolver.resolve(
      state: finalState,
      readiness: readiness,
    );
    return OpeningOrchestrationResult(
      state: finalState,
      readiness: readiness,
      suggestedActions: actions,
    );
  }

  OpeningIntentSnapshot _normalizeIntent(
    ProjectDescriptor project,
    OpeningIntentSnapshot intent,
  ) {
    var resolvedAgentGroupId = intent.resolvedAgentGroupId.trim();
    final availableAgentGroupIds = intent.availableAgentGroupIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (resolvedAgentGroupId.isEmpty && availableAgentGroupIds.length == 1) {
      // 中文注释: 只有一个可用组时，把它视为当前有效组，减少不必要的人为确认。
      resolvedAgentGroupId = availableAgentGroupIds.single;
    }
    final runtimeBaselineId = intent.runtimeBaselineId.trim().isNotEmpty
        ? intent.runtimeBaselineId.trim()
        : project.runtimeBaselineId.trim();
    return intent.copyWith(
      resolvedAgentGroupId: resolvedAgentGroupId,
      availableAgentGroupIds: availableAgentGroupIds,
      runtimeBaselineId: runtimeBaselineId,
      modeId: intent.modeId.trim(),
      sessionGoalModeId: intent.sessionGoalModeId.trim(),
      freeTextIntent: intent.freeTextIntent.trim(),
    );
  }

  String _statusFromReadiness(OpeningReadinessAssessment readiness) {
    if (readiness.canStartLongTask) {
      return OpeningSessionState.statusReadyForLongTask;
    }
    if (readiness.canStartInteractiveSession) {
      return OpeningSessionState.statusReadyForInteractiveSession;
    }
    return OpeningSessionState.statusCollecting;
  }
}
