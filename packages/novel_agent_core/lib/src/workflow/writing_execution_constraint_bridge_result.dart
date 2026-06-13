import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../creative/expression_constraint_execution_policy.dart';
import '../creative/expression_constraint_profile.dart';
import '../creative/expression_constraint_profile_normalizer_service.dart';
import '../creative/project_expression_constraint_binding.dart';
import '../creative/project_expression_constraint_binding_normalizer_service.dart';

class WritingExecutionConstraintBridgeResult {
  const WritingExecutionConstraintBridgeResult({
    this.chapterLengthMetadata = const <String, Object?>{},
    this.expressionConstraintProfiles = const <ExpressionConstraintProfile>[],
    this.projectExpressionConstraintBindings =
        const <ProjectExpressionConstraintBinding>[],
    this.expressionConstraintPolicyMode =
        ExpressionConstraintExecutionPolicyModes.disabled,
    this.expressionConstraintInjectionStrength =
        ExpressionConstraintInjectionStrengths.none,
    this.expressionConstraintReviewRequirement =
        ExpressionConstraintReviewRequirements.none,
    this.expressionConstraintViolationDisposition =
        ExpressionConstraintViolationDispositions.remind,
    this.expressionConstraintApplied = false,
    this.expressionConstraintRuntimeEscalated = false,
    this.expressionConstraintTechnicalTurnExcluded = false,
    this.expressionConstraintAppliedReasons = const <String>[],
    this.expressionConstraintSkippedReasons = const <String>[],
    this.expressionConstraintInjectionMode = 'disabled',
    this.expressionConstraintReviewRequired = false,
    this.runtimeReport = const <String, Object?>{},
  });

  final JsonMap chapterLengthMetadata;
  final List<ExpressionConstraintProfile> expressionConstraintProfiles;
  final List<ProjectExpressionConstraintBinding>
  projectExpressionConstraintBindings;
  final String expressionConstraintPolicyMode;
  final String expressionConstraintInjectionStrength;
  final String expressionConstraintReviewRequirement;
  final String expressionConstraintViolationDisposition;
  final bool expressionConstraintApplied;
  final bool expressionConstraintRuntimeEscalated;
  final bool expressionConstraintTechnicalTurnExcluded;
  final List<String> expressionConstraintAppliedReasons;
  final List<String> expressionConstraintSkippedReasons;
  final String expressionConstraintInjectionMode;
  final bool expressionConstraintReviewRequired;
  final JsonMap runtimeReport;

  factory WritingExecutionConstraintBridgeResult.fromJson(JsonMap json) {
    const profileNormalizer = ExpressionConstraintProfileNormalizerService();
    const bindingNormalizer =
        ProjectExpressionConstraintBindingNormalizerService();
    final bindings = ValueReaders.mapList(
      json['project_expression_constraint_bindings'],
    ).map(bindingNormalizer.normalize).toList(growable: false);
    final legacyInjectionMode = ValueReaders.stringValue(
      json['expression_constraint_injection_mode'],
      'disabled',
    ).trim();
    final legacyReviewRequired = ValueReaders.boolValue(
      json['expression_constraint_review_required'],
    );
    final policyMode = ValueReaders.stringValue(
      json['expression_constraint_policy_mode'],
      _inferPolicyMode(legacyInjectionMode),
    ).trim();
    final appliedReasons = ValueReaders.stringList(
      json['expression_constraint_applied_reasons'],
    );
    final skippedReasons = ValueReaders.stringList(
      json['expression_constraint_skipped_reasons'],
    );
    return WritingExecutionConstraintBridgeResult(
      chapterLengthMetadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['chapter_length_metadata']),
      ),
      expressionConstraintProfiles: ValueReaders.mapList(
        json['expression_constraint_profiles'],
      ).map(profileNormalizer.normalize).toList(growable: false),
      projectExpressionConstraintBindings: bindings,
      expressionConstraintPolicyMode: policyMode.isEmpty
          ? ExpressionConstraintExecutionPolicyModes.disabled
          : policyMode,
      expressionConstraintInjectionStrength: ValueReaders.stringValue(
        json['expression_constraint_injection_strength'],
        _inferInjectionStrength(legacyInjectionMode),
      ).trim(),
      expressionConstraintReviewRequirement: ValueReaders.stringValue(
        json['expression_constraint_review_requirement'],
        legacyReviewRequired
            ? ExpressionConstraintReviewRequirements.whenApplied
            : _defaultReviewRequirementForPolicyMode(policyMode),
      ).trim(),
      expressionConstraintViolationDisposition: ValueReaders.stringValue(
        json['expression_constraint_violation_disposition'],
        _defaultViolationDispositionForPolicyMode(policyMode),
      ).trim(),
      expressionConstraintApplied: ValueReaders.boolValue(
        json['expression_constraint_applied'],
        _inferApplied(
          policyMode: policyMode,
          bindings: bindings,
          injectionMode: legacyInjectionMode,
          appliedReasons: appliedReasons,
          skippedReasons: skippedReasons,
        ),
      ),
      expressionConstraintRuntimeEscalated: ValueReaders.boolValue(
        json['expression_constraint_runtime_escalated'],
      ),
      expressionConstraintTechnicalTurnExcluded: ValueReaders.boolValue(
        json['expression_constraint_technical_turn_excluded'],
      ),
      expressionConstraintAppliedReasons: appliedReasons,
      expressionConstraintSkippedReasons: skippedReasons,
      expressionConstraintInjectionMode: legacyInjectionMode,
      expressionConstraintReviewRequired: ValueReaders.boolValue(
        json['expression_constraint_review_required'],
        legacyReviewRequired,
      ),
      runtimeReport: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['runtime_report']),
      ),
    );
  }

  bool get hasChapterLengthMetadata => chapterLengthMetadata.isNotEmpty;
  bool get hasExpressionConstraintRuntime =>
      expressionConstraintProfiles.isNotEmpty ||
      projectExpressionConstraintBindings.isNotEmpty ||
      expressionConstraintApplied ||
      expressionConstraintRuntimeEscalated ||
      expressionConstraintTechnicalTurnExcluded ||
      expressionConstraintAppliedReasons.isNotEmpty ||
      expressionConstraintSkippedReasons.isNotEmpty ||
      expressionConstraintInjectionMode != 'disabled' ||
      expressionConstraintReviewRequired;

  JsonMap toJson() {
    const profileNormalizer = ExpressionConstraintProfileNormalizerService();
    const bindingNormalizer =
        ProjectExpressionConstraintBindingNormalizerService();
    return <String, Object?>{
      'chapter_length_metadata': ValueReaders.deepCopyMap(
        chapterLengthMetadata,
      ),
      'expression_constraint_profiles': expressionConstraintProfiles
          .map(profileNormalizer.toDocument)
          .cast<Object?>()
          .toList(growable: false),
      'project_expression_constraint_bindings':
          projectExpressionConstraintBindings
              .map(bindingNormalizer.toDocument)
              .cast<Object?>()
              .toList(growable: false),
      'expression_constraint_policy_mode': expressionConstraintPolicyMode,
      'expression_constraint_injection_strength':
          expressionConstraintInjectionStrength,
      'expression_constraint_review_requirement':
          expressionConstraintReviewRequirement,
      'expression_constraint_violation_disposition':
          expressionConstraintViolationDisposition,
      'expression_constraint_applied': expressionConstraintApplied,
      'expression_constraint_runtime_escalated':
          expressionConstraintRuntimeEscalated,
      'expression_constraint_technical_turn_excluded':
          expressionConstraintTechnicalTurnExcluded,
      'expression_constraint_applied_reasons': ValueReaders.deepCopyList(
        expressionConstraintAppliedReasons.cast<Object?>(),
      ),
      'expression_constraint_skipped_reasons': ValueReaders.deepCopyList(
        expressionConstraintSkippedReasons.cast<Object?>(),
      ),
      'expression_constraint_injection_mode': expressionConstraintInjectionMode,
      'expression_constraint_review_required':
          expressionConstraintReviewRequired,
      'runtime_report': ValueReaders.deepCopyMap(runtimeReport),
    };
  }
}

String _inferPolicyMode(String injectionMode) {
  return injectionMode.trim() == 'disabled'
      ? ExpressionConstraintExecutionPolicyModes.disabled
      : ExpressionConstraintExecutionPolicyModes.adaptive;
}

String _inferInjectionStrength(String injectionMode) {
  switch (injectionMode.trim()) {
    case 'brief_only':
      return ExpressionConstraintInjectionStrengths.brief;
    case 'brief_and_sections':
      return ExpressionConstraintInjectionStrengths.sections;
    default:
      return ExpressionConstraintInjectionStrengths.none;
  }
}

String _defaultReviewRequirementForPolicyMode(String policyMode) {
  return policyMode == ExpressionConstraintExecutionPolicyModes.force
      ? ExpressionConstraintReviewRequirements.alwaysForWriting
      : policyMode == ExpressionConstraintExecutionPolicyModes.disabled
      ? ExpressionConstraintReviewRequirements.none
      : ExpressionConstraintReviewRequirements.whenApplied;
}

String _defaultViolationDispositionForPolicyMode(String policyMode) {
  return policyMode == ExpressionConstraintExecutionPolicyModes.force
      ? ExpressionConstraintViolationDispositions.repair
      : policyMode == ExpressionConstraintExecutionPolicyModes.disabled
      ? ExpressionConstraintViolationDispositions.remind
      : ExpressionConstraintViolationDispositions.adjustNext;
}

bool _inferApplied({
  required String policyMode,
  required List<ProjectExpressionConstraintBinding> bindings,
  required String injectionMode,
  required List<String> appliedReasons,
  required List<String> skippedReasons,
}) {
  if (policyMode == ExpressionConstraintExecutionPolicyModes.disabled) {
    return false;
  }
  if (appliedReasons.isNotEmpty) {
    return true;
  }
  if (skippedReasons.isNotEmpty) {
    return false;
  }
  return bindings.isNotEmpty && injectionMode != 'disabled';
}
