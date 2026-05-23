import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

class LocalPackageDirectoryLoader {
  LocalPackageDirectoryLoader({
    PackageEntryFileNameService? entryFileNameService,
    AgentMarkdownPackageParserService? agentParserService,
    SkillMarkdownPackageParserService? skillParserService,
  }) : _entryFileNameService =
           entryFileNameService ?? PackageEntryFileNameService(),
       _agentParserService =
           agentParserService ?? AgentMarkdownPackageParserService(),
       _skillParserService =
           skillParserService ?? SkillMarkdownPackageParserService();

  final PackageEntryFileNameService _entryFileNameService;
  final AgentMarkdownPackageParserService _agentParserService;
  final SkillMarkdownPackageParserService _skillParserService;

  Future<List<JsonMap>> loadAgentPackages(String rootDirectoryPath) async {
    // 中文注释: 智能体目录加载器按包文件夹扫描，并以 AGENT.md / agent.md / agent.json 为入口。
    return _loadPackages(
      rootDirectoryPath,
      isEntryFile: _entryFileNameService.isAgentEntryFile,
      parse: (content, fallbackId) =>
          _agentParserService.parsePackage(content, fallbackId: fallbackId),
    );
  }

  Future<List<JsonMap>> loadSkillPackages(String rootDirectoryPath) async {
    // 中文注释: 技能目录加载器和智能体保持同一规范，只是入口文件和解析器不同。
    return _loadPackages(
      rootDirectoryPath,
      isEntryFile: _entryFileNameService.isSkillEntryFile,
      parse: (content, fallbackId) =>
          _skillParserService.parsePackage(content, fallbackId: fallbackId),
    );
  }

  Future<List<JsonMap>> _loadPackages(
    String rootDirectoryPath, {
    required bool Function(String fileName) isEntryFile,
    required JsonMap Function(String content, String fallbackId) parse,
  }) async {
    // 中文注释: 包目录扫描只负责文件系统发现和文本读取，结构解释完全交给 core 解析器。
    final root = Directory(rootDirectoryPath);
    if (!await root.exists()) {
      return const <JsonMap>[];
    }
    final result = <JsonMap>[];
    await for (final entity in root.list(followLinks: false)) {
      if (entity is! Directory) {
        continue;
      }
      final entryFile = await _findEntryFile(entity, isEntryFile);
      if (entryFile == null) {
        continue;
      }
      final content = await entryFile.readAsString();
      final packageId = entity.uri.pathSegments
          .where((segment) => segment.trim().isNotEmpty)
          .last;
      final parsed = parse(content, packageId);
      if (parsed.isNotEmpty) {
        result.add(parsed);
      }
    }
    return result;
  }

  Future<File?> _findEntryFile(
    Directory packageDirectory,
    bool Function(String fileName) isEntryFile,
  ) async {
    // 中文注释: 入口文件匹配大小写不敏感，保证用户手动复制或跨平台同步时不容易踩坑。
    await for (final entity in packageDirectory.list(followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      if (isEntryFile(entity.uri.pathSegments.last)) {
        return entity;
      }
    }
    return null;
  }
}
