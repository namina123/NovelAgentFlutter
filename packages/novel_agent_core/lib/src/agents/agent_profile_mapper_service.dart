import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_profile.dart';

class AgentProfileMapperService {
  const AgentProfileMapperService();

  AgentProfile fromDocument(JsonMap document) {
    // 中文注释: 这里把标准化后的智能体字典收束成强类型合同，后续项目绑定和策略层不再只能依赖裸 map。
    return AgentProfile(
      id: ValueReaders.stringValue(document['id']).trim(),
      name: ValueReaders.stringValue(document['name']).trim(),
      description: ValueReaders.stringValue(document['description']).trim(),
      role: ValueReaders.stringValue(document['role']).trim(),
      version: ValueReaders.stringValue(document['version'], '1').trim(),
      objective: ValueReaders.stringValue(document['objective']).trim(),
      kpis: ValueReaders.stringList(document['kpis']),
      canDo: ValueReaders.stringList(document['can_do']),
      mustNotDo: ValueReaders.stringList(document['must_not_do']),
      knowledgeSources: ValueReaders.stringList(document['knowledge_sources']),
      requiredCapabilities: ValueReaders.stringList(
        document['required_capabilities'],
      ),
      optionalCapabilities: ValueReaders.stringList(
        document['optional_capabilities'],
      ),
      outputSchemaPath: ValueReaders.stringValue(
        document['output_schema_path'],
      ).trim(),
      outputSchema: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(document['output_schema']),
      ),
      preferredOutput: ValueReaders.stringValue(
        document['preferred_output'],
      ).trim(),
      shortTermMemoryPolicy: ValueReaders.stringValue(
        document['short_term_memory_policy'],
        'conversation_window',
      ).trim(),
      longTermMemoryPaths: ValueReaders.stringList(
        document['long_term_memory_paths'],
      ),
      reflectionMode: ValueReaders.stringValue(
        document['reflection_mode'],
        'on_demand',
      ).trim(),
      resourceHints: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(document['resource_hints']),
      ),
      source: ValueReaders.stringValue(document['source']).trim(),
      sourceScope: ValueReaders.stringValue(document['source_scope']).trim(),
      enabledByDefault: ValueReaders.boolValue(document['enabled_by_default']),
      builtinPreset: ValueReaders.stringValue(
        document['builtin_preset'],
      ).trim(),
      customizable: ValueReaders.boolValue(document['customizable'], true),
      stages: ValueReaders.stringList(document['stages']),
      skills: ValueReaders.stringList(document['skills']),
      skillGroups: ValueReaders.stringList(document['skill_groups']),
      memoryPath: ValueReaders.stringValue(document['memory_path']).trim(),
      providerProfile: ValueReaders.stringValue(
        document['provider_profile'],
        'default',
      ).trim(),
      systemPrompt: ValueReaders.stringValue(document['system_prompt']).trim(),
      operatingManualMarkdown: ValueReaders.stringValue(
        document['operating_manual_markdown'],
      ).trim(),
      thinkingSupported: ValueReaders.boolValue(
        document['thinking_supported'],
        true,
      ),
      thinkingEnabled: ValueReaders.boolValue(document['thinking_enabled']),
      thinkingEffort: ValueReaders.stringValue(
        document['thinking_effort'],
        'high',
      ).trim(),
      temperature: document['temperature'] == null
          ? null
          : ValueReaders.doubleValue(document['temperature']),
      topP: document['top_p'] == null
          ? null
          : ValueReaders.doubleValue(document['top_p']),
      topK: document['top_k'] == null
          ? null
          : ValueReaders.intValue(document['top_k']),
      advancedModelOverrides: ValueReaders.deepCopyList(
        ValueReaders.objectList(document['advanced_model_overrides']),
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(document['metadata']),
      ),
      portableCore: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(document['portable_core']),
      ),
      novelAgentExtensions: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(document['novel_agent_extensions']),
      ),
    );
  }

  JsonMap toDocument(AgentProfile profile) {
    return <String, Object?>{
      'id': profile.id,
      'name': profile.name,
      'description': profile.description,
      'role': profile.role,
      'version': profile.version,
      'objective': profile.objective,
      'kpis': ValueReaders.deepCopyList(profile.kpis.cast<Object?>()),
      'can_do': ValueReaders.deepCopyList(profile.canDo.cast<Object?>()),
      'must_not_do': ValueReaders.deepCopyList(
        profile.mustNotDo.cast<Object?>(),
      ),
      'knowledge_sources': ValueReaders.deepCopyList(
        profile.knowledgeSources.cast<Object?>(),
      ),
      'required_capabilities': ValueReaders.deepCopyList(
        profile.requiredCapabilities.cast<Object?>(),
      ),
      'optional_capabilities': ValueReaders.deepCopyList(
        profile.optionalCapabilities.cast<Object?>(),
      ),
      'output_schema_path': profile.outputSchemaPath,
      'output_schema': ValueReaders.deepCopyMap(profile.outputSchema),
      'preferred_output': profile.preferredOutput,
      'short_term_memory_policy': profile.shortTermMemoryPolicy,
      'long_term_memory_paths': ValueReaders.deepCopyList(
        profile.longTermMemoryPaths.cast<Object?>(),
      ),
      'reflection_mode': profile.reflectionMode,
      'resource_hints': ValueReaders.deepCopyMap(profile.resourceHints),
      'source': profile.source,
      'source_scope': profile.sourceScope,
      'enabled_by_default': profile.enabledByDefault,
      'builtin_preset': profile.builtinPreset,
      'customizable': profile.customizable,
      'stages': ValueReaders.deepCopyList(profile.stages.cast<Object?>()),
      'skills': ValueReaders.deepCopyList(profile.skills.cast<Object?>()),
      'skill_groups': ValueReaders.deepCopyList(
        profile.skillGroups.cast<Object?>(),
      ),
      'memory_path': profile.memoryPath,
      'provider_profile': profile.providerProfile,
      'system_prompt': profile.systemPrompt,
      'operating_manual_markdown': profile.operatingManualMarkdown,
      'thinking_supported': profile.thinkingSupported,
      'thinking_enabled': profile.thinkingEnabled,
      'thinking_effort': profile.thinkingEffort,
      if (profile.temperature != null) 'temperature': profile.temperature,
      if (profile.topP != null) 'top_p': profile.topP,
      if (profile.topK != null) 'top_k': profile.topK,
      'advanced_model_overrides': ValueReaders.deepCopyList(
        profile.advancedModelOverrides,
      ),
      'metadata': ValueReaders.deepCopyMap(profile.metadata),
      'portable_core': ValueReaders.deepCopyMap(profile.portableCore),
      'novel_agent_extensions': ValueReaders.deepCopyMap(
        profile.novelAgentExtensions,
      ),
    };
  }
}
