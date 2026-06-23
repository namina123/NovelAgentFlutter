import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/custom_model_reasoning_override_view_data.dart';
import '../../presentation/models/model_editor_view_data.dart';
import '../../presentation/models/model_parameter_entry_view_data.dart';
import '../../presentation/models/settings_search_option.dart';

class ModelSettingsViewDataService {
  ModelSettingsViewDataService({
    ModelExecutionProfileService? modelExecutionProfileService,
    ProviderProfileService? profileService,
    ProviderConnectionValidationService? providerConnectionValidationService,
  }) : _modelExecutionProfileService =
           modelExecutionProfileService ?? ModelExecutionProfileService(),
       _offeringCatalogService = WritingModelOfferingCatalogService(),
       _profileService =
           profileService ??
           ProviderProfileService(
             catalogPort: ProviderCatalogService.seeded(),
             capabilityPort: ProviderCapabilityResolver.seeded(),
           ),
       _providerConnectionValidationService =
           providerConnectionValidationService ??
           ProviderConnectionValidationService();

  final ModelExecutionProfileService _modelExecutionProfileService;
  final WritingModelOfferingCatalogService _offeringCatalogService;
  final ProviderProfileService _profileService;
  final ProviderConnectionValidationService
  _providerConnectionValidationService;

  ModelEditorViewData build(
    AppSettings settings,
    Map<String, Object?> modelSettings,
  ) {
    // 中文注释: 这个服务只负责把设置持久化结构投影成模型编辑页可直接消费的数据。
    final modelSettingsDocument = ValueReaders.mapValue(modelSettings);
    final execution = _modelExecutionProfileService.resolve(
      settings: _settingsWithModelSettings(settings, modelSettingsDocument),
    );
    final runtimeProfile = ValueReaders.mapValue(execution['runtime_profile']);
    final metadata = _profileService.metadata.buildEditorMetadata(
      runtimeProfile,
    );
    final capabilityExposure = _capabilityExposureViewData(runtimeProfile);
    final connectionValidationResult = _providerConnectionValidationService
        .validate(
          title: ValueReaders.stringValue(metadata['provider_label']),
          protocol: ValueReaders.stringValue(metadata['protocol_mode']),
          baseUrl: ValueReaders.stringValue(metadata['base_url']),
          apiKey: ValueReaders.stringValue(runtimeProfile['api_key']),
          modelId: ValueReaders.stringValue(metadata['model_id']),
          apiMode: ValueReaders.stringValue(
            ValueReaders.mapValue(
              runtimeProfile['provider_runtime_route_contract'],
            )['resolved_api_mode'],
            ValueReaders.stringValue(metadata['api_mode'], 'chat'),
          ),
        );
    final customParameters = _customParameters(modelSettingsDocument, metadata);
    return ModelEditorViewData(
      providerId: ValueReaders.stringValue(metadata['provider_id']),
      providerLabel: ValueReaders.stringValue(metadata['provider_label']),
      protocolMode: ValueReaders.stringValue(metadata['protocol_mode']),
      baseUrl: ValueReaders.stringValue(metadata['base_url']),
      modelId: ValueReaders.stringValue(
        metadata['model_id'],
        ValueReaders.stringValue(execution['resolved_model_id']),
      ),
      embeddingModelId: ValueReaders.stringValue(
        settings.extraSettings['embedding_model_id'],
      ),
      supportsReasoning: ValueReaders.boolValue(metadata['supports_reasoning']),
      reasoningCanToggle: ValueReaders.boolValue(
        metadata['reasoning_can_toggle'],
      ),
      reasoningDefaultEnabled: ValueReaders.boolValue(
        metadata['reasoning_default_enabled'],
      ),
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
      supportsFileAttachments: ValueReaders.boolValue(
        metadata['supports_file_attachments'],
      ),
      supportsImageAttachments: ValueReaders.boolValue(
        metadata['supports_image_attachments'],
      ),
      supportsAttachmentUrlsOnly: ValueReaders.boolValue(
        metadata['supports_attachment_urls_only'],
      ),
      supportsMultiAttachments: ValueReaders.boolValue(
        metadata['supports_multi_attachments'],
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
        modelSettingsDocument['thinking_enabled'],
        ValueReaders.boolValue(metadata['reasoning_default_enabled']),
      ),
      thinkingEffortSupported: ValueReaders.boolValue(
        metadata['thinking_effort_supported'],
      ),
      thinkingEffortParameterLabel: ValueReaders.stringValue(
        metadata['thinking_effort_parameter_label'],
        '深度思考强度',
      ),
      thinkingEffort: ValueReaders.stringValue(
        modelSettingsDocument['thinking_effort'],
        'high',
      ),
      thinkingEffortOptions: _thinkingEffortOptions(
        metadata,
        modelSettingsDocument,
      ),
      temperature: ValueReaders.doubleValue(
        modelSettingsDocument['temperature'],
        ValueReaders.doubleValue(runtimeProfile['temperature'], 0.8),
      ),
      topP: ValueReaders.doubleValue(
        modelSettingsDocument['top_p'],
        ValueReaders.doubleValue(runtimeProfile['top_p'], 0.95),
      ),
      topK: ValueReaders.intValue(
        modelSettingsDocument['top_k'],
        ValueReaders.intValue(runtimeProfile['top_k']),
      ),
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
      customReasoningOverride: _customReasoningOverrideViewData(
        modelSettingsDocument,
        metadata,
      ),
      capabilityExposure: capabilityExposure,
      visibleAdvancedFields: capabilityExposure.visibleAdvancedFields,
      connectionValidationResult: ProviderConnectionValidationResultViewData(
        isSuccess: connectionValidationResult.isSuccess,
        summary: connectionValidationResult.summary,
        details: connectionValidationResult.details,
        errors: connectionValidationResult.errors,
        templateId: connectionValidationResult.templateId,
        providerId: connectionValidationResult.providerId,
        protocolId: connectionValidationResult.protocolId,
        protocolMode:
            connectionValidationResult.protocolKind?.id ??
            connectionValidationResult.protocolId,
        routeFamily: connectionValidationResult.routeFamily,
        selectedRouteFamily: connectionValidationResult.selectedRouteFamily,
        allowedRouteFamilies: connectionValidationResult.allowedRouteFamilies,
        hideOptions: connectionValidationResult.hideOptions,
        fallbackNotAllowed: connectionValidationResult.fallbackNotAllowed,
        warnings: connectionValidationResult.warnings,
        matchedTemplateId: connectionValidationResult.matchedTemplateId,
        matchedTemplateLabel: connectionValidationResult.matchedTemplateLabel,
      ),
    );
  }

  CapabilityExposureViewData _capabilityExposureViewData(
    Map<String, Object?> runtimeProfile,
  ) {
    // 中文注释: 设置页只消费共享曝光合同，不自己从 metadata 里再拼一套显隐逻辑。
    final exposure = CapabilityExposureView.fromRuntimeProfile(runtimeProfile);
    return CapabilityExposureViewData(
      protocolMode: exposure.protocolMode,
      protocolLabel: exposure.protocolLabel,
      apiMode: exposure.apiMode,
      routeFamily: exposure.routeFamily,
      allowedApiModes: exposure.allowedApiModes,
      allowedRouteFamilies: exposure.allowedRouteFamilies,
      apiModeVisible: exposure.apiModeVisible,
      visibleAdvancedFields: exposure.visibleAdvancedFields,
    );
  }

  List<String> _thinkingEffortOptions(
    Map<String, Object?> metadata,
    Map<String, Object?> modelSettingsDocument,
  ) {
    // 中文注释: 强度选项应尽量跟随模型/重写层的真实词表，避免把模型原生语义压回固定五项。
    final result = <String>[];
    for (final raw in ValueReaders.stringList(
      metadata['thinking_effort_options'],
    )) {
      final value = raw.trim();
      if (value.isNotEmpty && !result.contains(value)) {
        result.add(value);
      }
    }
    final current = ValueReaders.stringValue(
      modelSettingsDocument['thinking_effort'],
    ).trim();
    if (current.isNotEmpty && !result.contains(current)) {
      result.insert(0, current);
    }
    return result;
  }

  List<SettingsSearchOption<String>> _modelSuggestions(String providerId) {
    final cleanProviderId = providerId.trim();
    if (cleanProviderId.isEmpty) {
      return const <SettingsSearchOption<String>>[];
    }
    final selectionContractService = ProviderModelSelectionContractService(
      offeringCatalogService: _offeringCatalogService,
    );
    return selectionContractService
        .providerModelOptions(providerId: cleanProviderId, limit: 48)
        .map(
          (entry) => SettingsSearchOption<String>(
            value: entry.modelId,
            label: entry.modelLabel,
            note: entry.providerLabel,
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

  List<ModelParameterEntryViewData> _customParameters(
    Map<String, Object?> modelSettings,
    Map<String, Object?> metadata,
  ) {
    final stored = ValueReaders.mapList(modelSettings['custom_parameters']);
    if (stored.isNotEmpty) {
      return stored
          .map(ModelParameterEntryViewData.fromMap)
          .toList(growable: false);
    }

    final result = <ModelParameterEntryViewData>[];
    for (final entry in ValueReaders.mapList(
      metadata['model_default_parameters'],
    )) {
      final key = ValueReaders.stringValue(entry['key']).trim();
      if (_isStandardKey(key)) {
        continue;
      }
      result.add(ModelParameterEntryViewData.fromMap(entry));
    }
    return result;
  }

  CustomModelReasoningOverrideViewData _customReasoningOverrideViewData(
    Map<String, Object?> modelSettings,
    Map<String, Object?> metadata,
  ) {
    final rawOverride = ValueReaders.mapValue(
      modelSettings['custom_reasoning_override'],
    );
    final strategy = ValueReaders.mapValue(
      rawOverride['reasoning_toggle_parameter_strategy'],
    );
    final effortStrategy = ValueReaders.mapValue(
      rawOverride['reasoning_effort_parameter_strategy'],
    );
    final rawEffortValues = ValueReaders.mapValue(effortStrategy['values']);
    final effortValues = <String, String>{};
    for (final entry in rawEffortValues.entries) {
      final key = entry.key.toString().trim();
      if (key.isEmpty) {
        continue;
      }
      effortValues[key] = ValueReaders.stringValue(entry.value, key);
    }
    return CustomModelReasoningOverrideViewData(
      isKnownWritingModel: ValueReaders.stringValue(
        metadata['matched_writing_model_canonical_id'],
      ).trim().isNotEmpty,
      supportsReasoning: ValueReaders.boolValue(
        rawOverride['supports_reasoning'],
      ),
      reasoningCanToggle: ValueReaders.boolValue(
        rawOverride['reasoning_can_toggle'],
        true,
      ),
      reasoningDefaultEnabled: ValueReaders.boolValue(
        rawOverride['reasoning_default_enabled'],
      ),
      reasoningSupportsEffort: ValueReaders.boolValue(
        rawOverride['reasoning_supports_effort'],
      ),
      toggleStrategyKind: ValueReaders.stringValue(strategy['kind'], 'boolean'),
      toggleKey: ValueReaders.stringValue(strategy['key'], 'enable_thinking'),
      toggleEnabledValue: _stringifyOverrideValue(
        strategy['enabled_value'],
        fallback: 'true',
      ),
      toggleDisabledValue: _stringifyOverrideValue(
        strategy['disabled_value'],
        fallback: 'false',
      ),
      effortKey: ValueReaders.stringValue(
        effortStrategy['key'],
        'reasoning_effort',
      ),
      effortValues: effortValues,
    );
  }

  AppSettings _settingsWithModelSettings(
    AppSettings settings,
    Map<String, Object?> modelSettings,
  ) {
    return settings.copyWith(
      extraSettings: <String, Object?>{
        ...settings.extraSettings,
        'model_settings': ValueReaders.deepCopyMap(modelSettings),
      },
    );
  }

  String _stringifyOverrideValue(Object? value, {required String fallback}) {
    if (value == null) {
      return fallback;
    }
    if (value is Map) {
      return jsonEncode(value);
    }
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}
