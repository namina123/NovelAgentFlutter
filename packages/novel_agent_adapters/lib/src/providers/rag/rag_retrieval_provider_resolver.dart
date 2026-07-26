import 'package:novel_agent_core/novel_agent_core.dart';

import 'rag_retrieval_provider_contracts.dart';
import 'rag_retrieval_provider_registry.dart';

final class RagRetrievalProviderResolution {
  const RagRetrievalProviderResolution({
    required this.providerId,
    required this.providerKind,
    required this.isSupported,
    required this.isAvailable,
    required this.failureMessage,
    required this.displayName,
    required this.capabilityProfile,
  });

  final String providerId;
  final String providerKind;
  final bool isSupported;
  final bool isAvailable;
  final String failureMessage;
  final String displayName;
  final JsonMap capabilityProfile;

  JsonMap toJson() {
    // 中文注释: resolution 是 resolver 的最终对外合同，宿主只需要这个结构即可做 capability 分流。
    return <String, Object?>{
      'provider_id': providerId,
      'provider_kind': providerKind,
      'is_supported': isSupported,
      'is_available': isAvailable,
      'failure_message': failureMessage,
      'display_name': displayName,
      'capability_profile': capabilityProfile,
    };
  }
}

class RagRetrievalProviderResolver {
  RagRetrievalProviderResolver({RagRetrievalProviderRegistry? registry})
    : _registry = registry ?? RagRetrievalProviderRegistry.standard();

  final RagRetrievalProviderRegistry _registry;

  RagRetrievalProviderResolution resolve(String providerId) {
    // 中文注释: resolver 只做 provider 识别与 capability 归一，不构建任何具体 backend。
    final profile = _registry.profileForProviderId(providerId);
    if (profile == null) {
      return RagRetrievalProviderResolution(
        providerId: providerId.trim(),
        providerKind: '',
        isSupported: false,
        isAvailable: false,
        failureMessage: 'unsupported retrieval provider',
        displayName: '',
        capabilityProfile: <String, Object?>{
          'provider_id': providerId.trim(),
          'supported': false,
        },
      );
    }
    return RagRetrievalProviderResolution(
      providerId: profile.providerId,
      providerKind: profile.providerKind,
      isSupported: true,
      isAvailable: profile.isAvailable,
      failureMessage: profile.failureMessage,
      displayName: profile.displayName,
      capabilityProfile: profile.capabilityProfile,
    );
  }

  RagRetrievalCapabilityReport capabilityReport(String providerId) {
    // 中文注释: capability report 供 GUI / CLI / probe 消费，避免各宿主自己推断 provider 可用性。
    final resolution = resolve(providerId);
    return RagRetrievalCapabilityReport(
      providerId: resolution.providerId,
      providerKind: resolution.providerKind,
      isSupported: resolution.isSupported,
      isAvailable: resolution.isAvailable,
      failureMessage: resolution.failureMessage,
      capabilityProfile: resolution.capabilityProfile,
    );
  }

  bool supportsProvider(String providerId) {
    // 中文注释: 支持判断只依赖注册表，避免调用点直接访问 registry 内部结构。
    return _registry.supportsProvider(providerId);
  }
}
