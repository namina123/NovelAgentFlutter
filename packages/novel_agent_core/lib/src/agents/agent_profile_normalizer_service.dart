import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../llm/profile/provider_custom_parameter_service.dart';
import '../packages/agent_package_metadata_profile_service.dart';
import 'agent_effort_service.dart';
import 'agent_id_service.dart';
import 'agent_sampling_service.dart';
import 'agent_string_list_service.dart';

class AgentProfileNormalizerService {
  AgentProfileNormalizerService({
    AgentIdService? idService,
    AgentSamplingService? samplingService,
    AgentEffortService? effortService,
    AgentStringListService? stringListService,
    ProviderCustomParameterService? customParameterService,
    AgentPackageMetadataProfileService? metadataProfileService,
  }) : _idService = idService ?? AgentIdService(),
       _samplingService = samplingService ?? AgentSamplingService(),
       _effortService = effortService ?? AgentEffortService(),
       _stringListService = stringListService ?? AgentStringListService(),
       _customParameterService =
           customParameterService ?? ProviderCustomParameterService(),
       _metadataProfileService =
           metadataProfileService ?? const AgentPackageMetadataProfileService();

  final AgentIdService _idService;
  final AgentSamplingService _samplingService;
  final AgentEffortService _effortService;
  final AgentStringListService _stringListService;
  final ProviderCustomParameterService _customParameterService;
  final AgentPackageMetadataProfileService _metadataProfileService;

  JsonMap normalizeAgentProfile(JsonMap agent) {
    // 中文注释: 这里把项目标准智能体包收敛成稳定结构，确保角色、边界、能力、记忆和输出合同都能被统一消费。
    final id = _idService.safeAgentId(
      ValueReaders.stringValue(agent['id']).trim(),
    );
    final sampling = _samplingService.normalizeSampling(agent);
    final extensions = _metadataProfileService.extractExtensions(agent);
    final extensionSampling = _samplingService.normalizeSampling(extensions);
    final resourceHints = _normalizeResourceHints(agent['resource_hints']);
    final enabledByDefault = ValueReaders.boolValue(
      extensions['enabled_by_default'],
      id == 'default_generalist',
    );
    return <String, Object?>{
      ...agent,
      'id': id,
      'name': ValueReaders.stringValue(
        agent['name'],
        id.isEmpty ? '未命名智能体' : id,
      ).trim(),
      'role': ValueReaders.stringValue(agent['role']).trim(),
      'version': ValueReaders.stringValue(agent['version'], '1'),
      'objective': ValueReaders.stringValue(
        agent['objective'],
        ValueReaders.stringValue(agent['goal']),
      ).trim(),
      'kpis': _stringListService.normalize(agent['kpis']),
      'description': ValueReaders.stringValue(
        agent['description'],
        ValueReaders.stringValue(agent['role']),
      ).trim(),
      'can_do': _stringListService.normalize(agent['can_do']),
      'must_not_do': _stringListService.normalize(
        agent['must_not_do'] ?? agent['constraints'],
      ),
      'knowledge_sources': _stringListService.normalize(
        agent['knowledge_sources'],
      ),
      'required_capabilities': _stringListService.normalize(
        agent['required_capabilities'],
      ),
      'optional_capabilities': _stringListService.normalize(
        agent['optional_capabilities'] ?? agent['tools'],
      ),
      'output_schema_path': ValueReaders.stringValue(
        agent['output_schema_path'],
      ).trim(),
      'output_schema': ValueReaders.mapValue(agent['output_schema']),
      'preferred_output': ValueReaders.stringValue(
        agent['preferred_output'],
      ).trim(),
      'short_term_memory_policy': ValueReaders.stringValue(
        agent['short_term_memory_policy'],
        'conversation_window',
      ).trim(),
      'long_term_memory_paths': _stringListService.normalize(
        agent['long_term_memory_paths'],
      ),
      'reflection_mode': ValueReaders.stringValue(
        agent['reflection_mode'],
        'on_demand',
      ).trim(),
      'resource_hints': resourceHints,
      'source': ValueReaders.stringValue(extensions['source'], 'builtin'),
      'source_scope': ValueReaders.stringValue(
        extensions['source_scope'],
        'builtin',
      ),
      'enabled_by_default': enabledByDefault,
      'builtin_preset': ValueReaders.stringValue(
        extensions['builtin_preset'],
        enabledByDefault ? 'default_single_agent' : 'optional_multi_agent',
      ),
      'customizable': ValueReaders.boolValue(extensions['customizable'], true),
      'stages': _stringListService.normalize(extensions['stages']),
      'skills': _stringListService.normalize(extensions['skills']),
      'skill_groups': _stringListService.normalize(extensions['skill_groups']),
      'memory_path': ValueReaders.stringValue(
        extensions['memory_path'],
        id.isEmpty ? '' : 'agents/${id}_memory.md',
      ),
      'provider_profile': ValueReaders.stringValue(
        extensions['provider_profile'],
        'default',
      ),
      'system_prompt': ValueReaders.stringValue(agent['system_prompt']).trim(),
      'operating_manual_markdown': ValueReaders.stringValue(
        agent['operating_manual_markdown'],
        ValueReaders.stringValue(agent['system_prompt']),
      ).trim(),
      'thinking_supported': ValueReaders.boolValue(
        extensions['thinking_supported'],
        true,
      ),
      'thinking_enabled': ValueReaders.boolValue(
        extensions['thinking_enabled'],
      ),
      'thinking_effort': _effortService.normalizeEffort(
        ValueReaders.stringValue(extensions['thinking_effort'], 'high'),
      ),
      'temperature': _hasExplicitValue(extensions['temperature'])
          ? extensionSampling['temperature']
          : sampling['temperature'],
      'top_p': _hasExplicitValue(extensions['top_p'])
          ? extensionSampling['top_p']
          : sampling['top_p'],
      'top_k': _hasExplicitValue(extensions['top_k'])
          ? extensionSampling['top_k']
          : sampling['top_k'],
      'advanced_model_overrides': _customParameterService
          .normalizeCustomParameters(extensions['advanced_model_overrides']),
      'metadata': _metadataProfileService.extractPlainMetadata(agent),
      'portable_core': _metadataProfileService.buildPortableCore(
        agent,
        normalizedId: id,
        normalizedName: ValueReaders.stringValue(
          agent['name'],
          id.isEmpty ? '未命名智能体' : id,
        ).trim(),
        resourceHints: resourceHints,
      ),
      'novel_agent_extensions': extensions,
    };
  }

  JsonMap _normalizeResourceHints(Object? rawValue) {
    // 中文注释: 智能体包的资源提示只描述可选引用入口，不让运行时默认把所有资源一股脑塞进上下文。
    final rawMap = ValueReaders.mapValue(rawValue);
    return <String, Object?>{
      'references': _stringListService.normalize(rawMap['references']),
      'scripts': _stringListService.normalize(rawMap['scripts']),
      'assets': _stringListService.normalize(rawMap['assets']),
      'schemas': _stringListService.normalize(rawMap['schemas']),
      'memory': _stringListService.normalize(rawMap['memory']),
    };
  }

  bool _hasExplicitValue(Object? value) {
    if (value == null) {
      return false;
    }
    if (value is String) {
      return value.trim().isNotEmpty;
    }
    return true;
  }
}
