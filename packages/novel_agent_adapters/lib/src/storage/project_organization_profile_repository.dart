import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_organization_path_policy.dart';

class ProjectOrganizationProfileRepository {
  ProjectOrganizationProfileRepository({
    required ProjectToolHostPort hostPort,
    ProjectOrganizationPathPolicy? pathPolicy,
    OrganizationProfileMarkdownParserService? parserService,
    OrganizationProfileMarkdownCodecService? codecService,
  }) : _hostPort = hostPort,
       _pathPolicy = pathPolicy ?? const ProjectOrganizationPathPolicy(),
       _parserService =
           parserService ?? OrganizationProfileMarkdownParserService(),
       _codecService = codecService ?? OrganizationProfileMarkdownCodecService();

  final ProjectToolHostPort _hostPort;
  final ProjectOrganizationPathPolicy _pathPolicy;
  final OrganizationProfileMarkdownParserService _parserService;
  final OrganizationProfileMarkdownCodecService _codecService;

  Future<List<OrganizationProfile>> listProfiles(ProjectDescriptor project) async {
    // 中文注释: 组织列表优先读取新的 assets/organizations/，兼容期再纳入 legacy organizations/ 目录并按 id 去重。
    final entries = await _hostPort.listEntries(project.rootPath);
    final result = <OrganizationProfile>[];
    final seenIds = <String>{};
    for (final entry in entries) {
      final path = ValueReaders.stringValue(entry['relative_path']);
      if (ValueReaders.boolValue(entry['is_dir']) ||
          !_isOrganizationPath(path)) {
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

  Future<void> saveProfile(
    ProjectDescriptor project, {
    required OrganizationProfile profile,
  }) {
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
    // 中文注释: 组织主档统一写回资产目录，避免目录导入导出后再落回旧路径。
    return _hostPort.writeTextFile(
      project.rootPath,
      path,
      _codecService.encode(document),
    );
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
