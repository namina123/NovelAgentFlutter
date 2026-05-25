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
    final runtimeBaselineId = _chapterGatePolicyService
        .runtimeBaselineIdForTask(task);
    if (runtimeBaselineId == 'chapter_collaboration_autorun' &&
        <String>{'chapter', 'review', 'revision'}.contains(taskType)) {
      return TaskRuntimeConstants.statusSucceeded;
    }
    if (taskType != 'chapter') {
      return TaskRuntimeConstants.statusWaitingUser;
    }
    final mode = _modeService.normalizeMode(
      ValueReaders.stringValue(task['mode']),
    );
    final stage = ValueReaders.stringValue(
      ValueReaders.mapValue(task['metadata'])['stage'],
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
}
