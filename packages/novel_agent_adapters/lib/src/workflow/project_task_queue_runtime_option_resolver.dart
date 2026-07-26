import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_runtime_profile_repository.dart';

class ProjectTaskQueueRuntimeOptionResolver {
  ProjectTaskQueueRuntimeOptionResolver({
    required ProjectRuntimeProfileRepository runtimeProfileRepository,
    LongTaskProjectContractService? longTaskProjectContractService,
  }) : _runtimeProfileRepository = runtimeProfileRepository,
       _longTaskProjectContractService =
           longTaskProjectContractService ??
           const LongTaskProjectContractService();

  final ProjectRuntimeProfileRepository _runtimeProfileRepository;
  final LongTaskProjectContractService _longTaskProjectContractService;

  Future<JsonMap> resolveForLongTask(
    ProjectDescriptor project, {
    JsonMap options = const <String, Object?>{},
  }) async {
    // manifest 与 runtime profile 是长任务能力事实源；调用参数不能覆写项目运行基准。
    final profile = await _runtimeProfileRepository.load(project);
    final profileOptionBaselineId = ValueReaders.stringValue(
      profile.initialRunOptions['runtime_baseline_id'],
    ).trim();
    final optionBaselineId = ValueReaders.stringValue(
      options['runtime_baseline_id'],
    ).trim();
    final assessment = _longTaskProjectContractService.assess(
      project: project,
      runtimeProfile: profile,
      requestedRuntimeBaselineId: optionBaselineId.isNotEmpty
          ? optionBaselineId
          : profileOptionBaselineId,
    );
    if (!assessment.isAllowed) {
      return <String, Object?>{
        'ok': false,
        'error': assessment.errorCode,
        'message': assessment.message,
        'options': const <String, Object?>{},
      };
    }
    final merged = <String, Object?>{
      ...ValueReaders.deepCopyMap(profile.initialRunOptions),
      ...ValueReaders.deepCopyMap(options),
    };
    merged['runtime_baseline_id'] = project.runtimeBaselineId.trim();
    final runtimeMode = ValueReaders.stringValue(
      merged['runtime_mode'],
      profile.runtimeMode,
    ).trim();
    if (runtimeMode.isNotEmpty) {
      merged['runtime_mode'] = runtimeMode;
    }
    return <String, Object?>{'ok': true, 'options': merged};
  }
}
