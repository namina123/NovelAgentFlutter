import 'package:novel_agent_core/novel_agent_core.dart';

class OpenAiChatRouteResolver {
  const OpenAiChatRouteResolver();

  GatewayRouteResolution resolve({
    String apiMode = '',
  }) {
    // 中文注释: OpenAI Chat 链在这一轮只保留 chat/completions，Responses 的真实路由留待后续独立 session。
    return GatewayRouteResolution.resolve(
      protocolKind: ProtocolKind.openAiCompatible,
      apiMode: apiMode,
      allowedRouteFamilies: const <RequestRouteFamily>[
        RequestRouteFamily.chatCompletions,
      ],
      fallbackRouteFamily: RequestRouteFamily.chatCompletions,
    );
  }

  Uri resolveRequestUri(
    String baseUrl, {
    String apiMode = '',
  }) {
    // 中文注释: 请求 URI 只拼 chat/completions，避免 gateway 自己再发明第二套路由选择逻辑。
    final normalizedBaseUrl = _normalizeBaseUrl(baseUrl);
    resolve(apiMode: apiMode);
    return Uri.parse('$normalizedBaseUrl/chat/completions');
  }

  bool supportsRouteFamily(RequestRouteFamily routeFamily) {
    // 中文注释: 这个适配器当前只承接 Chat Completions，其他路由族不能从这里穿透。
    return routeFamily == RequestRouteFamily.chatCompletions;
  }

  String _normalizeBaseUrl(String value) {
    // 中文注释: base URL 统一去掉尾斜杠，保证路径拼接稳定。
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
