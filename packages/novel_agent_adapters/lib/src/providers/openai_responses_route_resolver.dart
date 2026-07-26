import 'package:novel_agent_core/novel_agent_core.dart';

class OpenAiResponsesRouteResolver {
  const OpenAiResponsesRouteResolver();

  GatewayRouteResolution resolve({String apiMode = ''}) {
    // 中文注释: Responses 链只承接 responses route family，避免再次回落到 Chat 语义。
    return GatewayRouteResolution.resolve(
      protocolKind: ProtocolKind.openAiCompatible,
      apiMode: apiMode,
      allowedRouteFamilies: const <RequestRouteFamily>[
        RequestRouteFamily.responses,
      ],
      fallbackRouteFamily: RequestRouteFamily.responses,
    );
  }

  Uri resolveRequestUri(String baseUrl) {
    // 中文注释: Responses 采用独立 /responses 端点，不与 chat/completions 混用。
    final normalizedBaseUrl = _normalizeBaseUrl(baseUrl);
    return Uri.parse('$normalizedBaseUrl/responses');
  }

  bool supportsRouteFamily(RequestRouteFamily routeFamily) {
    // 中文注释: 这个 resolver 只处理 Responses 入口，其他 route family 不应从这里穿透。
    return routeFamily == RequestRouteFamily.responses;
  }

  String _normalizeBaseUrl(String value) {
    // 中文注释: base URL 去尾斜杠后再拼接，避免路径重复。
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
