import 'builtin_tool_definition.dart';

final class BuiltinToolCatalog {
  static const List<BuiltinToolDefinition> definitions =
      <BuiltinToolDefinition>[
        BuiltinToolDefinition(
          id: 'list_project_files',
          name: '读取目录结构',
          description: '让 AI 了解项目文件夹和文件树。',
        ),
        BuiltinToolDefinition(
          id: 'read_project_file',
          name: '读取项目文件',
          description: '读取风格、设定、大纲、正文、摘要等文本。',
        ),
        BuiltinToolDefinition(
          id: 'write_project_file',
          name: '写入项目文件',
          description: '把草稿、正式正文和其他产物写入正确英文目录；修正同一路径时要显式 overwrite。',
        ),
        BuiltinToolDefinition(
          id: 'edit_project_file',
          name: '修改项目文件',
          description: '对已有文件追加、替换、前置或覆盖。',
        ),
        BuiltinToolDefinition(
          id: 'delete_project_file',
          name: '删除项目文件',
          description: '危险能力，默认关闭；开启后仍受删除权限控制。',
          enabledByDefault: false,
        ),
        BuiltinToolDefinition(
          id: 'present_user_options',
          name: '展示用户选项',
          description: '让 AI 用可点击按钮向用户列出方案。',
        ),
        BuiltinToolDefinition(
          id: 'set_agent_tasks',
          name: '设定智能体任务',
          description: '让 AI 为自己声明阶段目标和任务清单。',
        ),
        BuiltinToolDefinition(
          id: 'load_agent_skill',
          name: '按需读取技能说明',
          description: '只在当前任务需要某个技能时读取该技能的完整说明，避免把所有技能一次性塞进上下文。',
        ),
        BuiltinToolDefinition(
          id: 'call_sub_agent',
          name: '委派子智能体',
          description: '把明确子任务交给当前智能体组内的子智能体执行，并把结果返回主智能体整合。',
        ),
        BuiltinToolDefinition(
          id: 'update_world_state',
          name: '更新世界书',
          description: '把世界规则、地点、势力、术语、伏笔等长期记忆写入 world/。',
        ),
        BuiltinToolDefinition(
          id: 'update_character_state',
          name: '更新角色状态',
          description: '把角色卡、关系、当前状态和口吻写入 characters/。',
        ),
        BuiltinToolDefinition(
          id: 'create_chapter_task',
          name: '创建章节任务',
          description: '为长任务流创建章节或场景原子任务。',
        ),
        BuiltinToolDefinition(
          id: 'mark_task_status',
          name: '标记任务状态',
          description: '更新任务状态、说明和输出文件。',
        ),
        BuiltinToolDefinition(
          id: 'summarize_context',
          name: '保存上下文摘要',
          description: '把会话、阶段、章节或上下文包摘要保存到 summaries/。',
        ),
        BuiltinToolDefinition(
          id: 'run_continuity_check',
          name: '保存连续性检查',
          description: '保存角色、世界规则、时间线、伏笔和风格检查报告。',
        ),
        BuiltinToolDefinition(
          id: 'create_backup',
          name: '创建备份',
          description: '为项目内文件创建 backups/ 备份。',
        ),
        BuiltinToolDefinition(
          id: 'restore_backup',
          name: '恢复备份',
          description: '从 backups/ 恢复文件；危险能力，默认关闭。',
          enabledByDefault: false,
        ),
        BuiltinToolDefinition(
          id: 'get_project_file_info',
          name: '读取文件信息',
          description: '读取文件行数、字数和可选行范围。',
        ),
        BuiltinToolDefinition(
          id: 'search_project_files',
          name: '搜索项目文件',
          description: '在项目文本中搜索关键词并返回匹配行摘要。',
        ),
        BuiltinToolDefinition(
          id: 'create_project_entry',
          name: '创建项目条目',
          description: '创建文件或文件夹；正式产物优先使用写入项目文件。',
          enabledByDefault: false,
        ),
        BuiltinToolDefinition(
          id: 'move_project_file',
          name: '移动项目文件',
          description: '移动当前项目内文件；危险能力，默认关闭。',
          enabledByDefault: false,
        ),
        BuiltinToolDefinition(
          id: 'reorder_project_file',
          name: '重排项目文件',
          description: '识别文件排序请求；当前无排序元数据时会返回未执行。',
          enabledByDefault: false,
        ),
        BuiltinToolDefinition(
          id: 'rename_project_file',
          name: '重命名项目文件',
          description: '重命名当前项目内文件；危险能力，默认关闭。',
          enabledByDefault: false,
        ),
        BuiltinToolDefinition(
          id: 'rename_project',
          name: '重命名项目',
          description: '修改当前项目显示标题，不移动磁盘目录。',
          enabledByDefault: false,
        ),
        BuiltinToolDefinition(
          id: 'manipulate_project_file_lines',
          name: '行级处理文件',
          description: '按行复制、剪切或删除文本；危险能力，默认关闭。',
          enabledByDefault: false,
        ),
        BuiltinToolDefinition(
          id: 'list_history_sessions',
          name: '读取历史会话',
          description: '读取当前项目的历史会话摘要。',
        ),
        BuiltinToolDefinition(
          id: 'request_gateway_tool',
          name: '请求网关工具',
          description: '请求桌面端或远程 Gateway 执行联网、命令、媒体等高级能力。',
          enabledByDefault: false,
        ),
      ];
}
