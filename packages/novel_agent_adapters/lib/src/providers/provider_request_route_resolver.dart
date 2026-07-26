import 'package:novel_agent_core/novel_agent_core.dart';

import 'gateway_protocol_registry.dart';

class ProviderRequestRouteResolver {
  const ProviderRequestRouteResolver({GatewayProtocolRegistry? registry})
    : _registry = registry ?? const GatewayProtocolRegistry();

  final GatewayProtocolRegistry _registry;

  GatewayRouteResolution resolve({
    required String protocol,
    String apiMode = '',
  }) {
    // 中文注释: provider 协议先归一成注册表里的协议描述，再把 api_mode 收口为当前协议允许的 route family。
    final profile = _registry.profileForProtocol(protocol);
    return GatewayRouteResolution.resolve(
      protocolKind: profile.protocolKind,
      apiMode: apiMode,
      allowedRouteFamilies: profile.allowedRouteFamilies,
      fallbackRouteFamily: profile.fallbackRouteFamily,
    );
  }
}
