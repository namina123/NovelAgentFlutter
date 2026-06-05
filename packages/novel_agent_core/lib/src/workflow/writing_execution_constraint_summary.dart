import '../common/json_types.dart';
import '../common/value_readers.dart';

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
    this.expressionConstraintInjectionMode = 'disabled',
    this.expressionConstraintReviewRequired = false,
    this.expressionConstraintReviewProvided = false,
    this.expressionConstraintEvidenceMissing = false,
    this.hardGateReasons = const <String>[],
    this.softGateReasons = const <String>[],
    this.summary = '',
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
  final String expressionConstraintInjectionMode;
  final bool expressionConstraintReviewRequired;
  final bool expressionConstraintReviewProvided;
  final bool expressionConstraintEvidenceMissing;
  final List<String> hardGateReasons;
  final List<String> softGateReasons;
  final String summary;
  final JsonMap chapterLengthMetadata;
  final JsonMap runtimeReport;
  final JsonMap metadata;

  factory WritingExecutionConstraintSummary.fromJson(JsonMap json) {
    // 中文注释: constraint summary 需要稳定回读，确保字数与表达限制信号能脱离具体 runtime map 复用。
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
      expressionConstraintActive: ValueReaders.boolValue(
        json['expression_constraint_active'],
      ),
      expressionConstraintInjectionMode: ValueReaders.stringValue(
        json['expression_constraint_injection_mode'],
        'disabled',
      ).trim(),
      expressionConstraintReviewRequired: ValueReaders.boolValue(
        json['expression_constraint_review_required'],
      ),
      expressionConstraintReviewProvided: ValueReaders.boolValue(
        json['expression_constraint_review_provided'],
      ),
      expressionConstraintEvidenceMissing: ValueReaders.boolValue(
        json['expression_constraint_evidence_missing'],
      ),
      hardGateReasons: ValueReaders.stringList(json['hard_gate_reasons']),
      softGateReasons: ValueReaders.stringList(json['soft_gate_reasons']),
      summary: ValueReaders.stringValue(json['summary']).trim(),
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
      'expression_constraint_injection_mode': expressionConstraintInjectionMode,
      'expression_constraint_review_required':
          expressionConstraintReviewRequired,
      'expression_constraint_review_provided':
          expressionConstraintReviewProvided,
      'expression_constraint_evidence_missing':
          expressionConstraintEvidenceMissing,
      'hard_gate_reasons': hardGateReasons,
      'soft_gate_reasons': softGateReasons,
      'summary': summary,
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
    if (expressionConstraintEvidenceMissing &&
        !expressionConstraintReviewRequired) {
      result.add('invalid_writing_execution_constraint_review_evidence_state');
    }
    return result;
  }
}
