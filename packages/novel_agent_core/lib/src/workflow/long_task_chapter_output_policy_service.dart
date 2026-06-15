import 'long_task_mode_service.dart';
import 'task_runtime_constants.dart';
import '../project/chapter_output_path_policy_service.dart';
import '../project/project_content_path_policy_service.dart';

class LongTaskChapterOutputPolicyService {
  LongTaskChapterOutputPolicyService({
    required LongTaskModeService modeService,
    ProjectContentPathPolicyService? contentPathPolicyService,
  }) : _modeService = modeService,
       _contentPathPolicyService =
           contentPathPolicyService ?? const ProjectContentPathPolicyService(),
       _chapterOutputPathPolicyService = ChapterOutputPathPolicyService(
         contentPathPolicyService:
             contentPathPolicyService ??
             const ProjectContentPathPolicyService(),
       );

  final LongTaskModeService _modeService;
  final ProjectContentPathPolicyService _contentPathPolicyService;
  final ChapterOutputPathPolicyService _chapterOutputPathPolicyService;

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

  String chapterFileStem({
    required int chapterNumber,
    required String title,
    String fallbackTitle = 'chapter',
  }) {
    // 中文注释: 长任务只代理共享章节路径策略，避免正式交付、普通写作和动态续章各自发明文件名规则。
    return _chapterOutputPathPolicyService.chapterFileStem(
      chapterNumber: chapterNumber,
      title: title,
      fallbackTitle: fallbackTitle,
    );
  }

  String sampleFileStem({
    required String title,
    String fallbackTitle = '样章',
  }) {
    final safeTitle = _chapterOutputPathPolicyService.safeFilePart(
      title.trim(),
      fallbackTitle,
    );
    if (safeTitle.isEmpty || safeTitle == fallbackTitle) {
      return fallbackTitle;
    }
    return safeTitle;
  }

  String _directoryFor(String mode, String stage) {
    // 中文注释: 正式章节、样章和场景在这里分流；上层工厂和运行时只消费统一结果。
    if (stage == 'sample') {
      return _contentPathPolicyService.directoryForContentType('sample');
    }
    if (stage == 'scene' || stage == 'scenes') {
      return _contentPathPolicyService.directoryForContentType('scene');
    }
    if (mode == TaskRuntimeConstants.modeSeedToFullNovel &&
        stage == 'planning') {
      return _contentPathPolicyService.directoryForContentType('chapter');
    }
    if (stage.isNotEmpty && stage != 'checkpoint') {
      return _contentPathPolicyService.directoryForContentType('chapter');
    }
    return _contentPathPolicyService.directoryForContentType('chapter');
  }
}
