import 'package:novel_agent_core/novel_agent_core.dart';

import 'anthropic_llm_gateway.dart';
import 'gateway_protocol_registry.dart';
import 'gemini_native_llm_gateway.dart';
import 'openai_llm_gateway.dart';

class GatewayFactoryResolver {
  GatewayFactoryResolver({GatewayProtocolRegistry? registry})
    : _registry = registry ?? GatewayProtocolRegistry.standard();

  final GatewayProtocolRegistry _registry;

  LlmGateway resolve(
    ProviderEndpointSettings provider, {
    JsonMap networkSettings = const <String, Object?>{},
  }) {
    // 中文注释: 组合根只问 resolver 要具体网关实现，不再自己写协议分叉。
    final protocolKind = _registry.protocolKindFor(provider.protocol);
    switch (protocolKind) {
      case ProtocolKind.anthropicCompatible:
        return AnthropicLlmGateway.fromProviderSettings(
          provider,
          networkSettings: networkSettings,
        );
      case ProtocolKind.geminiNative:
        return GeminiNativeLlmGateway.fromProviderSettings(
          provider,
          networkSettings: networkSettings,
        );
      case ProtocolKind.openAiCompatible:
      default:
        return OpenAiLlmGateway.fromProviderSettings(
          provider,
          networkSettings: networkSettings,
        );
    }
  }
}
