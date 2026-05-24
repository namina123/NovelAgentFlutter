import '../agents/agent_id_service.dart';
import '../common/value_readers.dart';

class SkillMarkdownPackageBuilderService {
  SkillMarkdownPackageBuilderService({AgentIdService? idService})
    : _idService = idService ?? AgentIdService();

  final AgentIdService _idService;

  String buildMarkdown({
    required String name,
    String description = '',
  }) {
    // 中文注释: 技能脚手架保持和解析器兼容的 frontmatter 结构，便于项目内直接手写扩展。
    final resolvedName = name.trim().isEmpty ? '新建技能' : name.trim();
    final resolvedId = directoryId(resolvedName);
    final resolvedDescription = description.trim().isEmpty
        ? '请补充这个技能的触发时机、输入输出和边界。'
        : description.trim();
    return '''---
name: $resolvedId
description: $resolvedDescription
version: 1
activation_hints:
  - 请补充触发条件
inputs: []
outputs: []
required_capabilities: []
optional_capabilities: []
safe_without_tools: true
resource_hints:
  scripts: []
  references: []
  assets: []
preferred_output: 请补充偏好的输出格式
source: project_package
source_scope: project
---

# $resolvedName

## 使用时机

请补充这个技能在什么情况下使用。

## 工作流程

1. 请补充

## 约束

1. 请补充
''';
  }

  String directoryId(String name) {
    final safe = _idService.safeAgentId(ValueReaders.stringValue(name).trim());
    return safe.toLowerCase().replaceAll('_', '-');
  }
}
