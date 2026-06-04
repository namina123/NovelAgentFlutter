import '../../common/json_types.dart';
import '../../common/value_readers.dart';

class NarrativeProfileInterpretation {
  const NarrativeProfileInterpretation({
    required this.claimNamespace,
    this.profileId = '',
    this.profileNamespace = '',
    this.matchedRuleKey = '',
    this.namespaceMeaning = '',
    this.minimalFieldRequirements = const <String>[],
    this.missingRequiredFields = const <String>[],
    this.riskEscalationSuggestions = const <String>[],
    this.riskDeEscalationSuggestions = const <String>[],
    this.unknownPayloadPreservationExplanation = '',
    this.interpreterMetadata = const <String, Object?>{},
  });

  final String claimNamespace;
  final String profileId;
  final String profileNamespace;
  final String matchedRuleKey;
  final String namespaceMeaning;
  final List<String> minimalFieldRequirements;
  final List<String> missingRequiredFields;
  final List<String> riskEscalationSuggestions;
  final List<String> riskDeEscalationSuggestions;
  final String unknownPayloadPreservationExplanation;
  final JsonMap interpreterMetadata;

  JsonMap toJson() {
    // 中文注释: 解释结果未来会被投影成报告，这里先固定基础结构和开放 metadata。
    return <String, Object?>{
      'claim_namespace': claimNamespace,
      'profile_id': profileId,
      'profile_namespace': profileNamespace,
      'matched_rule_key': matchedRuleKey,
      'namespace_meaning': namespaceMeaning,
      'minimal_field_requirements': minimalFieldRequirements,
      'missing_required_fields': missingRequiredFields,
      'risk_escalation_suggestions': riskEscalationSuggestions,
      'risk_de_escalation_suggestions': riskDeEscalationSuggestions,
      'unknown_payload_preservation_explanation':
          unknownPayloadPreservationExplanation,
      'interpreter_metadata': ValueReaders.deepCopyMap(interpreterMetadata),
    };
  }
}
