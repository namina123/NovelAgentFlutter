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
      '归档原则：头脑风暴和备选方案放 inspiration/；未确认章节正文和样章草稿放 drafts/；用户确认后的正式正文放 chapters/；确认后的长期规则放 specs/、styles/、world/ 或 characters/；总结和压缩记忆放 summaries/。',
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
      '4. 写入前确认内容类型：草稿 draft 进 drafts/；正式正文 chapter 进 chapters/；大纲进 outline/ 或 chapter_outlines/；设定进 world/ 或 characters/；摘要进 summaries/。',
      '5. 修改或覆盖已有文件前先读取原文；修正同一个已存在文件时，优先 edit_project_file 精确修改，或在 write_project_file 中显式传 overwrite=true，避免生成重复文件。删除、恢复、覆盖等危险动作必须有明确用户意图，并尽量先备份。',
      '6. 工具参数只写项目相对路径；Android/iOS 上也不要请求终端命令或外部用户目录权限。',
    ].join('\n');
  }
}
