final class ProjectSupportDocumentCatalog {
  static const String projectOverviewRelativePath =
      'premise/project_overview.md';

  static const List<String> legacyProjectOverviewRelativePaths = <String>[
    'premise/project_brief.md',
    'specs/project_brief.md',
  ];

  static const List<String> allProjectOverviewRelativePaths = <String>[
    projectOverviewRelativePath,
    ...legacyProjectOverviewRelativePaths,
  ];

  static bool isProjectOverviewPath(String relativePath) {
    final normalized = _normalize(relativePath);
    if (normalized.isEmpty) {
      return false;
    }
    for (final candidate in allProjectOverviewRelativePaths) {
      if (normalized == _normalize(candidate)) {
        return true;
      }
    }
    return false;
  }

  static String normalizeProjectOverviewPath(String relativePath) {
    final normalized = _normalize(relativePath);
    if (normalized.isEmpty) {
      return '';
    }
    return isProjectOverviewPath(normalized) ? projectOverviewRelativePath : '';
  }

  static String canonicalizePath(String relativePath) {
    final normalized = _normalize(relativePath);
    if (normalized.isEmpty) {
      return '';
    }
    final overviewPath = normalizeProjectOverviewPath(normalized);
    if (overviewPath.isNotEmpty) {
      return overviewPath;
    }
    return normalized;
  }

  static String _normalize(String relativePath) {
    return relativePath
        .trim()
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'/+'), '/')
        .replaceAll(RegExp(r'^/+|/+$'), '')
        .toLowerCase();
  }
}
