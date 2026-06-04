import 'builtin_tool_definition.dart';
import 'tool_platform_policy.dart';

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
          description: '把章节正文、场景片段和其他产物写入正确英文目录；修正同一路径时要显式 overwrite。',
        ),
        BuiltinToolDefinition(
          id: 'submit_chapter_delivery',
          name: '提交章节交付',
          description: '一次性提交章节正文、目标路径和结构化 submission，由受控领域合同完成章节交付。',
        ),
        BuiltinToolDefinition(
          id: 'submit_narrative_state_claims',
          name: '提交叙事状态声明',
          description: '提交开放叙事状态 claims，保留未知 namespace 和 payload，不做文学语义判断。',
        ),
        BuiltinToolDefinition(
          id: 'propose_narrative_profile_update',
          name: '提出项目叙事解释器更新',
          description: '提出项目级 narrative profile 更新提案，只做结构化校验，不直接覆盖长期规则。',
        ),
        BuiltinToolDefinition(
          id: 'submit_semantic_review',
          name: '提交语义复核',
          description: '提交 reviewer 的结构化 findings 和 disposition 建议，不直接推进调度。',
        ),
        BuiltinToolDefinition(
          id: 'propose_constraint_binding',
          name: '提出约束绑定',
          description: '提出项目级或阶段级约束绑定，保留开放 constraint payload，不把题材写死进程序。',
        ),
        BuiltinToolDefinition(
          id: 'request_profile_clarification',
          name: '请求规则澄清',
          description: '在缺少关键信息时提出一个小而具体的澄清问题，等待用户确认后继续。',
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
          id: 'start_long_task_run',
          name: '启动长任务',
          description: '仅在长任务项目中可用；根据当前模式引导状态生成正式长任务队列。',
        ),
        BuiltinToolDefinition(
          id: 'set_agent_tasks',
          name: '设定智能体任务',
          description: '让 AI 为自己声明阶段目标和任务清单。',
        ),
        BuiltinToolDefinition(
          id: 'load_agent_skill',
          name: '按需读取技能说明',
          description: '按阶段策略读取技能摘要；确实需要时再读取 full 或指定 reference_path，避免反复整份加载。',
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
          description: '更新 assets/characters/ 下的角色主档，并同步 latest 状态与历史附录。',
        ),
        BuiltinToolDefinition(
          id: 'update_foreshadow_state',
          name: '更新伏笔状态',
          description: '更新 assets/foreshadows/ 下的伏笔主档，记录埋设、推进、回收与风险状态。',
        ),
        BuiltinToolDefinition(
          id: 'update_timeline_state',
          name: '更新时间线',
          description: '更新 assets/timeline/ 下的时间线事件与阶段顺序。',
        ),
        BuiltinToolDefinition(
          id: 'update_relationship_state',
          name: '更新关系状态',
          description: '更新 assets/relationships/ 下的关键关系变化与当前状态。',
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
          platformPolicy: ToolPlatformPolicy.transportOnly,
          enabledByDefault: false,
        ),
      ];
}
