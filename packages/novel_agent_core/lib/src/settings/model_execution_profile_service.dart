import '../agents/agent_model_override_service.dart';
import '../agents/project_agent_binding.dart';
import '../agents/project_agent_model_override.dart';
import '../agents/project_agent_model_override_normalizer_service.dart';
import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../llm/capabilities/provider_capability_resolver.dart';
import '../llm/catalog/legacy_provider_catalog_bridge_service.dart';
import '../llm/catalog/provider_catalog_service.dart';
import '../llm/catalog/writing_model_offering_catalog_service.dart';
import '../llm/catalog/writing_model_runtime_defaults_service.dart';
import '../llm/profile/provider_profile_constants.dart';
import '../llm/profile/provider_profile_service.dart';
import '../llm/profile/provider_request_options_service.dart';
import 'app_settings.dart';
import 'provider_endpoint_settings.dart';

class ModelExecutionProfileService {
  ModelExecutionProfileService({
    ProviderCatalogService? catalogService,
    LegacyProviderCatalogBridgeService? legacyProviderCatalogBridgeService,
    WritingModelOfferingCatalogService? offeringCatalogService,
    WritingModelRuntimeDefaultsService? writingModelRuntimeDefaultsService,
    ProviderProfileService? profileService,
    AgentModelOverrideService? agentModelOverrideService,
    ProjectAgentModelOverrideNormalizerService?
    projectAgentModelOverrideNormalizerService,
    ProviderRequestOptionsService? requestOptionsService,
  }) : _legacyProviderCatalogBridgeService =
           legacyProviderCatalogBridgeService ??
           LegacyProviderCatalogBridgeService(catalogService: catalogService),
       _offeringCatalogService =
           offeringCatalogService ?? WritingModelOfferingCatalogService(),
       _writingModelRuntimeDefaultsService =
           writingModelRuntimeDefaultsService ??
           WritingModelRuntimeDefaultsService(),
       _profileService =
           profileService ??
           ProviderProfileService(
             catalogPort: catalogService ?? ProviderCatalogService.seeded(),
             capabilityPort: ProviderCapabilityResolver.seeded(),
           ),
       _agentModelOverrideService =
           agentModelOverrideService ?? AgentModelOverrideService(),
       _projectAgentModelOverrideNormalizerService =
           projectAgentModelOverrideNormalizerService ??
           ProjectAgentModelOverrideNormalizerService(),
       _requestOptionsService =
           requestOptionsService ?? ProviderRequestOptionsService();

  final LegacyProviderCatalogBridgeService _legacyProviderCatalogBridgeService;
  final WritingModelOfferingCatalogService _offeringCatalogService;
  final WritingModelRuntimeDefaultsService _writingModelRuntimeDefaultsService;
  final ProviderProfileService _profileService;
  final AgentModelOverrideService _agentModelOverrideService;
  final ProjectAgentModelOverrideNormalizerService
  _projectAgentModelOverrideNormalizerService;
  final ProviderRequestOptionsService _requestOptionsService;

  JsonMap resolve({
    required AppSettings settings,
    ProviderEndpointSettings? provider,
    String overrideModelId = '',
    JsonMap agent = const <String, Object?>{},
    ProjectAgentBinding? projectAgentBinding,
    ProjectAgentModelOverride? projectAgentModelOverride,
  }) {
    // 中文注释: 这里把设置文件、接口、模型默认值与智能体重写收束成单一执行视图。
    final modelSettings = _modelSettingsOf(settings);
    final resolvedProvider =
        provider ?? _selectedProvider(settings, modelSettings);
    final resolvedModelId = _resolvedModelId(
      settings,
      modelSettings,
      resolvedProvider,
      overrideModelId: overrideModelId,
    );
    final credential = _profileService.runtimeProfiles
        .normalizeCredential(<String, Object?>{
          'id': resolvedProvider?.id ?? '',
          'name': resolvedProvider?.title ?? '',
          'provider_id': resolvedProvider?.id ?? '',
          'kind':
              resolvedProvider?.protocol ??
              ProviderProfileConstants.kindOpenAiCompatible,
          'base_url': resolvedProvider?.baseUrl ?? '',
          'api_key': resolvedProvider?.apiKey ?? '',
        });
    final matchedOffering = _offeringCatalogService.bestMatch(
      modelId: resolvedModelId,
      providerId: resolvedProvider?.id ?? '',
    );
    final writingDefaults = _writingModelRuntimeDefaultsService.resolveDefaults(
      providerId: resolvedProvider?.id ?? '',
      modelId: resolvedModelId,
      credentialId: ValueReaders.stringValue(credential['id']),
    );
    final defaults = _resolveModelDefaults(
      providerId: resolvedProvider?.id ?? '',
      modelId: resolvedModelId,
      credentialId: ValueReaders.stringValue(credential['id']),
      writingDefaults: writingDefaults,
      matchedOffering: matchedOffering,
    );
    final modelProfile = <String, Object?>{
      ...defaults,
      ...writingDefaults,
      'credential_id': credential['id'],
      'kind': resolvedProvider?.protocol ?? defaults['kind'],
      'name': _stringValue(
        ValueReaders.stringValue(
          writingDefaults['name'],
          matchedOffering == null
              ? ValueReaders.stringValue(defaults['name'])
              : ValueReaders.stringValue(
                  matchedOffering['display_label'],
                  ValueReaders.stringValue(defaults['name']),
                ),
        ),
        resolvedModelId.isEmpty ? '未命名模型' : resolvedModelId,
      ),
      'model': resolvedModelId,
      'context_length': _intOrDefault(
        modelSettings['compatible_context_window'],
        fallback: ValueReaders.intValue(
          writingDefaults['context_length'],
          ValueReaders.intValue(defaults['context_length'], 100000),
        ),
      ),
      'compression_context_length': _intOrDefault(
        modelSettings['app_context_window'],
        fallback: ValueReaders.intValue(
          writingDefaults['compression_context_length'],
          ValueReaders.intValue(defaults['compression_context_length'], 80000),
        ),
      ),
      'max_output_tokens': ValueReaders.intValue(
        writingDefaults['max_output_tokens'],
        ValueReaders.intValue(defaults['max_output_tokens'], 65536),
      ),
      'supports_streaming': ValueReaders.boolValue(
        writingDefaults['supports_streaming'],
        ValueReaders.boolValue(defaults['supports_streaming'], true),
      ),
      'supports_tools': ValueReaders.boolValue(
        writingDefaults['supports_tools'],
        ValueReaders.boolValue(defaults['supports_tools'], true),
      ),
      'supports_tool_choice': ValueReaders.boolValue(
        writingDefaults['supports_tool_choice'],
        ValueReaders.boolValue(defaults['supports_tool_choice']),
      ),
      'supports_file_attachments': ValueReaders.boolValue(
        writingDefaults['supports_file_attachments'],
        ValueReaders.boolValue(defaults['supports_file_attachments']),
      ),
      'supports_image_attachments': ValueReaders.boolValue(
        writingDefaults['supports_image_attachments'],
        ValueReaders.boolValue(defaults['supports_image_attachments']),
      ),
      'supports_attachment_urls_only': ValueReaders.boolValue(
        writingDefaults['supports_attachment_urls_only'],
        ValueReaders.boolValue(defaults['supports_attachment_urls_only']),
      ),
      'supports_multi_attachments': ValueReaders.boolValue(
        writingDefaults['supports_multi_attachments'],
        ValueReaders.boolValue(defaults['supports_multi_attachments']),
      ),
      'thinking_enabled': ValueReaders.boolValue(
        modelSettings['thinking_enabled'],
      ),
      'thinking_effort': _stringValue(modelSettings['thinking_effort'], 'high'),
      'custom_reasoning_override': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(modelSettings['custom_reasoning_override']),
      ),
      'temperature': _doubleOrDefault(
        modelSettings['temperature'],
        fallback: ValueReaders.doubleValue(
          defaults['temperature'],
          ProviderProfileConstants.defaultTemperature,
        ),
      ),
      'top_p': _doubleOrDefault(
        modelSettings['top_p'],
        fallback: ValueReaders.doubleValue(
          defaults['top_p'],
          ProviderProfileConstants.defaultTopP,
        ),
      ),
      'top_k': _intOrDefault(
        modelSettings['top_k'],
        fallback: ValueReaders.intValue(
          defaults['top_k'],
          ProviderProfileConstants.defaultTopK,
        ),
      ),
      'streaming_enabled':
          _stringValue(modelSettings['stream_mode'], 'stream') == 'stream',
      'custom_parameters': ValueReaders.deepCopyList(
        ValueReaders.objectList(modelSettings['custom_parameters']),
      ),
    };
    var runtimeProfile = _profileService.runtimeProfiles.composeRuntimeProfile(
      modelProfile,
      credential,
    );
    final effectiveProjectOverride =
        projectAgentModelOverride ?? projectAgentBinding?.modelOverride;
    if (effectiveProjectOverride != null) {
      runtimeProfile = _applyProjectAgentOverride(
        runtimeProfile,
        effectiveProjectOverride,
      );
    }
    if (agent.isNotEmpty) {
      runtimeProfile = _agentModelOverrideService.applyOverrides(
        runtimeProfile,
        agent,
      );
    }
    final requestOptions = _requestOptionsService.buildRequestOptions(
      runtimeProfile,
      apiMode: _stringValue(modelSettings['api_mode'], 'chat'),
    );
    return <String, Object?>{
      'provider_id': resolvedProvider?.id ?? '',
      'resolved_model_id': resolvedModelId,
      'runtime_profile': runtimeProfile,
      'request_options': requestOptions,
      'model_settings': ValueReaders.deepCopyMap(modelSettings),
    };
  }

  JsonMap _resolveModelDefaults({
    required String providerId,
    required String modelId,
    required String credentialId,
    required JsonMap writingDefaults,
    required JsonMap? matchedOffering,
  }) {
    if (writingDefaults.isNotEmpty || matchedOffering != null) {
      return <String, Object?>{
        'name': ValueReaders.stringValue(
          writingDefaults['name'],
          ValueReaders.stringValue(matchedOffering?['display_label'], modelId),
        ),
        'purpose': ValueReaders.stringValue(writingDefaults['purpose'], '通用创作'),
        'credential_id': credentialId,
        'kind': ValueReaders.stringValue(
          writingDefaults['kind'],
          ProviderProfileConstants.kindOpenAiCompatible,
        ),
        'model': modelId,
        'context_length': ValueReaders.intValue(
          writingDefaults['context_length'],
          ProviderProfileConstants.defaultContextLength,
        ),
        'compression_context_length': ValueReaders.intValue(
          writingDefaults['compression_context_length'],
          ProviderProfileConstants.defaultCompressionContextLength,
        ),
        'max_output_tokens': ValueReaders.intValue(
          writingDefaults['max_output_tokens'],
          ProviderProfileConstants.defaultMaxOutputTokens,
        ),
        'supports_streaming': ValueReaders.boolValue(
          writingDefaults['supports_streaming'],
          true,
        ),
        'supports_tools': ValueReaders.boolValue(
          writingDefaults['supports_tools'],
          true,
        ),
        'supports_tool_choice': ValueReaders.boolValue(
          writingDefaults['supports_tool_choice'],
        ),
        'supports_file_attachments': ValueReaders.boolValue(
          writingDefaults['supports_file_attachments'],
        ),
        'supports_image_attachments': ValueReaders.boolValue(
          writingDefaults['supports_image_attachments'],
        ),
        'supports_attachment_urls_only': ValueReaders.boolValue(
          writingDefaults['supports_attachment_urls_only'],
        ),
        'supports_multi_attachments': ValueReaders.boolValue(
          writingDefaults['supports_multi_attachments'],
        ),
      };
    }
    final legacyModel = _legacyProviderCatalogBridgeService.legacyMatchModel(
      modelId,
      providerId: providerId,
    );
    return _legacyProviderCatalogBridgeService.legacyModelProfileDefaults(
      legacyModel,
      credentialId: credentialId,
    );
  }

  JsonMap _applyProjectAgentOverride(
    JsonMap runtimeProfile,
    ProjectAgentModelOverride projectOverride,
  ) {
    // 中文注释: 项目级智能体模型覆写先于智能体定义层生效，用来表达“同一个智能体在这个项目里默认用什么模型和参数”。
    final merged = ValueReaders.deepCopyMap(runtimeProfile);
    if (projectOverride.providerProfile.trim().isNotEmpty) {
      merged['provider_profile'] = projectOverride.providerProfile;
    }
    if (projectOverride.modelId.trim().isNotEmpty) {
      merged['model'] = projectOverride.modelId;
    }
    final overrideDocument = _projectAgentModelOverrideNormalizerService
        .toDocument(projectOverride);
    return _agentModelOverrideService.applyOverrides(merged, overrideDocument);
  }

  ProviderEndpointSettings? _selectedProvider(
    AppSettings settings,
    JsonMap modelSettings,
  ) {
    final providerId = _stringValue(
      modelSettings['provider_id'],
      _stringValue(
        modelSettings['default_provider_id'],
        settings.defaultProviderId,
      ),
    );
    if (providerId.isNotEmpty) {
      for (final provider in settings.providers) {
        if (provider.id == providerId) {
          return provider;
        }
      }
    }
    return settings.defaultProvider();
  }

  String _resolvedModelId(
    AppSettings settings,
    JsonMap modelSettings,
    ProviderEndpointSettings? provider, {
    String overrideModelId = '',
  }) {
    final manual = overrideModelId.trim();
    if (manual.isNotEmpty) {
      return manual;
    }
    final configured = _stringValue(
      modelSettings['model_id'],
      _stringValue(modelSettings['default_model_id'], settings.defaultModelId),
    );
    if (configured.isNotEmpty) {
      return configured;
    }
    return provider?.modelId.trim() ?? '';
  }

  JsonMap _modelSettingsOf(AppSettings settings) {
    return ValueReaders.mapValue(settings.extraSettings['model_settings']);
  }

  int _intOrDefault(Object? value, {required int fallback}) {
    final text = _stringValue(value);
    if (text.isEmpty) {
      return fallback;
    }
    return int.tryParse(text) ?? fallback;
  }

  double _doubleOrDefault(Object? value, {required double fallback}) {
    final text = _stringValue(value);
    if (text.isEmpty) {
      return fallback;
    }
    return double.tryParse(text) ?? fallback;
  }

  String _stringValue(Object? value, [String fallback = '']) {
    if (value == null) {
      return fallback;
    }
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}
