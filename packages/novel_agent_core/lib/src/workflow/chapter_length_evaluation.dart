import '../common/json_types.dart';
import 'chapter_length_distribution_policy.dart';
import 'chapter_length_profile.dart';
import 'chapter_length_record.dart';

class ChapterLengthEvaluation {
  const ChapterLengthEvaluation({
    required this.profile,
    required this.policy,
    required this.currentRecord,
    required this.level,
    required this.recommendedAction,
    required this.notes,
    this.rollingAverageLength = 0,
    this.previousLength = 0,
    this.adjacentDelta = 0,
    this.targetDeviation = 0,
    this.targetDeviationRatio = 0,
    this.adjacentDeltaRatio = 0,
    this.historySamplesUsed = 0,
  });

  final ChapterLengthProfile profile;
  final ChapterLengthDistributionPolicy policy;
  final ChapterLengthRecord currentRecord;
  final int rollingAverageLength;
  final int previousLength;
  final int adjacentDelta;
  final int targetDeviation;
  final double targetDeviationRatio;
  final double adjacentDeltaRatio;
  final int historySamplesUsed;
  final String level;
  final String recommendedAction;
  final List<String> notes;

  JsonMap toJson() {
    // 中文注释: 评估结果会进运行记录、检查点复盘和未来 GUI 展示，所以统一收敛成稳定字段。
    return <String, Object?>{
      'enabled': profile.isConfigured,
      'metric_unit': profile.metricUnit,
      'profile': profile.toJson(),
      'policy': policy.toJson(),
      'current_record': currentRecord.toJson(),
      'current_length': currentRecord.length,
      'target_length': profile.targetLength,
      'preferred_min': profile.preferredMin,
      'preferred_max': profile.preferredMax,
      'rolling_average_length': rollingAverageLength,
      'previous_length': previousLength,
      'adjacent_delta': adjacentDelta,
      'target_deviation': targetDeviation,
      'target_deviation_ratio': targetDeviationRatio,
      'adjacent_delta_ratio': adjacentDeltaRatio,
      'history_samples_used': historySamplesUsed,
      'level': level,
      'recommended_action': recommendedAction,
      'notes': notes,
    };
  }
}
