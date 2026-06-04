import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'project_workspace_catalog.dart';

class ProjectPromptContract {
  String workspaceConvention() {
    // 中文注释: 工作空间约定集中由 core 输出，避免工具策略、上下文包和宿主页面各说各话。
    final lines = <String>[
      '## 工作空间约定',
      'NOVEL Agent 的项目按英文相对目录组织。工具调用只能使用项目内相对路径，不要使用绝对路径、终端路径或用户目录路径。',
      '',
      '用户可理解的创作目录：',
    ];
    for (final item in ProjectWorkspaceCatalog.userWorkspaceDirs) {
      lines.add('- **${item.name}**（${item.path}）：${item.purpose}');
    }
    lines.add('');
    lines.add('高级/系统目录通常由专用界面或工具维护，不要随意写入：');
    final advanced = ProjectWorkspaceCatalog.advancedWorkspaceDirs
        .map((item) => '${item.path}=${item.name}')
        .join('；');
    lines.add('- $advanced。');
    lines.add('');
    lines.add(
      '归档原则：题材、创作意图和项目承诺放 premise/；总纲、卷纲、章纲放 outlines/story/、outlines/volumes/、outlines/chapters/；章节正文、样章与连续正文放 chapters/；局部片段和场景稿放 scenes/；角色、组织、地点、物品、风格、世界、伏笔、关系、时间线放 assets/ 子目录；任务文档放 tasks/；分析结果放 analysis/；导出结果放 exports/。',
    );
    return lines.join('\n');
  }

  String directoryMappingLine() {
    // 中文注释: 目录映射只作为显示层释义，明确英文目录名才是工具协议里的唯一合法路径。
    final parts = ProjectWorkspaceCatalog.userWorkspaceDirs
        .map(
          (item) =>
              '${item.path.replaceAll(RegExp(r'/$'), '')}（界面显示为${item.name}）',
        )
        .join('，');
    return '英文目录名是工具协议唯一合法路径；中文仅用于界面显示。显示映射：$parts。';
  }

  String sessionInfo(
    JsonMap project,
    String intent, {
    JsonMap agent = const <String, Object?>{},
  }) {
    // 中文注释: 会话信息只做项目事实摘要，不掺杂工具调用或宿主状态判断。
    if (project.isEmpty) {
      return '当前没有打开项目。';
    }
    final lines = <String>[
      '当前项目：《${ValueReaders.stringValue(project['title'], '未命名项目')}》',
      '项目类型：${ValueReaders.stringValue(project['project_type'], 'novel')}',
      '主存储策略：${ValueReaders.stringValue(project['storage_strategy'], 'markdown_project_store')}',
      '项目阶段：${ValueReaders.stringValue(project['stage'], 'opening')}',
      '当前内容意图：$intent',
      '项目根路径：${ValueReaders.stringValue(project['path'])}（仅供系统定位；工具调用仍必须传项目相对路径）',
    ];
    final genre = ValueReaders.stringValue(project['genre']).trim();
    if (genre.isNotEmpty) {
      lines.add('题材：$genre');
    }
    final seedPrompt = ValueReaders.stringValue(project['seed_prompt']).trim();
    if (seedPrompt.isNotEmpty) {
      lines.add('创作种子：$seedPrompt');
    }
    final notes = ValueReaders.stringValue(project['notes']).trim();
    if (notes.isNotEmpty) {
      lines.add('项目备注：$notes');
    }
    final agentName = ValueReaders.stringValue(agent['name']).trim();
    if (agentName.isNotEmpty) {
      lines.add('当前智能体：$agentName');
    }
    return lines.join('\n');
  }

  String agentInstructions(JsonMap agent) {
    // 中文注释: 智能体设定段单独构造，是为了维持平台规则与角色规则的优先级边界。
    final lines = <String>[
      '## 当前智能体设定',
      '平台级规则用于保证项目安全和文件结构；智能体设定用于决定创作侧重。冲突时遵循：用户当前明确指令 > 项目规格/创作宪法 > 智能体设定 > 平台默认规则。',
      '',
      '智能体名称：${ValueReaders.stringValue(agent['name'], '综合创作智能体')}',
      '智能体职责：${ValueReaders.stringValue(agent['role'], '负责中文小说创作、规划、审稿和工具调度。')}',
    ];
    final agentPrompt = ValueReaders.stringValue(agent['system_prompt']).trim();
    if (agentPrompt.isNotEmpty) {
      lines.add('');
      lines.add('<agent_instructions>');
      lines.add(agentPrompt);
      lines.add('</agent_instructions>');
    }
    return lines.join('\n');
  }

  String agentBoundary(
    JsonMap agent, {
    List<JsonMap> optionalAgents = const <JsonMap>[],
    int maxAgents = 8,
  }) {
    // 中文注释: 主智能体与子智能体边界是核心规则，不应埋在 UI 呈现层里。
    final lines = <String>[
      '当前主智能体：${ValueReaders.stringValue(agent['name'], '综合创作智能体')}',
      '主智能体负责意图判断、上下文选择、工具决策和最终回答。',
      '子智能体只是可调用视角，只接收主智能体传递的任务、摘录和约束，不直接读取完整主会话上下文。',
    ];
    final optionalLines = <String>[];
    for (final item in optionalAgents) {
      final name = ValueReaders.stringValue(item['name']).trim();
      final role = ValueReaders.stringValue(item['role']).trim();
      if (name.isEmpty || role.isEmpty) {
        continue;
      }
      optionalLines.add(
        '- $name：${role.length <= 90 ? role : '${role.substring(0, 90)}...'}',
      );
      if (optionalLines.length >= maxAgents) {
        break;
      }
    }
    if (optionalLines.isEmpty) {
      lines.add('当前没有启用额外智能体组；可选预设仅作为后续组装素材。');
    } else {
      lines.add('可参考的协作视角素材：');
      lines.addAll(optionalLines);
    }
    return lines.join('\n');
  }

  String userTurnMessage(
    String prompt,
    JsonMap project,
    String intent, {
    JsonMap agent = const <String, Object?>{},
  }) {
    // 中文注释: 用户轮次消息由稳定标签包裹，降低模型把会话上下文误当用户正文的概率。
    return [
      '<user_query>',
      prompt.trim(),
      '</user_query>',
      '',
      '<session_info>',
      sessionInfo(project, intent, agent: agent),
      '</session_info>',
    ].join('\n');
  }

  String projectTreeSummary(List<JsonMap> files, {int maxLines = 120}) {
    // 中文注释: 项目树摘要是模型可读上下文，不是宿主命令输出，因此这里统一做文本渲染。
    if (files.isEmpty) {
      return '${directoryMappingLine()}\n项目目录为空或尚未加载。';
    }
    final lines = <String>[directoryMappingLine(), '项目文件目录结构：'];
    for (final item in files) {
      final path = ValueReaders.stringValue(item['relative_path']).trim();
      if (path.isEmpty) {
        continue;
      }
      final displayName = ValueReaders.stringValue(item['display_name']).trim();
      final isDir = ValueReaders.boolValue(item['is_dir']);
      final prefix = isDir ? '[目录]' : '[文件]';
      final _ = displayName;
      lines.add('$prefix $path');
      if (lines.length >= maxLines) {
        lines.add('...（目录过长，已截断；需要更多文件时先调用 list_project_files 或读取具体目录。）');
        break;
      }
    }
    return lines.join('\n');
  }

  String toolDecisionContract() {
    // 中文注释: 工具调用总原则由核心层统一维护，确保 GUI 和 CLI 触发的模型请求遵守同一规则。
    return [
      '## 工具调用原则',
      '1. 先判断用户真正要的是闲聊、创意选项、读取上下文、修订已有文件、生成正式产物，还是长任务推进。',
      '2. 不要为了显得主动而滥用工具；但需要项目事实、已有设定或文件写入时，也不要假装已经知道或已经保存。',
      '3. 用户要求“给我几个方案/选项/开局/方向”时，优先用选项工具展示可点击选择；不要把这种头脑风暴写入 chapters/。',
      '4. 写入前确认内容类型：章节正文、样章和连续正文默认进 chapters/；局部片段或实验场景进 scenes/；大纲进 outline/ 或 chapter_outlines/；设定进 world/ 或 assets/characters/；摘要进 summaries/。',
      '5. 修改或覆盖已有文件前先读取原文；修正同一个已存在文件时，优先 edit_project_file 精确修改，或在 write_project_file 中显式传 overwrite=true，避免生成重复文件。删除、恢复、覆盖等危险动作必须有明确用户意图，并尽量先备份。',
      '6. 共享叙事资产优先走专用工具：角色用 update_character_state，伏笔用 update_foreshadow_state，时间线用 update_timeline_state，关系用 update_relationship_state；不要把这些长期记忆混成随手写的普通 Markdown。',
      '7. 工具参数只写项目相对路径；Android/iOS 上也不要请求终端命令或外部用户目录权限。',
      '8. 正式章节交付优先使用 submit_chapter_delivery；不要把正文、sidecar 和交付状态拆成散乱的低层文件操作来冒充完成。',
      '9. 正式语义审稿优先使用 submit_semantic_review；自然语言点评、临时备注或 run_continuity_check 报告都不能替代结构化审稿交付。',
      '10. 项目级 narrative profile / 解释器更新优先使用 propose_narrative_profile_update；关键适用范围不明确时用 request_profile_clarification 停下等待。',
    ].join('\n');
  }

  String domainToolGuidance(
    String intent, {
    JsonMap agent = const <String, Object?>{},
  }) {
    // 中文注释: 领域工具收口规则按当前意图/角色切换，避免不同 prompt builder 各自散写固定文案。
    final normalizedIntent = intent.trim().toLowerCase();
    final lines = <String>[
      '## 领域工具收口',
      '示例只用于说明调用形态，不是题材、机制、世界观或叙事套路范本；不要把任何示例当成固定模板。',
      '遇到未知变化、混合题材或未覆盖设定时，保留原始变化和不确定性，不要擅自归类成常见套路。',
    ];
    if (_isProfileArchitect(agent, normalizedIntent)) {
      lines.addAll(<String>[
        '1. 设计或调整项目级叙事解释器 / 长期 profile 时，使用 propose_narrative_profile_update 提交结构化提案。',
        '2. 如果适用范围、保留策略、未知字段或未来扩展点存在关键歧义，调用 request_profile_clarification 停下来等待，不要擅自写死规则。',
        '3. 可以举例帮助说明，但例子不是范本；非常规题材、未知字段和未来扩展字段都要原样保留。',
      ]);
      return lines.join('\n');
    }
    if (_isReviewer(agent, normalizedIntent)) {
      lines.addAll(<String>[
        '1. 正式语义审稿必须调用 submit_semantic_review，提交结构化 findings 和 recommended_disposition。',
        '2. 不要把散文评论、任务调度建议或顺手修文冒充为 semantic review 交付。',
        '3. 如果还缺少关键证据，就在结构化审稿里明确标注缺口，而不是编造已确认结论。',
      ]);
      return lines.join('\n');
    }
    if (_isRecovery(agent, normalizedIntent)) {
      lines.addAll(<String>[
        '1. 本轮目标只能有一个：修复当前缺失/损坏的章节交付，或明确说明为什么仍然阻塞。',
        '2. 如果已经补齐正文、chapter_path 和必要交付信息，必须调用 submit_chapter_delivery 重新交付；不要顺手扩写下一章、改总纲或同时推进多个目标。',
        '3. 如果仍然无法交付，就只说明当前阻塞点和最小下一步，不要假装已经完成恢复。',
      ]);
      return lines.join('\n');
    }
    lines.addAll(<String>[
      '1. 需要正式交付章节、样章或补写结果时，必须调用 submit_chapter_delivery；不要只靠散文解释或低层文件工具假装已交付。',
      '2. 如果正文、chapter_path 或 submission sidecar 还不完整，就先补齐或明确阻塞，不要伪造成功交付。',
      '3. 若本轮只是给选项、结构建议或风险说明，不要把它们冒充成已经完成的章节交付。',
    ]);
    return lines.join('\n');
  }

  bool _isReviewer(JsonMap agent, String normalizedIntent) {
    if (normalizedIntent == 'review') {
      return true;
    }
    return _matchesAgent(agent, <String>['reviewer', '审稿', 'review']);
  }

  bool _isRecovery(JsonMap agent, String normalizedIntent) {
    if (normalizedIntent == 'recovery') {
      return true;
    }
    return _matchesAgent(agent, <String>['recovery', 'repair', '修复', '恢复']);
  }

  bool _isProfileArchitect(JsonMap agent, String normalizedIntent) {
    if (normalizedIntent == 'profile_architect' ||
        normalizedIntent == 'profile_architecture') {
      return true;
    }
    return _matchesAgent(agent, <String>[
      'profile_architect',
      'profile architect',
      '解释器',
      'profile',
      '叙事规则',
    ]);
  }

  bool _matchesAgent(JsonMap agent, List<String> tokens) {
    final haystack = <String>[
      ValueReaders.stringValue(agent['id']).toLowerCase(),
      ValueReaders.stringValue(agent['name']).toLowerCase(),
      ValueReaders.stringValue(agent['role']).toLowerCase(),
      ValueReaders.stringValue(agent['system_prompt']).toLowerCase(),
    ].join('\n');
    for (final token in tokens) {
      if (haystack.contains(token.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}
