class ProviderConnectionValidationService {
  const ProviderConnectionValidationService();

  ProviderConnectionValidationResult validate({
    required String title,
    required String protocol,
    required String baseUrl,
    required String apiKey,
    required String modelId,
  }) {
    final issues = <String>[];
    final normalizedTitle = title.trim();
    final normalizedProtocol = protocol.trim();
    final normalizedBaseUrl = baseUrl.trim();
    final normalizedApiKey = apiKey.trim();
    final normalizedModelId = modelId.trim();

    if (normalizedTitle.isEmpty) {
      issues.add('还没有选择接口/厂商名称。');
    }
    if (normalizedModelId.isEmpty) {
      issues.add('还没有填写模型 ID。');
    }
    if (normalizedProtocol.isEmpty) {
      issues.add('还没有选择协议。');
    }
    if (normalizedBaseUrl.isEmpty) {
      issues.add('还没有填写 Base URL，可在高级设置里补充。');
    } else {
      final uri = Uri.tryParse(normalizedBaseUrl);
      final validScheme = uri != null &&
          uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.trim().isNotEmpty;
      if (!validScheme) {
        issues.add('Base URL 需要是完整的 http/https 地址。');
      }
    }
    if (normalizedApiKey.isEmpty && !_looksLikeLocalEndpoint(normalizedBaseUrl)) {
      issues.add('还没有填写 API Key。');
    }

    if (issues.isNotEmpty) {
      return ProviderConnectionValidationResult.failure(
        summary: '当前配置还不能稳定发起连接测试。',
        details: issues,
      );
    }

    final details = <String>[
      '接口、模型、协议与地址都已补齐。',
      if (normalizedApiKey.isNotEmpty)
        'API Key 已填写，可继续用当前配置发起真实请求。'
      else
        '检测到本地地址，允许先不填写 API Key。',
      '本轮测试连接先做本地自检，不会直接发起联网请求。',
    ];
    return ProviderConnectionValidationResult.success(
      summary: '这组配置已经具备测试连接的基础条件。',
      details: details,
    );
  }

  bool _looksLikeLocalEndpoint(String baseUrl) {
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
  });

  const ProviderConnectionValidationResult.success({
    required String summary,
    required List<String> details,
  }) : this(
         isSuccess: true,
         summary: summary,
         details: details,
       );

  const ProviderConnectionValidationResult.failure({
    required String summary,
    required List<String> details,
  }) : this(
         isSuccess: false,
         summary: summary,
         details: details,
       );

  final bool isSuccess;
  final String summary;
  final List<String> details;
}
