import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_mode_guidance_repository.dart';

class ProjectModeGuidanceMemorySectionService {
  ProjectModeGuidanceMemorySectionService({
    required ProjectModeGuidanceRepository repository,
    ModeGuidanceAssetBundleBuilderService? assetBundleBuilderService,
    ModeGuidanceAssetContextSectionService? contextSectionService,
  }) : _repository = repository,
       _assetBundleBuilderService =
           assetBundleBuilderService ??
           const ModeGuidanceAssetBundleBuilderService(),
       _contextSectionService =
           contextSectionService ??
           const ModeGuidanceAssetContextSectionService();

  final ProjectModeGuidanceRepository _repository;
  final ModeGuidanceAssetBundleBuilderService _assetBundleBuilderService;
  final ModeGuidanceAssetContextSectionService _contextSectionService;

  Future<List<JsonMap>> buildForTask(
    ProjectDescriptor project,
    JsonMap task,
  ) async {
    // 中文注释: 这里从任务挂接的模式路径恢复模式状态，再投影成模型可直接消费的长期记忆片段。
    final sections = <JsonMap>[];
    for (final modeId in _modeIdsFromTask(task)) {
      final state = await _repository.load(project, modeId: modeId);
      if (state == null) {
        continue;
      }
      final bundle = _assetBundleBuilderService.build(state);
      sections.addAll(_contextSectionService.build(bundle));
    }
    return sections;
  }

  List<String> _modeIdsFromTask(JsonMap task) {
    final metadata = ValueReaders.mapValue(task['metadata']);
    final candidates = <String>[
      ...ValueReaders.stringList(metadata['persistent_context_paths']),
      ...ValueReaders.stringList(task['source_paths']),
    ];
    final result = <String>[];
    for (final path in candidates) {
      final trackingMatch = RegExp(
        r'^tracking/modes/([^/]+)/guidance\.md$',
      ).firstMatch(path);
      final hiddenMatch = RegExp(
        r'^\.novel_agent/modes/([^/]+)/guidance_state\.json$',
      ).firstMatch(path);
      final modeId =
          trackingMatch?.group(1)?.trim() ??
          hiddenMatch?.group(1)?.trim() ??
          '';
      if (modeId.isNotEmpty && !result.contains(modeId)) {
        result.add(modeId);
      }
    }
    return result;
  }
}
