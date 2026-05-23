import 'dart:convert';

import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_profile_normalizer_service.dart';

class AgentProfileCatalogService {
  AgentProfileCatalogService({AgentProfileNormalizerService? normalizerService})
    : _normalizerService = normalizerService ?? AgentProfileNormalizerService();

  final AgentProfileNormalizerService _normalizerService;

  List<JsonMap> builtinProfilesFromJson(String rawJson) {
    // 中文注释: 内置智能体原型只解析纯 JSON 文本，不触碰任何宿主资源读取职责。
    final decoded = jsonDecodeSafe(rawJson);
    final root = ValueReaders.mapValue(decoded);
    final rawProfiles = ValueReaders.objectList(
      root['profiles'] ?? root['agents'],
    );
    final result = <JsonMap>[];
    for (final rawProfile in rawProfiles) {
      final normalized = _normalizerService.normalizeAgentProfile(
        ValueReaders.mapValue(rawProfile),
      );
      if (ValueReaders.stringValue(normalized['id']).trim().isNotEmpty) {
        result.add(normalized);
      }
    }
    return result;
  }

  JsonMap fallbackDefaultAgent() {
    // 中文注释: native 或资源出错时至少保留一个全能默认智能体，避免应用无法进入创作流程。
    return _normalizerService.normalizeAgentProfile(<String, Object?>{
      'id': 'default_generalist',
      'name': '综合创作智能体',
      'role': '默认启用的单个全能小说创作智能体，负责理解用户意图、判断创作阶段、组织上下文、调用工具与技能。',
      'source': 'builtin',
      'source_scope': 'builtin',
      'enabled_by_default': true,
      'builtin_preset': 'default_single_agent',
      'customizable': true,
      'stages': <String>[
        'opening',
        'plot',
        'outline',
        'draft',
        'summary',
        'revision',
      ],
      'skills': <String>[
        'ask_opening_questions',
        'generate_outline',
        'chapter_drafting_method',
        'summarize_chapter',
        'check_continuity',
        'skill_blueprint_design',
      ],
      'skill_groups': <String>[
        'project_io',
        'interactive_planning',
        'memory_tools',
        'task_flow',
        'skill_ecology',
      ],
      'memory_path': 'agents/default_generalist_memory.md',
      'provider_profile': 'default',
      'thinking_supported': true,
      'thinking_enabled': false,
      'thinking_effort': 'high',
      'temperature': 0.85,
      'top_p': 0.95,
      'top_k': 0,
      'system_prompt': '你是 NOVEL Agent 的默认全能创作智能体。你要按需读取技能，真实读写必须通过工具完成。',
    });
  }

  String agentProfileSummaryText(List<Object?> agents) {
    // 中文注释: 这里只输出短摘要，供 CLI help、调试视图和系统提示检查复用。
    if (agents.isEmpty) {
      return '当前没有可用智能体原型。';
    }
    final lines = <String>['内置智能体原型摘要：'];
    for (final rawAgent in agents) {
      final agent = ValueReaders.mapValue(rawAgent);
      if (agent.isEmpty) {
        continue;
      }
      final id = ValueReaders.stringValue(agent['id']).trim();
      lines.add(
        '- ${ValueReaders.stringValue(agent['name'], id)}（agent_id: $id）：'
        '${ValueReaders.stringValue(agent['role'])}',
      );
    }
    return lines.join('\n');
  }

  Object? jsonDecodeSafe(String rawJson) {
    // 中文注释: JSON 解析失败时返回 null，让上层继续走兜底逻辑，而不是把异常传播到宿主。
    try {
      return jsonDecode(rawJson);
    } catch (_) {
      return null;
    }
  }
}
