import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../creative/expression_constraint_execution_policy.dart';
import '../review/review_contract.dart';
import '../review/review_summary.dart';
import 'chapter_length_discipline_summary.dart';
import 'expression_constraint_gate_signal.dart';

class WritingExecutionConstraintSummary {
  const WritingExecutionConstraintSummary({
    this.present = false,
    this.chapterLengthConfigured = false,
    this.chapterLengthLevel = '',
    this.chapterLengthRecommendedAction = '',
    this.chapterLengthCurrent = 0,
    this.chapterLengthTarget = 0,
    this.expressionConstraintProfileCount = 0,
    this.expressionConstraintBindingCount = 0,
    this.authenticityPassLevel = '',
    this.reviewFocuses = const <String>[],
    this.continuityWatchItems = const <String>[],
    this.miniRecheckItems = const <String>[],
    this.voiceProtectionNotes = const <String>[],
    this.notes = const <String>[],
    this.hardConstraintTriggered = false,
    this.reviewSuggested = false,
    this.contentQualityRisk = false,
    this.repairRequired = false,
    this.reminderOnly = false,
    this.expressionConstraintActive = false,
    this.expressionConstraintPolicyMode =
        ExpressionConstraintExecutionPolicyModes.disabled,
    this.expressionConstraintInjectionStrength =
        ExpressionConstraintInjectionStrengths.none,
    this.expressionConstraintReviewRequirement =
        ExpressionConstraintReviewRequirements.none,
    this.expressionConstraintViolationDisposition =
        ExpressionConstraintViolationDispositions.remind,
    this.expressionConstraintApplied = false,
    this.expressionConstraintDisabled = false,
    this.expressionConstraintSkipped = false,
    this.expressionConstraintRuntimeEscalated = false,
    this.expressionConstraintTechnicalTurnExcluded = false,
    this.expressionConstraintInjectionMode = 'disabled',
    this.expressionConstraintReviewRequired = false,
    this.expressionConstraintReviewProvided = false,
    this.expressionConstraintEvidenceMissing = false,
    this.expressionConstraintViolationRecorded = false,
    this.expressionConstraintAppliedReasons = const <String>[],
    this.expressionConstraintSkippedReasons = const <String>[],
    this.expressionConstraintGate = const ExpressionConstraintGateSignal(),
    this.expressionConstraintReviewContract,
    this.expressionConstraintReviewSummary,
    this.hardGateReasons = const <String>[],
    this.softGateReasons = const <String>[],
    this.summary = '',
    this.chapterLengthDiscipline = const ChapterLengthDisciplineSummary(),
    this.chapterLengthMetadata = const <String, Object?>{},
    this.runtimeReport = const <String, Object?>{},
    this.metadata = const <String, Object?>{},
  });

  final bool present;
  final bool chapterLengthConfigured;
  final String chapterLengthLevel;
  final String chapterLengthRecommendedAction;
  final int chapterLengthCurrent;
  final int chapterLengthTarget;
  final int expressionConstraintProfileCount;
  final int expressionConstraintBindingCount;
  final String authenticityPassLevel;
  final List<String> reviewFocuses;
  final List<String> continuityWatchItems;
  final List<String> miniRecheckItems;
  final List<String> voiceProtectionNotes;
  final List<String> notes;
  final bool hardConstraintTriggered;
  final bool reviewSuggested;
  final bool contentQualityRisk;
  final bool repairRequired;
  final bool reminderOnly;
  final bool expressionConstraintActive;
  final String expressionConstraintPolicyMode;
  final String expressionConstraintInjectionStrength;
  final String expressionConstraintReviewRequirement;
  final String expressionConstraintViolationDisposition;
  final bool expressionConstraintApplied;
  final bool expressionConstraintDisabled;
  final bool expressionConstraintSkipped;
  final bool expressionConstraintRuntimeEscalated;
  final bool expressionConstraintTechnicalTurnExcluded;
  final String expressionConstraintInjectionMode;
  final bool expressionConstraintReviewRequired;
  final bool expressionConstraintReviewProvided;
  final bool expressionConstraintEvidenceMissing;
  final bool expressionConstraintViolationRecorded;
  final List<String> expressionConstraintAppliedReasons;
  final List<String> expressionConstraintSkippedReasons;
  final ExpressionConstraintGateSignal expressionConstraintGate;
  final ReviewContract? expressionConstraintReviewContract;
  final ReviewSummary? expressionConstraintReviewSummary;
  final List<String> hardGateReasons;
  final List<String> softGateReasons;
  final String summary;
  final ChapterLengthDisciplineSummary chapterLengthDiscipline;
  final JsonMap chapterLengthMetadata;
  final JsonMap runtimeReport;
  final JsonMap metadata;

  factory WritingExecutionConstraintSummary.fromJson(JsonMap json) {
    // 中文注释: constraint summary 需要稳定回读，确保字数与表达限制信号能脱离具体 runtime map 复用。
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
    final expressionConstraintActive = ValueReaders.boolValue(
      json['expression_constraint_active'],
    );
    final appliedReasons = ValueReaders.stringList(
      json['expression_constraint_applied_reasons'],
    );
    final skippedReasons = ValueReaders.stringList(
      json['expression_constraint_skipped_reasons'],
    );
    final expressionConstraintGateJson = ValueReaders.mapValue(
      json['expression_constraint_gate'],
    );
    final expressionConstraintReviewContractJson = ValueReaders.mapValue(
      json['expression_constraint_review_contract'],
    );
    final expressionConstraintReviewSummaryJson = ValueReaders.mapValue(
      json['expression_constraint_review_summary'],
    );
    final expressionConstraintApplied = ValueReaders.boolValue(
      json['expression_constraint_applied'],
      expressionConstraintActive && legacyInjectionMode != 'disabled',
    );
    final expressionConstraintDisabled = ValueReaders.boolValue(
      json['expression_constraint_disabled'],
      policyMode == ExpressionConstraintExecutionPolicyModes.disabled,
    );
    final expressionConstraintSkipped = ValueReaders.boolValue(
      json['expression_constraint_skipped'],
      expressionConstraintActive &&
          !expressionConstraintDisabled &&
          !expressionConstraintApplied,
    );
    return WritingExecutionConstraintSummary(
      present: ValueReaders.boolValue(json['present']),
      chapterLengthConfigured: ValueReaders.boolValue(
        json['chapter_length_configured'],
      ),
      chapterLengthLevel: ValueReaders.stringValue(
        json['chapter_length_level'],
      ).trim(),
      chapterLengthRecommendedAction: ValueReaders.stringValue(
        json['chapter_length_recommended_action'],
      ).trim(),
      chapterLengthCurrent: ValueReaders.intValue(
        json['chapter_length_current'],
      ),
      chapterLengthTarget: ValueReaders.intValue(json['chapter_length_target']),
      expressionConstraintProfileCount: ValueReaders.intValue(
        json['expression_constraint_profile_count'],
      ),
      expressionConstraintBindingCount: ValueReaders.intValue(
        json['expression_constraint_binding_count'],
      ),
      authenticityPassLevel: ValueReaders.stringValue(
        json['authenticity_pass_level'],
      ).trim(),
      reviewFocuses: ValueReaders.stringList(json['review_focuses']),
      continuityWatchItems: ValueReaders.stringList(
        json['continuity_watch_items'],
      ),
      miniRecheckItems: ValueReaders.stringList(json['mini_recheck_items']),
      voiceProtectionNotes: ValueReaders.stringList(
        json['voice_protection_notes'],
      ),
      notes: ValueReaders.stringList(json['notes']),
      hardConstraintTriggered: ValueReaders.boolValue(
        json['hard_constraint_triggered'],
      ),
      reviewSuggested: ValueReaders.boolValue(json['review_suggested']),
      contentQualityRisk: ValueReaders.boolValue(json['content_quality_risk']),
      repairRequired: ValueReaders.boolValue(json['repair_required']),
      reminderOnly: ValueReaders.boolValue(json['reminder_only']),
      expressionConstraintActive: expressionConstraintActive,
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
      expressionConstraintApplied: expressionConstraintApplied,
      expressionConstraintDisabled: expressionConstraintDisabled,
      expressionConstraintSkipped: expressionConstraintSkipped,
      expressionConstraintRuntimeEscalated: ValueReaders.boolValue(
        json['expression_constraint_runtime_escalated'],
      ),
      expressionConstraintTechnicalTurnExcluded: ValueReaders.boolValue(
        json['expression_constraint_technical_turn_excluded'],
      ),
      expressionConstraintInjectionMode: ValueReaders.stringValue(
        json['expression_constraint_injection_mode'],
        legacyInjectionMode,
      ).trim(),
      expressionConstraintReviewRequired: ValueReaders.boolValue(
        json['expression_constraint_review_required'],
        legacyReviewRequired,
      ),
      expressionConstraintReviewProvided: ValueReaders.boolValue(
        json['expression_constraint_review_provided'],
      ),
      expressionConstraintEvidenceMissing: ValueReaders.boolValue(
        json['expression_constraint_evidence_missing'],
      ),
      expressionConstraintViolationRecorded: ValueReaders.boolValue(
        json['expression_constraint_violation_recorded'],
      ),
      expressionConstraintAppliedReasons: appliedReasons,
      expressionConstraintSkippedReasons: skippedReasons,
      expressionConstraintGate: ExpressionConstraintGateSignal.fromJson(
        expressionConstraintGateJson.isNotEmpty
            ? expressionConstraintGateJson
            : <String, Object?>{
                'present': ValueReaders.boolValue(
                  json['expression_constraint_violation_recorded'],
                ),
                'recommended_disposition': ValueReaders.stringValue(
                  json['expression_constraint_violation_disposition'],
                ),
                'risk_signals': ValueReaders.stringList(
                  json['continuity_watch_items'],
                ),
              },
      ),
      expressionConstraintReviewContract:
          expressionConstraintReviewContractJson.isEmpty
          ? null
          : ReviewContract.fromJson(expressionConstraintReviewContractJson),
      expressionConstraintReviewSummary:
          expressionConstraintReviewSummaryJson.isEmpty
          ? null
          : ReviewSummary.fromJson(expressionConstraintReviewSummaryJson),
      hardGateReasons: ValueReaders.stringList(json['hard_gate_reasons']),
      softGateReasons: ValueReaders.stringList(json['soft_gate_reasons']),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      chapterLengthDiscipline: ChapterLengthDisciplineSummary.fromJson(
        ValueReaders.mapValue(json['chapter_length_discipline']),
      ),
      chapterLengthMetadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['chapter_length_metadata']),
      ),
      runtimeReport: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['runtime_report']),
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: 约束摘要只保留后续 session 真正需要投影和归因的稳定字段，不泄漏具体宿主实现。
    return <String, Object?>{
      'present': present,
      'chapter_length_configured': chapterLengthConfigured,
      'chapter_length_level': chapterLengthLevel,
      'chapter_length_recommended_action': chapterLengthRecommendedAction,
      'chapter_length_current': chapterLengthCurrent,
      'chapter_length_target': chapterLengthTarget,
      'expression_constraint_profile_count': expressionConstraintProfileCount,
      'expression_constraint_binding_count': expressionConstraintBindingCount,
      'authenticity_pass_level': authenticityPassLevel,
      'review_focuses': reviewFocuses,
      'continuity_watch_items': continuityWatchItems,
      'mini_recheck_items': miniRecheckItems,
      'voice_protection_notes': voiceProtectionNotes,
      'notes': notes,
      'hard_constraint_triggered': hardConstraintTriggered,
      'review_suggested': reviewSuggested,
      'content_quality_risk': contentQualityRisk,
      'repair_required': repairRequired,
      'reminder_only': reminderOnly,
      'expression_constraint_active': expressionConstraintActive,
      'expression_constraint_policy_mode': expressionConstraintPolicyMode,
      'expression_constraint_injection_strength':
          expressionConstraintInjectionStrength,
      'expression_constraint_review_requirement':
          expressionConstraintReviewRequirement,
      'expression_constraint_violation_disposition':
          expressionConstraintViolationDisposition,
      'expression_constraint_applied': expressionConstraintApplied,
      'expression_constraint_disabled': expressionConstraintDisabled,
      'expression_constraint_skipped': expressionConstraintSkipped,
      'expression_constraint_runtime_escalated':
          expressionConstraintRuntimeEscalated,
      'expression_constraint_technical_turn_excluded':
          expressionConstraintTechnicalTurnExcluded,
      'expression_constraint_injection_mode': expressionConstraintInjectionMode,
      'expression_constraint_review_required':
          expressionConstraintReviewRequired,
      'expression_constraint_review_provided':
          expressionConstraintReviewProvided,
      'expression_constraint_evidence_missing':
          expressionConstraintEvidenceMissing,
      'expression_constraint_violation_recorded':
          expressionConstraintViolationRecorded,
      'expression_constraint_applied_reasons': ValueReaders.deepCopyList(
        expressionConstraintAppliedReasons.cast<Object?>(),
      ),
      'expression_constraint_skipped_reasons': ValueReaders.deepCopyList(
        expressionConstraintSkippedReasons.cast<Object?>(),
      ),
      'expression_constraint_gate': expressionConstraintGate.toJson(),
      if (expressionConstraintReviewContract != null)
        'expression_constraint_review_contract':
            expressionConstraintReviewContract!.toJson(),
      if (expressionConstraintReviewSummary != null)
        'expression_constraint_review_summary':
            expressionConstraintReviewSummary!.toJson(),
      'hard_gate_reasons': hardGateReasons,
      'soft_gate_reasons': softGateReasons,
      'summary': summary,
      'chapter_length_discipline': chapterLengthDiscipline.toJson(),
      'chapter_length_metadata': ValueReaders.deepCopyMap(
        chapterLengthMetadata,
      ),
      'runtime_report': ValueReaders.deepCopyMap(runtimeReport),
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: 约束摘要校验只检查核心计数和关键等级是否自洽，不替代真实审稿或字数评估。
    if (!present) {
      return const <String>[];
    }
    final result = <String>[];
    if (expressionConstraintProfileCount < 0 ||
        expressionConstraintBindingCount < 0) {
      result.add('invalid_writing_execution_constraint_counts');
    }
    if (chapterLengthCurrent < 0 || chapterLengthTarget < 0) {
      result.add('invalid_writing_execution_constraint_length_values');
    }
    if (chapterLengthConfigured && chapterLengthLevel.trim().isEmpty) {
      result.add('missing_writing_execution_constraint_level');
    }
    if (repairRequired && !hardConstraintTriggered) {
      result.add('invalid_writing_execution_constraint_repair_state');
    }
    if (expressionConstraintApplied && expressionConstraintDisabled) {
      result.add('invalid_writing_execution_constraint_disabled_apply_state');
    }
    if (expressionConstraintSkipped && expressionConstraintApplied) {
      result.add('invalid_writing_execution_constraint_skip_apply_state');
    }
    if (expressionConstraintEvidenceMissing &&
        !expressionConstraintReviewRequired) {
      result.add('invalid_writing_execution_constraint_review_evidence_state');
    }
    result.addAll(chapterLengthDiscipline.validateBasics());
    result.addAll(expressionConstraintGate.validateBasics());
    if (expressionConstraintReviewContract != null) {
      result.addAll(expressionConstraintReviewContract!.validateBasics());
    }
    if (expressionConstraintReviewSummary != null) {
      result.addAll(expressionConstraintReviewSummary!.validateBasics());
    }
    return result;
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
