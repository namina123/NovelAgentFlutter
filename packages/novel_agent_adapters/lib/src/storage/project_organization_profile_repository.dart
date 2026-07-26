import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_organization_path_policy.dart';
import 'project_structured_content_bridge_service.dart';

class ProjectOrganizationProfileRepository {
  ProjectOrganizationProfileRepository({
    required ProjectToolHostPort hostPort,
    ProjectOrganizationPathPolicy? pathPolicy,
    OrganizationProfileMarkdownParserService? parserService,
    OrganizationProfileMarkdownCodecService? codecService,
    ProjectStructuredContentBridgeService? structuredContentBridgeService,
  }) : _hostPort = hostPort,
       _pathPolicy = pathPolicy ?? const ProjectOrganizationPathPolicy(),
       _parserService =
           parserService ?? OrganizationProfileMarkdownParserService(),
       _codecService =
           codecService ?? OrganizationProfileMarkdownCodecService(),
       _structuredContentBridgeService =
           structuredContentBridgeService ??
           ProjectStructuredContentBridgeService();

  final ProjectToolHostPort _hostPort;
  final ProjectOrganizationPathPolicy _pathPolicy;
  final OrganizationProfileMarkdownParserService _parserService;
  final OrganizationProfileMarkdownCodecService _codecService;
  final ProjectStructuredContentBridgeService _structuredContentBridgeService;

  Future<List<OrganizationProfile>> listProfiles(
    ProjectDescriptor project,
  ) async {
    // 中文注释: 组织列表优先读取新的 assets/organizations/，兼容期再纳入 legacy organizations/ 目录并按 id 去重。
    final entries = await _hostPort.listEntries(project.rootPath);
    final result = <OrganizationProfile>[];
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
      if (!_isOrganizationPath(path)) {
        continue;
      }
      addProfile(document.combinedText(), path, _fallbackIdFromPath(path));
    }
    for (final entry in entries) {
      final path = ValueReaders.stringValue(entry['relative_path']);
      if (ValueReaders.boolValue(entry['is_dir']) ||
          !_isOrganizationPath(path)) {
        continue;
      }
      final content = await _readContent(project, path);
      addProfile(content ?? '', path, _fallbackIdFromPath(path));
    }
    result.sort((left, right) => left.displayName.compareTo(right.displayName));
    return result;
  }

  Future<void> saveProfile(
    ProjectDescriptor project, {
    required OrganizationProfile profile,
  }) async {
    final path = _pathPolicy.profilePath(profile.id);
    final document = OrganizationProfile(
      id: profile.id,
      displayName: profile.displayName,
      summary: profile.summary,
      aliases: profile.aliases,
      nameHistory: profile.nameHistory,
      organizationType: profile.organizationType,
      memberCharacterIds: profile.memberCharacterIds,
      sourcePath: path,
      metadata: profile.metadata,
    );
    final content = _codecService.encode(document);
    final snapshot = await _structuredContentBridgeService
        .loadStructuredDocument(project: project, documentPath: path);
    try {
      // 中文注释: 组织主档统一写回资产目录，避免目录导入导出后再落回旧路径。
      await _structuredContentBridgeService.persistStructuredDocument(
        project: project,
        documentPath: path,
        documentKind: 'organization_profile',
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

  bool _isOrganizationPath(String relativePath) {
    final lower = relativePath.toLowerCase();
    return lower.startsWith('assets/organizations/') ||
        lower.startsWith('organizations/');
  }

  String _fallbackIdFromPath(String relativePath) {
    var name = relativePath.split('/').last;
    if (name.toLowerCase().endsWith('.md')) {
      name = name.substring(0, name.length - '.md'.length);
    }
    return name.trim();
  }

  OrganizationProfile _parseProfile(
    String content,
    String relativePath,
    String fallbackId,
  ) {
    final parsed = _parserService.parseDocument(
      content,
      fallbackId: fallbackId,
      relativePath: relativePath,
    );
    return const OrganizationProfileNormalizerService().normalize(parsed);
  }
}
