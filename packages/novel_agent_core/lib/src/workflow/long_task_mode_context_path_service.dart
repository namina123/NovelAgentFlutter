import '../common/json_types.dart';
import '../continuity/project_continuity_bundle.dart';
import 'long_task_mode_service.dart';
import 'long_task_continuity_context_projection_service.dart';
import 'long_task_path_policy_service.dart';
import 'task_runtime_constants.dart';

class LongTaskModeContextPathService {
  LongTaskModeContextPathService({
    required LongTaskModeService modeService,
    required LongTaskPathPolicyService pathPolicyService,
    LongTaskContinuityContextProjectionService?
    continuityContextProjectionService,
  }) : _modeService = modeService,
       _pathPolicyService = pathPolicyService,
       _continuityContextProjectionService =
           continuityContextProjectionService ??
           LongTaskContinuityContextProjectionService(
             pathPolicyService: pathPolicyService,
           );

  final LongTaskModeService _modeService;
  final LongTaskPathPolicyService _pathPolicyService;
  final LongTaskContinuityContextProjectionService
  _continuityContextProjectionService;

  List<String> persistentContextPaths(
    String mode,
    JsonMap options, {
    ProjectContinuityBundle? continuityBundle,
    String continuityFrameId = '',
    String continuityScopeId = '',
    String continuityMechanicProfileId = '',
  }) {
    // 中文注释: 长任务长期约束路径集中由这里决定，后续任务工厂和提示事务直接复用，不再各自猜测。
    final cleanMode = _modeService.normalizeMode(mode);
    final explicitPaths = _pathPolicyService.stringList(
      options['persistent_context_paths'],
    );
    final continuityPaths = continuityBundle == null
        ? const <String>[]
        : _continuityContextProjectionService
              .project(
                continuityBundle,
                frameId: continuityFrameId,
                scopeId: continuityScopeId,
                mechanicProfileId: continuityMechanicProfileId,
              )
              .persistentPaths;
    if (explicitPaths.isNotEmpty) {
      return _pathPolicyService.mergePaths(explicitPaths, continuityPaths);
    }
    final sourcePaths = _pathPolicyService.stringList(options['source_paths']);
    if (cleanMode == TaskRuntimeConstants.modeSeedToFullNovel ||
        cleanMode == TaskRuntimeConstants.modeHumanOutlineAiDraft) {
      return _pathPolicyService.mergePaths(sourcePaths, continuityPaths);
    }
    return continuityPaths;
  }

  List<String> mergeTaskSourcePaths(
    String mode,
    JsonMap options,
    List<Object?> taskPaths, {
    ProjectContinuityBundle? continuityBundle,
    String continuityFrameId = '',
    String continuityScopeId = '',
    String continuityMechanicProfileId = '',
  }) {
    // 中文注释: 任务局部来源路径与模式长期约束路径合并后，才能保证后续章节不会把风格和世界锚点忘掉。
    return _pathPolicyService.mergePaths(
      persistentContextPaths(
        mode,
        options,
        continuityBundle: continuityBundle,
        continuityFrameId: continuityFrameId,
        continuityScopeId: continuityScopeId,
        continuityMechanicProfileId: continuityMechanicProfileId,
      ),
      taskPaths,
    );
  }
}
