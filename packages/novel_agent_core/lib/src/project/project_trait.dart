class ProjectTrait {
  const ProjectTrait({
    required this.id,
    required this.name,
    this.description = '',
  });

  final String id;
  final String name;
  final String description;

  static const ProjectTrait longTask = ProjectTrait(
    id: 'long_task',
    name: '长任务',
    description: '表示该项目或模式具备持续运行、自动恢复和检查点推进语义。',
  );

  static const ProjectTrait seedDriven = ProjectTrait(
    id: 'seed_driven',
    name: '灵感种子驱动',
    description: '表示该项目或模式以开局灵感、种子设定和逐步收束为主要启动方式。',
  );

  static const ProjectTrait fullOutline = ProjectTrait(
    id: 'full_outline',
    name: '全书建纲',
    description: '表示该项目或模式会先围绕全书结构、大纲和章级规划收束。',
  );

  static const ProjectTrait openingGuided = ProjectTrait(
    id: 'opening_guided',
    name: '开局引导',
    description: '表示该项目在启动链之前通常需要一段结构化的开局信息收束。',
  );

  static const ProjectTrait bookDeconstruction = ProjectTrait(
    id: 'book_deconstruction',
    name: '拆书提取',
    description: '表示该项目以外部作品导入、结构化提取和资产映射为主。',
  );

  static const List<ProjectTrait> builtIn = <ProjectTrait>[
    longTask,
    seedDriven,
    fullOutline,
    openingGuided,
    bookDeconstruction,
  ];

  static ProjectTrait fromId(String rawId) {
    // 中文注释: trait 允许后续扩展，因此未知 id 不报错，而是保留成通用 trait 以便上层继续传递。
    final cleanId = rawId.trim();
    for (final trait in builtIn) {
      if (trait.id == cleanId) {
        return trait;
      }
    }
    return ProjectTrait(id: cleanId, name: cleanId);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ProjectTrait && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
