import '../../common/json_types.dart';
import '../../common/open_json_contract_codec_service.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import 'constraint_binding_policy.dart';
import 'constraint_binding_scope.dart';
import 'narrative_constraint_binding_validation_codes.dart';
import 'narrative_source_ref.dart';

const _narrativeConstraintBindingCodecService = OpenJsonContractCodecService();
const _narrativeConstraintBindingValidatorService =
    OpenJsonStructureValidatorService();

class NarrativeConstraintBindingProposal {
  const NarrativeConstraintBindingProposal({
    required this.bindingId,
    required this.constraintType,
    required this.scope,
    required this.policy,
    required this.source,
    this.constraintId = '',
    this.constraintLabel = '',
    this.constraintOrigin = '',
    this.constraintPayload = const <String, Object?>{},
    this.reason = '',
    this.confidence = 0,
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final String bindingId;
  final String constraintType;
  final String constraintId;
  final String constraintLabel;
  final String constraintOrigin;
  final JsonMap constraintPayload;
  final ConstraintBindingScope scope;
  final ConstraintBindingPolicy policy;
  final NarrativeSourceRef source;
  final String reason;
  final double confidence;
  final String schemaVersion;
  final JsonMap metadata;

  NarrativeConstraintBindingProposal copyWith({
    String? bindingId,
    String? constraintType,
    String? constraintId,
    String? constraintLabel,
    String? constraintOrigin,
    JsonMap? constraintPayload,
    ConstraintBindingScope? scope,
    ConstraintBindingPolicy? policy,
    NarrativeSourceRef? source,
    String? reason,
    double? confidence,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    // 中文注释: proposal 只表达“要绑定什么约束”，不在本轮承担生效、替换旧链路或权限执行。
    return NarrativeConstraintBindingProposal(
      bindingId: bindingId ?? this.bindingId,
      constraintType: constraintType ?? this.constraintType,
      constraintId: constraintId ?? this.constraintId,
      constraintLabel: constraintLabel ?? this.constraintLabel,
      constraintOrigin: constraintOrigin ?? this.constraintOrigin,
      constraintPayload: constraintPayload ?? this.constraintPayload,
      scope: scope ?? this.scope,
      policy: policy ?? this.policy,
      source: source ?? this.source,
      reason: reason ?? this.reason,
      confidence: confidence ?? this.confidence,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NarrativeConstraintBindingProposal.fromJson(JsonMap json) {
    final scopeJson = ValueReaders.mapValue(json['binding_scope']).isNotEmpty
        ? ValueReaders.mapValue(json['binding_scope'])
        : ValueReaders.mapValue(json['scope']);
    final policyJson = ValueReaders.mapValue(json['binding_policy']).isNotEmpty
        ? ValueReaders.mapValue(json['binding_policy'])
        : json;
    // 中文注释: 解码同时兼容扁平 policy 字段和后续嵌套 binding_policy 结构，便于本轮只先稳定合同。
    return NarrativeConstraintBindingProposal(
      bindingId: ValueReaders.stringValue(json['binding_id']).trim(),
      constraintType: ValueReaders.stringValue(json['constraint_type']).trim(),
      constraintId: ValueReaders.stringValue(json['constraint_id']).trim(),
      constraintLabel: ValueReaders.stringValue(
        json['constraint_label'],
      ).trim(),
      constraintOrigin: ValueReaders.stringValue(
        json['constraint_origin'],
      ).trim(),
      constraintPayload: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['constraint_payload']),
      ),
      scope: ConstraintBindingScope.fromJson(scopeJson),
      policy: ConstraintBindingPolicy.fromJson(policyJson),
      source: NarrativeSourceRef.fromJson(
        ValueReaders.mapValue(json['source']),
      ),
      reason: ValueReaders.stringValue(json['reason']).trim(),
      confidence: ValueReaders.doubleValue(json['confidence']),
      schemaVersion: _narrativeConstraintBindingCodecService.readSchemaVersion(
        json,
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: 绑定提案显式保留用户可理解标签与开放 payload，避免统一约束抽象吞掉产品语义。
    return <String, Object?>{
      'binding_id': bindingId,
      'constraint_type': constraintType,
      'constraint_id': constraintId,
      'constraint_label': constraintLabel,
      'constraint_origin': constraintOrigin,
      'constraint_payload': ValueReaders.deepCopyMap(constraintPayload),
      'binding_scope': scope.toJson(),
      'binding_policy': policy.toJson(),
      'source': source.toJson(),
      'reason': reason,
      'confidence': confidence,
      'schema_version': schemaVersion,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _narrativeConstraintBindingValidatorService.requireNonBlankString(
        bindingId,
        NarrativeConstraintBindingValidationCodes.missingBindingId,
      ),
    );
    result.addAll(
      _narrativeConstraintBindingValidatorService.requireNonBlankString(
        constraintType,
        NarrativeConstraintBindingValidationCodes.missingConstraintType,
      ),
    );
    result.addAll(
      _narrativeConstraintBindingValidatorService.requireNonBlankString(
        source.sourceType,
        NarrativeConstraintBindingValidationCodes.missingSourceType,
      ),
    );
    result.addAll(
      _narrativeConstraintBindingValidatorService.validateConfidence(
        confidence,
        NarrativeConstraintBindingValidationCodes.invalidConfidence,
      ),
    );
    result.addAll(scope.validateBasics());
    result.addAll(policy.validateBasics());
    return result;
  }
}
