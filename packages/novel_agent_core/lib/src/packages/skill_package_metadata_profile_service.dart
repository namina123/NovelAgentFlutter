import '../common/json_types.dart';
import '../common/value_readers.dart';

class SkillPackageMetadataProfileService {
  const SkillPackageMetadataProfileService();

  JsonMap extractExtensions(JsonMap rawSkill) {
    // 中文注释: 技能元数据拆成可移植核心和 NovelAgent 扩展，便于未来被其他宿主部分理解。
    final nested = _nestedNovelAgentMetadata(rawSkill);
    return <String, Object?>{
      'activation_hints': ValueReaders.stringList(
        rawSkill['activation_hints'] ??
            rawSkill['triggers'] ??
            nested['activation_hints'],
      ),
      'inputs': ValueReaders.stringList(rawSkill['inputs'] ?? nested['inputs']),
      'outputs': ValueReaders.stringList(
        rawSkill['outputs'] ?? nested['outputs'],
      ),
      'required_capabilities': ValueReaders.stringList(
        rawSkill['required_capabilities'] ?? nested['required_capabilities'],
      ),
      'optional_capabilities': ValueReaders.stringList(
        rawSkill['optional_capabilities'] ?? nested['optional_capabilities'],
      ),
      'safe_without_tools': ValueReaders.boolValue(
        rawSkill.containsKey('safe_without_tools')
            ? rawSkill['safe_without_tools']
            : nested['safe_without_tools'],
        true,
      ),
      'preferred_output': ValueReaders.stringValue(
        rawSkill['preferred_output'] ?? nested['preferred_output'],
      ).trim(),
      'tool_schema': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(rawSkill['tool_schema']).isNotEmpty
            ? ValueReaders.mapValue(rawSkill['tool_schema'])
            : ValueReaders.mapValue(nested['tool_schema']),
      ),
      'source': ValueReaders.stringValue(
        rawSkill['source'] ?? nested['source'],
        'package',
      ).trim(),
      'source_scope': ValueReaders.stringValue(
        rawSkill['source_scope'] ?? nested['source_scope'],
      ).trim(),
    };
  }

  JsonMap extractPlainMetadata(JsonMap rawSkill) {
    // 中文注释: metadata 里除 novel_agent 之外的字段保持原样，避免抹掉第三方附加信息。
    final metadata = ValueReaders.deepCopyMap(
      ValueReaders.mapValue(rawSkill['metadata']),
    );
    metadata.remove('novel_agent');
    return metadata;
  }

  JsonMap buildPortableCore(
    JsonMap rawSkill, {
    required String normalizedId,
    required String normalizedName,
    required JsonMap resourceHints,
  }) {
    // 中文注释: 这里定义“多数 agent 至少看得懂”的技能核心字段。
    return <String, Object?>{
      'id': normalizedId,
      'name': normalizedName,
      'description': ValueReaders.stringValue(rawSkill['description']).trim(),
      'version': ValueReaders.stringValue(rawSkill['version'], '1').trim(),
      'tags': ValueReaders.stringList(rawSkill['tags']),
      'resource_hints': resourceHints,
    };
  }

  JsonMap buildRendererMetadata(JsonMap normalizedSkill) {
    // 中文注释: 渲染时把 NovelAgent 扩展统一放入 metadata.novel_agent，减少顶层私有字段扩散。
    final metadata = ValueReaders.deepCopyMap(
      ValueReaders.mapValue(normalizedSkill['metadata']),
    );
    final extensions = ValueReaders.deepCopyMap(
      ValueReaders.mapValue(normalizedSkill['novel_agent_extensions']),
    );
    if (extensions.isNotEmpty) {
      metadata['novel_agent'] = extensions;
    }
    return metadata;
  }

  JsonMap _nestedNovelAgentMetadata(JsonMap rawSkill) {
    return ValueReaders.mapValue(
      ValueReaders.mapValue(rawSkill['metadata'])['novel_agent'],
    );
  }
}
