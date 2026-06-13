import 'package:novel_agent_core/novel_agent_core.dart';

import 'long_task_supervisor.dart';

class ContinuousTaskSupervisorBridgeService {
  ContinuousTaskSupervisorBridgeService({
    required LongTaskSupervisor supervisor,
    RuntimeBaselineCatalogService? runtimeBaselineCatalogService,
    RunInstanceFactoryService? runInstanceFactoryService,
    ContinuousTaskControlProfileResolverService? controlProfileResolverService,
    ContinuousTaskRecoveryStateFactoryService? recoveryStateFactoryService,
    ContinuousTaskLongTaskStatusMapperService?
    continuousTaskLongTaskStatusMapperService,
  }) : _supervisor = supervisor,
       _runtimeBaselineCatalogService =
           runtimeBaselineCatalogService ??
           const RuntimeBaselineCatalogService(),
       _runInstanceFactoryService =
           runInstanceFactoryService ?? const RunInstanceFactoryService(),
       _controlProfileResolverService =
           controlProfileResolverService ??
           const ContinuousTaskControlProfileResolverService(),
       _recoveryStateFactoryService =
           recoveryStateFactoryService ??
           const ContinuousTaskRecoveryStateFactoryService(),
       _continuousTaskLongTaskStatusMapperService =
           continuousTaskLongTaskStatusMapperService ??
           const ContinuousTaskLongTaskStatusMapperService();

  final LongTaskSupervisor _supervisor;
  final RuntimeBaselineCatalogService _runtimeBaselineCatalogService;
  final RunInstanceFactoryService _runInstanceFactoryService;
  final ContinuousTaskControlProfileResolverService
  _controlProfileResolverService;
  final ContinuousTaskRecoveryStateFactoryService _recoveryStateFactoryService;
  final ContinuousTaskLongTaskStatusMapperService
  _continuousTaskLongTaskStatusMapperService;

  Future<RunInstance> trackTaskFamilyRun({
    required String runId,
    required ProjectDescriptor project,
    required String familyId,
    String workflowStrategyId = '',
    String modeId = '',
    String activeTaskId = '',
    String activeTaskTitle = '',
    ContinuousTaskLifecycleState lifecycleState =
        const ContinuousTaskLifecycleState(
          runPhase: ContinuousTaskRunPhases.running,
        ),
    ReferenceExtractionExecutionDiscipline executionDiscipline =
        const ReferenceExtractionExecutionDiscipline(),
    JsonMap metadata = const <String, Object?>{},
    DateTime? occurredAt,
    String note = '',
  }) async {
    final controlProfile = _resolveControlProfile(
      familyId: familyId,
      workflowStrategyId: workflowStrategyId,
      modeId: modeId,
      executionDiscipline: executionDiscipline,
      metadata: metadata,
    );
    final existing = await _supervisor.loadRun(runId);
    if (existing != null) {
      final updated = await _supervisor.applyContinuousTaskState(
        runId,
        controlProfile: controlProfile,
        lifecycleState: lifecycleState,
        metadata: _decorateMetadata(
          metadata,
          controlProfile: controlProfile,
          lifecycleState: lifecycleState,
        ),
        occurredAt: occurredAt,
        note: note,
      );
      return updated ?? existing;
    }
    final now = occurredAt ?? DateTime.now();
    final initialStatus = _continuousTaskLongTaskStatusMapperService
        .toLongTaskStatus(lifecycleState);
    final instance = _runInstanceFactoryService
        .createLongTaskInstance(
          runId: runId,
          project: project,
          runtimeBaseline: _resolveRuntimeBaseline(project),
          modeId: _effectiveModeId(modeId, controlProfile.taskProfile.runKind),
          workflowStrategyId: _effectiveWorkflowStrategyId(
            workflowStrategyId,
            controlProfile.taskProfile.workflowStrategyId,
          ),
          initialStatus: initialStatus,
          now: now,
        )
        .copyWith(
          activeTaskId: activeTaskId.trim(),
          activeTaskTitle: activeTaskTitle.trim(),
        );
    await _supervisor.trackContinuousTaskRun(
      instance,
      controlProfile: controlProfile,
      lifecycleState: lifecycleState,
      metadata: _decorateMetadata(
        metadata,
        controlProfile: controlProfile,
        lifecycleState: lifecycleState,
      ),
    );
    return (await _supervisor.loadRun(runId)) ?? instance;
  }

  Future<RunInstance?> applyLifecycleState(
    String runId, {
    required ContinuousTaskLifecycleState lifecycleState,
    String familyId = '',
    String workflowStrategyId = '',
    String modeId = '',
    ReferenceExtractionExecutionDiscipline executionDiscipline =
        const ReferenceExtractionExecutionDiscipline(),
    LongTaskRecoveryState recoveryState = const LongTaskRecoveryState(),
    JsonMap metadata = const <String, Object?>{},
    DateTime? occurredAt,
    String note = '',
  }) async {
    final instance = await _supervisor.loadRun(runId);
    if (instance == null) {
      return null;
    }
    final controlProfile = _storedOrResolvedControlProfile(
      instance,
      familyId: familyId,
      workflowStrategyId: workflowStrategyId,
      modeId: modeId,
      executionDiscipline: executionDiscipline,
      metadata: metadata,
    );
    return _supervisor.applyContinuousTaskState(
      runId,
      controlProfile: controlProfile,
      lifecycleState: lifecycleState,
      recoveryState: recoveryState,
      metadata: _decorateMetadata(
        metadata,
        controlProfile: controlProfile,
        lifecycleState: lifecycleState,
      ),
      occurredAt: occurredAt,
      note: note,
    );
  }

  Future<RunInstance?> pauseRun(
    String runId, {
    DateTime? occurredAt,
    String note = '',
    String reason = 'paused_by_supervisor',
  }) {
    return applyLifecycleState(
      runId,
      lifecycleState: ContinuousTaskLifecycleState(
        runPhase: ContinuousTaskRunPhases.paused,
        stopCategory: ContinuousTaskStopCategories.constraintGatePause,
        reason: reason,
      ),
      occurredAt: occurredAt,
      note: note,
    );
  }

  Future<RunInstance?> resumeRun(
    String runId, {
    DateTime? occurredAt,
    String note = '',
    String reason = 'resume_requested',
  }) {
    return applyLifecycleState(
      runId,
      lifecycleState: ContinuousTaskLifecycleState(
        runPhase: ContinuousTaskRunPhases.running,
        reason: reason,
      ),
      occurredAt: occurredAt,
      note: note,
    );
  }

  Future<RunInstance?> recoverRun(
    String runId, {
    DateTime? occurredAt,
    String note = '',
    String reason = 'technical_failure',
  }) {
    return applyLifecycleState(
      runId,
      lifecycleState: ContinuousTaskLifecycleState(
        runPhase: ContinuousTaskRunPhases.recovering,
        stopCategory: ContinuousTaskStopCategories.technicalFailure,
        reason: reason,
      ),
      recoveryState: _recoveryStateFactoryService.resumeReady(
        lifecycleState: ContinuousTaskLifecycleState(
          runPhase: ContinuousTaskRunPhases.recovering,
          stopCategory: ContinuousTaskStopCategories.technicalFailure,
          reason: reason,
        ),
        recommendedAction: 'resume_continuous_task',
        note: note,
        autoRetryEligible: true,
        blocksProgress: true,
      ),
      occurredAt: occurredAt,
      note: note,
    );
  }

  Future<RunInstance?> retryRun(
    String runId, {
    DateTime? occurredAt,
    String note = '',
    String reason = 'retry_requested',
  }) {
    return applyLifecycleState(
      runId,
      lifecycleState: ContinuousTaskLifecycleState(
        runPhase: ContinuousTaskRunPhases.running,
        reason: reason,
      ),
      recoveryState: LongTaskRecoveryState(
        present: true,
        state: LongTaskRecoveryStates.retrying,
        runStatus: LongTaskRunStatus.running.id,
        recommendedAction: 'retry_in_progress',
        reason: reason,
        note: note,
        autoRetryEligible: true,
        blocksProgress: false,
      ),
      occurredAt: occurredAt,
      note: note,
    );
  }

  ContinuousTaskControlProfile _storedOrResolvedControlProfile(
    RunInstance instance, {
    required String familyId,
    required String workflowStrategyId,
    required String modeId,
    required ReferenceExtractionExecutionDiscipline executionDiscipline,
    required JsonMap metadata,
  }) {
    final storedProfile = ValueReaders.mapValue(
      instance.metadata['continuous_task_control_profile'],
    );
    if (storedProfile.isNotEmpty) {
      return ContinuousTaskControlProfile.fromJson(storedProfile);
    }
    final fallbackFamilyId = familyId.trim().isNotEmpty
        ? familyId.trim()
        : ValueReaders.stringValue(
            instance.metadata['continuous_task_family_id'],
          ).trim();
    return _resolveControlProfile(
      familyId: fallbackFamilyId,
      workflowStrategyId: workflowStrategyId,
      modeId: modeId,
      executionDiscipline: executionDiscipline,
      metadata: metadata,
    );
  }

  ContinuousTaskControlProfile _resolveControlProfile({
    required String familyId,
    required String workflowStrategyId,
    required String modeId,
    required ReferenceExtractionExecutionDiscipline executionDiscipline,
    required JsonMap metadata,
  }) {
    return _controlProfileResolverService.resolve(
      familyId: familyId,
      workflowStrategyId: workflowStrategyId,
      modeId: modeId,
      executionDiscipline: executionDiscipline,
      metadata: metadata,
    );
  }

  RuntimeBaseline _resolveRuntimeBaseline(ProjectDescriptor project) {
    final preferred = _runtimeBaselineCatalogService.byId(
      project.runtimeBaselineId.trim(),
    );
    return preferred ??
        _runtimeBaselineCatalogService.byId('continuous_autonomous')!;
  }

  JsonMap _decorateMetadata(
    JsonMap metadata, {
    required ContinuousTaskControlProfile controlProfile,
    required ContinuousTaskLifecycleState lifecycleState,
  }) {
    return <String, Object?>{
      ...ValueReaders.deepCopyMap(metadata),
      'continuous_task_family_id': controlProfile.taskProfile.familyId,
      'continuous_task_run_kind': controlProfile.taskProfile.runKind,
      'continuous_task_profile_id':
          controlProfile.taskProfile.workflowStrategyId,
      'continuous_task_lifecycle_state': lifecycleState.toJson(),
    };
  }

  String _effectiveModeId(String explicitModeId, String fallbackRunKind) {
    final cleanModeId = explicitModeId.trim();
    return cleanModeId.isNotEmpty ? cleanModeId : fallbackRunKind.trim();
  }

  String _effectiveWorkflowStrategyId(String explicit, String fallback) {
    final cleanExplicit = explicit.trim();
    if (cleanExplicit.isNotEmpty) {
      return cleanExplicit;
    }
    return fallback.trim();
  }
}
