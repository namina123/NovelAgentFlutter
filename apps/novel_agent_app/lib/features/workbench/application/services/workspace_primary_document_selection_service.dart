import 'package:novel_agent_core/novel_agent_core.dart';

import 'workspace_resource_display_service.dart';

class WorkspacePrimaryDocumentSelectionService {
  const WorkspacePrimaryDocumentSelectionService({
    WorkspaceResourceDisplayService resourceDisplayService =
        const WorkspaceResourceDisplayService(),
  }) : _resourceDisplayService = resourceDisplayService;

  final WorkspaceResourceDisplayService _resourceDisplayService;

  String select(List<JsonMap> entries) {
    // 中文注释: 首次默认打开优先落在正式前提和总纲，避免 support overview 或随机文本抢占项目主入口。
    final readableFiles = entries
        .where((entry) => entry['is_dir'] != true)
        .map((entry) => _normalizePath(_stringValue(entry['relative_path'])))
        .where((path) => path.isNotEmpty)
        .where((path) => !_resourceDisplayService.shouldHidePath(path))
        .where(_canReadAsText)
        .toList(growable: false);
    if (readableFiles.isEmpty) {
      return '';
    }

    for (final candidate in _exactCandidates) {
      if (readableFiles.contains(candidate)) {
        return candidate;
      }
    }

    for (final matcher in _preferredMatchers) {
      final matched = readableFiles.where(matcher).toList(growable: true)
        ..sort();
      if (matched.isNotEmpty) {
        return matched.first;
      }
    }

    return readableFiles.first;
  }

  static const List<String> _exactCandidates = <String>[
    'premise/project_constitution.md',
    'outlines/story/story_outline.md',
    'outlines/story/project_outline.md',
    'outlines/story/full_outline_consensus_overview.md',
    'outlines/volumes/index.md',
    'outlines/chapters/index.md',
    'outline/outline.md',
    'outline/project_outline.md',
    'volume_outlines/index.md',
    'chapter_outlines/index.md',
  ];

  static final List<bool Function(String path)> _preferredMatchers =
      <bool Function(String path)>[
        (path) =>
            path.startsWith('premise/') &&
            !ProjectSupportDocumentCatalog.isProjectOverviewPath(path),
        (path) => path.startsWith('outlines/story/'),
        (path) => path.startsWith('outlines/volumes/'),
        (path) => path.startsWith('outlines/chapters/'),
        (path) => path.startsWith('outline/'),
        (path) => path.startsWith('volume_outlines/'),
        (path) => path.startsWith('chapter_outlines/'),
      ];

  bool _canReadAsText(String relativePath) {
    final lower = relativePath.toLowerCase();
    return lower.endsWith('.md') ||
        lower.endsWith('.txt') ||
        lower.endsWith('.json') ||
        lower.endsWith('.yaml') ||
        lower.endsWith('.yml');
  }

  String _normalizePath(String relativePath) {
    return relativePath.trim().replaceAll('\\', '/');
  }

  String _stringValue(Object? value, [String fallback = '']) {
    if (value == null) {
      return fallback;
    }
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}
