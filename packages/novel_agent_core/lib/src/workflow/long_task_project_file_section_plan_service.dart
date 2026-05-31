import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../continuity/project_continuity_bundle.dart';
import 'long_task_continuity_context_projection.dart';
import 'long_task_continuity_context_projection_service.dart';
import 'long_task_path_policy_service.dart';

class LongTaskProjectFileSectionPlanService {
  LongTaskProjectFileSectionPlanService({
    required LongTaskPathPolicyService pathPolicyService,
    LongTaskContinuityContextProjectionService?
    continuityContextProjectionService,
  }) : _pathPolicyService = pathPolicyService,
       _continuityContextProjectionService =
           continuityContextProjectionService ??
           LongTaskContinuityContextProjectionService(
             pathPolicyService: pathPolicyService,
           );

  final LongTaskPathPolicyService _pathPolicyService;
  final LongTaskContinuityContextProjectionService
  _continuityContextProjectionService;

  List<JsonMap> build(
    JsonMap task, {
    ProjectContinuityBundle? continuityBundle,
    String continuityFrameId = '',
    String continuityScopeId = '',
    String continuityMechanicProfileId = '',
  }) {
    // 中文注释: 长任务执行包优先读取显式任务来源与长期约束路径，这里只负责生成结构化片段计划，不触碰文件系统。
    final metadata = ValueReaders.mapValue(task['metadata']);
    final persistentPaths = _pathPolicyService.stringList(
      metadata['persistent_context_paths'],
    );
    final continuityProjection = continuityBundle == null
        ? const LongTaskContinuityContextProjection()
        : _continuityContextProjectionService.project(
            continuityBundle,
            frameId: continuityFrameId,
            scopeId: continuityScopeId,
            mechanicProfileId: continuityMechanicProfileId,
          );
    final continuityPersistentPaths = continuityProjection.persistentPaths;
    final genericPersistentPaths = <String>[];
    for (final path in persistentPaths) {
      if (!continuityPersistentPaths.contains(path)) {
        genericPersistentPaths.add(path);
      }
    }
    final sourcePaths = _pathPolicyService.stringList(task['source_paths']);
    final focusedPaths = <String>[];
    for (final path in sourcePaths) {
      if (!persistentPaths.contains(path) &&
          !continuityPersistentPaths.contains(path)) {
        focusedPaths.add(path);
      }
    }
    final sections = <JsonMap>[];
    if (continuityProjection.canonicalPaths.isNotEmpty) {
      sections.add(
        _section(
          id: 'continuity_global_context',
          title: '连续性全局事实',
          source: 'continuity.canonical_paths',
          priority: 96,
          maxChars: 2200,
          paths: continuityProjection.canonicalPaths,
        ),
      );
    }
    if (continuityProjection.overlayPaths.isNotEmpty) {
      sections.add(
        _section(
          id: 'continuity_scope_overlays',
          title: '连续性作用域覆盖',
          source: 'continuity.overlay_paths',
          priority: 94,
          maxChars: 2200,
          paths: continuityProjection.overlayPaths,
        ),
      );
    }
    if (continuityProjection.statePaths.isNotEmpty) {
      sections.add(
        _section(
          id: 'continuity_runtime_state',
          title: '连续性阶段状态',
          source: 'continuity.state_paths',
          priority: 93,
          maxChars: 2200,
          paths: continuityProjection.statePaths,
        ),
      );
    }
    if (continuityProjection.tailWindowPaths.isNotEmpty) {
      sections.add(
        _section(
          id: 'continuity_tail_window',
          title: '连续性尾部窗口',
          source: 'continuity.tail_window_paths',
          priority: 91,
          maxChars: 2600,
          paths: continuityProjection.tailWindowPaths,
        ),
      );
    }
    if (genericPersistentPaths.isNotEmpty) {
      sections.add(
        _section(
          id: 'task_persistent_context',
          title: '长期约束',
          source: 'persistent_context_paths',
          priority: 92,
          maxChars: 2200,
          paths: genericPersistentPaths,
        ),
      );
    }
    if (focusedPaths.isNotEmpty) {
      sections.add(
        _section(
          id: 'task_source_paths',
          title: '任务指定来源',
          source: 'source_paths',
          priority: 88,
          maxChars: 2200,
          paths: focusedPaths,
        ),
      );
    }
    return sections;
  }

  JsonMap _section({
    required String id,
    required String title,
    required String source,
    required int priority,
    required int maxChars,
    required List<String> paths,
  }) {
    return <String, Object?>{
      'id': id,
      'title': title,
      'source': source,
      'priority': priority,
      'max_chars': maxChars,
      'paths': paths,
    };
  }
}
