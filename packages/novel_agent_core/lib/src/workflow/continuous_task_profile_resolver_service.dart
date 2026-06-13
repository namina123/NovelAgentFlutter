import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../reference_extraction/reference_extraction_execution_discipline.dart';
import '../reference_extraction/reference_extraction_strategy_profile.dart';
import 'continuous_task_family.dart';
import 'continuous_task_profile.dart';
import 'continuous_task_run_kind.dart';
import 'task_runtime_constants.dart';

class ContinuousTaskProfileResolverService {
  const ContinuousTaskProfileResolverService();

  ContinuousTaskProfile forLongTaskMode(
    String modeId, {
    String workflowStrategyId = '',
    JsonMap metadata = const <String, Object?>{},
  }) {
    // 中文注释: 长任务先继续复用既有 mode id，但在这里统一投影成连续任务合同，避免后续 goal/reference 再各长一套 pause-resume 语义。
    final cleanMode = modeId.trim().isEmpty
        ? TaskRuntimeConstants.modeSupervisedChapterQueue
        : modeId.trim();
    return ContinuousTaskProfile(
      familyId: ContinuousTaskFamilies.longFormWriting,
      runKind: ContinuousTaskRunKinds.chapterQueue,
      workflowStrategyId: workflowStrategyId.trim(),
      modeId: cleanMode,
      metadata: <String, Object?>{
        'source_contract': 'long_task_mode',
        'mode_id': cleanMode,
        ...ValueReaders.deepCopyMap(metadata),
      },
    );
  }

  ContinuousTaskProfile forGoalMode({
    String workflowStrategyId = 'goal_mode',
    JsonMap metadata = const <String, Object?>{},
  }) {
    // 中文注释: 目标模式虽然不一定有章节队列，但仍是可暂停、可恢复、可继续的轻量连续会话链，因此共享同一控制面语义。
    return ContinuousTaskProfile(
      familyId: ContinuousTaskFamilies.goalMode,
      runKind: ContinuousTaskRunKinds.conversationLoop,
      workflowStrategyId: workflowStrategyId.trim(),
      metadata: <String, Object?>{
        'source_contract': 'goal_mode',
        ...ValueReaders.deepCopyMap(metadata),
      },
    );
  }

  ContinuousTaskProfile forReferenceExtraction({
    String workflowStrategyId =
        ReferenceExtractionBuiltinStrategyProfileIds.standard,
    ReferenceExtractionExecutionDiscipline executionDiscipline =
        const ReferenceExtractionExecutionDiscipline(),
    JsonMap metadata = const <String, Object?>{},
  }) {
    // 中文注释: 参考提取已经有 batch/coverage/reentry 合同，这里只把它上提为连续任务族，不在本 session 里改动具体 runtime 行为。
    return ContinuousTaskProfile(
      familyId: ContinuousTaskFamilies.referenceExtraction,
      runKind: ContinuousTaskRunKinds.batchPipeline,
      workflowStrategyId: workflowStrategyId.trim(),
      metadata: <String, Object?>{
        'source_contract': 'reference_extraction',
        'execution_discipline': executionDiscipline.toJson(),
        ...ValueReaders.deepCopyMap(metadata),
      },
    );
  }

  ContinuousTaskProfile forResearchConsolidation({
    String workflowStrategyId = 'research_consolidation',
    JsonMap metadata = const <String, Object?>{},
  }) {
    // 中文注释: 研究整编与普通单次 research 不同，它面向多轮收集、归并和恢复，因此需要纳入连续任务族而不是只做工具调用。
    return ContinuousTaskProfile(
      familyId: ContinuousTaskFamilies.researchConsolidation,
      runKind: ContinuousTaskRunKinds.researchSweep,
      workflowStrategyId: workflowStrategyId.trim(),
      metadata: <String, Object?>{
        'source_contract': 'research_consolidation',
        ...ValueReaders.deepCopyMap(metadata),
      },
    );
  }

  ContinuousTaskProfile resolve({
    required String familyId,
    String workflowStrategyId = '',
    String modeId = '',
    ReferenceExtractionExecutionDiscipline executionDiscipline =
        const ReferenceExtractionExecutionDiscipline(),
    JsonMap metadata = const <String, Object?>{},
  }) {
    // 中文注释: 统一 resolver 让后续 watchdog / supervisor / runtime 只认连续任务族合同，不再各自猜 family-specific 字段组合。
    final cleanFamilyId = familyId.trim();
    switch (cleanFamilyId) {
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
    return ContinuousTaskProfile(
      familyId: cleanFamilyId,
      runKind: ContinuousTaskRunKinds.conversationLoop,
      workflowStrategyId: workflowStrategyId.trim(),
      modeId: modeId.trim(),
      metadata: <String, Object?>{
        'source_contract': 'custom_continuous_task_family',
        ...ValueReaders.deepCopyMap(metadata),
      },
    );
  }
}
