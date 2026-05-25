import '../workflow/long_task_mode_service.dart';
import '../workflow/task_runtime_constants.dart';

class RuntimeBaselineExecutionModeService {
  RuntimeBaselineExecutionModeService({LongTaskModeService? modeService})
    : _modeService = modeService ?? LongTaskModeService();

  final LongTaskModeService _modeService;

  String defaultRuntimeMode(String runtimeBaselineId) {
    // 中文注释: 运行基准和任务模式不是同一层；这里集中维护“这个基准默认跑哪种章节工作流”。
    final cleanBaselineId = runtimeBaselineId.trim();
    switch (cleanBaselineId) {
      case 'continuous_autonomous':
        return TaskRuntimeConstants.modeSeedToFullNovel;
      case 'chapter_collaboration_autorun':
        return TaskRuntimeConstants.modeHumanOutlineAiDraft;
      default:
        return TaskRuntimeConstants.modeHumanOutlineAiDraft;
    }
  }

  String resolveRuntimeMode({
    String runtimeBaselineId = '',
    String runtimeMode = '',
  }) {
    final cleanRuntimeMode = runtimeMode.trim();
    if (cleanRuntimeMode.isNotEmpty) {
      return _modeService.normalizeMode(cleanRuntimeMode);
    }
    return _modeService.normalizeMode(defaultRuntimeMode(runtimeBaselineId));
  }
}
