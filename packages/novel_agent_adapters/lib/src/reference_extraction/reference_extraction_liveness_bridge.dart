import 'package:novel_agent_core/novel_agent_core.dart';

import '../runtime/continuous_task_supervisor_bridge_service.dart';
import 'project_reference_extraction_runtime_models.dart';
import 'reference_extraction_continuous_task_sync_service.dart';

class ReferenceExtractionLivenessBridge {
  ReferenceExtractionLivenessBridge({
    required ContinuousTaskSupervisorBridgeService supervisorBridgeService,
    ReferenceExtractionContinuousTaskSyncService? syncService,
  }) : _syncService =
           syncService ??
           ReferenceExtractionContinuousTaskSyncService(
             supervisorBridgeService: supervisorBridgeService,
           );

  final ReferenceExtractionContinuousTaskSyncService _syncService;

  Future<void> trackExecutionStart({
    required ProjectDescriptor project,
    required ProjectReferenceExtractionRequest request,
    required String runId,
    required String displayName,
    required String sourceFilePath,
  }) {
    return _syncService.trackExecutionStart(
      project: project,
      request: request,
      runId: runId,
      displayName: displayName,
      sourceFilePath: sourceFilePath,
    );
  }

  Future<void> syncExecutionResult({
    required ProjectDescriptor project,
    required ProjectReferenceExtractionResult result,
  }) {
    return _syncService.syncExecutionResult(project: project, result: result);
  }

  Future<void> syncExecutionFailure({
    required ProjectDescriptor project,
    required ProjectReferenceExtractionRequest request,
    required String runId,
    required String displayName,
    required String sourceFilePath,
    required Object error,
  }) {
    return _syncService.syncExecutionFailure(
      project: project,
      request: request,
      runId: runId,
      displayName: displayName,
      sourceFilePath: sourceFilePath,
      error: error,
    );
  }
}
