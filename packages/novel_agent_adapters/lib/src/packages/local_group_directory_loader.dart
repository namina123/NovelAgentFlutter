import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

class LocalGroupDirectoryLoader {
  LocalGroupDirectoryLoader({
    AgentGroupNormalizerService? agentGroupNormalizerService,
    SkillGroupNormalizerService? skillGroupNormalizerService,
  }) : _agentGroupNormalizerService =
           agentGroupNormalizerService ?? AgentGroupNormalizerService(),
       _skillGroupNormalizerService =
           skillGroupNormalizerService ?? SkillGroupNormalizerService();

  final AgentGroupNormalizerService _agentGroupNormalizerService;
  final SkillGroupNormalizerService _skillGroupNormalizerService;

  Future<List<JsonMap>> loadAgentGroups(String rootDirectoryPath) {
    // 中文注释: 智能体组目录扫描只负责发现与读取 JSON 文件，结构解释仍交给 core normalizer。
    return _loadGroups(
      rootDirectoryPath,
      entryFileName: 'agent_group.json',
      normalize: _agentGroupNormalizerService.normalizeAgentGroup,
    );
  }

  Future<List<JsonMap>> loadSkillGroups(String rootDirectoryPath) {
    // 中文注释: 技能组目录扫描和智能体组保持同一策略，避免项目级分组结构再出现特例。
    return _loadGroups(
      rootDirectoryPath,
      entryFileName: 'skill_group.json',
      normalize: _skillGroupNormalizerService.normalizeSkillGroup,
    );
  }

  Future<List<JsonMap>> _loadGroups(
    String rootDirectoryPath, {
    required String entryFileName,
    required JsonMap Function(JsonMap value) normalize,
  }) async {
    final root = Directory(rootDirectoryPath);
    if (!await root.exists()) {
      return const <JsonMap>[];
    }
    final result = <JsonMap>[];
    await for (final entity in root.list(followLinks: false)) {
      if (entity is! Directory) {
        continue;
      }
      final entryFile = File(
        '${entity.path}${Platform.pathSeparator}$entryFileName',
      );
      if (!await entryFile.exists()) {
        continue;
      }
      JsonMap parsed;
      try {
        parsed = ValueReaders.mapValue(
          jsonDecode(await entryFile.readAsString()),
        );
      } catch (_) {
        continue;
      }
      final normalized = normalize(parsed);
      if (normalized.isEmpty) {
        continue;
      }
      result.add(<String, Object?>{
        ...normalized,
        'package_root_path': root.path,
        'package_directory_path': entity.path,
        'entry_file_path': entryFile.path,
      });
    }
    return result;
  }
}
