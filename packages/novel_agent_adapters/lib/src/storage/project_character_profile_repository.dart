import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_character_path_policy.dart';
import 'project_structured_content_bridge_service.dart';

class ProjectCharacterProfileRepository {
  ProjectCharacterProfileRepository({
    required ProjectToolHostPort hostPort,
    ProjectCharacterPathPolicy? pathPolicy,
    CharacterProfileMarkdownParserService? parserService,
    CharacterProfileMarkdownCodecService? codecService,
    ProjectStructuredContentBridgeService? structuredContentBridgeService,
  }) : _hostPort = hostPort,
       _pathPolicy = pathPolicy ?? ProjectCharacterPathPolicy(),
       _parserService =
           parserService ?? CharacterProfileMarkdownParserService(),
       _codecService = codecService ?? CharacterProfileMarkdownCodecService(),
       _structuredContentBridgeService =
           structuredContentBridgeService ??
           ProjectStructuredContentBridgeService();

  final ProjectToolHostPort _hostPort;
  final ProjectCharacterPathPolicy _pathPolicy;
  final CharacterProfileMarkdownParserService _parserService;
  final CharacterProfileMarkdownCodecService _codecService;
  final ProjectStructuredContentBridgeService _structuredContentBridgeService;

  Future<List<CharacterProfile>> listProfiles(ProjectDescriptor project) async {
    // 中文注释: 角色列表与单条读取共用同一套 parser，目录导入导出和运行主链才能看到一致的角色视图。
    final entries = await _hostPort.listEntries(project.rootPath);
    final result = <CharacterProfile>[];
    final seenIds = <String>{};
    void addProfile(String content, String path, String fallbackId) {
      if (content.trim().isEmpty) {
        return;
      }
      final profile = _parseProfile(content, path, fallbackId);
      if (profile.id.trim().isEmpty || seenIds.contains(profile.id)) {
        return;
      }
      seenIds.add(profile.id);
      result.add(profile);
    }

    final structuredDocuments = await _structuredContentBridgeService
        .listStructuredDocuments(project: project);
    for (final document in structuredDocuments) {
      final path = document.markdownPath.trim().isEmpty
          ? document.documentId
          : document.markdownPath;
      if (!_isCharacterPath(path)) {
        continue;
      }
      addProfile(document.combinedText(), path, _fallbackIdFromPath(path));
    }
    for (final entry in entries) {
      final path = ValueReaders.stringValue(entry['relative_path']);
      if (ValueReaders.boolValue(entry['is_dir']) || !_isCharacterPath(path)) {
        continue;
      }
      final content = await _readContent(project, path);
      addProfile(content ?? '', path, _fallbackIdFromPath(path));
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
    final preferredText = await _readContent(project, preferredPath);
    if ((preferredText ?? '').trim().isNotEmpty) {
      return _parseProfile(preferredText!, preferredPath, characterId);
    }
    final legacyPath = _pathPolicy.legacyProfilePath(displayName);
    final legacyText = await _readContent(project, legacyPath);
    if ((legacyText ?? '').trim().isEmpty) {
      return null;
    }
    return _parseProfile(legacyText!, legacyPath, characterId);
  }

  Future<void> saveProfile(
    ProjectDescriptor project, {
    required CharacterProfile profile,
  }) async {
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
    final content = _codecService.encode(document);
    final snapshot = await _structuredContentBridgeService
        .loadStructuredDocument(project: project, documentPath: path);
    try {
      // 中文注释: 主档保存统一覆盖固定路径，杜绝角色名_2 / _3 这类逐次膨胀文件。
      await _structuredContentBridgeService.persistStructuredDocument(
        project: project,
        documentPath: path,
        documentKind: 'character',
        title: document.displayName,
        content: content,
      );
      await _hostPort.writeTextFile(project.rootPath, path, content);
    } catch (_) {
      await _restoreStructuredSnapshot(
        project: project,
        documentPath: path,
        snapshot: snapshot,
      );
      rethrow;
    }
  }

  Future<String?> _readContent(ProjectDescriptor project, String path) async {
    return await _structuredContentBridgeService.readProjectedBodyText(
          project,
          path,
        ) ??
        _hostPort.readTextFile(project.rootPath, path);
  }

  Future<void> _restoreStructuredSnapshot({
    required ProjectDescriptor project,
    required String documentPath,
    required SqliteProjectBodyTextDocument? snapshot,
  }) async {
    try {
      await _structuredContentBridgeService.restoreStructuredDocument(
        project: project,
        documentPath: documentPath,
        snapshot: snapshot,
      );
    } catch (_) {}
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
