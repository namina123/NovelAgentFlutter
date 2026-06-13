import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'information_collection_request.dart';
import 'information_host_permission_resolution.dart';
import 'information_permission_decision.dart';

class InformationResearchExecutionDecision {
  const InformationResearchExecutionDecision({
    required this.permissionDecision,
    required this.hostPermissionResolution,
    required this.effectiveRequest,
    this.autoExecuteNetwork = false,
    this.autoExecuteImport = false,
    this.awaitUserConfirmation = false,
    this.blocked = false,
    this.reason = '',
    this.metadata = const <String, Object?>{},
  });

  final InformationPermissionDecision permissionDecision;
  final HostInformationPermissionResolution hostPermissionResolution;
  final InformationCollectionRequest effectiveRequest;
  final bool autoExecuteNetwork;
  final bool autoExecuteImport;
  final bool awaitUserConfirmation;
  final bool blocked;
  final String reason;
  final JsonMap metadata;

  JsonMap toJson() {
    // 中文注释: 决策结果只给 adapters 一个稳定“下一步动作”合同，不负责真正执行 gateway 或写本地状态。
    return <String, Object?>{
      'permission_decision': permissionDecision.toJson(),
      'host_permission_resolution': hostPermissionResolution.toJson(),
      'effective_request': effectiveRequest.toJson(),
      'auto_execute_network': autoExecuteNetwork,
      'auto_execute_import': autoExecuteImport,
      'await_user_confirmation': awaitUserConfirmation,
      'blocked': blocked,
      'reason': reason,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
