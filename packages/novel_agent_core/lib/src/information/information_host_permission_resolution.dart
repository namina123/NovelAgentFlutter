import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'information_collection_request.dart';
import 'information_host_permission_context.dart';

class HostInformationPermissionResolution {
  const HostInformationPermissionResolution({
    required this.hostContext,
    required this.originalRequest,
    required this.effectiveRequest,
    required this.rawModelUserGrantedNetworkAccess,
    required this.effectiveUserGrantedNetworkAccess,
    required this.requiresNetwork,
    required this.requestsImportCollection,
    required this.importCollectionAllowed,
    this.metadata = const <String, Object?>{},
  });

  final HostInformationPermissionContext hostContext;
  final InformationCollectionRequest originalRequest;
  final InformationCollectionRequest effectiveRequest;
  final bool rawModelUserGrantedNetworkAccess;
  final bool effectiveUserGrantedNetworkAccess;
  final bool requiresNetwork;
  final bool requestsImportCollection;
  final bool importCollectionAllowed;
  final JsonMap metadata;

  JsonMap toJson() {
    // 中文注释: resolution 只表达“raw 声明”和“宿主生效授权”之间的结果差异，方便后续 adapters 审计接线。
    return <String, Object?>{
      'host_context': hostContext.toJson(),
      'original_request': originalRequest.toJson(),
      'effective_request': effectiveRequest.toJson(),
      'raw_model_user_granted_network_access':
          rawModelUserGrantedNetworkAccess,
      'effective_user_granted_network_access':
          effectiveUserGrantedNetworkAccess,
      'requires_network': requiresNetwork,
      'requests_import_collection': requestsImportCollection,
      'import_collection_allowed': importCollectionAllowed,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
