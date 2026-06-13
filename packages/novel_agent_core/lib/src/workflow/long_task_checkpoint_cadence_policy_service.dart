import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_checkpoint_cadence_policy.dart';
import 'task_runtime_constants.dart';

class LongTaskCheckpointCadencePolicyService {
  const LongTaskCheckpointCadencePolicyService();

  LongTaskCheckpointCadencePolicy policyForMode(
    String mode, {
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 基线 cadence 只看模式和 runtime baseline，不掺入正文或宿主私有推断。
    final runtimeBaselineId = _runtimeBaselineId(options);
    final checkpointPolicy = _checkpointPolicyForMode(
      mode,
      runtimeBaselineId: runtimeBaselineId,
    );
    final baseCheckpointInterval = _baseCheckpointInterval(
      mode,
      options: options,
      runtimeBaselineId: runtimeBaselineId,
    );
    final baseBatchSteps = _baseBatchSteps(
      mode,
      options: options,
      runtimeBaselineId: runtimeBaselineId,
    );
    final baseBatchSeconds = _baseBatchSeconds(
      mode,
      options: options,
      runtimeBaselineId: runtimeBaselineId,
    );
    return LongTaskCheckpointCadencePolicy(
      mode: mode,
      runtimeBaselineId: runtimeBaselineId,
      checkpointPolicy: checkpointPolicy,
      baseCheckpointInterval: baseCheckpointInterval,
      effectiveCheckpointInterval: baseCheckpointInterval,
      baseBatchSteps: baseBatchSteps,
      effectiveBatchSteps: baseBatchSteps,
      baseBatchSeconds: baseBatchSeconds,
      effectiveBatchSeconds: baseBatchSeconds,
      riskLevel: LongTaskCheckpointCadenceRiskLevels.low,
      trailingRiskCount: 0,
      tighteningApplied: false,
      tightenAfterChapter: runtimeBaselineId == 'chapter_collaboration_autorun',
      reasons: <String>[_modeReason(mode, runtimeBaselineId: runtimeBaselineId)],
    );
  }

  LongTaskCheckpointCadencePolicy policyForRuntime(
    String mode, {
    required JsonMap record,
    JsonMap options = const <String, Object?>{},
    JsonMap controllerProfile = const <String, Object?>{},
  }) {
    // 中文注释: 运行态 cadence 只消费已结构化的 review/result 摘要，并在连续风险时自动收紧。
    final basePolicy = policyForMode(mode, options: options);
    final profile = controllerProfile.isEmpty
        ? const <String, Object?>{}
        : ValueReaders.deepCopyMap(controllerProfile);
    final profileInterval = ValueReaders.intValue(
      profile['checkpoint_interval'],
      basePolicy.baseCheckpointInterval,
    );
    final profileSteps = ValueReaders.intValue(
      profile['max_steps'],
      basePolicy.baseBatchSteps,
    );
    final profileSeconds = ValueReaders.intValue(
      profile['max_seconds'],
      basePolicy.baseBatchSeconds,
    );
    final rawRiskLevel = _riskLevelForRecord(record);
    final trailingRiskCount = _trailingRiskCount(record, rawRiskLevel);
    final effectiveRiskLevel = _escalateRiskLevel(
      rawRiskLevel,
      trailingRiskCount,
    );
    final tightened = _tightenedValues(
      effectiveRiskLevel,
      runtimeBaselineId: basePolicy.runtimeBaselineId,
      baseCheckpointInterval: profileInterval,
      baseBatchSteps: profileSteps,
      baseBatchSeconds: profileSeconds,
    );
    final reasons = <String>[
      ...basePolicy.reasons,
      ..._reasonsForRisk(
        rawRiskLevel: rawRiskLevel,
        effectiveRiskLevel: effectiveRiskLevel,
        trailingRiskCount: trailingRiskCount,
        record: record,
      ),
    ];
    final tighteningApplied =
        tightened.$1 != profileInterval ||
        tightened.$2 != profileSteps ||
        tightened.$3 != profileSeconds ||
        effectiveRiskLevel != LongTaskCheckpointCadenceRiskLevels.low;
    return LongTaskCheckpointCadencePolicy(
      mode: mode,
      runtimeBaselineId: basePolicy.runtimeBaselineId,
      checkpointPolicy: basePolicy.checkpointPolicy,
      baseCheckpointInterval: profileInterval,
      effectiveCheckpointInterval: tightened.$1,
      baseBatchSteps: profileSteps,
      effectiveBatchSteps: tightened.$2,
      baseBatchSeconds: profileSeconds,
      effectiveBatchSeconds: tightened.$3,
      riskLevel: effectiveRiskLevel,
      trailingRiskCount: trailingRiskCount,
      tighteningApplied: tighteningApplied,
      tightenAfterChapter: basePolicy.tightenAfterChapter,
      reasons: reasons,
      metadata: <String, Object?>{
        'raw_risk_level': rawRiskLevel,
        'last_checkpoint_review_severity': ValueReaders.stringValue(
          record['last_checkpoint_review_severity'],
        ).trim(),
        'last_writing_execution_category': ValueReaders.stringValue(
          record['last_writing_execution_category'],
        ).trim(),
        'last_information_risk_category': ValueReaders.stringValue(
          record['last_information_risk_category'],
        ).trim(),
      },
    );
  }

  int _baseCheckpointInterval(
    String mode, {
    required JsonMap options,
    required String runtimeBaselineId,
  }) {
    final optionValue = ValueReaders.intValue(
      options['checkpoint_interval'],
      -1,
    );
    if (optionValue >= 0) {
      return optionValue.clamp(0, 30);
    }
    if (runtimeBaselineId == 'chapter_collaboration_autorun') {
      return 0;
    }
    if (mode == TaskRuntimeConstants.modeSupervisedChapterQueue) {
      return 1;
    }
    if (mode == TaskRuntimeConstants.modeSeedToFullNovel) {
      return 3;
    }
    return 3;
  }

  int _baseBatchSteps(
    String mode, {
    required JsonMap options,
    required String runtimeBaselineId,
  }) {
    final optionValue = ValueReaders.intValue(options['max_steps'], -1);
    if (optionValue > 0) {
      return optionValue.clamp(1, 80);
    }
    if (runtimeBaselineId == 'chapter_collaboration_autorun') {
      return 4;
    }
    if (mode == TaskRuntimeConstants.modeSingleChapterAtomic) {
      return 1;
    }
    if (mode == TaskRuntimeConstants.modeSupervisedChapterQueue) {
      return 1;
    }
    if (mode == TaskRuntimeConstants.modeSeedToFullNovel) {
      return 2;
    }
    return 3;
  }

  int _baseBatchSeconds(
    String mode, {
    required JsonMap options,
    required String runtimeBaselineId,
  }) {
    final optionValue = ValueReaders.intValue(options['max_seconds'], -1);
    if (optionValue > 0) {
      return optionValue.clamp(30, 86400);
    }
    if (runtimeBaselineId == 'chapter_collaboration_autorun') {
      return 10800;
    }
    if (mode == TaskRuntimeConstants.modeSingleChapterAtomic) {
      return 1800;
    }
    if (mode == TaskRuntimeConstants.modeSupervisedChapterQueue) {
      return 3600;
    }
    return 7200;
  }

  String _checkpointPolicyForMode(
    String mode, {
    required String runtimeBaselineId,
  }) {
    if (runtimeBaselineId == 'chapter_collaboration_autorun') {
      return 'after_chapter_gate';
    }
    if (mode == TaskRuntimeConstants.modeSingleChapterAtomic) {
      return 'after_single_step';
    }
    if (mode == TaskRuntimeConstants.modeSupervisedChapterQueue) {
      return 'after_each_chapter';
    }
    if (mode == TaskRuntimeConstants.modeSeedToFullNovel) {
      return 'planning_outline_sample';
    }
    return 'interval_manual';
  }

  String _modeReason(String mode, {required String runtimeBaselineId}) {
    if (runtimeBaselineId == 'chapter_collaboration_autorun') {
      return 'baseline_chapter_collaboration_autorun';
    }
    if (mode == TaskRuntimeConstants.modeSingleChapterAtomic) {
      return 'baseline_single_step';
    }
    if (mode == TaskRuntimeConstants.modeSupervisedChapterQueue) {
      return 'baseline_supervised_queue';
    }
    if (mode == TaskRuntimeConstants.modeSeedToFullNovel) {
      return 'baseline_seed_to_full';
    }
    return 'baseline_outline_interval';
  }

  String _runtimeBaselineId(JsonMap options) {
    return ValueReaders.stringValue(options['runtime_baseline_id']).trim();
  }

  String _riskLevelForRecord(JsonMap record) {
    final checkpointRisk = _riskLevelFromCheckpointSeverity(
      ValueReaders.stringValue(record['last_checkpoint_review_severity']).trim(),
    );
    final writingRisk = _riskLevelFromWritingCategory(
      ValueReaders.stringValue(record['last_writing_execution_category']).trim(),
    );
    final informationRisk = _riskLevelFromInformationCategory(
      ValueReaders.stringValue(record['last_information_risk_category']).trim(),
    );
    return _maxRiskLevel(<String>[checkpointRisk, writingRisk, informationRisk]);
  }

  int _trailingRiskCount(JsonMap record, String targetRiskLevel) {
    if (targetRiskLevel == LongTaskCheckpointCadenceRiskLevels.low) {
      return 0;
    }
    var count = 0;
    final steps = ValueReaders.objectList(record['steps']).reversed;
    for (final rawStep in steps) {
      final step = ValueReaders.mapValue(rawStep);
      final level = _maxRiskLevel(<String>[
        _riskLevelFromCheckpointSeverity(
          ValueReaders.stringValue(step['checkpoint_review_severity']).trim(),
        ),
        _riskLevelFromWritingCategory(
          ValueReaders.stringValue(step['writing_execution_category']).trim(),
        ),
        _riskLevelFromInformationCategory(
          ValueReaders.stringValue(step['information_risk_category']).trim(),
        ),
      ]);
      if (_riskRank(level) >= _riskRank(LongTaskCheckpointCadenceRiskLevels.medium)) {
        count += 1;
        continue;
      }
      break;
    }
    return count;
  }

  String _escalateRiskLevel(String rawRiskLevel, int trailingRiskCount) {
    var rank = _riskRank(rawRiskLevel);
    if (trailingRiskCount >= 3 && rank < _riskRank(LongTaskCheckpointCadenceRiskLevels.critical)) {
      rank += 2;
    } else if (trailingRiskCount >= 2 &&
        rank < _riskRank(LongTaskCheckpointCadenceRiskLevels.critical)) {
      rank += 1;
    }
    if (rank >= _riskRank(LongTaskCheckpointCadenceRiskLevels.critical)) {
      return LongTaskCheckpointCadenceRiskLevels.critical;
    }
    if (rank == _riskRank(LongTaskCheckpointCadenceRiskLevels.high)) {
      return LongTaskCheckpointCadenceRiskLevels.high;
    }
    if (rank == _riskRank(LongTaskCheckpointCadenceRiskLevels.medium)) {
      return LongTaskCheckpointCadenceRiskLevels.medium;
    }
    return LongTaskCheckpointCadenceRiskLevels.low;
  }

  (int, int, int) _tightenedValues(
    String riskLevel, {
    required String runtimeBaselineId,
    required int baseCheckpointInterval,
    required int baseBatchSteps,
    required int baseBatchSeconds,
  }) {
    var interval = baseCheckpointInterval.clamp(0, 30);
    var batchSteps = baseBatchSteps.clamp(1, 80);
    var batchSeconds = baseBatchSeconds.clamp(30, 86400);
    switch (riskLevel) {
      case LongTaskCheckpointCadenceRiskLevels.medium:
        if (runtimeBaselineId != 'chapter_collaboration_autorun') {
          interval = baseCheckpointInterval == 0 ? 0 : interval.clamp(1, 2);
        }
        batchSteps = batchSteps.clamp(1, 2);
        batchSeconds = batchSeconds > 5400 ? 5400 : batchSeconds;
      case LongTaskCheckpointCadenceRiskLevels.high:
        if (runtimeBaselineId != 'chapter_collaboration_autorun') {
          interval = baseCheckpointInterval == 0 ? 0 : 1;
        }
        batchSteps = 1;
        batchSeconds = batchSeconds > 3600 ? 3600 : batchSeconds;
      case LongTaskCheckpointCadenceRiskLevels.critical:
        if (runtimeBaselineId != 'chapter_collaboration_autorun') {
          interval = baseCheckpointInterval == 0 ? 0 : 1;
        }
        batchSteps = 1;
        batchSeconds = batchSeconds > 1800 ? 1800 : batchSeconds;
      case LongTaskCheckpointCadenceRiskLevels.low:
        break;
    }
    return (interval, batchSteps, batchSeconds);
  }

  List<String> _reasonsForRisk({
    required String rawRiskLevel,
    required String effectiveRiskLevel,
    required int trailingRiskCount,
    required JsonMap record,
  }) {
    final reasons = <String>[];
    final severity = ValueReaders.stringValue(
      record['last_checkpoint_review_severity'],
    ).trim();
    final writingCategory = ValueReaders.stringValue(
      record['last_writing_execution_category'],
    ).trim();
    final informationCategory = ValueReaders.stringValue(
      record['last_information_risk_category'],
    ).trim();
    if (severity.isNotEmpty) {
      reasons.add('checkpoint_review_$severity');
    }
    if (writingCategory.isNotEmpty) {
      reasons.add('writing_execution_$writingCategory');
    }
    if (informationCategory.isNotEmpty) {
      reasons.add('information_risk_$informationCategory');
    }
    if (trailingRiskCount >= 2) {
      reasons.add('consecutive_structured_risk_$trailingRiskCount');
    }
    if (rawRiskLevel != effectiveRiskLevel) {
      reasons.add('risk_escalated_to_$effectiveRiskLevel');
    } else {
      reasons.add('risk_level_$effectiveRiskLevel');
    }
    return reasons;
  }

  String _riskLevelFromCheckpointSeverity(String severity) {
    switch (severity) {
      case 'critical':
        return LongTaskCheckpointCadenceRiskLevels.critical;
      case 'high':
        return LongTaskCheckpointCadenceRiskLevels.high;
      case 'medium':
        return LongTaskCheckpointCadenceRiskLevels.medium;
      default:
        return LongTaskCheckpointCadenceRiskLevels.low;
    }
  }

  String _riskLevelFromWritingCategory(String category) {
    switch (category) {
      case 'technical_failed':
      case 'content_quality_failed':
        return LongTaskCheckpointCadenceRiskLevels.critical;
      case 'recoverable':
        return LongTaskCheckpointCadenceRiskLevels.high;
      case 'waiting_user':
        return LongTaskCheckpointCadenceRiskLevels.medium;
      default:
        return LongTaskCheckpointCadenceRiskLevels.low;
    }
  }

  String _riskLevelFromInformationCategory(String category) {
    switch (category) {
      case 'manual_attention':
        return LongTaskCheckpointCadenceRiskLevels.critical;
      case 'repair':
        return LongTaskCheckpointCadenceRiskLevels.high;
      case 'checkpoint_user':
        return LongTaskCheckpointCadenceRiskLevels.medium;
      default:
        return LongTaskCheckpointCadenceRiskLevels.low;
    }
  }

  String _maxRiskLevel(List<String> levels) {
    var best = LongTaskCheckpointCadenceRiskLevels.low;
    for (final level in levels) {
      if (_riskRank(level) > _riskRank(best)) {
        best = level;
      }
    }
    return best;
  }

  int _riskRank(String level) {
    switch (level) {
      case LongTaskCheckpointCadenceRiskLevels.critical:
        return 3;
      case LongTaskCheckpointCadenceRiskLevels.high:
        return 2;
      case LongTaskCheckpointCadenceRiskLevels.medium:
        return 1;
      default:
        return 0;
    }
  }
}
