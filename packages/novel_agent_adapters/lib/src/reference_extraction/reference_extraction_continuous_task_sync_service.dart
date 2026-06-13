import 'package:novel_agent_core/novel_agent_core.dart';

import '../runtime/continuous_task_supervisor_bridge_service.dart';
import 'project_reference_extraction_runtime_models.dart';
import 'reference_extraction_supervisor_signal_service.dart';

class ReferenceExtractionContinuousTaskSyncService {
  ReferenceExtractionContinuousTaskSyncService({
    required ContinuousTaskSupervisorBridgeService supervisorBridgeService,
    ReferenceExtractionSupervisorSignalService? supervisorSignalService,
    ContinuousTaskRecoveryStateFactoryService? recoveryStateFactoryService,
  }) : _supervisorBridgeService = supervisorBridgeService,
       _supervisorSignalService =
           supervisorSignalService ??
           const ReferenceExtractionSupervisorSignalService(),
       _recoveryStateFactoryService =
           recoveryStateFactoryService ??
           const ContinuousTaskRecoveryStateFactoryService();

  final ContinuousTaskSupervisorBridgeService _supervisorBridgeService;
  final ReferenceExtractionSupervisorSignalService _supervisorSignalService;
  final ContinuousTaskRecoveryStateFactoryService _recoveryStateFactoryService;

  Future<void> trackExecutionStart({
    required ProjectDescriptor project,
    required ProjectReferenceExtractionRequest request,
    required String runId,
    required String displayName,
    required String sourceFilePath,
  }) {
    return _supervisorBridgeService.trackTaskFamilyRun(
      runId: runId,
      project: project,
      familyId: ContinuousTaskFamilies.referenceExtraction,
      workflowStrategyId: request.strategyProfileId,
      activeTaskId: runId,
      activeTaskTitle: displayName,
      lifecycleState: ContinuousTaskLifecycleState(
        runPhase: ContinuousTaskRunPhases.running,
        reason: 'reference_extraction_running',
      ),
      metadata: <String, Object?>{
        'source_file_path': sourceFilePath,
        'requested_strategy_profile_id': request.strategyProfileId,
      },
      note: 'reference_extraction_running',
    );
  }

  Future<void> syncExecutionResult({
    required ProjectDescriptor project,
    required ProjectReferenceExtractionResult result,
  }) async {
    final supervisorSignal = _supervisorSignalService.build(result);
    final lifecycleState = supervisorSignal.lifecycleState;
    await _supervisorBridgeService.applyLifecycleState(
      result.runId,
      familyId: ContinuousTaskFamilies.referenceExtraction,
      workflowStrategyId: result.strategyProfileId,
      executionDiscipline: _executionDisciplineFromResult(result),
      lifecycleState: lifecycleState,
      metadata: supervisorSignal.metadata,
      note: lifecycleState.reason,
    );
  }

  Future<void> syncExecutionFailure({
    required ProjectDescriptor project,
    required ProjectReferenceExtractionRequest request,
    required String runId,
    required String displayName,
    required String sourceFilePath,
    required Object error,
  }) async {
    final reason = error.toString();
    final lifecycleState = ContinuousTaskLifecycleState(
      runPhase: ContinuousTaskRunPhases.recovering,
      stopCategory: ContinuousTaskStopCategories.technicalFailure,
      reason: reason,
      metadata: <String, Object?>{'source_file_path': sourceFilePath},
    );
    await _supervisorBridgeService.applyLifecycleState(
      runId,
      familyId: ContinuousTaskFamilies.referenceExtraction,
      workflowStrategyId: request.strategyProfileId,
      lifecycleState: lifecycleState,
      recoveryState: _recoveryStateFactoryService.resumeReady(
        lifecycleState: lifecycleState,
        recommendedAction: 'resume_reference_extraction',
        note: 'reference_extraction_recovering',
        autoRetryEligible: true,
        blocksProgress: true,
        taskId: runId,
        taskTitle: displayName,
        metadata: <String, Object?>{
          'source_file_path': sourceFilePath,
          'requested_strategy_profile_id': request.strategyProfileId,
        },
      ),
      metadata: <String, Object?>{
        'source_file_path': sourceFilePath,
        'requested_strategy_profile_id': request.strategyProfileId,
      },
      note: 'reference_extraction_recovering',
    );
  }

  ReferenceExtractionExecutionDiscipline _executionDisciplineFromResult(
    ProjectReferenceExtractionResult result,
  ) {
    return ReferenceExtractionExecutionDiscipline(
      concurrencyMode: result.executionConcurrencyMode,
      maxConcurrentBatches: result.executionMaxConcurrentBatches,
      allowParallelHeavyTextConsumption:
          result.allowParallelHeavyTextConsumption,
    );
  }
}
