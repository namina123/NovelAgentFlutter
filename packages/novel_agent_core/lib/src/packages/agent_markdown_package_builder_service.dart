import '../agents/agent_id_service.dart';
import '../common/value_readers.dart';

class AgentMarkdownPackageBuilderService {
  AgentMarkdownPackageBuilderService({AgentIdService? idService})
    : _idService = idService ?? AgentIdService();

  final AgentIdService _idService;

  String buildMarkdown({
    required String name,
    String description = '',
    String role = '',
  }) {
    // 中文注释: 智能体脚手架只生成最小可编辑骨架，具体角色细节继续由用户在项目内修改。
    final resolvedName = name.trim().isEmpty ? '新建智能体' : name.trim();
    final resolvedId = _idService.safeAgentId(resolvedName);
    final resolvedDescription = description.trim().isEmpty
        ? '请补充这个智能体负责的目标、边界与可用技能。'
        : description.trim();
    final resolvedRole = role.trim().isEmpty ? resolvedName : role.trim();
    return '''---
name: $resolvedId
description: $resolvedDescription
version: 1
role: $resolvedRole
objective: 请补充该智能体的工作目标。
kpis:
  - 产出与当前任务匹配
can_do:
  - 请补充
must_not_do:
  - 不伪造已执行的文件操作
knowledge_sources: []
required_capabilities: []
optional_capabilities: []
preferred_output: 面向主智能体或用户的结构化自然语言结果
short_term_memory_policy: conversation_window
long_term_memory_paths: []
reflection_mode: on_demand
resource_hints:
  references: []
  scripts: []
  assets: []
  schemas: []
  memory: []
source: project_package
source_scope: project
enabled_by_default: false
customizable: true
stages: []
skills: []
skill_groups: []
provider_profile: default
thinking_supported: true
thinking_enabled: false
thinking_effort: medium
temperature: 0.7
top_p: 0.9
top_k: 0
---

# $resolvedName

## 角色

请补充这个智能体的职责、边界和协作方式。
''';
  }

  String directoryId(String name) {
    return _idService.safeAgentId(ValueReaders.stringValue(name).trim());
  }
}
