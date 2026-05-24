import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/model_editor_view_data.dart';
import '../../presentation/models/model_parameter_entry_view_data.dart';
import '../../presentation/models/settings_search_option.dart';

class ModelSettingsViewDataService {
  ModelSettingsViewDataService({
    ModelExecutionProfileService? modelExecutionProfileService,
    ProviderProfileService? profileService,
  }) : _modelExecutionProfileService =
           modelExecutionProfileService ?? ModelExecutionProfileService(),
       _catalogService = ProviderCatalogService.seeded(),
       _profileService =
           profileService ??
           ProviderProfileService(
             catalogPort: ProviderCatalogService.seeded(),
             capabilityPort: ProviderCapabilityResolver.seeded(),
           );

  final ModelExecutionProfileService _modelExecutionProfileService;
  final ProviderCatalogService _catalogService;
  final ProviderProfileService _profileService;

  ModelEditorViewData build(
    AppSettings settings,
    Map<String, Object?> modelSettings,
  ) {
    // 中文注释: 这个服务只负责把设置持久化结构投影成模型编辑页可直接消费的数据。
    final execution = _modelExecutionProfileService.resolve(settings: settings);
    final runtimeProfile = ValueReaders.mapValue(execution['runtime_profile']);
    final metadata = _profileService.metadata.buildEditorMetadata(
      runtimeProfile,
    );
    final customParameters = <ModelParameterEntryViewData>[];
    for (final entry in ValueReaders.mapList(
      metadata['model_default_parameters'],
    )) {
      final key = ValueReaders.stringValue(entry['key']).trim();
      if (_isStandardKey(key)) {
        continue;
      }
      customParameters.add(ModelParameterEntryViewData.fromMap(entry));
    }
    return ModelEditorViewData(
      providerId: ValueReaders.stringValue(metadata['provider_id']),
      providerLabel: ValueReaders.stringValue(metadata['provider_label']),
      protocolMode: ValueReaders.stringValue(metadata['protocol_mode']),
      baseUrl: ValueReaders.stringValue(metadata['base_url']),
      modelId: ValueReaders.stringValue(
        metadata['model_id'],
        ValueReaders.stringValue(execution['resolved_model_id']),
      ),
      supportsReasoning: ValueReaders.boolValue(metadata['supports_reasoning']),
      supportsTemperature: ValueReaders.boolValue(
        metadata['supports_temperature'],
        true,
      ),
      supportsTopP: ValueReaders.boolValue(metadata['supports_top_p'], true),
      supportsTopK: ValueReaders.boolValue(metadata['supports_top_k']),
      supportsStreaming: ValueReaders.boolValue(
        metadata['supports_streaming'],
        true,
      ),
      supportsTools: ValueReaders.boolValue(metadata['supports_tools'], true),
      supportsToolChoice: ValueReaders.boolValue(
        metadata['supports_tool_choice'],
      ),
      thinkingParameterFormat: ValueReaders.stringValue(
        metadata['thinking_parameter_format'],
        'none',
      ),
      thinkingParameterLabel: ValueReaders.stringValue(
        metadata['thinking_parameter_label'],
        '深度思考',
      ),
      thinkingEnabled: ValueReaders.boolValue(
        runtimeProfile['thinking_enabled'],
      ),
      thinkingEffortSupported: ValueReaders.boolValue(
        metadata['thinking_effort_supported'],
      ),
      thinkingEffort: ValueReaders.stringValue(
        runtimeProfile['thinking_effort'],
        'high',
      ),
      thinkingEffortOptions: ValueReaders.stringList(
        metadata['thinking_effort_options'],
      ),
      temperature: ValueReaders.doubleValue(runtimeProfile['temperature'], 0.8),
      topP: ValueReaders.doubleValue(runtimeProfile['top_p'], 0.95),
      topK: ValueReaders.intValue(runtimeProfile['top_k']),
      modelSuggestions: _modelSuggestions(
        ValueReaders.stringValue(metadata['provider_id']),
      ),
      customParameters: customParameters,
      supportedParameters: ValueReaders.stringList(
        metadata['supported_parameters'],
      ),
      unsupportedParameters: ValueReaders.stringList(
        metadata['unsupported_parameters'],
      ),
    );
  }

  List<SettingsSearchOption<String>> _modelSuggestions(String providerId) {
    return _catalogService
        .modelSuggestions(
          providerId: providerId,
          includeImage: false,
          limit: 48,
        )
        .map(
          (entry) => SettingsSearchOption<String>(
            value: ValueReaders.stringValue(entry['id']),
            label: ValueReaders.stringValue(entry['id']),
            note: ValueReaders.stringValue(entry['provider_label']),
          ),
        )
        .toList(growable: false);
  }

  bool _isStandardKey(String key) {
    return const <String>{
      'thinking_enabled',
      'thinking_effort',
      'temperature',
      'top_p',
      'top_k',
    }.contains(key);
  }
}
