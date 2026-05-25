enum ProjectStorageStrategy {
  markdownProjectStore('markdown_project_store'),
  sqliteProjectStore('sqlite_project_store');

  const ProjectStorageStrategy(this.id);

  final String id;

  static ProjectStorageStrategy fromId(String raw) {
    // 中文注释: 存储策略解析默认向旧项目兼容回退到 Markdown，避免未升级 manifest 直接失效。
    final clean = raw.trim();
    for (final strategy in ProjectStorageStrategy.values) {
      if (strategy.id == clean) {
        return strategy;
      }
    }
    return ProjectStorageStrategy.markdownProjectStore;
  }
}
