import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import '../catalog/provider_connection_contract.dart';
import 'provider_route_contract.dart';

final class ProviderRuntimeRouteContract {
  const ProviderRuntimeRouteContract({
    required this.protocolKind,
    required this.providerConnectionContractId,
    required this.providerConnectionProtocolId,
    required this.providerConnectionRouteFamily,
    required this.allowedRouteFamilies,
    required this.requestedApiMode,
    required this.selectedRouteFamily,
    required this.resolvedApiMode,
    required this.isFallbackUsed,
    required this.isAllowed,
    required this.matchedWritingModelCanonicalId,
    required this.matchedWritingModelOfferingId,
  });

  final ProtocolKind protocolKind;
  final String providerConnectionContractId;
  final String providerConnectionProtocolId;
  final RequestRouteFamily providerConnectionRouteFamily;
  final List<RequestRouteFamily> allowedRouteFamilies;
  final String requestedApiMode;
  final RequestRouteFamily selectedRouteFamily;
  final String resolvedApiMode;
  final bool isFallbackUsed;
  final bool isAllowed;
  final String matchedWritingModelCanonicalId;
  final String matchedWritingModelOfferingId;

  String get selectedRouteFamilyId => selectedRouteFamily.id;

  JsonMap toJson() {
    // 中文注释: runtime route contract 的 JSON 投影用于 runtime profile、request options 与测试共享同一份稳定事实。
    return <String, Object?>{
      'protocol_kind': protocolKind.id,
      'provider_connection_contract_id': providerConnectionContractId,
      'provider_connection_protocol_id': providerConnectionProtocolId,
      'provider_connection_route_family': providerConnectionRouteFamily.id,
      'allowed_route_families': allowedRouteFamilies
          .map((family) => family.id)
          .toList(growable: false),
      'requested_api_mode': requestedApiMode,
      'selected_route_family': selectedRouteFamilyId,
      'resolved_api_mode': resolvedApiMode,
      'is_fallback_used': isFallbackUsed,
      'is_allowed': isAllowed,
      'matched_writing_model_canonical_id': matchedWritingModelCanonicalId,
      'matched_writing_model_offering_id': matchedWritingModelOfferingId,
    };
  }

  static ProviderRuntimeRouteContract resolve({
    required ProtocolKind protocolKind,
    required ProviderConnectionContract connectionContract,
    String apiMode = '',
    String matchedWritingModelCanonicalId = '',
    String matchedWritingModelOfferingId = '',
  }) {
    // 中文注释: runtime route 统一由协议合同、连接合同和 api_mode 三者共同决定，不在请求层再猜。
    final routeResolution = GatewayRouteResolution.resolve(
      protocolKind: protocolKind,
      apiMode: apiMode,
      allowedRouteFamilies: connectionContract.allowedRouteFamilies,
      fallbackRouteFamily: connectionContract.routeFamily,
    );
    return ProviderRuntimeRouteContract(
      protocolKind: protocolKind,
      providerConnectionContractId: connectionContract.templateId,
      providerConnectionProtocolId: connectionContract.protocolId,
      providerConnectionRouteFamily: connectionContract.routeFamily,
      allowedRouteFamilies: routeResolution.allowedRouteFamilies,
      requestedApiMode: routeResolution.requestedApiMode,
      selectedRouteFamily: routeResolution.routeFamily,
      resolvedApiMode: routeResolution.apiMode,
      isFallbackUsed: routeResolution.isFallbackUsed,
      isAllowed: routeResolution.isAllowed,
      matchedWritingModelCanonicalId: matchedWritingModelCanonicalId,
      matchedWritingModelOfferingId: matchedWritingModelOfferingId,
    );
  }

  static ProviderRuntimeRouteContract fromRuntimeProfile(JsonMap runtimeProfile) {
    // 中文注释: 这里优先读 runtime profile 里的正式合同投影，再回退到旧顶层字段，避免 request options 自己重算路由。
    final routeContract = ValueReaders.mapValue(
      runtimeProfile['provider_runtime_route_contract'],
    );
    final fallbackConnection = ValueReaders.mapValue(
      runtimeProfile['provider_connection_contract'],
    );
    final protocolKind = ProtocolKindCodec.tryParse(
          ValueReaders.stringValue(routeContract['protocol_kind']),
        ) ??
        ProtocolKindCodec.tryParse(
          ValueReaders.stringValue(runtimeProfile['resolved_protocol_kind']),
        ) ??
        ProtocolKindCodec.tryParse(ValueReaders.stringValue(runtimeProfile['kind'])) ??
        ProtocolKind.openAiCompatible;
    final providerConnectionRouteFamily = RequestRouteFamilyCodec.tryParse(
          ValueReaders.stringValue(routeContract['provider_connection_route_family']),
        ) ??
        RequestRouteFamilyCodec.tryParse(
          ValueReaders.stringValue(runtimeProfile['provider_connection_route_family']),
        ) ??
        RequestRouteFamilyCodec.tryParse(
          ValueReaders.stringValue(fallbackConnection['route_family']),
        ) ??
        protocolKind.defaultRouteFamily;
    final allowedRouteFamilies = <RequestRouteFamily>[
      for (final raw in ValueReaders.stringList(routeContract['allowed_route_families']))
        if (RequestRouteFamilyCodec.tryParse(raw) != null)
          RequestRouteFamilyCodec.parse(raw),
    ];
    final selectedRouteFamily = RequestRouteFamilyCodec.tryParse(
          ValueReaders.stringValue(routeContract['selected_route_family']),
        ) ??
        RequestRouteFamilyCodec.tryParse(
          ValueReaders.stringValue(runtimeProfile['resolved_selected_route_family']),
        ) ??
        RequestRouteFamilyCodec.tryParse(
          ValueReaders.stringValue(runtimeProfile['route_family']),
        ) ??
        providerConnectionRouteFamily;
    final requestedApiMode = ValueReaders.stringValue(
      routeContract['requested_api_mode'],
      ValueReaders.stringValue(runtimeProfile['requested_api_mode']),
    ).trim();
    final resolvedApiMode = ValueReaders.stringValue(
      routeContract['resolved_api_mode'],
      ValueReaders.stringValue(runtimeProfile['resolved_selected_api_mode']),
    ).trim();
    return ProviderRuntimeRouteContract(
      protocolKind: protocolKind,
      providerConnectionContractId: ValueReaders.stringValue(
        routeContract['provider_connection_contract_id'],
        ValueReaders.stringValue(
          runtimeProfile['resolved_provider_connection_contract_id'],
        ),
      ),
      providerConnectionProtocolId: ValueReaders.stringValue(
        routeContract['provider_connection_protocol_id'],
        ValueReaders.stringValue(runtimeProfile['provider_connection_protocol_id']),
      ),
      providerConnectionRouteFamily: providerConnectionRouteFamily,
      allowedRouteFamilies: allowedRouteFamilies.isNotEmpty
          ? List<RequestRouteFamily>.unmodifiable(allowedRouteFamilies)
          : List<RequestRouteFamily>.unmodifiable(
              ValueReaders.stringList(
                runtimeProfile['resolved_route_families'],
              ).map((raw) => RequestRouteFamilyCodec.parse(raw)).toList(
                    growable: false,
                  ),
            ),
      requestedApiMode: requestedApiMode.isNotEmpty
          ? requestedApiMode
          : selectedRouteFamily.apiMode,
      selectedRouteFamily: selectedRouteFamily,
      resolvedApiMode: resolvedApiMode.isNotEmpty
          ? resolvedApiMode
          : selectedRouteFamily.apiMode,
      isFallbackUsed: ValueReaders.boolValue(
        routeContract['is_fallback_used'],
        ValueReaders.boolValue(runtimeProfile['resolved_route_is_fallback_used']),
      ),
      isAllowed: ValueReaders.boolValue(
        routeContract['is_allowed'],
        ValueReaders.boolValue(runtimeProfile['resolved_route_is_allowed'], true),
      ),
      matchedWritingModelCanonicalId: ValueReaders.stringValue(
        routeContract['matched_writing_model_canonical_id'],
        ValueReaders.stringValue(
          runtimeProfile['matched_writing_model_canonical_id'],
        ),
      ),
      matchedWritingModelOfferingId: ValueReaders.stringValue(
        routeContract['matched_writing_model_offering_id'],
        ValueReaders.stringValue(
          runtimeProfile['matched_writing_model_offering_id'],
        ),
      ),
    );
  }
}
