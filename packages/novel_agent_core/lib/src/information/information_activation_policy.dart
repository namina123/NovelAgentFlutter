import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import 'information_validation_codes.dart';

const _informationActivationPolicyCodecService = OpenJsonContractCodecService();
const _informationActivationPolicyValidatorService =
    OpenJsonStructureValidatorService();

class InformationActivationPolicy {
  const InformationActivationPolicy({
    this.activationPriority = '',
    this.requiresExplicitSelection = false,
    this.preferredBudgetChars = 0,
    this.metadata = const <String, Object?>{},
  });

  final String activationPriority;
  final bool requiresExplicitSelection;
  final int preferredBudgetChars;
  final JsonMap metadata;

  InformationActivationPolicy copyWith({
    String? activationPriority,
    bool? requiresExplicitSelection,
    int? preferredBudgetChars,
    JsonMap? metadata,
  }) {
    // 中文注释: 激活策略只表达注入优先级与预算偏好，不在这里实现真正的上下文裁剪算法。
    return InformationActivationPolicy(
      activationPriority: activationPriority ?? this.activationPriority,
      requiresExplicitSelection:
          requiresExplicitSelection ?? this.requiresExplicitSelection,
      preferredBudgetChars: preferredBudgetChars ?? this.preferredBudgetChars,
      metadata: metadata ?? this.metadata,
    );
  }

  factory InformationActivationPolicy.fromJson(JsonMap json) {
    return InformationActivationPolicy(
      activationPriority: ValueReaders.stringValue(
        json['activation_priority'],
      ).trim(),
      requiresExplicitSelection: ValueReaders.boolValue(
        json['requires_explicit_selection'],
      ),
      preferredBudgetChars: ValueReaders.intValue(
        json['preferred_budget_chars'],
      ),
      metadata: _informationActivationPolicyCodecService
          .readMetadataWithUnknownFields(
            json,
            knownFields: const <String>{
              'activation_priority',
              'requires_explicit_selection',
              'preferred_budget_chars',
              'metadata',
            },
          ),
    );
  }

  JsonMap toJson() {
    return _informationActivationPolicyCodecService
        .encodeWithUnknownFields(<String, Object?>{
          'activation_priority': activationPriority,
          'requires_explicit_selection': requiresExplicitSelection,
          'preferred_budget_chars': preferredBudgetChars,
        }, metadata: metadata);
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _informationActivationPolicyValidatorService.requireNonBlankString(
        activationPriority,
        InformationValidationCodes.missingInformationActivationPriority,
      ),
    );
    result.addAll(
      _informationActivationPolicyValidatorService.validateNonNegativeInt(
        preferredBudgetChars,
        InformationValidationCodes.invalidInformationPreferredBudgetChars,
      ),
    );
    return result;
  }
}
