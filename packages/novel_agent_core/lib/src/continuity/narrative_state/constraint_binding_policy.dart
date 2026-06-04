import '../../common/json_types.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import 'narrative_constraint_binding_validation_codes.dart';

const _constraintBindingPolicyValidatorService =
    OpenJsonStructureValidatorService();

class ConstraintBindingPolicy {
  const ConstraintBindingPolicy({
    this.hardExecutionPolicy = const <String, Object?>{},
    this.softReviewPolicy = const <String, Object?>{},
    this.autoAccept = false,
    this.requiresUserConfirmation = false,
    this.forbiddenAutoApply = false,
    this.metadata = const <String, Object?>{},
  });

  final JsonMap hardExecutionPolicy;
  final JsonMap softReviewPolicy;
  final bool autoAccept;
  final bool requiresUserConfirmation;
  final bool forbiddenAutoApply;
  final JsonMap metadata;

  ConstraintBindingPolicy copyWith({
    JsonMap? hardExecutionPolicy,
    JsonMap? softReviewPolicy,
    bool? autoAccept,
    bool? requiresUserConfirmation,
    bool? forbiddenAutoApply,
    JsonMap? metadata,
  }) {
    // 中文注释: policy 层只表达执行/评审建议与权限姿态，不实现真正的权限裁决。
    return ConstraintBindingPolicy(
      hardExecutionPolicy: hardExecutionPolicy ?? this.hardExecutionPolicy,
      softReviewPolicy: softReviewPolicy ?? this.softReviewPolicy,
      autoAccept: autoAccept ?? this.autoAccept,
      requiresUserConfirmation:
          requiresUserConfirmation ?? this.requiresUserConfirmation,
      forbiddenAutoApply: forbiddenAutoApply ?? this.forbiddenAutoApply,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ConstraintBindingPolicy.fromJson(JsonMap json) {
    return ConstraintBindingPolicy(
      hardExecutionPolicy: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['hard_execution_policy']),
      ),
      softReviewPolicy: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['soft_review_policy']),
      ),
      autoAccept: ValueReaders.boolValue(json['auto_accept']),
      requiresUserConfirmation: ValueReaders.boolValue(
        json['requires_user_confirmation'],
      ),
      forbiddenAutoApply: ValueReaders.boolValue(json['forbidden_auto_apply']),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'hard_execution_policy': ValueReaders.deepCopyMap(hardExecutionPolicy),
      'soft_review_policy': ValueReaders.deepCopyMap(softReviewPolicy),
      'auto_accept': autoAccept,
      'requires_user_confirmation': requiresUserConfirmation,
      'forbidden_auto_apply': forbiddenAutoApply,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    final enabledModes = <bool>[
      autoAccept,
      requiresUserConfirmation,
      forbiddenAutoApply,
    ].where((entry) => entry).length;
    result.addAll(
      _constraintBindingPolicyValidatorService.requireCondition(
        enabledModes <= 1,
        NarrativeConstraintBindingValidationCodes
            .conflictingPermissionDisposition,
      ),
    );
    return result;
  }
}
