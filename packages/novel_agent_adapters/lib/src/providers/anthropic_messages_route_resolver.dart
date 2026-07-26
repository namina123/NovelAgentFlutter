import 'package:novel_agent_core/novel_agent_core.dart';

class AnthropicMessagesRouteResolver {
  const AnthropicMessagesRouteResolver();

  GatewayRouteResolution resolve({String apiMode = ''}) {
    // 中文注释: Anthropic 这条链只承接 Messages 语义，route contract 固定收口到 messages。
    return GatewayRouteResolution.resolve(
      protocolKind: ProtocolKind.anthropicCompatible,
      apiMode: apiMode,
      allowedRouteFamilies: const <RequestRouteFamily>[
        RequestRouteFamily.messages,
      ],
      fallbackRouteFamily: RequestRouteFamily.messages,
    );
  }

  Uri resolveRequestUri(String baseUrl) {
    // 中文注释: Anthropic Messages 使用独立 /messages 端点，不能与 OpenAI 风格端点混用。
    final normalizedBaseUrl = _normalizeBaseUrl(baseUrl);
    return Uri.parse('$normalizedBaseUrl/messages');
  }

  bool supportsRouteFamily(RequestRouteFamily routeFamily) {
    // 中文注释: 这条适配器只处理 Messages，其他 route family 不应从这里穿透。
    return routeFamily == RequestRouteFamily.messages;
  }

  String _normalizeBaseUrl(String value) {
    // 中文注释: base URL 去尾斜杠，避免后续拼接出现双斜杠。
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
