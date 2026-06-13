import '../common/json_types.dart';
import '../common/value_readers.dart';

class ChapterLengthDisciplineSummary {
  const ChapterLengthDisciplineSummary({
    this.present = false,
    this.configured = false,
    this.currentLength = 0,
    this.targetLength = 0,
    this.preferredMinLength = 0,
    this.preferredMaxLength = 0,
    this.mildDeviationRatioThreshold = 0,
    this.severeDeviationRatioThreshold = 0,
    this.mildAdjacentDeltaRatioThreshold = 0,
    this.severeAdjacentDeltaRatioThreshold = 0,
    this.targetDeviationRatio = 0,
    this.adjacentDeltaRatio = 0,
    this.level = '',
    this.recommendedAction = '',
    this.hardGateTriggered = false,
    this.reviewSuggested = false,
    this.reminderOnly = false,
    this.repairRequired = false,
    this.notes = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final bool present;
  final bool configured;
  final int currentLength;
  final int targetLength;
  final int preferredMinLength;
  final int preferredMaxLength;
  final double mildDeviationRatioThreshold;
  final double severeDeviationRatioThreshold;
  final double mildAdjacentDeltaRatioThreshold;
  final double severeAdjacentDeltaRatioThreshold;
  final double targetDeviationRatio;
  final double adjacentDeltaRatio;
  final String level;
  final String recommendedAction;
  final bool hardGateTriggered;
  final bool reviewSuggested;
  final bool reminderOnly;
  final bool repairRequired;
  final List<String> notes;
  final JsonMap metadata;

  factory ChapterLengthDisciplineSummary.fromJson(JsonMap json) {
    // 中文注释: 字数纪律摘要允许独立回读，确保 supervisor/runtime 不再重新猜测阈值和处置层级。
    return ChapterLengthDisciplineSummary(
      present: ValueReaders.boolValue(json['present']),
      configured: ValueReaders.boolValue(json['configured']),
      currentLength: ValueReaders.intValue(json['current_length']),
      targetLength: ValueReaders.intValue(json['target_length']),
      preferredMinLength: ValueReaders.intValue(json['preferred_min_length']),
      preferredMaxLength: ValueReaders.intValue(json['preferred_max_length']),
      mildDeviationRatioThreshold: ValueReaders.doubleValue(
        json['mild_deviation_ratio_threshold'],
      ),
      severeDeviationRatioThreshold: ValueReaders.doubleValue(
        json['severe_deviation_ratio_threshold'],
      ),
      mildAdjacentDeltaRatioThreshold: ValueReaders.doubleValue(
        json['mild_adjacent_delta_ratio_threshold'],
      ),
      severeAdjacentDeltaRatioThreshold: ValueReaders.doubleValue(
        json['severe_adjacent_delta_ratio_threshold'],
      ),
      targetDeviationRatio: ValueReaders.doubleValue(
        json['target_deviation_ratio'],
      ),
      adjacentDeltaRatio: ValueReaders.doubleValue(
        json['adjacent_delta_ratio'],
      ),
      level: ValueReaders.stringValue(json['level']).trim(),
      recommendedAction: ValueReaders.stringValue(
        json['recommended_action'],
      ).trim(),
      hardGateTriggered: ValueReaders.boolValue(json['hard_gate_triggered']),
      reviewSuggested: ValueReaders.boolValue(json['review_suggested']),
      reminderOnly: ValueReaders.boolValue(json['reminder_only']),
      repairRequired: ValueReaders.boolValue(json['repair_required']),
      notes: ValueReaders.stringList(json['notes']),
      metadata: ValueReaders.deepCopyMap(ValueReaders.mapValue(json['metadata'])),
    );
  }

  JsonMap toJson() {
    // 中文注释: 序列化只输出后续调度真正需要的阈值与当前结论，不泄漏具体评估服务内部对象。
    return <String, Object?>{
      'present': present,
      'configured': configured,
      'current_length': currentLength,
      'target_length': targetLength,
      'preferred_min_length': preferredMinLength,
      'preferred_max_length': preferredMaxLength,
      'mild_deviation_ratio_threshold': mildDeviationRatioThreshold,
      'severe_deviation_ratio_threshold': severeDeviationRatioThreshold,
      'mild_adjacent_delta_ratio_threshold': mildAdjacentDeltaRatioThreshold,
      'severe_adjacent_delta_ratio_threshold': severeAdjacentDeltaRatioThreshold,
      'target_deviation_ratio': targetDeviationRatio,
      'adjacent_delta_ratio': adjacentDeltaRatio,
      'level': level,
      'recommended_action': recommendedAction,
      'hard_gate_triggered': hardGateTriggered,
      'review_suggested': reviewSuggested,
      'reminder_only': reminderOnly,
      'repair_required': repairRequired,
      'notes': notes,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: 摘要校验只检查阈值和动作语义是否自洽，不重跑字数分布算法。
    if (!present) {
      return const <String>[];
    }
    final result = <String>[];
    if (configured && targetLength <= 0) {
      result.add('invalid_chapter_length_discipline_target');
    }
    if (currentLength < 0 ||
        preferredMinLength < 0 ||
        preferredMaxLength < 0) {
      result.add('invalid_chapter_length_discipline_lengths');
    }
    if (configured && level.trim().isEmpty) {
      result.add('missing_chapter_length_discipline_level');
    }
    if (repairRequired && !hardGateTriggered) {
      result.add('invalid_chapter_length_discipline_repair_state');
    }
    if (reminderOnly && repairRequired) {
      result.add('invalid_chapter_length_discipline_reminder_state');
    }
    return result;
  }
}
