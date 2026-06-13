import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../reference_extraction/reference_extraction_execution_discipline.dart';
import 'continuous_task_control_profile.dart';
import 'continuous_task_family.dart';
import 'continuous_task_profile.dart';
import 'continuous_task_profile_resolver_service.dart';
import 'continuous_task_run_phase.dart';
import 'continuous_task_stop_category.dart';
import 'continuous_task_supervisor_profile.dart';
import 'continuous_task_watchdog_profile.dart';

class ContinuousTaskControlProfileResolverService {
  const ContinuousTaskControlProfileResolverService({
    ContinuousTaskProfileResolverService? taskProfileResolverService,
  }) : _taskProfileResolverService =
           taskProfileResolverService ??
           const ContinuousTaskProfileResolverService();

  final ContinuousTaskProfileResolverService _taskProfileResolverService;

  ContinuousTaskControlProfile forLongTaskMode(
    String modeId, {
    String workflowStrategyId = '',
    JsonMap metadata = const <String, Object?>{},
  }) {
    final taskProfile = _taskProfileResolverService.forLongTaskMode(
      modeId,
      workflowStrategyId: workflowStrategyId,
      metadata: metadata,
    );
    return _buildProfile(
      taskProfile: taskProfile,
      watchdogProfile: ContinuousTaskWatchdogProfile(
        profileId: 'durable_continuous_watchdog',
        familyId: taskProfile.familyId,
        metadata: <String, Object?>{
          'cadence_class': 'chapter_queue_standard',
          ...ValueReaders.deepCopyMap(metadata),
        },
      ),
      supervisorProfile: ContinuousTaskSupervisorProfile(
        profileId: 'structured_chapter_queue_supervisor',
        familyId: taskProfile.familyId,
        metadata: <String, Object?>{
          'decision_surface': 'chapter_queue',
          ...ValueReaders.deepCopyMap(metadata),
        },
      ),
      supportedRunPhases: <String>[
        ContinuousTaskRunPhases.draftingGuidance,
        ContinuousTaskRunPhases.readyToStart,
        ContinuousTaskRunPhases.running,
        ContinuousTaskRunPhases.waitingUser,
        ContinuousTaskRunPhases.paused,
        ContinuousTaskRunPhases.recovering,
        ContinuousTaskRunPhases.manualAttention,
        ContinuousTaskRunPhases.stopped,
      ],
      metadata: <String, Object?>{
        'source_contract': 'long_task_control_profile',
        ...ValueReaders.deepCopyMap(metadata),
      },
    );
  }

  ContinuousTaskControlProfile forGoalMode({
    String workflowStrategyId = 'goal_mode',
    JsonMap metadata = const <String, Object?>{},
  }) {
    final taskProfile = _taskProfileResolverService.forGoalMode(
      workflowStrategyId: workflowStrategyId,
      metadata: metadata,
    );
    return _buildProfile(
      taskProfile: taskProfile,
      watchdogProfile: ContinuousTaskWatchdogProfile(
        profileId: 'lightweight_conversation_watchdog',
        familyId: taskProfile.familyId,
        metadata: <String, Object?>{
          'cadence_class': 'conversation_lightweight',
          'checkpoint_ui_required': false,
          ...ValueReaders.deepCopyMap(metadata),
        },
      ),
      supervisorProfile: ContinuousTaskSupervisorProfile(
        profileId: 'goal_mode_supervisor',
        familyId: taskProfile.familyId,
        metadata: <String, Object?>{
          'decision_surface': 'conversation_loop',
          ...ValueReaders.deepCopyMap(metadata),
        },
      ),
      supportedRunPhases: <String>[
        ContinuousTaskRunPhases.readyToStart,
        ContinuousTaskRunPhases.running,
        ContinuousTaskRunPhases.waitingUser,
        ContinuousTaskRunPhases.paused,
        ContinuousTaskRunPhases.recovering,
        ContinuousTaskRunPhases.manualAttention,
        ContinuousTaskRunPhases.stopped,
      ],
      metadata: <String, Object?>{
        'source_contract': 'goal_mode_control_profile',
        ...ValueReaders.deepCopyMap(metadata),
      },
    );
  }

  ContinuousTaskControlProfile forReferenceExtraction({
    String workflowStrategyId = '',
    ReferenceExtractionExecutionDiscipline executionDiscipline =
        const ReferenceExtractionExecutionDiscipline(),
    JsonMap metadata = const <String, Object?>{},
  }) {
    final taskProfile = _taskProfileResolverService.forReferenceExtraction(
      workflowStrategyId: workflowStrategyId,
      executionDiscipline: executionDiscipline,
      metadata: metadata,
    );
    return _buildProfile(
      taskProfile: taskProfile,
      watchdogProfile: ContinuousTaskWatchdogProfile(
        profileId: 'reference_extraction_watchdog',
        familyId: taskProfile.familyId,
        metadata: <String, Object?>{
          'cadence_class': 'batch_pipeline_standard',
          'default_concurrency': 1,
          ...ValueReaders.deepCopyMap(metadata),
        },
      ),
      supervisorProfile: ContinuousTaskSupervisorProfile(
        profileId: 'reference_extraction_supervisor',
        familyId: taskProfile.familyId,
        metadata: <String, Object?>{
          'decision_surface': 'batch_pipeline',
          ...ValueReaders.deepCopyMap(metadata),
        },
      ),
      supportedRunPhases: <String>[
        ContinuousTaskRunPhases.readyToStart,
        ContinuousTaskRunPhases.running,
        ContinuousTaskRunPhases.waitingUser,
        ContinuousTaskRunPhases.paused,
        ContinuousTaskRunPhases.recovering,
        ContinuousTaskRunPhases.manualAttention,
        ContinuousTaskRunPhases.stopped,
      ],
      metadata: <String, Object?>{
        'source_contract': 'reference_extraction_control_profile',
        'execution_discipline': executionDiscipline.toJson(),
        ...ValueReaders.deepCopyMap(metadata),
      },
    );
  }

  ContinuousTaskControlProfile forResearchConsolidation({
    String workflowStrategyId = 'research_consolidation',
    JsonMap metadata = const <String, Object?>{},
  }) {
    final taskProfile = _taskProfileResolverService.forResearchConsolidation(
      workflowStrategyId: workflowStrategyId,
      metadata: metadata,
    );
    return _buildProfile(
      taskProfile: taskProfile,
      watchdogProfile: ContinuousTaskWatchdogProfile(
        profileId: 'research_consolidation_watchdog',
        familyId: taskProfile.familyId,
        metadata: <String, Object?>{
          'cadence_class': 'research_sweep_standard',
          ...ValueReaders.deepCopyMap(metadata),
        },
      ),
      supervisorProfile: ContinuousTaskSupervisorProfile(
        profileId: 'research_consolidation_supervisor',
        familyId: taskProfile.familyId,
        metadata: <String, Object?>{
          'decision_surface': 'research_sweep',
          ...ValueReaders.deepCopyMap(metadata),
        },
      ),
      supportedRunPhases: <String>[
        ContinuousTaskRunPhases.readyToStart,
        ContinuousTaskRunPhases.running,
        ContinuousTaskRunPhases.waitingUser,
        ContinuousTaskRunPhases.paused,
        ContinuousTaskRunPhases.recovering,
        ContinuousTaskRunPhases.manualAttention,
        ContinuousTaskRunPhases.stopped,
      ],
      metadata: <String, Object?>{
        'source_contract': 'research_consolidation_control_profile',
        ...ValueReaders.deepCopyMap(metadata),
      },
    );
  }

  ContinuousTaskControlProfile resolve({
    required String familyId,
    String workflowStrategyId = '',
    String modeId = '',
    ReferenceExtractionExecutionDiscipline executionDiscipline =
        const ReferenceExtractionExecutionDiscipline(),
    JsonMap metadata = const <String, Object?>{},
  }) {
    switch (familyId.trim()) {
      case ContinuousTaskFamilies.longFormWriting:
        return forLongTaskMode(
          modeId,
          workflowStrategyId: workflowStrategyId,
          metadata: metadata,
        );
      case ContinuousTaskFamilies.goalMode:
        return forGoalMode(
          workflowStrategyId: workflowStrategyId,
          metadata: metadata,
        );
      case ContinuousTaskFamilies.referenceExtraction:
        return forReferenceExtraction(
          workflowStrategyId: workflowStrategyId,
          executionDiscipline: executionDiscipline,
          metadata: metadata,
        );
      case ContinuousTaskFamilies.researchConsolidation:
        return forResearchConsolidation(
          workflowStrategyId: workflowStrategyId,
          metadata: metadata,
        );
    }
    final taskProfile = _taskProfileResolverService.resolve(
      familyId: familyId,
      workflowStrategyId: workflowStrategyId,
      modeId: modeId,
      executionDiscipline: executionDiscipline,
      metadata: metadata,
    );
    return _buildProfile(
      taskProfile: taskProfile,
      watchdogProfile: ContinuousTaskWatchdogProfile(
        profileId: 'custom_continuous_task_watchdog',
        familyId: taskProfile.familyId,
        metadata: ValueReaders.deepCopyMap(metadata),
      ),
      supervisorProfile: ContinuousTaskSupervisorProfile(
        profileId: 'custom_continuous_task_supervisor',
        familyId: taskProfile.familyId,
        metadata: ValueReaders.deepCopyMap(metadata),
      ),
      supportedRunPhases: <String>[
        ContinuousTaskRunPhases.readyToStart,
        ContinuousTaskRunPhases.running,
        ContinuousTaskRunPhases.waitingUser,
        ContinuousTaskRunPhases.paused,
        ContinuousTaskRunPhases.recovering,
        ContinuousTaskRunPhases.manualAttention,
        ContinuousTaskRunPhases.stopped,
      ],
      metadata: <String, Object?>{
        'source_contract': 'custom_continuous_task_control_profile',
        ...ValueReaders.deepCopyMap(metadata),
      },
    );
  }

  ContinuousTaskControlProfile _buildProfile({
    required ContinuousTaskProfile taskProfile,
    required ContinuousTaskWatchdogProfile watchdogProfile,
    required ContinuousTaskSupervisorProfile supervisorProfile,
    required List<String> supportedRunPhases,
    required JsonMap metadata,
  }) {
    return ContinuousTaskControlProfile(
      taskProfile: taskProfile,
      watchdogProfile: watchdogProfile,
      supervisorProfile: supervisorProfile,
      supportedRunPhases: List<String>.from(supportedRunPhases),
      supportedStopCategories: const <String>[
        ContinuousTaskStopCategories.completedNaturally,
        ContinuousTaskStopCategories.cancelled,
        ContinuousTaskStopCategories.budgetExhausted,
        ContinuousTaskStopCategories.technicalFailure,
        ContinuousTaskStopCategories.deliveryFailure,
        ContinuousTaskStopCategories.constraintGatePause,
        ContinuousTaskStopCategories.waitingUser,
        ContinuousTaskStopCategories.manualAttention,
        ContinuousTaskStopCategories.recoveryExhausted,
      ],
      metadata: metadata,
    );
  }
}
