import '../../common/value_readers.dart';
import '../catalog/provider_connection_contract.dart';
import 'provider_runtime_route_contract.dart';
import 'provider_route_contract.dart';

class ProviderConnectionValidationService {
  ProviderConnectionValidationService({
    ProviderConnectionContractService? connectionContractService,
    ProviderRuntimeRouteContract? runtimeRouteContract,
  })  : _connectionContractService =
           connectionContractService ?? ProviderConnectionContractService(),
        _runtimeRouteContract = runtimeRouteContract;

  final ProviderConnectionContractService _connectionContractService;
  final ProviderRuntimeRouteContract? _runtimeRouteContract;

  ProviderConnectionValidationResult validate({
    required String title,
    required String protocol,
    required String baseUrl,
    required String apiKey,
    required String modelId,
    String apiMode = 'chat',
  }) {
    // 中文注释: 连接验证作为共享合同只做本地规则与模板约束判断，不触发联网 probe。
    final normalizedTitle = title.trim();
    final normalizedProtocol = protocol.trim();
    final normalizedBaseUrl = baseUrl.trim();
    final normalizedApiKey = apiKey.trim();
    final normalizedModelId = modelId.trim();
    final contractResolution = _connectionContractService.resolve(
      query: normalizedTitle.isNotEmpty ? normalizedTitle : normalizedProtocol,
      baseUrl: normalizedBaseUrl,
    );
    final connectionContract = contractResolution.contract;
    final protocolKind = ProtocolKindCodec.tryParse(normalizedProtocol);
    final runtimeRoute = _runtimeRouteContract ??
        ProviderRuntimeRouteContract.resolve(
          protocolKind:
              protocolKind ??
              connectionContract.protocolKind ??
              ProtocolKind.openAiCompatible,
          connectionContract: connectionContract,
          apiMode: apiMode,
        );
    final errors = <String>[];
    final warnings = <String>[];
    final hideOptions = <String>[];
    var fallbackNotAllowed = false;

    if (normalizedTitle.isEmpty) {
      errors.add('还没有选择接口/厂商名称。');
    }
    if (normalizedModelId.isEmpty) {
      errors.add('还没有填写模型 ID。');
    }
    if (normalizedProtocol.isEmpty) {
      errors.add('还没有选择协议。');
    }
    if (normalizedBaseUrl.isEmpty) {
      errors.add('还没有填写 Base URL，可在高级设置里补充。');
    } else {
      final uri = Uri.tryParse(normalizedBaseUrl);
      final validScheme = uri != null &&
          uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.trim().isNotEmpty;
      if (!validScheme) {
        errors.add('Base URL 需要是完整的 http/https 地址。');
      }
    }
    if (normalizedApiKey.isEmpty && !_looksLikeLocalEndpoint(normalizedBaseUrl)) {
      errors.add('还没有填写 API Key。');
    }

    if (protocolKind != null &&
        connectionContract.protocolKind != null &&
        protocolKind != connectionContract.protocolKind) {
      errors.add('当前协议与接口模板不一致。');
      hideOptions.addAll(
        connectionContract.allowedApiModes.where(
          (mode) => mode != runtimeRoute.resolvedApiMode,
        ),
      );
    }
    if (!connectionContract.allowedRouteFamilies.contains(
      runtimeRoute.selectedRouteFamily,
    )) {
      errors.add('当前 route family 不在接口模板允许范围内。');
      fallbackNotAllowed = true;
    }
    if (runtimeRoute.isFallbackUsed) {
      warnings.add('当前 api_mode 已回退到接口默认 route。');
      if (runtimeRoute.selectedRouteFamily != connectionContract.routeFamily) {
        fallbackNotAllowed = true;
      }
    }

    final isSuccess = errors.isEmpty;
    final summary = isSuccess
        ? '这组配置已经具备测试连接的基础条件。'
        : '当前配置还不能稳定发起连接测试。';
    final details = <String>[
      if (isSuccess) '接口、模型、协议与地址都已补齐。' else ...errors,
      if (isSuccess && normalizedApiKey.isNotEmpty)
        'API Key 已填写，可继续用当前配置发起真实请求。'
      else if (isSuccess)
        '检测到本地地址，允许先不填写 API Key。',
      if (isSuccess) '本轮测试连接先做本地自检，不会直接发起联网请求。',
      if (warnings.isNotEmpty) ...warnings,
    ];
    return ProviderConnectionValidationResult(
      isSuccess: isSuccess,
      summary: summary,
      details: details,
      errors: List<String>.unmodifiable(errors),
      templateId: contractResolution.contract.templateId,
      providerId: contractResolution.contract.providerId,
      protocolId: contractResolution.contract.protocolId,
      protocolKind: protocolKind ?? connectionContract.protocolKind,
      routeFamily: runtimeRoute.selectedRouteFamily.id,
      selectedRouteFamily: runtimeRoute.selectedRouteFamily.id,
      allowedRouteFamilies: connectionContract.allowedApiModes,
      hideOptions: List<String>.unmodifiable(hideOptions),
      fallbackNotAllowed: fallbackNotAllowed,
      warnings: List<String>.unmodifiable(warnings),
      matchedTemplateId: ValueReaders.stringValue(
        contractResolution.matchedTemplate['id'],
      ),
      matchedTemplateLabel: ValueReaders.stringValue(
        contractResolution.matchedTemplate['label'],
      ),
    );
  }

  bool _looksLikeLocalEndpoint(String baseUrl) {
    // 中文注释: 本地地址在诊断时允许先不填 API key，方便 CLI 和 GUI 做离线自检。
    final uri = Uri.tryParse(baseUrl.trim());
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

class ProviderConnectionValidationResult {
  const ProviderConnectionValidationResult({
    required this.isSuccess,
    required this.summary,
    required this.details,
    required this.errors,
    required this.templateId,
    required this.providerId,
    required this.protocolId,
    required this.protocolKind,
    required this.routeFamily,
    required this.selectedRouteFamily,
    required this.allowedRouteFamilies,
    required this.hideOptions,
    required this.fallbackNotAllowed,
    required this.warnings,
    required this.matchedTemplateId,
    required this.matchedTemplateLabel,
  });

  final bool isSuccess;
  final String summary;
  final List<String> details;
  final List<String> errors;
  final String templateId;
  final String providerId;
  final String protocolId;
  final ProtocolKind? protocolKind;
  final String routeFamily;
  final String selectedRouteFamily;
  final List<String> allowedRouteFamilies;
  final List<String> hideOptions;
  final bool fallbackNotAllowed;
  final List<String> warnings;
  final String matchedTemplateId;
  final String matchedTemplateLabel;
}
