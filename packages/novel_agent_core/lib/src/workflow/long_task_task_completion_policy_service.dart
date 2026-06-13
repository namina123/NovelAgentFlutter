import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_chapter_gate_policy_service.dart';
import 'long_task_mode_service.dart';
import 'task_runtime_constants.dart';

class LongTaskTaskCompletionPolicyService {
  LongTaskTaskCompletionPolicyService({
    required LongTaskModeService modeService,
    LongTaskChapterGatePolicyService? chapterGatePolicyService,
  }) : _modeService = modeService,
       _chapterGatePolicyService =
           chapterGatePolicyService ?? const LongTaskChapterGatePolicyService();

  final LongTaskModeService _modeService;
  final LongTaskChapterGatePolicyService _chapterGatePolicyService;

  String statusAfterSuccessfulModelStep(JsonMap task) {
    // 中文注释: 单步执行成功后是“等待用户”还是“直接完成”，统一由策略服务给出，避免运行时散落分支。
    final taskType = ValueReaders.stringValue(task['task_type'], 'chapter');
    final mode = _modeService.normalizeMode(
      ValueReaders.stringValue(task['mode']),
    );
    final metadata = ValueReaders.mapValue(task['metadata']);
    final runtimeBaselineId = _chapterGatePolicyService
        .runtimeBaselineIdForTask(task);
    if (runtimeBaselineId == 'chapter_collaboration_autorun' &&
        <String>{'chapter', 'review', 'revision'}.contains(taskType)) {
      return TaskRuntimeConstants.statusSucceeded;
    }
    if (taskType != 'chapter') {
      if (_shouldAutoCompleteContinuousAgentTask(
        taskType: taskType,
        mode: mode,
        runtimeBaselineId: runtimeBaselineId,
        generatedBy: ValueReaders.stringValue(metadata['generated_by']).trim(),
      )) {
        return TaskRuntimeConstants.statusSucceeded;
      }
      if (_shouldAutoCompleteContinuousFollowupTask(
        taskType: taskType,
        mode: mode,
        origin: ValueReaders.stringValue(metadata['origin']).trim(),
      )) {
        return TaskRuntimeConstants.statusSucceeded;
      }
      return TaskRuntimeConstants.statusWaitingUser;
    }
    final stage = ValueReaders.stringValue(
      metadata['stage'],
    ).trim().toLowerCase();
    if (mode == TaskRuntimeConstants.modeSupervisedChapterQueue) {
      return TaskRuntimeConstants.statusWaitingUser;
    }
    if (mode == TaskRuntimeConstants.modeSingleChapterAtomic) {
      return TaskRuntimeConstants.statusWaitingUser;
    }
    if (mode == TaskRuntimeConstants.modeSeedToFullNovel && stage == 'sample') {
      return TaskRuntimeConstants.statusWaitingUser;
    }
    if (mode == TaskRuntimeConstants.modeHumanOutlineAiDraft ||
        mode == TaskRuntimeConstants.modeSeedToFullNovel) {
      return TaskRuntimeConstants.statusSucceeded;
    }
    return TaskRuntimeConstants.statusWaitingUser;
  }

  bool _shouldAutoCompleteContinuousFollowupTask({
    required String taskType,
    required String mode,
    required String origin,
  }) {
    if (!_isContinuousLongTaskMode(mode)) {
      return false;
    }
    if (taskType == 'review') {
      return origin == 'checkpoint_review_suggestion';
    }
    if (taskType == 'revision') {
      return const <String>{
        'review_report',
        'review_repair_handoff',
        'execution_constraint_gate',
      }.contains(origin);
    }
    return false;
  }

  bool _shouldAutoCompleteContinuousAgentTask({
    required String taskType,
    required String mode,
    required String runtimeBaselineId,
    required String generatedBy,
  }) {
    return taskType == 'agent_task' &&
        _isContinuousLongTaskMode(mode) &&
        runtimeBaselineId == 'continuous_autonomous' &&
        generatedBy == 'LongTaskRevision';
  }

  bool _isContinuousLongTaskMode(String mode) {
    return mode == TaskRuntimeConstants.modeHumanOutlineAiDraft ||
        mode == TaskRuntimeConstants.modeSeedToFullNovel;
  }
}
