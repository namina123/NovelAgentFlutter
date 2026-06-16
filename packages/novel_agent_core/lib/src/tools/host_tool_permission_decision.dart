import '../common/json_types.dart';
import '../common/value_readers.dart';

class HostToolPermissionDecision {
  const HostToolPermissionDecision({
    required this.disposition,
    this.reason = '',
    this.policyRef = '',
    this.requiredCapability = '',
    this.metadata = const <String, Object?>{},
  });

  final String disposition;
  final String reason;
  final String policyRef;
  final String requiredCapability;
  final JsonMap metadata;

  HostToolPermissionDecision copyWith({
    String? disposition,
    String? reason,
    String? policyRef,
    String? requiredCapability,
    JsonMap? metadata,
  }) {
    return HostToolPermissionDecision(
      disposition: disposition ?? this.disposition,
      reason: reason ?? this.reason,
      policyRef: policyRef ?? this.policyRef,
      requiredCapability: requiredCapability ?? this.requiredCapability,
      metadata: metadata ?? this.metadata,
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'disposition': disposition,
      'reason': reason,
      'policy_ref': policyRef,
      'required_capability': requiredCapability,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
