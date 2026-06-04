import '../../common/json_types.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import 'domain_tool_validation_codes.dart';

const _domainToolPermissionDecisionValidatorService =
    OpenJsonStructureValidatorService();

class DomainToolPermissionDecision {
  const DomainToolPermissionDecision({
    required this.disposition,
    this.reason = '',
    this.policyRef = '',
    this.metadata = const <String, Object?>{},
  });

  final String disposition;
  final String reason;
  final String policyRef;
  final JsonMap metadata;

  DomainToolPermissionDecision copyWith({
    String? disposition,
    String? reason,
    String? policyRef,
    JsonMap? metadata,
  }) {
    // 中文注释: 权限决定只表达当前工具调用的权限姿态，不执行真正的权限流程或 UI 确认。
    return DomainToolPermissionDecision(
      disposition: disposition ?? this.disposition,
      reason: reason ?? this.reason,
      policyRef: policyRef ?? this.policyRef,
      metadata: metadata ?? this.metadata,
    );
  }

  factory DomainToolPermissionDecision.fromJson(JsonMap json) {
    return DomainToolPermissionDecision(
      disposition: ValueReaders.stringValue(json['disposition']).trim(),
      reason: ValueReaders.stringValue(json['reason']).trim(),
      policyRef: ValueReaders.stringValue(json['policy_ref']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
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

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _domainToolPermissionDecisionValidatorService.requireNonBlankString(
        disposition,
        DomainToolValidationCodes.missingPermissionDisposition,
      ),
    );
    return result;
  }
}
