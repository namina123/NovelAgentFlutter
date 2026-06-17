import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import '../../ports/provider_capability_port.dart';
import '../../ports/provider_catalog_port.dart';
import '../catalog/legacy_provider_catalog_bridge_service.dart';
import '../catalog/provider_connection_contract.dart';
import '../catalog/provider_catalog_service.dart';
import '../catalog/provider_interface_template_service.dart';
import '../catalog/writing_model_offering_catalog_service.dart';
import '../catalog/writing_model_runtime_defaults_service.dart';
import '../catalog/writing_model_reasoning_profile_service.dart';
import 'custom_model_reasoning_override_service.dart';
import 'provider_custom_parameter_service.dart';
import 'provider_profile_constants.dart';
import 'provider_profile_normalizer_service.dart';
import 'provider_protocol_service.dart';
import 'provider_route_contract.dart';
import 'provider_runtime_route_contract.dart';
import 'provider_thinking_parameter_service.dart';

class ProviderRuntimeProfileService {
  ProviderRuntimeProfileService({
    required ProviderCatalogPort catalogPort,
    required ProviderCapabilityPort capabilityPort,
    required ProviderProfileNormalizerService normalizerService,
    required ProviderProtocolService protocolService,
    required ProviderThinkingParameterService thinkingService,
    required ProviderCustomParameterService customParameterService,
    ProviderInterfaceTemplateService? providerInterfaceTemplateService,
    ProviderConnectionContractService? providerConnectionContractService,
    LegacyProviderCatalogBridgeService? legacyProviderCatalogBridgeService,
    WritingModelOfferingCatalogService? writingModelOfferingCatalogService,
    WritingModelRuntimeDefaultsService? writingModelRuntimeDefaultsService,
    WritingModelReasoningProfileService? writingReasoningProfileService,
    CustomModelReasoningOverrideService? customReasoningOverrideService,
  }) : _catalogPort = catalogPort,
       _capabilityPort = capabilityPort,
       _normalizerService = normalizerService,
       _protocolService = protocolService,
       _thinkingService = thinkingService,
       _customParameterService = customParameterService,
       _providerInterfaceTemplateService =
           providerInterfaceTemplateService ??
           ProviderInterfaceTemplateService.seeded(),
       _providerConnectionContractService =
           providerConnectionContractService ??
           ProviderConnectionContractService(
             templateService:
                 providerInterfaceTemplateService ??
                 ProviderInterfaceTemplateService.seeded(),
           ),
       _legacyProviderCatalogBridgeService =
           legacyProviderCatalogBridgeService ??
           (catalogPort is ProviderCatalogService
               ? LegacyProviderCatalogBridgeService(catalogService: catalogPort)
               : null),
       _writingModelOfferingCatalogService =
           writingModelOfferingCatalogService ??
           WritingModelOfferingCatalogService(),
       _writingModelRuntimeDefaultsService =
           writingModelRuntimeDefaultsService ??
           WritingModelRuntimeDefaultsService(),
       _writingReasoningProfileService =
           writingReasoningProfileService ??
           WritingModelReasoningProfileService(),
       _customReasoningOverrideService =
           customReasoningOverrideService ??
           CustomModelReasoningOverrideService();

  final ProviderCatalogPort _catalogPort;
  final ProviderCapabilityPort _capabilityPort;
  final ProviderProfileNormalizerService _normalizerService;
  final ProviderProtocolService _protocolService;
  final ProviderThinkingParameterService _thinkingService;
  final ProviderCustomParameterService _customParameterService;
  final ProviderInterfaceTemplateService _providerInterfaceTemplateService;
  final ProviderConnectionContractService _providerConnectionContractService;
  final LegacyProviderCatalogBridgeService? _legacyProviderCatalogBridgeService;
  final WritingModelOfferingCatalogService _writingModelOfferingCatalogService;
  final WritingModelRuntimeDefaultsService _writingModelRuntimeDefaultsService;
  final WritingModelReasoningProfileService _writingReasoningProfileService;
  final CustomModelReasoningOverrideService _customReasoningOverrideService;

  JsonMap composeRuntimeProfile(
    JsonMap modelProfile,
    JsonMap credential, {
    String apiMode = 'chat',
  }) {
    // 中文注释: 运行配置组装是这一层的核心职责，负责把模型态与接口态合成可执行配置。
    final model = _normalizerService.normalizeModelProfile(modelProfile);
    final cred = credential.isEmpty
        ? _normalizerService.blankCredential()
        : _normalizerService.normalizeCredential(credential);
    var runtimeKind = ValueReaders.stringValue(
      modelProfile['kind'],
      ValueReaders.stringValue(
        cred['kind'],
        ProviderProfileConstants.kindOpenAiCompatible,
      ),
    );
    if (!_protocolService.isSupportedProtocol(runtimeKind)) {
      runtimeKind = ProviderProfileConstants.kindOpenAiCompatible;
    }
    final writingReasoning = _writingReasoningProfileService.resolve(
      providerId: ValueReaders.stringValue(cred['provider_id']),
      modelId: ValueReaders.stringValue(model['model']),
      baseUrl: ValueReaders.stringValue(cred['base_url']),
    );
    final writingOffering = _resolveWritingOffering(
      providerId: ValueReaders.stringValue(cred['provider_id']),
      modelId: ValueReaders.stringValue(model['model']),
    );
    final customReasoning = _customReasoningOverrideService.normalize(
      modelProfile['custom_reasoning_override'],
    );
    final effectiveReasoning = customReasoning.isNotEmpty
        ? customReasoning
        : writingReasoning;
    final providerConnectionContractResolution =
        _providerConnectionContractService.resolve(
          query: _providerTemplateQuery(
            providerId: ValueReaders.stringValue(cred['provider_id']),
            providerName: ValueReaders.stringValue(cred['name']),
            runtimeKind: runtimeKind,
          ),
          baseUrl: ValueReaders.stringValue(cred['base_url']),
          providerId: ValueReaders.stringValue(cred['provider_id']),
          preferredProtocolId: runtimeKind,
        );
    final providerConnectionContract =
        providerConnectionContractResolution.contract;
    final runtimeRoute = ProviderRuntimeRouteContract.resolve(
      protocolKind: ProtocolKindCodec.parse(runtimeKind),
      connectionContract: providerConnectionContract,
      apiMode: apiMode,
      matchedWritingModelCanonicalId: ValueReaders.stringValue(
        writingReasoning['matched_canonical_model_id'],
      ),
      matchedWritingModelOfferingId: ValueReaders.stringValue(
        writingReasoning['matched_provider_offering_id'],
      ),
    );
    final defaultReasoningEnabled = ValueReaders.boolValue(
      effectiveReasoning['reasoning_default_enabled'],
    );
    final runtime = <String, Object?>{
      'id': model['id'],
      'name': model['name'],
      'purpose': model['purpose'],
      'credential_id': model['credential_id'],
      'credential_name': cred['name'],
      'provider_id': cred['provider_id'],
      'provider_label': _providerLabelForCredential(cred),
      'provider_connection_contract':
          providerConnectionContract.toJson(),
      'provider_connection_contract_id':
          providerConnectionContract.templateId,
      'provider_connection_protocol_id':
          providerConnectionContract.protocolId,
      'provider_connection_route_family':
          providerConnectionContract.routeFamily.apiMode,
      'provider_connection_allowed_route_families':
          providerConnectionContract.allowedRouteFamilies
              .map((family) => family.apiMode)
              .toList(growable: false),
      'provider_connection_allowed_api_modes':
          providerConnectionContract.allowedApiModes,
      'resolved_protocol_kind': runtimeRoute.protocolKind.id,
      'resolved_route_families': runtimeRoute.allowedRouteFamilies
          .map((family) => family.id)
          .toList(growable: false),
      'resolved_selected_route_family': runtimeRoute.selectedRouteFamily.id,
      'resolved_selected_api_mode': runtimeRoute.resolvedApiMode,
      'resolved_provider_connection_contract_id':
          runtimeRoute.providerConnectionContractId,
      'resolved_route_is_fallback_used': runtimeRoute.isFallbackUsed,
      'resolved_route_is_allowed': runtimeRoute.isAllowed,
      'requested_api_mode': runtimeRoute.requestedApiMode,
      'provider_runtime_route_contract': runtimeRoute.toJson(),
      'kind': runtimeKind,
      'base_url': cred['base_url'],
      'api_key': cred['api_key'],
      'model': model['model'],
      'context_length': model['context_length'],
      'compression_context_length': model['compression_context_length'],
      'max_output_tokens': model['max_output_tokens'],
      'thinking_parameter_format': model['thinking_parameter_format'],
      'thinking_supported': ValueReaders.boolValue(
        modelProfile['thinking_supported'],
        true,
      ),
      'thinking_enabled': modelProfile.containsKey('thinking_enabled')
          ? ValueReaders.boolValue(modelProfile['thinking_enabled'])
          : defaultReasoningEnabled,
      'thinking_effort': _thinkingService.normalizeThinkingEffort(
        ValueReaders.stringValue(modelProfile['thinking_effort'], 'high'),
      ),
      'temperature': model['temperature'],
      'top_p': model['top_p'],
      'top_k': model['top_k'],
      'custom_parameters': ValueReaders.deepCopyList(
        ValueReaders.objectList(model['custom_parameters']),
      ),
      'custom_reasoning_override': ValueReaders.deepCopyMap(customReasoning),
      'streaming_enabled': model['streaming_enabled'],
      'supports_streaming': model['supports_streaming'],
      'supports_tools': model['supports_tools'],
      'supports_tool_choice': model['supports_tool_choice'],
      'supports_image_generation': model['supports_image_generation'],
      'supports_file_attachments': model['supports_file_attachments'],
      'supports_image_attachments': model['supports_image_attachments'],
      'supports_attachment_urls_only': model['supports_attachment_urls_only'],
      'supports_multi_attachments': model['supports_multi_attachments'],
    };
    if (writingOffering != null) {
      runtime['matched_writing_model_offering'] = writingOffering;
      runtime['matched_writing_model_offering_id'] = ValueReaders.stringValue(
        writingOffering['model_id'],
      );
      runtime['matched_writing_model_offering_canonical_id'] =
          ValueReaders.stringValue(writingOffering['canonical_model_id']);
      runtime['matched_writing_model_canonical_id'] = ValueReaders.stringValue(
        writingOffering['canonical_model_id'],
      );
    }
    if (effectiveReasoning.isNotEmpty) {
      // 中文注释: 写作模型事实层提供更精细的 reasoning 投影，先并入运行态，供 metadata 与能力链继续共享。
      runtime['supports_reasoning'] = ValueReaders.boolValue(
        effectiveReasoning['supports_reasoning'],
      );
      runtime['reasoning_mode_behavior'] =
          effectiveReasoning['reasoning_mode_behavior'];
      runtime['reasoning_can_toggle'] = ValueReaders.boolValue(
        effectiveReasoning['reasoning_can_toggle'],
      );
      runtime['reasoning_default_enabled'] = defaultReasoningEnabled;
      runtime['reasoning_supports_effort'] = ValueReaders.boolValue(
        effectiveReasoning['reasoning_supports_effort'],
      );
      runtime['reasoning_effort_options'] = ValueReaders.deepCopyList(
        ValueReaders.stringList(
          effectiveReasoning['reasoning_effort_options'],
        ).cast<Object?>(),
      );
      final overrideToggle = ValueReaders.mapValue(
        effectiveReasoning['reasoning_toggle_parameter_strategy'],
      );
      if (overrideToggle.isNotEmpty) {
        runtime['reasoning_toggle_parameter_strategy'] = overrideToggle;
        final format = customReasoning.isNotEmpty
            ? _customReasoningOverrideService.compatibilityThinkingFormat(
                customReasoning,
              )
            : _strategyToThinkingFormat(overrideToggle);
        if (format.isNotEmpty) {
          runtime['thinking_parameter_format'] = format;
        }
      }
      final overrideEffort = ValueReaders.mapValue(
        effectiveReasoning['reasoning_effort_parameter_strategy'],
      );
      if (overrideEffort.isNotEmpty) {
        runtime['reasoning_effort_parameter_strategy'] = overrideEffort;
      }
    }
    return applyModelCapabilityMapping(
      runtime,
      modelProfile: model,
      credential: cred,
    );
  }

  String _providerTemplateQuery({
    required String providerId,
    required String providerName,
    required String runtimeKind,
  }) {
    // 中文注释: 接口模板匹配优先使用 provider + protocol 联合查询，避免同一 provider 的 native/compatible 模板互相抢占。
    final cleanProviderId = providerId.trim();
    final cleanProviderName = providerName.trim();
    final cleanRuntimeKind = runtimeKind.trim();
    final providerText = cleanProviderId.isNotEmpty
        ? cleanProviderId
        : cleanProviderName;
    if (providerText.isEmpty) {
      return cleanRuntimeKind;
    }
    if (cleanRuntimeKind.isEmpty) {
      return providerText;
    }
    return '$providerText ${cleanRuntimeKind.replaceAll('_', ' ')}';
  }

  JsonMap applyModelCapabilityMapping(
    JsonMap runtimeProfile, {
    JsonMap modelProfile = const <String, Object?>{},
    JsonMap credential = const <String, Object?>{},
  }) {
    // 中文注释: 能力映射只负责规则合并和参数整理，不承担输入归一化或展示摘要职责。
    final result = ValueReaders.deepCopyMap(runtimeProfile);
    final model = modelProfile.isEmpty ? result : modelProfile;
    final cred = credential.isEmpty
        ? <String, Object?>{
            'id': result['credential_id'],
            'name': result['credential_name'],
            'kind': result['kind'],
            'base_url': result['base_url'],
            'api_key': result['api_key'],
            'provider_id': result['provider_id'],
          }
        : credential;
    final mapping = _capabilityPort.resolve(
      cred,
      model,
      runtimeProfile: result,
    );
    final writingOffering = ValueReaders.mapValue(
      result['matched_writing_model_offering'],
    );
    final writingDefaults = _writingModelRuntimeDefaultsService.resolveDefaults(
      providerId: ValueReaders.stringValue(cred['provider_id']),
      modelId: ValueReaders.stringValue(result['model']),
      credentialId: ValueReaders.stringValue(result['credential_id']),
    );
    final legacyCatalogModel = _resolveLegacyCatalogModel(
      providerId: ValueReaders.stringValue(cred['provider_id']),
      modelId: ValueReaders.stringValue(result['model']),
      writingDefaults: writingDefaults,
      writingOffering: writingOffering,
    );
    _applyWritingOfferingDefaults(result, writingDefaults, writingOffering);
    _applyCatalogModelDefaults(result, legacyCatalogModel);

    final profileDefaults = ValueReaders.mapValue(mapping['profile_defaults']);
    profileDefaults.forEach((key, value) {
      // 中文注释: 只有字段仍然处于默认态时，目录规则才有资格回填推荐值。
      if (_shouldApplyProfileDefault(key, result[key])) {
        result[key] = value;
      }
    });

    final capabilities = ValueReaders.mapValue(mapping['capabilities']);
    capabilities.forEach((key, value) {
      // 中文注释: 顶层 capability 只接受核心已知字段，避免运行配置模型被额外键污染。
      if (ProviderProfileConstants.capabilityKeys.contains(key)) {
        result[key] = ValueReaders.boolValue(value);
      }
    });

    final parameters = <Object?>[];
    parameters.addAll(ValueReaders.objectList(mapping['request_parameters']));
    parameters.addAll(ValueReaders.objectList(result['custom_parameters']));
    result['custom_parameters'] = _customParameterService
        .resolveCustomParameters(
          parameters,
          excludedKeys: ValueReaders.stringList(mapping['excluded_parameters']),
        );
    result['provider_model_capability'] = <String, Object?>{
      'version': ValueReaders.intValue(mapping['version']),
      'provider_id': ValueReaders.stringValue(mapping['provider_id']),
      'provider_label': ValueReaders.stringValue(mapping['provider_label']),
      'matched_rule_ids': ValueReaders.stringList(mapping['matched_rule_ids']),
      'parameter_definitions': ValueReaders.deepCopyList(
        ValueReaders.objectList(mapping['parameter_definitions']),
      ),
      'excluded_parameters': ValueReaders.stringList(
        mapping['excluded_parameters'],
      ),
      'supported_parameters': ValueReaders.stringList(
        _supportedParameters(
          legacyCatalogModel: legacyCatalogModel,
          writingDefaults: writingDefaults,
        ),
      ),
      'unsupported_parameters': _mergedUniqueStringArrays(
        _unsupportedParameters(
          legacyCatalogModel: legacyCatalogModel,
          writingDefaults: writingDefaults,
        ),
        mapping['excluded_parameters'],
      ),
      'catalog_model': legacyCatalogModel,
      'writing_model_offering': writingOffering,
    };
    return result;
  }

  JsonMap defaultProfile() {
    // 中文注释: 默认运行配置仍然走完整组装链，保证默认值与真实运行值没有两套来源。
    return composeRuntimeProfile(
      _normalizerService.blankModelProfile(),
      _normalizerService.blankCredential(),
    );
  }

  JsonMap normalize(JsonMap profile) {
    // 中文注释: 这里把外部输入统一收敛到运行态配置，供 GUI、CLI、存储恢复共享同一路径。
    if (profile.containsKey('credential_id')) {
      if (profile.containsKey('base_url') ||
          profile.containsKey('api_key') ||
          profile.containsKey('kind')) {
        final runtimeCredential = _normalizerService
            .normalizeCredential(<String, Object?>{
              'id': profile['credential_id'],
              'name': profile['credential_name'],
              'provider_id': profile['provider_id'],
              'kind': profile['kind'],
              'base_url': profile['base_url'],
              'api_key': profile['api_key'],
            });
        return composeRuntimeProfile(
          profile,
          runtimeCredential,
          apiMode: ValueReaders.stringValue(profile['api_mode'], 'chat'),
        );
      }
      return composeRuntimeProfile(
        profile,
        const <String, Object?>{},
        apiMode: ValueReaders.stringValue(profile['api_mode'], 'chat'),
      );
    }

    final credential = _normalizerService.normalizeCredential(<String, Object?>{
      'id': profile['credential_id'],
      'name': profile['credential_name'] ?? profile['name'],
      'provider_id': profile['provider_id'],
      'kind': profile['kind'],
      'base_url': profile['base_url'],
      'api_key': profile['api_key'],
    });
    final model = _normalizerService.normalizeModelProfile(<String, Object?>{
      'id': profile['id'],
      'name': profile['name'],
      'purpose': profile['purpose'],
      'credential_id': credential['id'],
      'kind': profile['kind'] ?? credential['kind'],
      'model': profile['model'],
      'context_length': profile['context_length'],
      'compression_context_length': profile['compression_context_length'],
      'max_output_tokens': profile['max_output_tokens'],
      'thinking_parameter_format': profile['thinking_parameter_format'],
      'custom_reasoning_override': profile['custom_reasoning_override'],
      'temperature': profile['temperature'],
      'top_p': profile['top_p'],
      'top_k': profile['top_k'],
      'custom_parameters': profile['custom_parameters'],
      'streaming_enabled': profile['streaming_enabled'],
      'supports_streaming': profile['supports_streaming'],
      'supports_tools': profile['supports_tools'],
      'supports_tool_choice': profile['supports_tool_choice'],
      'supports_image_generation': profile['supports_image_generation'],
      'supports_file_attachments': profile['supports_file_attachments'],
      'supports_image_attachments': profile['supports_image_attachments'],
      'supports_attachment_urls_only': profile['supports_attachment_urls_only'],
      'supports_multi_attachments': profile['supports_multi_attachments'],
    });
    return composeRuntimeProfile(
      model,
      credential,
      apiMode: ValueReaders.stringValue(profile['api_mode'], 'chat'),
    );
  }

  JsonMap normalizeCredential(JsonMap credential) {
    // 中文注释: 运行配置服务对外暴露 credential 归一化，是为了让描述服务和上层入口不必直接碰 normalizer。
    return _normalizerService.normalizeCredential(credential);
  }

  JsonMap normalizeModelProfile(JsonMap profile) {
    // 中文注释: 这里转发模型归一化能力，保持上层只依赖一个运行配置入口即可使用常见操作。
    return _normalizerService.normalizeModelProfile(profile);
  }

  bool _shouldApplyProfileDefault(String key, Object? value) {
    // 中文注释: 默认态识别只服务于目录推荐值回填，避免覆盖用户显式设置。
    switch (key) {
      case 'thinking_parameter_format':
        return _thinkingService.normalizeThinkingParameterFormat(
              ValueReaders.stringValue(value),
            ) ==
            ProviderProfileConstants.thinkingFormatNone;
      case 'context_length':
        return ValueReaders.intValue(value) <= 0 ||
            ValueReaders.intValue(value) ==
                ProviderProfileConstants.defaultContextLength;
      case 'compression_context_length':
        return ValueReaders.intValue(value) <= 0 ||
            ValueReaders.intValue(value) ==
                ProviderProfileConstants.defaultCompressionContextLength;
      case 'max_output_tokens':
        return ValueReaders.intValue(value) ==
            ProviderProfileConstants.defaultMaxOutputTokens;
      default:
        if (value == null) {
          return true;
        }
        if (value is String) {
          return value.trim().isEmpty;
        }
        return false;
    }
  }

  void _applyCatalogModelDefaults(JsonMap result, JsonMap catalogModel) {
    // 中文注释: 目录默认值只在用户尚未显式填写时补齐，确保推荐不会压过用户选择。
    if (catalogModel.isEmpty) {
      return;
    }
    for (final key in <String>[
      'context_length',
      'compression_context_length',
      'max_output_tokens',
      'thinking_parameter_format',
    ]) {
      if (_shouldApplyProfileDefault(key, result[key])) {
        result[key] = catalogModel[key] ?? result[key];
      }
    }
    for (final key in <String>[
      'supports_streaming',
      'supports_tools',
      'supports_tool_choice',
      'supports_image_generation',
      'supports_file_attachments',
      'supports_image_attachments',
      'supports_attachment_urls_only',
      'supports_multi_attachments',
    ]) {
      if (catalogModel.containsKey(key)) {
        result[key] = ValueReaders.boolValue(catalogModel[key]);
      }
    }
  }

  void _applyWritingOfferingDefaults(
    JsonMap result,
    JsonMap writingDefaults,
    JsonMap writingOffering,
  ) {
    // 中文注释: 命中新写作事实层时，先以 runtime defaults 为主补齐字段，再让旧 catalog 只负责剩余空白位。
    if (writingDefaults.isEmpty && writingOffering.isEmpty) {
      return;
    }
    for (final key in <String>[
      'context_length',
      'compression_context_length',
      'max_output_tokens',
      'supports_streaming',
      'supports_tools',
      'supports_tool_choice',
      'supports_file_attachments',
      'supports_image_attachments',
      'supports_attachment_urls_only',
      'supports_multi_attachments',
    ]) {
      if (writingDefaults.containsKey(key) &&
          _shouldApplyProfileDefault(key, result[key])) {
        result[key] = writingDefaults[key];
      }
    }
    final displayLabel = ValueReaders.stringValue(
      writingDefaults['name'],
      ValueReaders.stringValue(writingOffering['display_label']),
    );
    if (displayLabel.trim().isNotEmpty &&
        ValueReaders.stringValue(result['name']).trim() == '未命名模型') {
      result['name'] = displayLabel;
    }
  }

  JsonMap _resolveLegacyCatalogModel({
    required String providerId,
    required String modelId,
    required JsonMap writingDefaults,
    required JsonMap writingOffering,
  }) {
    if (writingDefaults.isNotEmpty || writingOffering.isNotEmpty) {
      return <String, Object?>{};
    }
    return _legacyProviderCatalogBridgeService?.legacyMatchModel(
          modelId,
          providerId: providerId,
        ) ??
        <String, Object?>{};
  }

  JsonMap _parameterSummary({
    required JsonMap writingDefaults,
    required JsonMap legacyCatalogModel,
  }) {
    if (writingDefaults.isNotEmpty) {
      final runtimeSummary = _writingModelRuntimeDefaultsService
          .parameterSummary(writingDefaults);
      if (ValueReaders.stringList(
            runtimeSummary['supported_parameters'],
          ).isNotEmpty ||
          ValueReaders.stringList(
            runtimeSummary['unsupported_parameters'],
          ).isNotEmpty) {
        return runtimeSummary;
      }
    }
    return _legacyProviderCatalogBridgeService?.legacyCatalogParameterSummary(
          legacyCatalogModel,
        ) ??
        <String, Object?>{};
  }

  List<String> _supportedParameters({
    required JsonMap legacyCatalogModel,
    required JsonMap writingDefaults,
  }) {
    return ValueReaders.stringList(
      _parameterSummary(
        writingDefaults: writingDefaults,
        legacyCatalogModel: legacyCatalogModel,
      )['supported_parameters'],
    );
  }

  List<String> _unsupportedParameters({
    required JsonMap legacyCatalogModel,
    required JsonMap writingDefaults,
  }) {
    return ValueReaders.stringList(
      _parameterSummary(
        writingDefaults: writingDefaults,
        legacyCatalogModel: legacyCatalogModel,
      )['unsupported_parameters'],
    );
  }

  JsonMap? _resolveWritingOffering({
    required String providerId,
    required String modelId,
  }) {
    final providerMatched = _writingModelOfferingCatalogService
        .offeringByProviderModelId(providerId: providerId, modelId: modelId);
    if (providerMatched != null) {
      return providerMatched;
    }
    return _writingModelOfferingCatalogService.canonicalByAlias(modelId);
  }

  String _providerLabelForCredential(JsonMap credential) {
    final providerId = ValueReaders.stringValue(
      credential['provider_id'],
    ).trim();
    if (providerId.isEmpty) {
      return '';
    }
    final matched = _providerInterfaceTemplateService.bestTemplateMatch(
      query: providerId,
      baseUrl: ValueReaders.stringValue(credential['base_url']),
    );
    final label = ValueReaders.stringValue(matched['label']).trim();
    if (label.isNotEmpty) {
      return label;
    }
    return ValueReaders.stringValue(
      _catalogPort.providerById(providerId)['label'],
      providerId,
    );
  }

  List<String> _mergedUniqueStringArrays(Object? first, Object? second) {
    // 中文注释: 黑名单合并集中在这里，避免 capability 摘要与参数支持判断看到重复值。
    final result = <String>[];
    for (final raw in <Object?>[first, second]) {
      for (final value in ValueReaders.stringList(raw)) {
        if (!result.contains(value)) {
          result.add(value);
        }
      }
    }
    return result;
  }

  String _strategyToThinkingFormat(JsonMap strategy) {
    // 中文注释: 写作模型事实层先把少数明确可映射的 reasoning 策略回投到旧格式字段，降低 WM-02 首轮接线风险。
    final kind = ValueReaders.stringValue(strategy['kind']);
    switch (kind) {
      case 'thinking_object':
        return ProviderProfileConstants.thinkingFormatDeepseekObject;
      case 'boolean':
        return ProviderProfileConstants.thinkingFormatEnableBoolean;
      case 'reasoning_effort_only':
        return ProviderProfileConstants.thinkingFormatReasoningEffortOnly;
      default:
        return '';
    }
  }
}
