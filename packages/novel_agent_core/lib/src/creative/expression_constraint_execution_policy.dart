import '../common/json_types.dart';
import '../common/open_json_contract_codec_service.dart';
import '../common/open_json_structure_validator_service.dart';
import '../common/value_readers.dart';

const _expressionConstraintExecutionPolicyCodecService =
    OpenJsonContractCodecService();
const _expressionConstraintExecutionPolicyValidatorService =
    OpenJsonStructureValidatorService();
const _expressionConstraintExecutionPolicyKnownFields = <String>{
  'mode',
  'injection_strength',
  'review_requirement',
  'violation_disposition',
  'allow_runtime_escalation',
  'exclude_tool_protocols',
  'exclude_research_execution',
  'metadata',
};

abstract final class ExpressionConstraintExecutionPolicyModes {
  static const String disabled = 'disabled';
  static const String adaptive = 'adaptive';
  static const String force = 'force';

  static const List<String> knownValues = <String>[disabled, adaptive, force];
}

abstract final class ExpressionConstraintInjectionStrengths {
  static const String none = 'none';
  static const String brief = 'brief';
  static const String sections = 'sections';
  static const String full = 'full';

  static const List<String> knownValues = <String>[none, brief, sections, full];
}

abstract final class ExpressionConstraintReviewRequirements {
  static const String none = 'none';
  static const String whenApplied = 'when_applied';
  static const String alwaysForWriting = 'always_for_writing';

  static const List<String> knownValues = <String>[
    none,
    whenApplied,
    alwaysForWriting,
  ];
}

abstract final class ExpressionConstraintViolationDispositions {
  static const String remind = 'remind';
  static const String adjustNext = 'adjust_next';
  static const String repair = 'repair';

  static const List<String> knownValues = <String>[remind, adjustNext, repair];
}

abstract final class ExpressionConstraintExecutionPolicyValidationCodes {
  static const String missingMode =
      'missing_expression_constraint_execution_policy_mode';
  static const String invalidMode =
      'invalid_expression_constraint_execution_policy_mode';
  static const String missingInjectionStrength =
      'missing_expression_constraint_injection_strength';
  static const String invalidInjectionStrength =
      'invalid_expression_constraint_injection_strength';
  static const String missingReviewRequirement =
      'missing_expression_constraint_review_requirement';
  static const String invalidReviewRequirement =
      'invalid_expression_constraint_review_requirement';
  static const String missingViolationDisposition =
      'missing_expression_constraint_violation_disposition';
  static const String invalidViolationDisposition =
      'invalid_expression_constraint_violation_disposition';
  static const String invalidDisabledInjectionStrength =
      'invalid_disabled_expression_constraint_injection_strength';
  static const String invalidDisabledReviewRequirement =
      'invalid_disabled_expression_constraint_review_requirement';
}

class ExpressionConstraintExecutionPolicy {
  const ExpressionConstraintExecutionPolicy({
    this.mode = ExpressionConstraintExecutionPolicyModes.adaptive,
    this.injectionStrength = ExpressionConstraintInjectionStrengths.sections,
    this.reviewRequirement = ExpressionConstraintReviewRequirements.whenApplied,
    this.violationDisposition =
        ExpressionConstraintViolationDispositions.adjustNext,
    this.allowRuntimeEscalation = true,
    this.excludeToolProtocols = true,
    this.excludeResearchExecution = true,
    this.metadata = const <String, Object?>{},
  });

  const ExpressionConstraintExecutionPolicy.disabled({
    this.violationDisposition =
        ExpressionConstraintViolationDispositions.remind,
    this.excludeToolProtocols = true,
    this.excludeResearchExecution = true,
    this.metadata = const <String, Object?>{},
  }) : mode = ExpressionConstraintExecutionPolicyModes.disabled,
       injectionStrength = ExpressionConstraintInjectionStrengths.none,
       reviewRequirement = ExpressionConstraintReviewRequirements.none,
       allowRuntimeEscalation = false;

  const ExpressionConstraintExecutionPolicy.force({
    this.allowRuntimeEscalation = false,
    this.excludeToolProtocols = true,
    this.excludeResearchExecution = true,
    this.metadata = const <String, Object?>{},
  }) : mode = ExpressionConstraintExecutionPolicyModes.force,
       injectionStrength = ExpressionConstraintInjectionStrengths.full,
       reviewRequirement =
           ExpressionConstraintReviewRequirements.alwaysForWriting,
       violationDisposition = ExpressionConstraintViolationDispositions.repair;

  static const ExpressionConstraintExecutionPolicy defaultAdaptive =
      ExpressionConstraintExecutionPolicy();

  final String mode;
  final String injectionStrength;
  final String reviewRequirement;
  final String violationDisposition;
  final bool allowRuntimeEscalation;
  final bool excludeToolProtocols;
  final bool excludeResearchExecution;
  final JsonMap metadata;

  bool get isDisabled =>
      mode == ExpressionConstraintExecutionPolicyModes.disabled;
  bool get isAdaptive =>
      mode == ExpressionConstraintExecutionPolicyModes.adaptive;
  bool get isForce => mode == ExpressionConstraintExecutionPolicyModes.force;

  ExpressionConstraintExecutionPolicy copyWith({
    String? mode,
    String? injectionStrength,
    String? reviewRequirement,
    String? violationDisposition,
    bool? allowRuntimeEscalation,
    bool? excludeToolProtocols,
    bool? excludeResearchExecution,
    JsonMap? metadata,
  }) {
    // 中文注释: 执行策略合同会在 core、adapters 和外层宿主之间薄桥传递，这里提供统一 copy 入口。
    return ExpressionConstraintExecutionPolicy(
      mode: mode ?? this.mode,
      injectionStrength: injectionStrength ?? this.injectionStrength,
      reviewRequirement: reviewRequirement ?? this.reviewRequirement,
      violationDisposition: violationDisposition ?? this.violationDisposition,
      allowRuntimeEscalation:
          allowRuntimeEscalation ?? this.allowRuntimeEscalation,
      excludeToolProtocols: excludeToolProtocols ?? this.excludeToolProtocols,
      excludeResearchExecution:
          excludeResearchExecution ?? this.excludeResearchExecution,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ExpressionConstraintExecutionPolicy.fromJson(JsonMap json) {
    // 中文注释: fromJson 对缺省字段使用模式默认值，但保留未知顶层字段进 metadata 以支持未来扩展。
    final mode = _readMode(json['mode']);
    final fallbackMode = _knownModeOrAdaptive(mode);
    return ExpressionConstraintExecutionPolicy(
      mode: mode,
      injectionStrength: _readInjectionStrength(
        json['injection_strength'],
        fallbackMode: fallbackMode,
      ),
      reviewRequirement: _readReviewRequirement(
        json['review_requirement'],
        fallbackMode: fallbackMode,
      ),
      violationDisposition: _readViolationDisposition(
        json['violation_disposition'],
        fallbackMode: fallbackMode,
      ),
      allowRuntimeEscalation: ValueReaders.boolValue(
        json['allow_runtime_escalation'],
        _defaultAllowRuntimeEscalationForMode(fallbackMode),
      ),
      excludeToolProtocols: ValueReaders.boolValue(
        json['exclude_tool_protocols'],
        true,
      ),
      excludeResearchExecution: ValueReaders.boolValue(
        json['exclude_research_execution'],
        true,
      ),
      metadata: _expressionConstraintExecutionPolicyCodecService
          .readMetadataWithUnknownFields(
            json,
            knownFields: _expressionConstraintExecutionPolicyKnownFields,
          ),
    );
  }

  JsonMap toJson() {
    // 中文注释: toJson 保持 open contract 形态，把未知顶层字段从 metadata 回放出去，避免 round-trip 丢失。
    return _expressionConstraintExecutionPolicyCodecService
        .encodeWithUnknownFields(<String, Object?>{
          'mode': mode,
          'injection_strength': injectionStrength,
          'review_requirement': reviewRequirement,
          'violation_disposition': violationDisposition,
          'allow_runtime_escalation': allowRuntimeEscalation,
          'exclude_tool_protocols': excludeToolProtocols,
          'exclude_research_execution': excludeResearchExecution,
        }, metadata: metadata);
  }

  List<String> validateBasics() {
    // 中文注释: 基础校验只检查合同形状和 disabled 模式最小自洽性，不在这里提前实现 resolver 语义。
    final result = <String>[];
    result.addAll(
      _expressionConstraintExecutionPolicyValidatorService
          .requireNonBlankString(
            mode,
            ExpressionConstraintExecutionPolicyValidationCodes.missingMode,
          ),
    );
    if (!_isKnownValue(
      mode,
      ExpressionConstraintExecutionPolicyModes.knownValues,
    )) {
      result.add(
        ExpressionConstraintExecutionPolicyValidationCodes.invalidMode,
      );
    }
    result.addAll(
      _expressionConstraintExecutionPolicyValidatorService
          .requireNonBlankString(
            injectionStrength,
            ExpressionConstraintExecutionPolicyValidationCodes
                .missingInjectionStrength,
          ),
    );
    if (!_isKnownValue(
      injectionStrength,
      ExpressionConstraintInjectionStrengths.knownValues,
    )) {
      result.add(
        ExpressionConstraintExecutionPolicyValidationCodes
            .invalidInjectionStrength,
      );
    }
    result.addAll(
      _expressionConstraintExecutionPolicyValidatorService
          .requireNonBlankString(
            reviewRequirement,
            ExpressionConstraintExecutionPolicyValidationCodes
                .missingReviewRequirement,
          ),
    );
    if (!_isKnownValue(
      reviewRequirement,
      ExpressionConstraintReviewRequirements.knownValues,
    )) {
      result.add(
        ExpressionConstraintExecutionPolicyValidationCodes
            .invalidReviewRequirement,
      );
    }
    result.addAll(
      _expressionConstraintExecutionPolicyValidatorService
          .requireNonBlankString(
            violationDisposition,
            ExpressionConstraintExecutionPolicyValidationCodes
                .missingViolationDisposition,
          ),
    );
    if (!_isKnownValue(
      violationDisposition,
      ExpressionConstraintViolationDispositions.knownValues,
    )) {
      result.add(
        ExpressionConstraintExecutionPolicyValidationCodes
            .invalidViolationDisposition,
      );
    }
    if (isDisabled &&
        injectionStrength != ExpressionConstraintInjectionStrengths.none) {
      result.add(
        ExpressionConstraintExecutionPolicyValidationCodes
            .invalidDisabledInjectionStrength,
      );
    }
    if (isDisabled &&
        reviewRequirement != ExpressionConstraintReviewRequirements.none) {
      result.add(
        ExpressionConstraintExecutionPolicyValidationCodes
            .invalidDisabledReviewRequirement,
      );
    }
    return result;
  }
}

String _readMode(Object? raw) {
  final mode = ValueReaders.stringValue(raw).trim();
  return mode.isEmpty
      ? ExpressionConstraintExecutionPolicyModes.adaptive
      : mode;
}

String _readInjectionStrength(Object? raw, {required String fallbackMode}) {
  final value = ValueReaders.stringValue(raw).trim();
  return value.isEmpty ? _defaultInjectionStrengthForMode(fallbackMode) : value;
}

String _readReviewRequirement(Object? raw, {required String fallbackMode}) {
  final value = ValueReaders.stringValue(raw).trim();
  return value.isEmpty ? _defaultReviewRequirementForMode(fallbackMode) : value;
}

String _readViolationDisposition(Object? raw, {required String fallbackMode}) {
  final value = ValueReaders.stringValue(raw).trim();
  return value.isEmpty
      ? _defaultViolationDispositionForMode(fallbackMode)
      : value;
}

String _knownModeOrAdaptive(String mode) {
  return _isKnownValue(
        mode,
        ExpressionConstraintExecutionPolicyModes.knownValues,
      )
      ? mode
      : ExpressionConstraintExecutionPolicyModes.adaptive;
}

String _defaultInjectionStrengthForMode(String mode) {
  switch (mode) {
    case ExpressionConstraintExecutionPolicyModes.disabled:
      return ExpressionConstraintInjectionStrengths.none;
    case ExpressionConstraintExecutionPolicyModes.force:
      return ExpressionConstraintInjectionStrengths.full;
    default:
      return ExpressionConstraintInjectionStrengths.sections;
  }
}

String _defaultReviewRequirementForMode(String mode) {
  switch (mode) {
    case ExpressionConstraintExecutionPolicyModes.disabled:
      return ExpressionConstraintReviewRequirements.none;
    case ExpressionConstraintExecutionPolicyModes.force:
      return ExpressionConstraintReviewRequirements.alwaysForWriting;
    default:
      return ExpressionConstraintReviewRequirements.whenApplied;
  }
}

String _defaultViolationDispositionForMode(String mode) {
  switch (mode) {
    case ExpressionConstraintExecutionPolicyModes.force:
      return ExpressionConstraintViolationDispositions.repair;
    case ExpressionConstraintExecutionPolicyModes.disabled:
      return ExpressionConstraintViolationDispositions.remind;
    default:
      return ExpressionConstraintViolationDispositions.adjustNext;
  }
}

bool _defaultAllowRuntimeEscalationForMode(String mode) {
  return mode == ExpressionConstraintExecutionPolicyModes.adaptive;
}

bool _isKnownValue(String value, List<String> knownValues) {
  return value.trim().isNotEmpty && knownValues.contains(value.trim());
}
