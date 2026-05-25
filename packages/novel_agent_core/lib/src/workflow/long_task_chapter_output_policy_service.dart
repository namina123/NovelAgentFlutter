import 'long_task_mode_service.dart';
import 'task_runtime_constants.dart';

class LongTaskChapterOutputPolicyService {
  LongTaskChapterOutputPolicyService({required LongTaskModeService modeService})
    : _modeService = modeService;

  final LongTaskModeService _modeService;

  String defaultOutputPath({
    required String mode,
    required String stage,
    required String fileStem,
  }) {
    // 中文注释: 长任务章节默认写到哪里，只由这一处集中决定，避免工厂和运行时各自猜目录。
    final cleanMode = _modeService.normalizeMode(mode);
    final cleanStage = stage.trim().toLowerCase();
    final cleanStem = fileStem.trim();
    if (cleanStem.isEmpty) {
      return '';
    }
    return '${_directoryFor(cleanMode, cleanStage)}/$cleanStem.md';
  }

  String _directoryFor(String mode, String stage) {
    // 中文注释: 目前只有“种子到长篇”的常规章节默认进入 chapters/，其余模式继续保持草稿导向。
    if (mode == TaskRuntimeConstants.modeSeedToFullNovel &&
        stage.isNotEmpty &&
        stage != 'sample' &&
        stage != 'planning' &&
        stage != 'checkpoint') {
      return 'chapters';
    }
    return 'drafts';
  }
}
