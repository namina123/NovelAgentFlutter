import 'package:novel_agent_core/novel_agent_core.dart';

abstract final class RagRetrievalProviderKinds {
  static const String localPlaceholder = 'local_placeholder';
  static const String remotePlaceholder = 'remote_placeholder';
}

final class RagRetrievalProviderProfile {
  const RagRetrievalProviderProfile({
    required this.providerId,
    required this.providerKind,
    required this.displayName,
    required this.hostCapabilityFlags,
    required this.isAvailable,
    required this.failureMessage,
    required this.capabilityProfile,
  });

  final String providerId;
  final String providerKind;
  final String displayName;
  final List<String> hostCapabilityFlags;
  final bool isAvailable;
  final String failureMessage;
  final JsonMap capabilityProfile;

  JsonMap toJson() {
    // 中文注释: provider profile 只输出宿主识别所需的稳定摘要，不暴露任何后端私有实现细节。
    return <String, Object?>{
      'provider_id': providerId,
      'provider_kind': providerKind,
      'display_name': displayName,
      'host_capability_flags': hostCapabilityFlags.toList(growable: false),
      'is_available': isAvailable,
      'failure_message': failureMessage,
      'capability_profile': capabilityProfile,
    };
  }
}

final class RagRetrievalCapabilityReport {
  const RagRetrievalCapabilityReport({
    required this.providerId,
    required this.providerKind,
    required this.isSupported,
    required this.isAvailable,
    required this.failureMessage,
    required this.capabilityProfile,
  });

  final String providerId;
  final String providerKind;
  final bool isSupported;
  final bool isAvailable;
  final String failureMessage;
  final JsonMap capabilityProfile;

  JsonMap toJson() {
    // 中文注释: capability report 供 GUI / CLI / probe 读取，避免它们自己重建 provider 判断逻辑。
    return <String, Object?>{
      'provider_id': providerId,
      'provider_kind': providerKind,
      'is_supported': isSupported,
      'is_available': isAvailable,
      'failure_message': failureMessage,
      'capability_profile': capabilityProfile,
    };
  }
}

abstract interface class RagRetrievalProvider {
  String get providerId;

  String get providerKind;

  String get displayName;

  RagRetrievalCapabilityReport capabilityReport();
}

