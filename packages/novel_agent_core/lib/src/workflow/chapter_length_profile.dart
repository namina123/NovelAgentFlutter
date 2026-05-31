import '../common/json_types.dart';

class ChapterLengthProfile {
  const ChapterLengthProfile({
    required this.enabled,
    required this.targetLength,
    required this.stage,
    this.preferredMin = 0,
    this.preferredMax = 0,
    this.metricUnit = 'visible_characters',
  });

  final bool enabled;
  final int targetLength;
  final int preferredMin;
  final int preferredMax;
  final String stage;
  final String metricUnit;

  bool get isConfigured => enabled && targetLength > 0;

  JsonMap toJson() {
    // 中文注释: profile 负责表达“本章以什么字数基准写”，供任务、后处理和 GUI 共用同一结构。
    return <String, Object?>{
      'enabled': enabled,
      'target_length': targetLength,
      'preferred_min': preferredMin,
      'preferred_max': preferredMax,
      'stage': stage,
      'metric_unit': metricUnit,
    };
  }
}
