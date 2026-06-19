import 'rag_retrieval_provider_contracts.dart';

class RagRetrievalProviderRegistry {
  RagRetrievalProviderRegistry({Map<String, RagRetrievalProviderProfile>? profiles})
      : _profiles = profiles ?? _defaultProfiles;

  final Map<String, RagRetrievalProviderProfile> _profiles;

  factory RagRetrievalProviderRegistry.standard() {
    // 中文注释: 默认注册表先收录本轮允许的 placeholder provider，后续再由 adapter 扩展真实 backend。
    return RagRetrievalProviderRegistry(
      profiles: <String, RagRetrievalProviderProfile>{
        RagRetrievalProviderKinds.localPlaceholder:
            RagRetrievalProviderProfile(
          providerId: RagRetrievalProviderKinds.localPlaceholder,
          providerKind: RagRetrievalProviderKinds.localPlaceholder,
          displayName: 'Local Placeholder Retrieval',
          hostCapabilityFlags: <String>['metadata_only', 'offline'],
          isAvailable: true,
          failureMessage: '',
          capabilityProfile: <String, Object?>{
            'provider_kind': RagRetrievalProviderKinds.localPlaceholder,
            'backend_mode': 'placeholder',
            'supports_embedding': false,
            'supports_search': false,
            'supports_mount_scoped_search': false,
            'supports_health_check': true,
            'supports_index_management': false,
            'supports_activation_package': false,
          },
        ),
        RagRetrievalProviderKinds.remotePlaceholder:
            RagRetrievalProviderProfile(
          providerId: RagRetrievalProviderKinds.remotePlaceholder,
          providerKind: RagRetrievalProviderKinds.remotePlaceholder,
          displayName: 'Remote Placeholder Retrieval',
          hostCapabilityFlags: <String>['metadata_only', 'network_optional'],
          isAvailable: false,
          failureMessage: 'remote placeholder backend not wired yet',
          capabilityProfile: <String, Object?>{
            'provider_kind': RagRetrievalProviderKinds.remotePlaceholder,
            'backend_mode': 'placeholder',
            'supports_embedding': false,
            'supports_search': false,
            'supports_mount_scoped_search': false,
            'supports_health_check': true,
            'supports_index_management': false,
            'supports_activation_package': false,
          },
        ),
      },
    );
  }

  RagRetrievalProviderProfile? profileForProviderId(String providerId) {
    // 中文注释: provider id 先做轻量归一，再从注册表取 profile，避免宿主自己猜支持面。
    final cleanId = providerId.trim();
    if (cleanId.isEmpty) {
      return null;
    }
    return _profiles[cleanId];
  }

  bool supportsProvider(String providerId) {
    // 中文注释: 支持性判断只看注册表是否收录，不把真正的 backend 可用性混进来。
    return profileForProviderId(providerId) != null;
  }

  List<RagRetrievalProviderProfile> profiles() {
    // 中文注释: profiles 以稳定顺序导出，供 GUI/CLI 摘要和 probe 检查使用。
    final list = _profiles.values.toList(growable: false);
    list.sort((left, right) => left.providerId.compareTo(right.providerId));
    return list;
  }

  static Map<String, RagRetrievalProviderProfile> get _defaultProfiles =>
      <String, RagRetrievalProviderProfile>{
        RagRetrievalProviderKinds.localPlaceholder:
            RagRetrievalProviderProfile(
          providerId: RagRetrievalProviderKinds.localPlaceholder,
          providerKind: RagRetrievalProviderKinds.localPlaceholder,
          displayName: 'Local Placeholder Retrieval',
          hostCapabilityFlags: <String>['metadata_only', 'offline'],
          isAvailable: true,
          failureMessage: '',
          capabilityProfile: <String, Object?>{
            'provider_kind': RagRetrievalProviderKinds.localPlaceholder,
            'backend_mode': 'placeholder',
            'supports_embedding': false,
            'supports_search': false,
            'supports_mount_scoped_search': false,
            'supports_health_check': true,
            'supports_index_management': false,
            'supports_activation_package': false,
          },
        ),
        RagRetrievalProviderKinds.remotePlaceholder:
            RagRetrievalProviderProfile(
          providerId: RagRetrievalProviderKinds.remotePlaceholder,
          providerKind: RagRetrievalProviderKinds.remotePlaceholder,
          displayName: 'Remote Placeholder Retrieval',
          hostCapabilityFlags: <String>['metadata_only', 'network_optional'],
          isAvailable: false,
          failureMessage: 'remote placeholder backend not wired yet',
          capabilityProfile: <String, Object?>{
            'provider_kind': RagRetrievalProviderKinds.remotePlaceholder,
            'backend_mode': 'placeholder',
            'supports_embedding': false,
            'supports_search': false,
            'supports_mount_scoped_search': false,
            'supports_health_check': true,
            'supports_index_management': false,
            'supports_activation_package': false,
          },
        ),
      };
}
