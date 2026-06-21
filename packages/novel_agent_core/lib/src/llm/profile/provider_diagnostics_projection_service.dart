import '../../common/json_types.dart';
import '../../settings/provider_endpoint_settings.dart';
import 'capability_exposure_view.dart';
import 'provider_route_contract.dart';
import 'provider_runtime_route_contract.dart';

final class ProviderDiagnosticsProjection {
  const ProviderDiagnosticsProjection({
    required this.protocolKind,
    required this.protocolLabel,
    required this.apiModeVisible,
    required this.resolvedApiMode,
    required this.selectedRouteFamily,
    required this.allowedRouteFamilies,
    required this.validationWarnings,
    required this.validationErrors,
    required this.visibleAdvancedFields,
  });

  final ProtocolKind protocolKind;
  final String protocolLabel;
  final bool apiModeVisible;
  final String resolvedApiMode;
  final RequestRouteFamily selectedRouteFamily;
  final List<RequestRouteFamily> allowedRouteFamilies;
  final List<String> validationWarnings;
  final List<String> validationErrors;
  final List<String> visibleAdvancedFields;

  JsonMap toJson() {
    // 中文注释: 诊断投影要直接给 CLI / probes / future UI 读取，因此输出稳定 JSON 视图。
    return <String, Object?>{
      'resolved_protocol_kind': protocolKind.id,
      'resolved_protocol_label': protocolLabel,
      'resolved_api_mode': resolvedApiMode,
      'selected_route_family': selectedRouteFamily.id,
      'allowed_route_families': allowedRouteFamilies
          .map((family) => family.id)
          .toList(growable: false),
      'api_mode_visible': apiModeVisible,
      'validation_warnings': List<String>.unmodifiable(validationWarnings),
      'validation_errors': List<String>.unmodifiable(validationErrors),
      'visible_advanced_fields': List<String>.unmodifiable(
        visibleAdvancedFields,
      ),
    };
  }
}

final class ProviderDiagnosticsProjectionService {
  const ProviderDiagnosticsProjectionService();

  ProviderDiagnosticsProjection build({
    required JsonMap runtimeProfile,
    required ProviderEndpointSettings providerSettings,
  }) {
    // 中文注释: 诊断投影只消费 runtime profile 与 provider 设置的正式合同，不自己再发明一套路由判断。
    final runtimeRoute = ProviderRuntimeRouteContract.fromRuntimeProfile(
      runtimeProfile,
    );
    final exposure = CapabilityExposureView.fromRuntimeProfile(runtimeProfile);
    final validation = _validateProviderSettings(
      providerSettings: providerSettings,
      runtimeRoute: runtimeRoute,
    );
    return ProviderDiagnosticsProjection(
      protocolKind: runtimeRoute.protocolKind,
      protocolLabel: runtimeRoute.protocolKind.label,
      apiModeVisible: exposure.apiModeVisible,
      resolvedApiMode: runtimeRoute.resolvedApiMode,
      selectedRouteFamily: runtimeRoute.selectedRouteFamily,
      allowedRouteFamilies: runtimeRoute.allowedRouteFamilies,
      validationWarnings: validation['warnings'] as List<String>,
      validationErrors: validation['errors'] as List<String>,
      visibleAdvancedFields: exposure.visibleAdvancedFields,
    );
  }

  JsonMap buildJson({
    required JsonMap runtimeProfile,
    required ProviderEndpointSettings providerSettings,
  }) {
    // 中文注释: CLI 与诊断报告更喜欢字典结构，这里直接给出 JSON 友好的投影。
    return build(
      runtimeProfile: runtimeProfile,
      providerSettings: providerSettings,
    ).toJson();
  }

  JsonMap _validateProviderSettings({
    required ProviderEndpointSettings providerSettings,
    required ProviderRuntimeRouteContract runtimeRoute,
  }) {
    // 中文注释: 校验只做本地合同与基础可达性判断，不尝试联网 probe，也不替代真实请求。
    final errors = <String>[];
    final warnings = <String>[];
    final title = providerSettings.title.trim();
    final protocol = providerSettings.protocol.trim();
    final baseUrl = providerSettings.baseUrl.trim();
    final apiKey = providerSettings.apiKey.trim();
    final modelId = providerSettings.modelId.trim();
    final protocolKind = ProtocolKindCodec.tryParse(protocol);

    if (title.isEmpty) {
      errors.add('missing_provider_title');
    }
    if (modelId.isEmpty) {
      errors.add('missing_model_id');
    }
    if (protocol.isEmpty) {
      errors.add('missing_protocol');
    } else if (protocolKind == null) {
      errors.add('invalid_protocol');
    }
    if (baseUrl.isEmpty) {
      errors.add('missing_base_url');
    } else if (!_isValidHttpUrl(baseUrl)) {
      errors.add('invalid_base_url');
    }
    if (apiKey.isEmpty && !_looksLikeLocalEndpoint(baseUrl)) {
      errors.add('missing_api_key');
    }
    if (protocolKind != null && protocolKind != runtimeRoute.protocolKind) {
      errors.add('protocol_mismatch');
    }
    if (!runtimeRoute.allowedRouteFamilies.contains(runtimeRoute.selectedRouteFamily)) {
      errors.add('selected_route_not_allowed');
    }
    if (runtimeRoute.isFallbackUsed) {
      warnings.add('route_fallback_used');
    }
    if (!runtimeRoute.isAllowed) {
      warnings.add('route_not_explicitly_allowed');
    }
    return <String, Object?>{
      'errors': List<String>.unmodifiable(errors),
      'warnings': List<String>.unmodifiable(warnings),
    };
  }

  bool _isValidHttpUrl(String value) {
    // 中文注释: Base URL 校验只接受可解析的 http(s) 地址，避免把明显错误的字符串继续传下去。
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.trim().isNotEmpty;
  }

  bool _looksLikeLocalEndpoint(String value) {
    // 中文注释: 本地地址在诊断时允许先不填 API key，方便 CLI 做离线自检。
    final uri = Uri.tryParse(value.trim());
    if (uri == null) {
      return false;
    }
    final host = uri.host.trim().toLowerCase();
    return host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '0.0.0.0' ||
        host == '::1';
  }
}
