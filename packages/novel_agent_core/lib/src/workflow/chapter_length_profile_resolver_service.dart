import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'chapter_length_distribution_policy.dart';
import 'chapter_length_profile.dart';

class ChapterLengthProfileResolverService {
  const ChapterLengthProfileResolverService();

  ChapterLengthProfile resolveFromTask(JsonMap task) {
    final metadata = ValueReaders.mapValue(task['metadata']);
    final stage = ValueReaders.stringValue(metadata['stage'], 'draft');
    final profileMap = ValueReaders.mapValue(metadata['chapter_length_profile']);
    if (profileMap.isNotEmpty) {
      return _profileFromMap(profileMap, fallbackStage: stage);
    }
    return _legacyProfileFromLooseData(
      metadata,
      fallbackStage: stage,
      allowSampleOverride: false,
    );
  }

  ChapterLengthDistributionPolicy resolvePolicyFromTask(JsonMap task) {
    final metadata = ValueReaders.mapValue(task['metadata']);
    final policyMap = ValueReaders.mapValue(
      metadata['chapter_length_distribution_policy'],
    );
    if (policyMap.isEmpty) {
      return defaultPolicy();
    }
    return _policyFromMap(policyMap);
  }

  JsonMap buildMetadataFromOptions(JsonMap options, {required String stage}) {
    // 中文注释: 初始计划里的 loose options 在这里归一化成标准 profile + policy + 兼容旧字段。
    final profile = _legacyProfileFromLooseData(
      options,
      fallbackStage: stage,
      allowSampleOverride: true,
    );
    if (!profile.isConfigured) {
      return const <String, Object?>{};
    }
    final policy = _policyFromLooseData(options);
    return _metadata(profile, policy);
  }

  JsonMap buildMetadataFromDynamicArguments(
    JsonMap arguments, {
    required String stage,
  }) {
    // 中文注释: 动态插入章节时不走 sample override，但仍允许显式覆写策略参数。
    final profile = _legacyProfileFromLooseData(
      arguments,
      fallbackStage: stage,
      allowSampleOverride: false,
    );
    if (!profile.isConfigured) {
      return const <String, Object?>{};
    }
    final policy = _policyFromLooseData(arguments);
    return _metadata(profile, policy);
  }

  JsonMap buildPromptConstraintMap(ChapterLengthProfile profile) {
    if (!profile.isConfigured) {
      return const <String, Object?>{};
    }
    return <String, Object?>{
      'target': profile.targetLength,
      if (profile.preferredMin > 0) 'min': profile.preferredMin,
      if (profile.preferredMax > 0) 'max': profile.preferredMax,
    };
  }

  ChapterLengthDistributionPolicy defaultPolicy() {
    return const ChapterLengthDistributionPolicy();
  }

  ChapterLengthProfile _legacyProfileFromLooseData(
    JsonMap data, {
    required String fallbackStage,
    required bool allowSampleOverride,
  }) {
    final enabled = data.containsKey('enable_chapter_word_constraints')
        ? ValueReaders.boolValue(data['enable_chapter_word_constraints'])
        : _hasAnyLegacyConstraint(data);
    if (!enabled) {
      return ChapterLengthProfile(
        enabled: false,
        targetLength: 0,
        stage: fallbackStage,
      );
    }
    final cleanStage = fallbackStage.trim().toLowerCase();
    final useSampleOverride = allowSampleOverride && cleanStage == 'sample';
    final target = ValueReaders.intValue(
      useSampleOverride
          ? data['sample_chapter_word_target']
          : data['chapter_word_target'],
      ValueReaders.intValue(data['chapter_word_target']),
    );
    final min = ValueReaders.intValue(
      useSampleOverride
          ? data['sample_chapter_word_min']
          : data['chapter_word_min'],
      ValueReaders.intValue(data['chapter_word_min']),
    );
    final max = ValueReaders.intValue(
      useSampleOverride
          ? data['sample_chapter_word_max']
          : data['chapter_word_max'],
      ValueReaders.intValue(data['chapter_word_max']),
    );
    return ChapterLengthProfile(
      enabled: target > 0,
      targetLength: target,
      preferredMin: min,
      preferredMax: max,
      stage: cleanStage.isEmpty ? 'draft' : cleanStage,
    );
  }

  ChapterLengthDistributionPolicy _policyFromLooseData(JsonMap data) {
    return ChapterLengthDistributionPolicy(
      rollingWindow: ValueReaders.intValue(data['chapter_length_rolling_window'], 4)
          .clamp(2, 8),
      mildDeviationRatio: _positiveRatio(
        data['chapter_length_mild_deviation_ratio'],
        0.18,
      ),
      severeDeviationRatio: _positiveRatio(
        data['chapter_length_severe_deviation_ratio'],
        0.35,
      ),
      mildAdjacentDeltaRatio: _positiveRatio(
        data['chapter_length_mild_adjacent_delta_ratio'],
        0.22,
      ),
      severeAdjacentDeltaRatio: _positiveRatio(
        data['chapter_length_severe_adjacent_delta_ratio'],
        0.45,
      ),
    );
  }

  ChapterLengthProfile _profileFromMap(
    JsonMap data, {
    required String fallbackStage,
  }) {
    return ChapterLengthProfile(
      enabled: ValueReaders.boolValue(data['enabled']),
      targetLength: ValueReaders.intValue(data['target_length']),
      preferredMin: ValueReaders.intValue(data['preferred_min']),
      preferredMax: ValueReaders.intValue(data['preferred_max']),
      stage: ValueReaders.stringValue(data['stage'], fallbackStage),
      metricUnit: ValueReaders.stringValue(
        data['metric_unit'],
        'visible_characters',
      ),
    );
  }

  ChapterLengthDistributionPolicy _policyFromMap(JsonMap data) {
    return ChapterLengthDistributionPolicy(
      rollingWindow: ValueReaders.intValue(data['rolling_window'], 4).clamp(2, 8),
      mildDeviationRatio: _positiveRatio(data['mild_deviation_ratio'], 0.18),
      severeDeviationRatio: _positiveRatio(data['severe_deviation_ratio'], 0.35),
      mildAdjacentDeltaRatio: _positiveRatio(
        data['mild_adjacent_delta_ratio'],
        0.22,
      ),
      severeAdjacentDeltaRatio: _positiveRatio(
        data['severe_adjacent_delta_ratio'],
        0.45,
      ),
    );
  }

  JsonMap _metadata(
    ChapterLengthProfile profile,
    ChapterLengthDistributionPolicy policy,
  ) {
    return <String, Object?>{
      'chapter_length_profile': profile.toJson(),
      'chapter_length_distribution_policy': policy.toJson(),
      if (profile.targetLength > 0) 'chapter_word_target': profile.targetLength,
      if (profile.preferredMin > 0) 'chapter_word_min': profile.preferredMin,
      if (profile.preferredMax > 0) 'chapter_word_max': profile.preferredMax,
    };
  }

  bool _hasAnyLegacyConstraint(JsonMap data) {
    return ValueReaders.intValue(data['chapter_word_target']) > 0 ||
        ValueReaders.intValue(data['chapter_word_min']) > 0 ||
        ValueReaders.intValue(data['chapter_word_max']) > 0 ||
        ValueReaders.intValue(data['sample_chapter_word_target']) > 0 ||
        ValueReaders.intValue(data['sample_chapter_word_min']) > 0 ||
        ValueReaders.intValue(data['sample_chapter_word_max']) > 0;
  }

  double _positiveRatio(Object? value, double fallback) {
    final resolved = ValueReaders.doubleValue(value, fallback);
    if (resolved <= 0) {
      return fallback;
    }
    return resolved;
  }
}
