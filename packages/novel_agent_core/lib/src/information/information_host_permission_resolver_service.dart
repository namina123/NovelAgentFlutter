import '../common/value_readers.dart';
import 'information_collection_constants.dart';
import 'information_collection_policy_service.dart';
import 'information_collection_request.dart';
import 'information_host_permission_context.dart';
import 'information_host_permission_resolution.dart';

class HostInformationPermissionResolverService {
  const HostInformationPermissionResolverService({
    InformationCollectionPolicyService? collectionPolicyService,
  }) : _collectionPolicyService =
           collectionPolicyService ??
           const InformationCollectionPolicyService();

  final InformationCollectionPolicyService _collectionPolicyService;

  HostInformationPermissionResolution resolve({
    required InformationCollectionRequest request,
    required HostInformationPermissionContext hostContext,
  }) {
    // 中文注释: 这里把模型 payload 中的联网授权视为 raw 声明，最终生效值始终由宿主上下文决定。
    final normalizedRequest = _collectionPolicyService.normalize(request);
    final rawModelUserGrantedNetworkAccess =
        request.rawModelUserGrantedNetworkAccess;
    final requestsImportCollection = _requestsImportCollection(
      normalizedRequest,
    );
    final requiresNetwork = normalizedRequest.requiresNetwork;
    final effectiveUserGrantedNetworkAccess =
        requiresNetwork && hostContext.allowNetwork;
    final importCollectionAllowed =
        !requestsImportCollection || hostContext.allowImportCollection;
    final effectiveMetadata = <String, Object?>{
      ...normalizedRequest.metadata,
      'raw_model_user_granted_network_access': rawModelUserGrantedNetworkAccess,
      'effective_user_granted_network_access':
          effectiveUserGrantedNetworkAccess,
      'host_information_permission_context': hostContext.toJson(),
      'host_allow_network': hostContext.allowNetwork,
      'host_allow_import_collection': hostContext.allowImportCollection,
      'host_permission_mode': hostContext.permissionMode,
      'host_confirmation_mode': hostContext.confirmationMode,
      'host_permission_source': hostContext.source,
    };
    final effectiveRequest = normalizedRequest.copyWith(
      userGrantedNetworkAccess: effectiveUserGrantedNetworkAccess,
      metadata: ValueReaders.deepCopyMap(effectiveMetadata),
    );
    return HostInformationPermissionResolution(
      hostContext: hostContext,
      originalRequest: request,
      effectiveRequest: effectiveRequest,
      rawModelUserGrantedNetworkAccess: rawModelUserGrantedNetworkAccess,
      effectiveUserGrantedNetworkAccess: effectiveUserGrantedNetworkAccess,
      requiresNetwork: requiresNetwork,
      requestsImportCollection: requestsImportCollection,
      importCollectionAllowed: importCollectionAllowed,
      metadata: <String, Object?>{
        'raw_model_user_granted_network_access':
            rawModelUserGrantedNetworkAccess,
        'effective_user_granted_network_access':
            effectiveUserGrantedNetworkAccess,
        'host_permission_mode': hostContext.permissionMode,
        'host_confirmation_mode': hostContext.confirmationMode,
        'host_permission_source': hostContext.source,
      },
    );
  }

  bool _requestsImportCollection(InformationCollectionRequest request) {
    final normalized = request.collectionMode.trim().toLowerCase();
    return normalized == InformationCollectionModes.import ||
        normalized == InformationCollectionModes.hybrid;
  }
}
