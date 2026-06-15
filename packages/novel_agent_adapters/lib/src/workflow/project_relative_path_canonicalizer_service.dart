class ProjectRelativePathCanonicalizerService {
  const ProjectRelativePathCanonicalizerService();

  String canonicalize(String path) {
    final normalized = path.trim().replaceAll('\\', '/');
    if (normalized.isEmpty) {
      return '';
    }
    final lower = normalized.toLowerCase();
    const markers = <String>[
      'tracking/continuity/',
      '.novel_agent/continuity/deliveries/',
      '.novel_agent/continuity/',
      'chapters/',
      'summaries/',
      'assets/timeline/',
    ];
    for (final marker in markers) {
      final index = lower.indexOf(marker);
      if (index >= 0) {
        return normalized.substring(index);
      }
    }
    return normalized;
  }

  bool hasCanonicalPrefix(String path, String prefix) {
    return canonicalize(path).toLowerCase().startsWith(prefix.toLowerCase());
  }

  bool equalsCanonicalPath(String left, String right) {
    return canonicalize(left).toLowerCase() == canonicalize(right).toLowerCase();
  }
}
