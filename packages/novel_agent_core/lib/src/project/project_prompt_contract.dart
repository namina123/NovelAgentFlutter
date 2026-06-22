import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../project/project_storage_strategy.dart';
import 'project_workspace_catalog.dart';
import 'project_fact_acquisition_contract.dart';
import 'project_fact_acquisition_contract_service.dart';
import '../tools/project_storage_aware_tool_capability_matrix.dart';
import '../tools/project_tool_exposure_context.dart';

class ProjectPromptContract {
  ProjectPromptContract({
    ProjectFactAcquisitionContractService? factAcquisitionContractService,
  }) : _factAcquisitionContractService =
           factAcquisitionContractService ??
           const ProjectFactAcquisitionContractService();

  final ProjectFactAcquisitionContractService _factAcquisitionContractService;

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
      '归档原则：题材、创作意图和项目承诺放 premise/；总纲、卷纲、章纲放 outlines/story/、outlines/volumes/、outlines/chapters/；正式章节正文与连续正文放 chapters/；样章、开篇验证稿和非正式章节级试写放 samples/；局部片段和场景稿放 scenes/；角色、组织、地点、物品、风格、世界、伏笔、关系、时间线放 assets/ 子目录；任务文档放 tasks/；分析结果放 analysis/；导出结果放 exports/。',
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

  ProjectFactAcquisitionContract factAcquisitionContract({
    required String workflowId,
    String projectTypeId = 'novel',
    String intent = '',
  }) {
    return _factAcquisitionContractService.build(
      workflowId: workflowId,
      projectTypeId: projectTypeId,
      intent: intent,
    );
  }

  String factAcquisitionGuidance({
    required String workflowId,
    String projectTypeId = 'novel',
    String intent = '',
  }) {
    return factAcquisitionContract(
      workflowId: workflowId,
      projectTypeId: projectTypeId,
      intent: intent,
    ).renderMarkdown();
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
      '项目根路径：${_projectPathForPrompt(project)}（仅供系统定位；工具调用仍必须传项目相对路径）',
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
      '4. 写入前确认内容类型：正式章节正文和连续正文默认进 chapters/；样章、开篇验证稿和非正式章节级试写进 samples/；局部片段或实验场景进 scenes/；总纲/卷纲/章纲分别进 outlines/story/、outlines/volumes/、outlines/chapters/；设定进 assets/world/，角色进 assets/characters/；摘要进 summaries/。',
      '5. 修改或覆盖已有文件前先读取原文；修正同一个已存在文件时，优先 edit_project_file 精确修改，或在 write_project_file 中显式传 overwrite=true，避免生成重复文件。删除、恢复、覆盖等危险动作必须有明确用户意图，并尽量先备份。',
      '6. 共享叙事资产优先走专用工具：角色用 update_character_state，伏笔用 update_foreshadow_state，时间线用 update_timeline_state，关系用 update_relationship_state；不要把这些长期记忆混成随手写的普通 Markdown。',
      '7. 工具参数只写项目相对路径；Android/iOS 上也不要请求终端命令或外部用户目录权限。',
      '8. 正式章节交付优先使用 submit_chapter_delivery；不要把正文、sidecar 和交付状态拆成散乱的低层文件操作来冒充完成。',
      '9. 正式语义审稿优先使用 submit_semantic_review；自然语言点评、临时备注或 run_continuity_check 报告都不能替代结构化审稿交付。',
      '10. 项目级 narrative profile / 解释器更新优先使用 propose_narrative_profile_update；关键适用范围不明确时用 request_profile_clarification 停下等待。',
      '11. 当 sessionInfo 显示主存储策略为 sqlite_project_store 时，文件树工具只属于兼容/投影/修复层，不要把 write_project_file、edit_project_file、create_project_entry、move_project_file、delete_project_file、rename_project_file、reorder_project_file、manipulate_project_file_lines 当作默认主能力面。',
      '12. SQLite 项目里，submit_chapter_delivery、submit_narrative_state_claims、submit_semantic_review、知识/设计/研究/引用工具优先构成主链；read_project_file、list_project_files、get_project_file_info、search_project_files 只承担投影读取与兼容读取。',
    ].join('\n');
  }

  String storageAwareToolGuidance(JsonMap project) {
    // 中文注释: 这段把项目存储策略显式翻译成工具面说明，供 draft/system prompt 直接消费。
    final matrix = const ProjectStorageAwareToolCapabilityMatrix();
    final context = ProjectToolExposureContext(
      projectType: ValueReaders.stringValue(project['project_type'], 'novel'),
      storageStrategy: ProjectStorageStrategy.fromId(
        ValueReaders.stringValue(project['storage_strategy']),
      ),
    );
    return ['## 存储感知工具面', matrix.guidanceFor(context)].join('\n');
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
        '2. 连续性/状态复核时，优先依据正文、已知 claims 和 evidence 下结论；不要因为“多世界、回档、特殊机制”等题材关键词就自动判定通过或失败。',
        '3. 如果确认、质疑或补充了 claims，优先在 submit_semantic_review 中填写 accepted_claim_ids / questioned_claim_ids / suggested_claims；需要单独补充稳定状态变化时，可调用 submit_narrative_state_claims。',
        '4. 不要把散文评论、任务调度建议或顺手修文冒充为 semantic review 交付。',
        '5. 如果还缺少关键证据，就在结构化审稿里明确标注缺口，而不是编造已确认结论。',
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

  String informationToolGuidance(
    String intent, {
    JsonMap agent = const <String, Object?>{},
  }) {
    // 中文注释: information tools 的使用约束集中放在这里，确保 writer、deconstructor、researcher、reviewer 共享同一套知识/设计/研究/引用边界。
    final normalizedIntent = intent.trim().toLowerCase();
    final lines = <String>[
      '## Information Tools',
      '信息工具分四类：project knowledge 用 propose_knowledge_card；作品巧思/结构设计/符号系统/命名暗线用 propose_design_element；外部资料与联网结果先走 request_external_research / submit_research_note；引用作品边界与风险用 propose_reference_work。',
      '巧思、设计、符号系统、结构回扣、命名规律不能只写进正文、普通 Markdown 或聊天说明；如果它们会影响后续创作，必须通过 propose_design_element 提交。',
      '外部资料、网页摘录、检索结论和来源说明不能直接冒充长期设定；先形成 research request / research note，再根据稳定性决定是否提升为 knowledge card 或 design element proposal。',
      '发起资料收集时要显式区分 collection_mode：联网资料用 network，导入资料用 import，两者都需要时用 hybrid；客观事实、历史、科学、技术、法律、医学等资料必须在 source_requirements 中要求 rigorous sources，并保留不确定性。',
      '当项目涉及架空历史、历史科技、制度边界、生产工艺、普通人可否实施、阶层/许可/成本/风险等可行性问题时，资料收集不能只查时代背景；应同时收集技术基线、材料工具、制度/法律/行业管制、社会执行成本，并按用户世界观严谨度判断是严格遵循、软架空放宽，还是明确作为有意违背规则的剧情设计。',
      '联网研究要尽量保留多个候选来源、来源质量、引用地址和不确定性；导入研究要保留候选片段，不要把导入文本直接改写成未经确认的长期规则。',
      '如果只是发现来源证据、章节片段和已有知识/设计之间的可追踪关系，优先使用 link_information_evidence，而不是把来源线索埋进自然语言。',
      '如果本轮没有显著的新长期信息、没有稳定证据、或仍然只是模糊猜测，就不要编造 knowledge/design/research/reference 交付，也不要为了显得积极而强行调用信息工具。',
      '示例只能说明工具形态，不是题材、文化母题、世界观或叙事套路范本；不要把任何示例当作默认方案。',
    ];
    if (_isReviewer(agent, normalizedIntent)) {
      lines.addAll(<String>[
        'reviewer 重点：正式审稿发现的证据链、来源缺口、引用边界或高风险资料，应优先补 link_information_evidence、submit_research_note 或 propose_reference_work；不要把“需要补证据”只写成散文评语。',
        '如果你只是指出“这里可能有巧思/长期规则”，但尚未形成稳定事实，就明确标注缺口；不要伪造已经提交过的信息卡。',
      ]);
      return lines.join('\n');
    }
    if (_isResearcher(agent, normalizedIntent)) {
      lines.addAll(<String>[
        'researcher 重点：需要外部资料时，先 request_external_research，并填写 collection_mode、information_domain、source_requirements、extraction_policy；拿到来源后再 submit_research_note。只有当研究结论已经稳定且适合进入项目长期记忆时，才继续 propose_knowledge_card 或 propose_design_element。',
        '不要把联网摘录、引用原文或未经确认的研究结论直接包装成项目既定设定。',
      ]);
      return lines.join('\n');
    }
    if (_isDeconstructor(agent, normalizedIntent)) {
      lines.addAll(<String>[
        'deconstructor 重点：从原文、拆书分析或续写承接中提炼出的结构巧思、象征系统、命名暗线、章节回扣，优先 propose_design_element；明确世界事实、规则或可复用设定再用 propose_knowledge_card。',
        '来源片段、章节证据和分析依据应保持可追踪；如果只是暂时观察到一种可能解释，不要冒充成已确认设计规则。',
      ]);
      return lines.join('\n');
    }
    if (_isWriter(agent, normalizedIntent)) {
      lines.addAll(<String>[
        'writer 重点：写作中如果顺带确定了新的长期世界事实，可用 propose_knowledge_card；如果发现了可复用的巧思、结构呼应、象征系统或命名规律，必须用 propose_design_element，不要只留在正文里等下一轮遗忘。',
        '如果本章形成了明确且稳定的状态变化，优先在 submit_chapter_delivery 的 submission.claims 中附带，或单独调用 submit_narrative_state_claims；如果没有显著变化，允许空 claims，不要编造。',
        '如果当前任务承接前文，submit_chapter_delivery 的 submission 不要只留空壳；至少填写本章 summary，并在 final_state_summary 中写明章末人物所处位置、正在进行的动作/目标、仍未完成的悬念，以及下一章应从哪个已落定状态继续，避免开头倒带重演上一章末尾。',
        '如果会话上下文里出现“章节承接 Gate”或 continuity_checkpoint，把它当成章节推进硬约束，不是表达风格建议：正文第一段就要承接上一章已落定状态，直接推进新的回应、动作或结果，不要回退重演寻路、敲门、到达、开门或重复对话开场。',
        '如果本轮只是正常推进章节、没有新增显著长期信息，就专注交付正文，不要为了凑工具而编造知识卡或设计卡。',
      ]);
      return lines.join('\n');
    }
    lines.addAll(<String>[
      '通用重点：长期事实走 knowledge，作品巧思走 design，外部资料先 research，再按需要提升为 knowledge/design，引用边界走 reference。',
      '如果角色/模式不明确，仍然遵守“不编造、不强提、先 research note 再 proposal、巧思必须走 propose_design_element”的最低规则。',
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

  bool _isResearcher(JsonMap agent, String normalizedIntent) {
    if (normalizedIntent == 'research' ||
        normalizedIntent == 'researcher' ||
        normalizedIntent == 'external_research') {
      return true;
    }
    return _matchesAgent(agent, <String>['researcher', 'research', '研究']);
  }

  bool _isDeconstructor(JsonMap agent, String normalizedIntent) {
    if (normalizedIntent == 'deconstruction' ||
        normalizedIntent == 'deconstructor') {
      return true;
    }
    return _matchesAgent(agent, <String>[
      'deconstructor',
      'deconstruction',
      '拆书',
      '解构',
    ]);
  }

  bool _isWriter(JsonMap agent, String normalizedIntent) {
    if (normalizedIntent == 'draft' ||
        normalizedIntent == 'chapter' ||
        normalizedIntent == 'write' ||
        normalizedIntent == 'writer') {
      return true;
    }
    return _matchesAgent(agent, <String>['writer', '写作', '正文', '作者']);
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
    // 中文注释: 角色分类只看权威身份字段（id/name/role）。system_prompt 是长自由文本，
    // 任意提及关键词（如“审稿”“研究”）都会误命中，导致 agent 被错分类、注入错误的领域
    // 工具指引；故不纳入匹配 haystack。
    final haystack = <String>[
      ValueReaders.stringValue(agent['id']).toLowerCase(),
      ValueReaders.stringValue(agent['name']).toLowerCase(),
      ValueReaders.stringValue(agent['role']).toLowerCase(),
    ].join('\n');
    for (final token in tokens) {
      if (haystack.contains(token.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  String _projectPathForPrompt(JsonMap project) {
    final pathHint = ValueReaders.stringValue(project['path_hint']).trim();
    if (pathHint.isNotEmpty) {
      return pathHint;
    }
    final rawPath = ValueReaders.stringValue(project['path']).trim();
    if (rawPath.isEmpty || _looksAbsolutePath(rawPath)) {
      return '项目工作区根目录';
    }
    return rawPath;
  }

  bool _looksAbsolutePath(String path) {
    if (path.startsWith('/')) {
      return true;
    }
    return RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path);
  }
}
