import '../common/json_types.dart';
import '../common/value_readers.dart';

class InformationPermissionDecision {
  const InformationPermissionDecision({
    required this.disposition,
    this.reason = '',
    this.policyRef = '',
    this.metadata = const <String, Object?>{},
  });

  final String disposition;
  final String reason;
  final String policyRef;
  final JsonMap metadata;

  InformationPermissionDecision copyWith({
    String? disposition,
    String? reason,
    String? policyRef,
    JsonMap? metadata,
  }) {
    // 中文注释: 信息权限决定只表达结构化进入项目时的策略姿态，不执行真正的工具分发或 UI 审批。
    return InformationPermissionDecision(
      disposition: disposition ?? this.disposition,
      reason: reason ?? this.reason,
      policyRef: policyRef ?? this.policyRef,
      metadata: metadata ?? this.metadata,
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'disposition': disposition,
      'reason': reason,
      'policy_ref': policyRef,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
