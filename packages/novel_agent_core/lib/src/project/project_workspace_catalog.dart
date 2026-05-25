import 'workspace_directory_descriptor.dart';

final class ProjectWorkspaceCatalog {
  static const List<WorkspaceDirectoryDescriptor> userWorkspaceDirs =
      <WorkspaceDirectoryDescriptor>[
        WorkspaceDirectoryDescriptor(
          path: 'specs/',
          name: '项目规格',
          purpose: '项目名、题材、创作宪法、核心卖点和不可违背的长期要求。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'styles/',
          name: '风格',
          purpose: '叙事声音、文风规范、禁用表达、节奏和读者体验要求。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'outline/',
          name: '总纲',
          purpose: '主线结构、世界阶段、主要冲突、结局方向。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'volume_outlines/',
          name: '卷纲',
          purpose: '分卷目标、阶段性矛盾、卷内节奏。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'chapter_outlines/',
          name: '章纲',
          purpose: '章节任务、场景目标、关键事件与卡点。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'drafts/',
          name: '草稿',
          purpose: 'AI 或人工生成的章节工作草稿、样章、局部补写和待确认正文；可自动保存，确认后再进入正式正文。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'chapters/',
          name: '正文',
          purpose: '正式小说正文；只有用户确认或任务明确要求的可交付正文/定稿才能写入这里。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'world/',
          name: '设定',
          purpose: '世界规则、地点、势力、能力体系、术语、道具、伏笔和时间线。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'characters/',
          name: '角色',
          purpose: '角色卡、人物关系、当前状态、口吻、成长变化和秘密。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'summaries/',
          name: '摘要',
          purpose: '会话、阶段、章节、全书或上下文包摘要，供后续压缩与续写读取。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'knowledge/',
          name: '知识库',
          purpose: '资料、考据、可复用参考，不等同于已确认设定。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'inspiration/',
          name: '灵感',
          purpose: '尚未确认的脑洞、备选方案和零散想法；不要直接当作正文事实。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'assets/',
          name: '素材',
          purpose: '图片、封面、参考资料等资源。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'tasks/',
          name: '任务',
          purpose: '长任务流、章节原子任务、修订任务和检查点。',
        ),
        WorkspaceDirectoryDescriptor(
          path: 'reviews/',
          name: '审稿',
          purpose: '连续性、剧情、文风和综合检查报告。',
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
        WorkspaceDirectoryDescriptor(path: 'exports/', name: '导出包'),
      ];

  static const List<WorkspaceDirectoryDescriptor> internalWorkspaceDirs =
      <WorkspaceDirectoryDescriptor>[
        WorkspaceDirectoryDescriptor(path: '.novel_agent/', name: '内部状态'),
        WorkspaceDirectoryDescriptor(path: '.novel_agent/modes/', name: '模式状态'),
        WorkspaceDirectoryDescriptor(path: '.novel_agent/sqlite/', name: 'SQLite 索引'),
      ];
}
