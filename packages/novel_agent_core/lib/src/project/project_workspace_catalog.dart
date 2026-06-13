import 'workspace_directory_descriptor.dart';

final class ProjectWorkspaceCatalog {
  static const List<WorkspaceDirectoryDescriptor> userWorkspaceDirs =
      <WorkspaceDirectoryDescriptor>[
        WorkspaceDirectoryDescriptor(
          path: 'premise/',
          name: '前提',
          purpose: '题材、核心设定、开局摘要、创作意图和长期不可违背的项目承诺。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'outlines/',
          name: '大纲',
          purpose: '总纲、分卷纲、章纲等结构化创作规划。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'chapters/',
          name: '正文',
          purpose: '章节正文、样章与章节级可交付内容。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'scenes/',
          name: '场景',
          purpose: '独立场景、片段补写与局部正文内容。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'assets/',
          name: '资产',
          purpose: '角色、组织、地点、物品、世界、风格、伏笔、关系和时间线等共享写作资产。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'tasks/',
          name: '任务',
          purpose: '面向用户可理解的计划、审稿和返工任务文档。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'analysis/',
          name: '分析',
          purpose: '分析结果、图谱导出和结构化审稿摘要。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'exports/',
          name: '导出',
          purpose: '项目导出包、共享资产包和对外交换结果。',
        ),
      ];

  static const List<WorkspaceDirectoryDescriptor> visibleWorkspaceSkeletonDirs =
      <WorkspaceDirectoryDescriptor>[
        WorkspaceDirectoryDescriptor(
          path: 'premise/',
          name: '前提',
          purpose: '题材、核心设定、开局摘要、创作意图和长期不可违背的项目承诺。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'outlines/',
          name: '大纲',
          purpose: '总纲、分卷纲、章纲等结构化创作规划。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'outlines/story/',
          name: '故事总纲',
          purpose: '主线结构、主题承诺、核心冲突和结局方向。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'outlines/volumes/',
          name: '卷纲',
          purpose: '分卷目标、阶段冲突和卷内节奏。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'outlines/chapters/',
          name: '章纲',
          purpose: '章节任务、场景目标、关键事件与卡点。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'chapters/',
          name: '正文',
          purpose: '章节正文、样章与章节级可交付内容。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'scenes/',
          name: '场景',
          purpose: '独立场景、片段补写与局部正文内容。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'assets/',
          name: '资产',
          purpose: '角色、组织、地点、物品、世界、风格、伏笔、关系和时间线等共享写作资产。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'assets/characters/',
          name: '角色',
          purpose: '角色卡、状态卡、角色映射和成长变化记录。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'assets/organizations/',
          name: '组织',
          purpose: '势力、门派、团体和组织关系资料。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'assets/locations/',
          name: '地点',
          purpose: '地图节点、地点卡和场景地点资料。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'assets/items/',
          name: '物品',
          purpose: '道具、装备、资源和关键物件记录。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'assets/styles/',
          name: '风格',
          purpose: '叙事声音、文风规范、禁用表达和读者体验要求。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'assets/world/',
          name: '世界',
          purpose: '世界规则、能力体系、术语和长期稳定设定。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'assets/foreshadows/',
          name: '伏笔',
          purpose: '伏笔布设、回收状态和风险提醒。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'assets/relationships/',
          name: '关系',
          purpose: '角色关系、阵营关系和关系变更记录。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'assets/timeline/',
          name: '时间线',
          purpose: '事件时间轴、阶段推进和关键节点记录。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'tasks/',
          name: '任务',
          purpose: '面向用户可理解的计划、审稿和返工任务文档。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'tasks/plans/',
          name: '计划',
          purpose: '项目计划、阶段计划和执行任务清单。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'tasks/reviews/',
          name: '审稿任务',
          purpose: '待执行或已归档的审稿任务文档。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'tasks/revisions/',
          name: '返工任务',
          purpose: '修订、返工和重写类任务文档。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'analysis/',
          name: '分析',
          purpose: '分析结果、图谱导出和结构化审稿摘要。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'exports/',
          name: '导出',
          purpose: '项目导出包、共享资产包和对外交换结果。',
        ),
      ];

  static const List<WorkspaceDirectoryDescriptor> advancedWorkspaceDirs =
      <WorkspaceDirectoryDescriptor>[
        WorkspaceDirectoryDescriptor(path: 'agents/', name: '智能体配置'),
        WorkspaceDirectoryDescriptor(path: 'agent_groups/', name: '智能体组配置'),
        WorkspaceDirectoryDescriptor(path: 'skills/', name: '技能配置'),
        WorkspaceDirectoryDescriptor(path: 'skill_groups/', name: '技能组配置'),
        WorkspaceDirectoryDescriptor(path: 'prompts/', name: '提示词模板'),
        WorkspaceDirectoryDescriptor(path: 'tracking/', name: '执行追踪'),
        WorkspaceDirectoryDescriptor(path: 'runs/', name: '生成记录'),
        WorkspaceDirectoryDescriptor(path: 'backups/', name: '备份'),
      ];

  static const List<WorkspaceDirectoryDescriptor>
  legacyResourceCompatibilityDirs = <WorkspaceDirectoryDescriptor>[
    WorkspaceDirectoryDescriptor(
      path: 'outline/',
      name: '大纲',
      purpose: '旧项目中的总纲目录，兼容映射到当前大纲展示语义。',
    ),
    WorkspaceDirectoryDescriptor(
      path: 'volume_outlines/',
      name: '卷纲',
      purpose: '旧项目中的分卷大纲目录，兼容映射到当前卷纲展示语义。',
    ),
    WorkspaceDirectoryDescriptor(
      path: 'chapter_outlines/',
      name: '章纲',
      purpose: '旧项目中的章节任务目录，兼容映射到当前章纲展示语义。',
    ),
    WorkspaceDirectoryDescriptor(
      path: 'styles/',
      name: '风格',
      purpose: '旧项目中的风格目录，兼容映射到当前风格资产展示语义。',
    ),
    WorkspaceDirectoryDescriptor(
      path: 'world/',
      name: '世界',
      purpose: '旧项目中的世界设定目录，兼容映射到当前世界资产展示语义。',
    ),
    WorkspaceDirectoryDescriptor(
      path: 'specs/',
      name: '项目规格',
      purpose: '作品规格、创作宪法和模式约束等可读规划文件的稳定目录。',
    ),
    WorkspaceDirectoryDescriptor(
      path: 'knowledge/',
      name: '知识',
      purpose: '旧项目中的知识材料目录，兼容保留为可读资源。',
    ),
    WorkspaceDirectoryDescriptor(
      path: 'inspiration/',
      name: '灵感',
      purpose: '创作种子、灵感投影和前置素材的稳定目录。',
    ),
    WorkspaceDirectoryDescriptor(
      path: 'summaries/',
      name: '摘要',
      purpose: '旧项目中的章节摘要目录，兼容保留为可读资源。',
    ),
    WorkspaceDirectoryDescriptor(
      path: 'constraints/',
      name: '约束',
      purpose: '开放叙事状态投影出的项目约束摘要，可作为模型可读的稳定创作边界。',
    ),
    WorkspaceDirectoryDescriptor(
      path: 'continuity/',
      name: '连续性',
      purpose: '开放叙事状态投影出的叙事状态规则与最近变化摘要，可作为模型可读的连续性资源。',
    ),
    WorkspaceDirectoryDescriptor(
      path: 'reviews/',
      name: '审稿',
      purpose: '旧项目中的审稿报告目录，兼容保留为可读资源。',
    ),
  ];

  static const List<WorkspaceDirectoryDescriptor>
  internalWorkspaceDirs = <WorkspaceDirectoryDescriptor>[
    WorkspaceDirectoryDescriptor(path: '.novel_agent/', name: '内部状态'),
    WorkspaceDirectoryDescriptor(path: '.novel_agent/state/', name: '状态'),
    WorkspaceDirectoryDescriptor(path: '.novel_agent/runtime/', name: '运行态'),
    WorkspaceDirectoryDescriptor(path: '.novel_agent/runs/', name: '运行记录'),
    WorkspaceDirectoryDescriptor(path: '.novel_agent/threads/', name: '线程'),
    WorkspaceDirectoryDescriptor(path: '.novel_agent/tasks/', name: '内部任务'),
    WorkspaceDirectoryDescriptor(
      path: '.novel_agent/checkpoints/',
      name: '检查点',
    ),
    WorkspaceDirectoryDescriptor(path: '.novel_agent/indexes/', name: '索引'),
    WorkspaceDirectoryDescriptor(path: '.novel_agent/cache/', name: '缓存'),
    WorkspaceDirectoryDescriptor(path: '.novel_agent/settings/', name: '设置'),
    WorkspaceDirectoryDescriptor(path: '.novel_agent/logs/', name: '日志'),
    WorkspaceDirectoryDescriptor(path: '.novel_agent/modes/', name: '模式状态'),
    WorkspaceDirectoryDescriptor(
      path: '.novel_agent/sqlite/',
      name: 'SQLite 索引',
    ),
  ];

  static List<WorkspaceDirectoryDescriptor>
  get defaultResourceTreeDirectoryDescriptors => visibleWorkspaceSkeletonDirs;

  static List<WorkspaceDirectoryDescriptor>
  get resourceTreeDirectoryDescriptors => <WorkspaceDirectoryDescriptor>[
    ...defaultResourceTreeDirectoryDescriptors,
    ...legacyResourceCompatibilityDirs,
  ];

  static bool isAdvancedWorkspacePath(String relativePath) {
    return _matchesAnyDescriptor(relativePath, advancedWorkspaceDirs);
  }

  static bool isInternalWorkspacePath(String relativePath) {
    return _matchesAnyDescriptor(relativePath, internalWorkspaceDirs);
  }

  static bool isDefaultResourceTreePath(String relativePath) {
    return _matchesAnyDescriptor(
      relativePath,
      defaultResourceTreeDirectoryDescriptors,
    );
  }

  static bool _matchesAnyDescriptor(
    String relativePath,
    List<WorkspaceDirectoryDescriptor> descriptors,
  ) {
    final cleanPath = _normalize(relativePath);
    if (cleanPath.isEmpty) {
      return false;
    }
    for (final descriptor in descriptors) {
      final basePath = _normalize(descriptor.path);
      if (basePath.isEmpty) {
        continue;
      }
      if (cleanPath == basePath || cleanPath.startsWith('$basePath/')) {
        return true;
      }
    }
    return false;
  }

  static String _normalize(String relativePath) {
    return relativePath
        .trim()
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'/+$'), '');
  }
}
