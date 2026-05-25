import '../common/json_types.dart';
import 'long_task_mode_service.dart';
import 'long_task_path_policy_service.dart';
import 'task_runtime_constants.dart';

class LongTaskModeContextPathService {
  LongTaskModeContextPathService({
    required LongTaskModeService modeService,
    required LongTaskPathPolicyService pathPolicyService,
  }) : _modeService = modeService,
       _pathPolicyService = pathPolicyService;

  final LongTaskModeService _modeService;
  final LongTaskPathPolicyService _pathPolicyService;

  List<String> persistentContextPaths(String mode, JsonMap options) {
    // 中文注释: 长任务长期约束路径集中由这里决定，后续任务工厂和提示事务直接复用，不再各自猜测。
    final cleanMode = _modeService.normalizeMode(mode);
    final explicitPaths = _pathPolicyService.stringList(
      options['persistent_context_paths'],
    );
    if (explicitPaths.isNotEmpty) {
      return explicitPaths;
    }
    final sourcePaths = _pathPolicyService.stringList(options['source_paths']);
    if (cleanMode == TaskRuntimeConstants.modeSeedToFullNovel ||
        cleanMode == TaskRuntimeConstants.modeHumanOutlineAiDraft) {
      return sourcePaths;
    }
    return const <String>[];
  }

  List<String> mergeTaskSourcePaths(
    String mode,
    JsonMap options,
    List<Object?> taskPaths,
  ) {
    // 中文注释: 任务局部来源路径与模式长期约束路径合并后，才能保证后续章节不会把风格和世界锚点忘掉。
    return _pathPolicyService.mergePaths(
      persistentContextPaths(mode, options),
      taskPaths,
    );
  }
}
