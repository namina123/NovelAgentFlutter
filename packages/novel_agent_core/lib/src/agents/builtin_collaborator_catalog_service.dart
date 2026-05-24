import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_group_normalizer_service.dart';
import 'agent_profile_normalizer_service.dart';

class BuiltinCollaboratorCatalogService {
  BuiltinCollaboratorCatalogService({
    AgentProfileNormalizerService? profileNormalizerService,
    AgentGroupNormalizerService? groupNormalizerService,
  }) : _profileNormalizerService =
           profileNormalizerService ?? AgentProfileNormalizerService(),
       _groupNormalizerService =
           groupNormalizerService ?? AgentGroupNormalizerService();

  final AgentProfileNormalizerService _profileNormalizerService;
  final AgentGroupNormalizerService _groupNormalizerService;

  List<JsonMap> optionalCollaboratorProfiles() {
    // 中文注释: 这里保留旧项目多智能体协作所需的内置子智能体素材，供主智能体运行时直接复用。
    return _rawProfiles
        .map(_profileNormalizerService.normalizeAgentProfile)
        .toList(growable: false);
  }

  List<JsonMap> optionalCollaboratorGroups() {
    // 中文注释: 内置协作组只输出轻量合同，真正执行策略仍由上层运行时服务决定。
    return _rawGroups
        .map(_groupNormalizerService.normalizeAgentGroup)
        .toList(growable: false);
  }

  JsonMap groupById(String groupId) {
    // 中文注释: 协作组按 id 查询统一收口，避免调用方自行线性扫描和处理空值。
    for (final group in optionalCollaboratorGroups()) {
      if (ValueReaders.stringValue(group['id']) == groupId) {
        return ValueReaders.deepCopyMap(group);
      }
    }
    return <String, Object?>{};
  }

  static const List<JsonMap> _rawProfiles = <JsonMap>[
    <String, Object?>{
      'id': 'editor_in_chief',
      'name': '主编',
      'role': '拆解目标、推进阶段、审查结果，并决定下一步调用哪些技能或子智能体。',
      'description': '用于多智能体协作中的统筹视角，关注目标、阶段、验收、风险和下一步。',
      'source': 'builtin',
      'source_scope': 'builtin',
      'enabled_by_default': false,
      'builtin_preset': 'optional_multi_agent',
      'customizable': true,
      'stages': <String>['opening', 'plot', 'outline', 'draft'],
      'skills': <String>[
        'ask_opening_questions',
        'generate_outline',
        'check_continuity',
        'summarize_chapter',
      ],
      'skill_groups': <String>[
        'read_only',
        'interactive_planning',
        'memory_tools',
        'task_flow',
      ],
      'provider_profile': 'default',
      'thinking_supported': true,
      'thinking_enabled': false,
      'thinking_effort': 'high',
      'temperature': 0.7,
      'top_p': 0.9,
      'top_k': 0,
      'system_prompt':
          '你是 NOVEL Agent 内部协作中的主编视角。你优先识别目标、阶段、风险和验收标准，并把复杂任务拆成可执行步骤。',
    },
    <String, Object?>{
      'id': 'writer',
      'name': '作者',
      'role': '负责正文生成、续写、改写和局部润色，优先维护叙事声音、场景节拍和阅读节奏。',
      'description': '用于章节草稿、场景扩写和文本改写的创作视角。',
      'source': 'builtin',
      'source_scope': 'builtin',
      'enabled_by_default': false,
      'builtin_preset': 'optional_multi_agent',
      'customizable': true,
      'stages': <String>['draft'],
      'skills': <String>['chapter_drafting_method', 'summarize_chapter'],
      'skill_groups': <String>['project_io', 'memory_tools', 'task_flow'],
      'provider_profile': 'default',
      'thinking_supported': true,
      'thinking_enabled': false,
      'thinking_effort': 'high',
      'temperature': 0.95,
      'top_p': 0.97,
      'top_k': 0,
      'system_prompt': '你是 NOVEL Agent 的作者视角，专注中文小说正文。你只返回可供主智能体合并的草稿片段、建议或风险。',
    },
    <String, Object?>{
      'id': 'plot_architect',
      'name': '剧情专家',
      'role': '负责冲突、节奏、伏笔、反转和章节推进方案。',
      'description': '用于大纲、卷纲、章纲和剧情结构检查。',
      'source': 'builtin',
      'source_scope': 'builtin',
      'enabled_by_default': false,
      'builtin_preset': 'optional_multi_agent',
      'customizable': true,
      'stages': <String>['plot', 'outline', 'draft'],
      'skills': <String>['generate_outline', 'check_continuity'],
      'skill_groups': <String>[
        'read_only',
        'interactive_planning',
        'memory_tools',
        'task_flow',
      ],
      'provider_profile': 'default',
      'thinking_supported': true,
      'thinking_enabled': false,
      'thinking_effort': 'high',
      'temperature': 0.75,
      'top_p': 0.92,
      'top_k': 0,
      'system_prompt': '你是 NOVEL Agent 的剧情结构视角。你关注主线目标、冲突升级和章节功能，只返回结构建议与风险。',
    },
    <String, Object?>{
      'id': 'continuity_keeper',
      'name': '设定专家',
      'role': '维护世界观、角色状态、规则一致性和前后文连续性。',
      'description': '用于世界书、角色状态、设定冲突和连续性风险检查。',
      'source': 'builtin',
      'source_scope': 'builtin',
      'enabled_by_default': false,
      'builtin_preset': 'optional_multi_agent',
      'customizable': true,
      'stages': <String>['plot', 'outline', 'draft'],
      'skills': <String>[
        'world_bible_design',
        'memory_maintenance',
        'check_continuity',
      ],
      'skill_groups': <String>['project_io', 'memory_tools'],
      'provider_profile': 'default',
      'thinking_supported': true,
      'thinking_enabled': false,
      'thinking_effort': 'high',
      'temperature': 0.55,
      'top_p': 0.85,
      'top_k': 0,
      'system_prompt': '你是 NOVEL Agent 的设定与连续性视角。你给证据、影响范围和最小修复建议，没有证据时只标疑点。',
    },
    <String, Object?>{
      'id': 'reader_lens',
      'name': '读者视角',
      'role': '模拟读者期待、疑惑和爽点反馈，帮助判断可读性与继续阅读动机。',
      'description': '用于开局吸引力、章节可读性、爽点和弃读风险判断。',
      'source': 'builtin',
      'source_scope': 'builtin',
      'enabled_by_default': false,
      'builtin_preset': 'optional_multi_agent',
      'customizable': true,
      'stages': <String>['opening', 'plot', 'draft'],
      'skills': <String>['reader_feedback', 'summarize_chapter'],
      'skill_groups': <String>[
        'read_only',
        'interactive_planning',
        'memory_tools',
      ],
      'provider_profile': 'default',
      'thinking_supported': true,
      'thinking_enabled': false,
      'thinking_effort': 'medium',
      'temperature': 0.8,
      'top_p': 0.92,
      'top_k': 0,
      'system_prompt': '你是 NOVEL Agent 的读者视角。你说明哪里吸引、哪里困惑、哪里可能弃读，并保留作品特色。',
    },
    <String, Object?>{
      'id': 'prose_reviewer',
      'name': '文风审稿',
      'role': '检查文风一致性、叙述节奏、对白质感、段落流动和可读性，只给修改建议。',
      'description': '用于语言层面的审稿、润色建议和修订风险提示。',
      'source': 'builtin',
      'source_scope': 'builtin',
      'enabled_by_default': false,
      'builtin_preset': 'optional_multi_agent',
      'customizable': true,
      'stages': <String>['draft', 'revision'],
      'skills': <String>[
        'revision_workflow',
        'check_continuity',
        'reader_feedback',
      ],
      'skill_groups': <String>['read_only', 'memory_tools'],
      'provider_profile': 'default',
      'thinking_supported': true,
      'thinking_enabled': false,
      'thinking_effort': 'high',
      'temperature': 0.65,
      'top_p': 0.88,
      'top_k': 0,
      'system_prompt': '你是 NOVEL Agent 的文风审稿视角。你的建议必须具体到问题、证据和改法。',
    },
    <String, Object?>{
      'id': 'context_researcher',
      'name': '资料检索员',
      'role': '只按目标读取项目资料、风格、设定、摘要和知识库，避免把无关文件塞进上下文。',
      'description': '用于查找当前任务需要的最小项目资料和 source_paths。',
      'source': 'builtin',
      'source_scope': 'builtin',
      'enabled_by_default': false,
      'builtin_preset': 'optional_multi_agent',
      'customizable': true,
      'stages': <String>['opening', 'plot', 'outline', 'draft', 'summary'],
      'skills': <String>['project_context_research', 'summarize_chapter'],
      'skill_groups': <String>['read_only', 'memory_tools'],
      'provider_profile': 'default',
      'thinking_supported': true,
      'thinking_enabled': false,
      'thinking_effort': 'medium',
      'temperature': 0.45,
      'top_p': 0.85,
      'top_k': 0,
      'system_prompt': '你是 NOVEL Agent 的资料检索视角。你返回路径清单、关键摘录摘要和风险缺口，供主智能体合并。',
    },
    <String, Object?>{
      'id': 'workflow_keeper',
      'name': '创作管家',
      'role': '负责版本、备份、任务进度、检查点和写作会话收尾建议。',
      'description': '用于长任务、任务队列、备份和收尾检查。',
      'source': 'builtin',
      'source_scope': 'builtin',
      'enabled_by_default': false,
      'builtin_preset': 'optional_multi_agent',
      'customizable': true,
      'stages': <String>['draft', 'summary', 'revision'],
      'skills': <String>['summarize_chapter', 'task_workflow_planning'],
      'skill_groups': <String>[
        'read_only',
        'interactive_planning',
        'task_flow',
      ],
      'provider_profile': 'default',
      'thinking_supported': true,
      'thinking_enabled': false,
      'thinking_effort': 'medium',
      'temperature': 0.5,
      'top_p': 0.85,
      'top_k': 0,
      'system_prompt': '你是 NOVEL Agent 的创作管家视角。你返回任务流建议、检查点、备份建议和收尾清单，不直接操作文件。',
    },
  ];

  static const List<JsonMap> _rawGroups = <JsonMap>[
    <String, Object?>{
      'id': 'optional_editorial_room',
      'name': '可选主编室',
      'description': '覆盖资料检索、结构规划、设定连续性、正文写作、文风审稿和读者反馈的监督式智能体组。',
      'source': 'builtin',
      'enabled': false,
      'orchestration': 'supervised',
      'agents': <String>[
        'context_researcher',
        'editor_in_chief',
        'plot_architect',
        'continuity_keeper',
        'writer',
        'prose_reviewer',
        'reader_lens',
        'workflow_keeper',
      ],
    },
    <String, Object?>{
      'id': 'optional_review_room',
      'name': '可选审稿室',
      'description': '用于章节完成后的文风、连续性、读者体验和修复建议。',
      'source': 'builtin',
      'enabled': false,
      'orchestration': 'supervised',
      'agents': <String>[
        'editor_in_chief',
        'continuity_keeper',
        'prose_reviewer',
        'reader_lens',
      ],
    },
  ];
}
