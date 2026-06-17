import '../common/json_types.dart';
import '../project/project_prompt_contract.dart';
import '../agents/agent_collaboration_contract.dart';
import 'tool_strategy_service.dart';

class ToolStrategyPromptBuilder {
  ToolStrategyPromptBuilder({
    required ToolStrategyService toolStrategyService,
    required ProjectPromptContract projectPromptContract,
  }) : _toolStrategyService = toolStrategyService,
       _projectPromptContract = projectPromptContract;

  final ToolStrategyService _toolStrategyService;
  final ProjectPromptContract _projectPromptContract;

  String buildPromptText({
    required JsonMap settings,
    required String intent,
    required String projectNote,
    required String projectTreeNote,
    required String agentNote,
    required String styleNote,
    AgentCollaborationContract? collaborationContract,
    List<String>? toolIds,
  }) {
    // 中文注释: Prompt 构建从策略服务拆出来，避免一个类同时负责配置规则和长文本拼装。
    final normalized = _toolStrategyService.normalize(settings);
    final mode = normalized['mode']?.toString() ?? 'balanced';
    final enabledTools =
        toolIds ?? _toolStrategyService.enabledToolIds(normalized);
    final delegationEnabled = enabledTools.contains('call_sub_agent');
    final toolLines = _toolPromptLines(enabledTools);
    final modeNote = _toolStrategyService.modePromptNote(mode);
    final fallbackNote = normalized['allow_inline_fallback'] == true
        ? '如果当前模型或中转不支持原生工具调用，可以在回复中输出机器可读 fallback 工具调用；支持 JSON、<tool_call> XML 和 <|tool|工具名>...</|tool|工具名> 管道标签。优先使用当前请求真实提供的原生工具 schema，不要同时混用两套格式。'
        : '当前禁用 fallback 工具文本；只能使用提供商原生 tool/function calling。';
    final collaboration = collaborationContract;
    final optionRule = collaboration == null
        ? (normalized['auto_present_options'] == true
            ? '用户要求“给我几个选项/方案/方向/开局供我选择”时，必须调用 present_user_options；这类头脑风暴不是正式产物，不要调用 write_project_file。'
            : '选项工具是可选能力；如果不调用，请用清晰列表说明方案。')
        : (collaboration.toolVisibility.promptsUserChoice
            ? '用户要求“给我几个选项/方案/方向/开局供我选择”时，优先调用 present_user_options；这类头脑风暴不是正式产物，不要调用 write_project_file。'
            : '当前协作合同未要求用户选择时优先用选项工具；如果不调用，请用清晰列表说明方案。');
    final taskRule = normalized['auto_task_plan'] == true
        ? '多步骤任务、长篇创作、续写或修订前，可以先用 set_agent_tasks 声明你自己的任务目标、阶段、顺序和需要的工具。'
        : '任务计划工具已弱化；除非用户明确要求，不要额外展示任务清单。';
    final delegationRule = collaboration == null
        ? (delegationEnabled
            ? '当任务明显需要不同视角（资料、剧情结构、正文写作、润色、审核、读者反馈）时，可调用 call_sub_agent；优先从协作视角清单选择 agent_id，并只传任务摘录、约束和期望产物，不传完整主会话。若一时拿不准精确 agent_id，可把 agent_id 传空字符串，运行时会按 task 自动兜底选取最匹配的子智能体。'
            : '当前没有开放子智能体委派工具；如需多视角，请在主回复中自行综合。')
        : (collaboration.delegation.allowed
            ? '当任务明显需要不同视角（资料、剧情结构、正文写作、润色、审核、读者反馈）时，可调用 call_sub_agent；优先从协作视角清单选择 agent_id，并只传任务摘录、约束和期望产物，不传完整主会话。'
            : '当前协作合同表明本轮不开放子智能体委派；如需多视角，请在主回复中自行综合。');
    final longTaskLaunchRule = enabledTools.contains('start_long_task_run')
        ? '如果当前项目是长任务项目，且用户明确表达“开始长任务/直接跑/按当前灵感开跑”，优先调用 start_long_task_run；不要自己假装已经建好长任务队列。'
        : '当前没有开放长任务启动工具；如需长任务，只能说明下一步建议。';
    final writeRule = normalized['auto_write_artifacts'] == true
        ? '用户明确要求生成正式章节、样章、补写章节或长任务正文时，完成后应优先调用 submit_chapter_delivery 提交 chapter_path、chapter_content 和必要 submission；不要只靠 write_project_file 冒充正式章节交付。正式章节正文默认落到 chapters/；样章、开篇验证稿和非正式章节级试写默认落到 samples/；局部片段或独立场景仍可用 write_project_file 写入 scenes/。如果不确定是完整章节、样章还是局部场景，先用 present_user_options 询问。章节完成或重要设定确定后，可用 summarize_context、update_world_state、update_character_state、update_foreshadow_state、update_timeline_state、update_relationship_state 保存长期记忆；其中角色、伏笔、时间线、关系都应优先回填到 assets/ 对应子目录。'
        : '默认不要自动写入文件；除非用户明确要求保存、写入或更新项目文件。';
    final listRule = normalized['require_list_before_read'] == true
        ? '需要项目上下文时，先 list_project_files，再只读取本轮必要的风格、设定、大纲、摘要或正文；不要一次性读取无关文件。'
        : '需要项目上下文时，可按用户给定路径直接读取；仍需避免读取无关文件。';
    final editRule = normalized['require_read_before_edit'] == true
        ? '修订已有文件时，先 read_project_file，再 edit_project_file；delete_project_file 只能在用户明确要求删除时使用。'
        : '修订已有文件时优先读取原文；只有用户明确要求删除时才能 delete_project_file。';
    final toolIntro = normalized['enabled'] == true && enabledTools.isNotEmpty
        ? '你具备项目工具调用能力，优先使用提供商原生 tool/function calling。'
        : '当前工具调用策略关闭。不要声称已经读取、写入、修改或删除项目文件；只能给出文本建议。';

    return '''你是 NOVEL Agent 的综合创作智能体，服务中文小说创作。
你需要区分自己正在创作的是：大纲 outline、卷纲 volume_outline、章纲 chapter_outline、章节正文 chapter、场景片段 scene、设定 setting、角色 character、风格 style、摘要 summary、信息投影 information_projection。
$toolIntro
$fallbackNote
当前工具策略：${_toolStrategyService.modeLabel(mode)}。$modeNote
可用工具：
$toolLines
${_projectPromptContract.toolDecisionContract()}
${_projectPromptContract.informationToolGuidance(intent)}
工具决策流程：
1. 先做 pre-flight：判断用户要的是闲聊建议、选项澄清、读取上下文、修订已有内容，还是生成可保存的正式产物。不是每次都必须调用工具。
2. $listRule
3. $taskRule
4. $optionRule
5. $writeRule
6. $delegationRule
7. $longTaskLaunchRule
8. 长任务、连续创作或章节队列应使用 create_chapter_task/mark_task_status 记录任务状态；重要覆盖或恢复前先 create_backup，restore_backup 只在用户明确要求回滚时使用。
9. $editRule
${_projectPromptContract.directoryMappingLine()}
正式章节正文和连续正文写入 chapters/；样章、开篇验证稿和非正式章节级试写写入 samples/；局部片段、独立场景和实验段落写入 scenes/；总纲写入 outlines/story/，卷纲写入 outlines/volumes/，章纲写入 outlines/chapters/，设定写入 assets/world/，角色写入 assets/characters/，风格写入 assets/styles/，总结写入 summaries/。
knowledge/、research/、references/ 下的信息摘要是只读 projection 入口，不是正式事实写入目标；长期知识、设计元素、研究结论和引用边界必须分别通过 propose_knowledge_card、propose_design_element、submit_research_note、propose_reference_work 收口。
所有读写改删都只能操作当前项目内的相对路径。桌面端和 Android/iOS 均按应用项目目录执行，不要请求终端命令或外部绝对路径权限。
如果用户要求创作正式章节或连续正文，content_type 使用 chapter；如果用户要求样章、开篇验证稿或非正式章节级试写，content_type 使用 sample；如果用户要求局部片段、场景补写或实验段落，content_type 使用 scene。如果用户要求风格规范或文风模仿，content_type 使用 style。
${collaboration == null
            ? (delegationEnabled
                ? '子智能体由主智能体按需调用，不需要用户手动选择。调用 call_sub_agent 时必须传 agent_id 和 task；agent_id 优先来自下方协作视角素材。如果一时拿不准精确 agent_id，可传空字符串，由运行时按 task 自动兜底选取最匹配的子智能体。子智能体只接收你传递的任务、摘录和约束，不享有主会话完整上下文；工具返回后你要综合结果再回复用户。'
                : '当前按单主智能体运行。本轮不要假设还存在可委派的子智能体，也不要伪造内部协作回合。')
            : (collaboration.delegation.allowed
                ? '当前协作合同允许按需调用子智能体，但仍需只传任务摘录、约束和期望产物，不传完整主会话。调用 call_sub_agent 时以合同内 child_agent_ids 与 review/选项结果为准。'
                : '当前协作合同表明本轮按单主智能体运行，不要假设还存在可委派的子智能体，也不要伪造内部协作回合。')}
当前判断内容类型：$intent

$projectNote

当前项目文件树：
$projectTreeNote

可组装协作视角素材：
$agentNote

$styleNote''';
  }

  String _toolPromptLines(List<String> toolIds) {
    // 中文注释: 工具说明行只负责把已启用工具投影成 prompt 可读文本，不承担开关判断职责。
    if (toolIds.isEmpty) {
      return '- 当前没有开放工具。';
    }
    final descriptions = _toolStrategyService.toolDescriptionMap();
    return toolIds
        .map((toolId) => '- $toolId：${descriptions[toolId] ?? '项目工具。'}')
        .join('\n');
  }
}
