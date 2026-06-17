import 'package:novel_agent_core/novel_agent_core.dart';

class GeminiNativeRouteResolver {
  const GeminiNativeRouteResolver();

  GatewayRouteResolution resolve({
    String apiMode = '',
  }) {
    // 中文注释: Gemini native 只承接 generateContent / streamGenerateContent，不与 OpenAI-compatible 路由混用。
    return GatewayRouteResolution.resolve(
      protocolKind: ProtocolKind.geminiNative,
      apiMode: apiMode,
      allowedRouteFamilies: const <RequestRouteFamily>[
        RequestRouteFamily.generateContent,
        RequestRouteFamily.streamGenerateContent,
      ],
      fallbackRouteFamily: RequestRouteFamily.generateContent,
    );
  }

  Uri resolveRequestUri(
    String baseUrl, {
    String modelId = '',
    String apiMode = '',
  }) {
    // 中文注释: Gemini native 使用 /models/{model}:generateContent 族路径，stream 版本仅切换方法名。
    final normalizedBaseUrl = _normalizeBaseUrl(baseUrl);
    final routeFamily = resolve(apiMode: apiMode).routeFamily;
    final method = routeFamily == RequestRouteFamily.streamGenerateContent
        ? 'streamGenerateContent'
        : 'generateContent';
    final modelSegment = modelId.trim().isEmpty ? 'models/*' : 'models/$modelId';
    return Uri.parse('$normalizedBaseUrl/$modelSegment:$method');
  }

  bool supportsRouteFamily(RequestRouteFamily routeFamily) {
    // 中文注释: Gemini native 只接受 generateContent / streamGenerateContent。
    return routeFamily == RequestRouteFamily.generateContent ||
        routeFamily == RequestRouteFamily.streamGenerateContent;
  }

  String _normalizeBaseUrl(String value) {
    // 中文注释: base URL 统一去掉尾斜杠，避免后续拼接出现双斜杠。
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
