import 'package:novel_agent_core/novel_agent_core.dart';

final class GatewayProtocolProfile {
  const GatewayProtocolProfile({
    required this.protocolKind,
    required this.allowedRouteFamilies,
    required this.fallbackRouteFamily,
  });

  final ProtocolKind protocolKind;
  final List<RequestRouteFamily> allowedRouteFamilies;
  final RequestRouteFamily fallbackRouteFamily;
}

class GatewayProtocolRegistry {
  const GatewayProtocolRegistry(
      {Map<ProtocolKind, GatewayProtocolProfile>? profiles})
      : _profiles = profiles ?? _defaultProfiles;

  final Map<ProtocolKind, GatewayProtocolProfile> _profiles;

  factory GatewayProtocolRegistry.standard() {
    // 中文注释: 默认注册表只收录当前主链协议，组合根和 route resolver 都从这里取统一协议描述。
    return const GatewayProtocolRegistry();
  }

  GatewayProtocolProfile profileForProtocol(String protocol) {
    // 中文注释: 协议字符串先归一到正式枚举，再取协议描述，避免调用点自己维护散落的 protocol if/else。
    final protocolKind =
        ProtocolKindCodec.tryParse(protocol) ?? ProtocolKind.openAiCompatible;
    return _profiles[protocolKind] ?? _profiles[ProtocolKind.openAiCompatible]!;
  }

  ProtocolKind protocolKindFor(String protocol) {
    // 中文注释: 组合根和 route resolver 只需要 protocolKind 时，直接从注册表读取统一结果。
    return profileForProtocol(protocol).protocolKind;
  }

  List<RequestRouteFamily> allowedRouteFamiliesFor(String protocol) {
    // 中文注释: 允许路由族由注册表集中给出，避免 gateway 自己重写协议支持面。
    return profileForProtocol(protocol).allowedRouteFamilies;
  }

  RequestRouteFamily fallbackRouteFamilyFor(String protocol) {
    // 中文注释: 路由回退面由注册表统一声明，保证 API 兼容层对外表现一致。
    return profileForProtocol(protocol).fallbackRouteFamily;
  }

  bool supportsProtocol(String protocol) {
    // 中文注释: 支持性判断先走协议枚举解析，再决定是否属于当前注册表收录范围。
    return ProtocolKindCodec.tryParse(protocol) != null;
  }

  static const Map<ProtocolKind, GatewayProtocolProfile> _defaultProfiles =
      <ProtocolKind, GatewayProtocolProfile>{
    ProtocolKind.openAiCompatible: GatewayProtocolProfile(
      protocolKind: ProtocolKind.openAiCompatible,
      allowedRouteFamilies: <RequestRouteFamily>[
        RequestRouteFamily.chatCompletions,
        RequestRouteFamily.responses,
      ],
      fallbackRouteFamily: RequestRouteFamily.chatCompletions,
    ),
    ProtocolKind.anthropicCompatible: GatewayProtocolProfile(
      protocolKind: ProtocolKind.anthropicCompatible,
      allowedRouteFamilies: <RequestRouteFamily>[
        RequestRouteFamily.messages,
      ],
      fallbackRouteFamily: RequestRouteFamily.messages,
    ),
    ProtocolKind.geminiNative: GatewayProtocolProfile(
      protocolKind: ProtocolKind.geminiNative,
      allowedRouteFamilies: <RequestRouteFamily>[
        RequestRouteFamily.generateContent,
        RequestRouteFamily.streamGenerateContent,
      ],
      fallbackRouteFamily: RequestRouteFamily.generateContent,
    ),
  };
}
