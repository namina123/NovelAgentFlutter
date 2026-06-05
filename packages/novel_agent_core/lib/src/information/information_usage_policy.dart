import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';
import 'information_validation_codes.dart';

const _informationUsagePolicyCodecService = OpenJsonContractCodecService();
const _informationUsagePolicyValidatorService =
    OpenJsonStructureValidatorService();

class InformationUsagePolicy {
  const InformationUsagePolicy({
    this.usageMode = '',
    this.citationRiskLevel = '',
    this.requiresConfirmation = false,
    this.allowsDerivativeUse = true,
    this.allowsDirectQuote = false,
    this.referenceScope = const <String, Object?>{},
    this.metadata = const <String, Object?>{},
  });

  final String usageMode;
  final String citationRiskLevel;
  final bool requiresConfirmation;
  final bool allowsDerivativeUse;
  final bool allowsDirectQuote;
  final JsonMap referenceScope;
  final JsonMap metadata;

  InformationUsagePolicy copyWith({
    String? usageMode,
    String? citationRiskLevel,
    bool? requiresConfirmation,
    bool? allowsDerivativeUse,
    bool? allowsDirectQuote,
    JsonMap? referenceScope,
    JsonMap? metadata,
  }) {
    // 中文注释: 使用策略只表达使用边界和风险姿态，不直接做权限审批或引用落盘。
    return InformationUsagePolicy(
      usageMode: usageMode ?? this.usageMode,
      citationRiskLevel: citationRiskLevel ?? this.citationRiskLevel,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      allowsDerivativeUse: allowsDerivativeUse ?? this.allowsDerivativeUse,
      allowsDirectQuote: allowsDirectQuote ?? this.allowsDirectQuote,
      referenceScope: referenceScope ?? this.referenceScope,
      metadata: metadata ?? this.metadata,
    );
  }

  factory InformationUsagePolicy.fromJson(JsonMap json) {
    return InformationUsagePolicy(
      usageMode: ValueReaders.stringValue(json['usage_mode']).trim(),
      citationRiskLevel: ValueReaders.stringValue(
        json['citation_risk_level'],
      ).trim(),
      requiresConfirmation: ValueReaders.boolValue(
        json['requires_confirmation'],
      ),
      allowsDerivativeUse: ValueReaders.boolValue(
        json['allows_derivative_use'],
        true,
      ),
      allowsDirectQuote: ValueReaders.boolValue(json['allows_direct_quote']),
      referenceScope: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['reference_scope']),
      ),
      metadata: _informationUsagePolicyCodecService
          .readMetadataWithUnknownFields(
            json,
            knownFields: const <String>{
              'usage_mode',
              'citation_risk_level',
              'requires_confirmation',
              'allows_derivative_use',
              'allows_direct_quote',
              'reference_scope',
              'metadata',
            },
          ),
    );
  }

  JsonMap toJson() {
    return _informationUsagePolicyCodecService
        .encodeWithUnknownFields(<String, Object?>{
          'usage_mode': usageMode,
          'citation_risk_level': citationRiskLevel,
          'requires_confirmation': requiresConfirmation,
          'allows_derivative_use': allowsDerivativeUse,
          'allows_direct_quote': allowsDirectQuote,
          'reference_scope': ValueReaders.deepCopyMap(referenceScope),
        }, metadata: metadata);
  }

  List<String> validateBasics() {
    final result = <String>[];
    result.addAll(
      _informationUsagePolicyValidatorService.requireNonBlankString(
        usageMode,
        InformationValidationCodes.missingInformationUsageMode,
      ),
    );
    result.addAll(
      _informationUsagePolicyValidatorService.requireNonBlankString(
        citationRiskLevel,
        InformationValidationCodes.missingInformationCitationRiskLevel,
      ),
    );
    result.addAll(
      _informationUsagePolicyValidatorService.requireCondition(
        allowsDerivativeUse || !allowsDirectQuote,
        InformationValidationCodes.conflictingInformationUsageDisposition,
      ),
    );
    return result;
  }
}
