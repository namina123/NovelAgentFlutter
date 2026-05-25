import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_runtime_profile_repository.dart';

class ProjectTaskQueueRuntimeOptionResolver {
  ProjectTaskQueueRuntimeOptionResolver({
    required ProjectRuntimeProfileRepository runtimeProfileRepository,
  }) : _runtimeProfileRepository = runtimeProfileRepository;

  final ProjectRuntimeProfileRepository _runtimeProfileRepository;

  Future<JsonMap> resolve(
    ProjectDescriptor project, {
    JsonMap options = const <String, Object?>{},
  }) async {
    // 中文注释: 队列运行入口先吃项目级 runtime_profile，再允许本次命令参数按需覆写，保证 GUI/CLI 同源。
    final profile = await _runtimeProfileRepository.load(project);
    final merged = <String, Object?>{
      ...ValueReaders.deepCopyMap(profile.initialRunOptions),
      ...ValueReaders.deepCopyMap(options),
    };
    final runtimeBaselineId = ValueReaders.stringValue(
      merged['runtime_baseline_id'],
      profile.runtimeBaselineId,
    ).trim();
    if (runtimeBaselineId.isNotEmpty) {
      merged['runtime_baseline_id'] = runtimeBaselineId;
    }
    final runtimeMode = ValueReaders.stringValue(
      merged['runtime_mode'],
      profile.runtimeMode,
    ).trim();
    if (runtimeMode.isNotEmpty) {
      merged['runtime_mode'] = runtimeMode;
    }
    return merged;
  }
}
