import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_character_path_policy.dart';

class ProjectCharacterProfileRepository {
  ProjectCharacterProfileRepository({
    required ProjectToolHostPort hostPort,
    ProjectCharacterPathPolicy? pathPolicy,
    CharacterProfileMarkdownParserService? parserService,
    CharacterProfileMarkdownCodecService? codecService,
  }) : _hostPort = hostPort,
       _pathPolicy = pathPolicy ?? ProjectCharacterPathPolicy(),
       _parserService =
           parserService ?? CharacterProfileMarkdownParserService(),
       _codecService = codecService ?? CharacterProfileMarkdownCodecService();

  final ProjectToolHostPort _hostPort;
  final ProjectCharacterPathPolicy _pathPolicy;
  final CharacterProfileMarkdownParserService _parserService;
  final CharacterProfileMarkdownCodecService _codecService;

  Future<List<CharacterProfile>> listProfiles(ProjectDescriptor project) async {
    // 中文注释: 角色列表与单条读取共用同一套 parser，目录导入导出和运行主链才能看到一致的角色视图。
    final entries = await _hostPort.listEntries(project.rootPath);
    final result = <CharacterProfile>[];
    final seenIds = <String>{};
    for (final entry in entries) {
      final path = ValueReaders.stringValue(entry['relative_path']);
      if (ValueReaders.boolValue(entry['is_dir']) || !_isCharacterPath(path)) {
        continue;
      }
      final content = await _hostPort.readTextFile(project.rootPath, path);
      if ((content ?? '').trim().isEmpty) {
        continue;
      }
      final profile = _parseProfile(content!, path, _fallbackIdFromPath(path));
      if (profile.id.trim().isEmpty || seenIds.contains(profile.id)) {
        continue;
      }
      seenIds.add(profile.id);
      result.add(profile);
    }
    result.sort((left, right) => left.displayName.compareTo(right.displayName));
    return result;
  }

  Future<CharacterProfile?> readProfile(
    ProjectDescriptor project, {
    required String characterId,
    required String displayName,
  }) async {
    // 中文注释: 读取先走新的资产主档路径，兼容期再回退 legacy characters/，但不再把 legacy 当主写入位置。
    final preferredPath = _pathPolicy.profilePath(characterId);
    final preferredText = await _hostPort.readTextFile(
      project.rootPath,
      preferredPath,
    );
    if ((preferredText ?? '').trim().isNotEmpty) {
      return _parseProfile(preferredText!, preferredPath, characterId);
    }
    final legacyPath = _pathPolicy.legacyProfilePath(displayName);
    final legacyText = await _hostPort.readTextFile(
      project.rootPath,
      legacyPath,
    );
    if ((legacyText ?? '').trim().isEmpty) {
      return null;
    }
    return _parseProfile(legacyText!, legacyPath, characterId);
  }

  Future<void> saveProfile(
    ProjectDescriptor project, {
    required CharacterProfile profile,
  }) {
    final path = _pathPolicy.profilePath(profile.id);
    final document = CharacterProfile(
      id: profile.id,
      displayName: profile.displayName,
      summary: profile.summary,
      currentStatus: profile.currentStatus,
      currentStateSummary: profile.currentStateSummary,
      latestStageLabel: profile.latestStageLabel,
      latestUpdatedAt: profile.latestUpdatedAt,
      latestSourcePaths: profile.latestSourcePaths,
      aliases: profile.aliases,
      nameHistory: profile.nameHistory,
      storyRole: profile.storyRole,
      traits: profile.traits,
      organizationIds: profile.organizationIds,
      sourcePath: path,
      metadata: <String, Object?>{
        ...profile.metadata,
        'character_profile_path': path,
      },
    );
    // 中文注释: 主档保存统一覆盖固定路径，杜绝角色名_2 / _3 这类逐次膨胀文件。
    return _hostPort.writeTextFile(
      project.rootPath,
      path,
      _codecService.encode(document),
    );
  }

  CharacterProfile _parseProfile(
    String content,
    String relativePath,
    String fallbackId,
  ) {
    final parsed = _parserService.parseDocument(
      content,
      fallbackId: fallbackId,
      relativePath: relativePath,
    );
    return const CharacterProfileNormalizerService().normalize(parsed);
  }

  bool _isCharacterPath(String relativePath) {
    final lower = relativePath.toLowerCase();
    return lower.startsWith('assets/characters/') ||
        lower.startsWith('characters/');
  }

  String _fallbackIdFromPath(String relativePath) {
    var name = relativePath.split('/').last;
    if (name.toLowerCase().endsWith('.md')) {
      name = name.substring(0, name.length - '.md'.length);
    }
    return name.trim();
  }
}
