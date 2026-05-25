import '../common/json_types.dart';
import '../common/value_readers.dart';

class AgentPackageMetadataProfileService {
  const AgentPackageMetadataProfileService();

  JsonMap extractExtensions(JsonMap rawAgent) {
    // 中文注释: 智能体的宿主私有配置集中放进扩展层，核心层尽量保持通用表达。
    final nested = _nestedNovelAgentMetadata(rawAgent);
    return <String, Object?>{
      'source': ValueReaders.stringValue(
        rawAgent['source'] ?? nested['source'],
      ).trim(),
      'source_scope': ValueReaders.stringValue(
        rawAgent['source_scope'] ?? nested['source_scope'],
      ).trim(),
      'enabled_by_default': ValueReaders.boolValue(
        rawAgent.containsKey('enabled_by_default')
            ? rawAgent['enabled_by_default']
            : nested['enabled_by_default'],
      ),
      'builtin_preset': ValueReaders.stringValue(
        rawAgent['builtin_preset'] ?? nested['builtin_preset'],
      ).trim(),
      'customizable': ValueReaders.boolValue(
        rawAgent.containsKey('customizable')
            ? rawAgent['customizable']
            : nested['customizable'],
        true,
      ),
      'stages': _normalizeStringList(rawAgent['stages'] ?? nested['stages']),
      'skills': _normalizeStringList(rawAgent['skills'] ?? nested['skills']),
      'skill_groups': _normalizeStringList(
        rawAgent['skill_groups'] ?? nested['skill_groups'],
      ),
      'memory_path': ValueReaders.stringValue(
        rawAgent['memory_path'] ?? nested['memory_path'],
      ).trim(),
      'provider_profile': ValueReaders.stringValue(
        rawAgent['provider_profile'] ?? nested['provider_profile'],
        'default',
      ).trim(),
      'thinking_supported': ValueReaders.boolValue(
        rawAgent.containsKey('thinking_supported')
            ? rawAgent['thinking_supported']
            : nested['thinking_supported'],
        true,
      ),
      'thinking_enabled': ValueReaders.boolValue(
        rawAgent.containsKey('thinking_enabled')
            ? rawAgent['thinking_enabled']
            : nested['thinking_enabled'],
      ),
      'thinking_effort': ValueReaders.stringValue(
        rawAgent['thinking_effort'] ?? nested['thinking_effort'],
        'high',
      ).trim(),
      'temperature': rawAgent.containsKey('temperature')
          ? rawAgent['temperature']
          : nested['temperature'],
      'top_p': rawAgent.containsKey('top_p')
          ? rawAgent['top_p']
          : nested['top_p'],
      'top_k': rawAgent.containsKey('top_k')
          ? rawAgent['top_k']
          : nested['top_k'],
      'advanced_model_overrides': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(rawAgent['advanced_model_overrides']).isNotEmpty
            ? ValueReaders.mapValue(rawAgent['advanced_model_overrides'])
            : ValueReaders.mapValue(nested['advanced_model_overrides']),
      ),
    };
  }

  JsonMap extractPlainMetadata(JsonMap rawAgent) {
    // 中文注释: 非 NovelAgent 专用 metadata 继续原样保留。
    final metadata = ValueReaders.deepCopyMap(
      ValueReaders.mapValue(rawAgent['metadata']),
    );
    metadata.remove('novel_agent');
    return metadata;
  }

  JsonMap buildPortableCore(
    JsonMap rawAgent, {
    required String normalizedId,
    required String normalizedName,
    required JsonMap resourceHints,
  }) {
    // 中文注释: 这是智能体的通用核心，覆盖角色、目标、边界、知识、记忆与输出合同。
    return <String, Object?>{
      'id': normalizedId,
      'name': normalizedName,
      'description': ValueReaders.stringValue(rawAgent['description']).trim(),
      'version': ValueReaders.stringValue(rawAgent['version'], '1').trim(),
      'role': ValueReaders.stringValue(rawAgent['role']).trim(),
      'objective': ValueReaders.stringValue(
        rawAgent['objective'],
        ValueReaders.stringValue(rawAgent['goal']),
      ).trim(),
      'kpis': ValueReaders.stringList(rawAgent['kpis']),
      'can_do': ValueReaders.stringList(rawAgent['can_do']),
      'must_not_do': ValueReaders.stringList(
        rawAgent['must_not_do'] ?? rawAgent['constraints'],
      ),
      'knowledge_sources': ValueReaders.stringList(
        rawAgent['knowledge_sources'],
      ),
      'required_capabilities': ValueReaders.stringList(
        rawAgent['required_capabilities'],
      ),
      'optional_capabilities': ValueReaders.stringList(
        rawAgent['optional_capabilities'] ?? rawAgent['tools'],
      ),
      'output_schema_path': ValueReaders.stringValue(
        rawAgent['output_schema_path'],
      ).trim(),
      'output_schema': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(rawAgent['output_schema']),
      ),
      'preferred_output': ValueReaders.stringValue(
        rawAgent['preferred_output'],
      ).trim(),
      'short_term_memory_policy': ValueReaders.stringValue(
        rawAgent['short_term_memory_policy'],
        'conversation_window',
      ).trim(),
      'long_term_memory_paths': ValueReaders.stringList(
        rawAgent['long_term_memory_paths'],
      ),
      'reflection_mode': ValueReaders.stringValue(
        rawAgent['reflection_mode'],
        'on_demand',
      ).trim(),
      'resource_hints': resourceHints,
    };
  }

  JsonMap buildRendererMetadata(JsonMap normalizedAgent) {
    // 中文注释: 渲染时只把扩展字段折叠进 metadata.novel_agent。
    final metadata = ValueReaders.deepCopyMap(
      ValueReaders.mapValue(normalizedAgent['metadata']),
    );
    final extensions = ValueReaders.deepCopyMap(
      ValueReaders.mapValue(normalizedAgent['novel_agent_extensions']),
    );
    if (extensions.isNotEmpty) {
      metadata['novel_agent'] = extensions;
    }
    return metadata;
  }

  JsonMap _nestedNovelAgentMetadata(JsonMap rawAgent) {
    return ValueReaders.mapValue(
      ValueReaders.mapValue(rawAgent['metadata'])['novel_agent'],
    );
  }

  List<String> _normalizeStringList(Object? rawValue) {
    // 中文注释: 这里兼容数组和逗号分隔字符串，确保技能、阶段和技能组在不同包格式下仍能稳定归一化。
    if (rawValue is String) {
      final normalized = rawValue.replaceAll('，', ',').replaceAll('、', ',');
      final result = <String>[];
      for (final part in normalized.split(',')) {
        final value = part.trim();
        if (value.isNotEmpty && !result.contains(value)) {
          result.add(value);
        }
      }
      return result;
    }
    return ValueReaders.stringList(rawValue);
  }
}
