import 'task_runtime_constants.dart';

class LongTaskModeService {
  String normalizeMode(String mode) {
    // 中文注释: 长任务合同在缺省时更偏向“人定大纲 AI 写作”，和普通任务规范化默认值不同。
    final clean = mode.trim();
    if (const <String>{
      TaskRuntimeConstants.modeSingleChapterAtomic,
      TaskRuntimeConstants.modeSupervisedChapterQueue,
      TaskRuntimeConstants.modeHumanOutlineAiDraft,
      TaskRuntimeConstants.modeSeedToFullNovel,
    }.contains(clean)) {
      return clean;
    }
    return TaskRuntimeConstants.modeHumanOutlineAiDraft;
  }
}
