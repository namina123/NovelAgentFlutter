import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../workflow/continuous_task_stop_category.dart';

abstract final class LongTaskStopOutcomeCategories {
  static const String completedNaturally =
      ContinuousTaskStopCategories.completedNaturally;
  static const String budgetExhausted =
      ContinuousTaskStopCategories.budgetExhausted;
  static const String technicalFailure =
      ContinuousTaskStopCategories.technicalFailure;
  static const String deliveryFailure =
      ContinuousTaskStopCategories.deliveryFailure;
  static const String constraintGatePause =
      ContinuousTaskStopCategories.constraintGatePause;
  static const String waitingUser = ContinuousTaskStopCategories.waitingUser;
  static const String manualAttention =
      ContinuousTaskStopCategories.manualAttention;
  static const String recoveryExhausted =
      ContinuousTaskStopCategories.recoveryExhausted;

  static const List<String> knownValues =
      ContinuousTaskStopCategories.knownValues;
}

class LongTaskStopOutcome {
  const LongTaskStopOutcome({
    this.present = false,
    this.category = '',
    this.reason = '',
    this.legacyStopReason = '',
    this.summary = '',
    this.completionReason = '',
    this.metadata = const <String, Object?>{},
  });

  final bool present;
  final String category;
  final String reason;
  final String legacyStopReason;
  final String summary;
  final String completionReason;
  final JsonMap metadata;

  bool get isTerminalOutcome => present && category.trim().isNotEmpty;

  LongTaskStopOutcome copyWith({
    bool? present,
    String? category,
    String? reason,
    String? legacyStopReason,
    String? summary,
    String? completionReason,
    JsonMap? metadata,
  }) {
    // 中文注释: stop outcome 需要稳定 copyWith，方便后续 runtime/projection 在不重写旧字段的前提下逐步迁移。
    return LongTaskStopOutcome(
      present: present ?? this.present,
      category: category ?? this.category,
      reason: reason ?? this.reason,
      legacyStopReason: legacyStopReason ?? this.legacyStopReason,
      summary: summary ?? this.summary,
      completionReason: completionReason ?? this.completionReason,
      metadata: metadata ?? this.metadata,
    );
  }

  factory LongTaskStopOutcome.fromJson(JsonMap json) {
    // 中文注释: 允许旧 payload 缺少 stop outcome；空对象按 absent 处理，避免强行打断旧合同回读。
    final category = ValueReaders.stringValue(json['category']).trim();
    final legacyStopReason = ValueReaders.stringValue(
      json['legacy_stop_reason'],
    ).trim();
    return LongTaskStopOutcome(
      present: ValueReaders.boolValue(
        json['present'],
        category.isNotEmpty || legacyStopReason.isNotEmpty,
      ),
      category: category,
      reason: ValueReaders.stringValue(json['reason']).trim(),
      legacyStopReason: legacyStopReason,
      summary: ValueReaders.stringValue(json['summary']).trim(),
      completionReason: ValueReaders.stringValue(
        json['completion_reason'],
      ).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: 新合同显式保留 legacy_stop_reason，确保后续 adapter/CLI 迁移期间不丢旧兼容字段。
    return <String, Object?>{
      'present': present,
      'category': category,
      'reason': reason,
      'legacy_stop_reason': legacyStopReason,
      'summary': summary,
      'completion_reason': completionReason,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: 这里只校验 taxonomy 壳层是否稳定，不在本轮扩展到具体 recovery 算法或 GUI 文案。
    if (!present) {
      return const <String>[];
    }
    final result = <String>[];
    if (!LongTaskStopOutcomeCategories.knownValues.contains(category)) {
      result.add('invalid_long_task_stop_outcome_category');
    }
    if (reason.trim().isEmpty) {
      result.add('missing_long_task_stop_outcome_reason');
    }
    if (category == LongTaskStopOutcomeCategories.completedNaturally &&
        completionReason.trim().isEmpty) {
      result.add('missing_long_task_completion_reason');
    }
    return result;
  }
}
