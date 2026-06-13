import '../common/json_types.dart';
import '../common/value_readers.dart';

abstract final class LongTaskCheckpointCadenceRiskLevels {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String critical = 'critical';

  static const List<String> knownValues = <String>[
    low,
    medium,
    high,
    critical,
  ];
}

class LongTaskCheckpointCadencePolicy {
  const LongTaskCheckpointCadencePolicy({
    this.mode = '',
    this.runtimeBaselineId = '',
    this.checkpointPolicy = '',
    this.baseCheckpointInterval = 0,
    this.effectiveCheckpointInterval = 0,
    this.baseBatchSteps = 1,
    this.effectiveBatchSteps = 1,
    this.baseBatchSeconds = 7200,
    this.effectiveBatchSeconds = 7200,
    this.riskLevel = LongTaskCheckpointCadenceRiskLevels.low,
    this.trailingRiskCount = 0,
    this.tighteningApplied = false,
    this.tightenAfterChapter = false,
    this.schemaVersion = 1,
    this.reasons = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final String mode;
  final String runtimeBaselineId;
  final String checkpointPolicy;
  final int baseCheckpointInterval;
  final int effectiveCheckpointInterval;
  final int baseBatchSteps;
  final int effectiveBatchSteps;
  final int baseBatchSeconds;
  final int effectiveBatchSeconds;
  final String riskLevel;
  final int trailingRiskCount;
  final bool tighteningApplied;
  final bool tightenAfterChapter;
  final int schemaVersion;
  final List<String> reasons;
  final JsonMap metadata;

  factory LongTaskCheckpointCadencePolicy.fromJson(JsonMap json) {
    // 中文注释: cadence 合同允许稳定回读，避免 runtime/projection 再从散落字段重新拼风险节奏。
    return LongTaskCheckpointCadencePolicy(
      mode: ValueReaders.stringValue(json['mode']).trim(),
      runtimeBaselineId: ValueReaders.stringValue(
        json['runtime_baseline_id'],
      ).trim(),
      checkpointPolicy: ValueReaders.stringValue(
        json['checkpoint_policy'],
      ).trim(),
      baseCheckpointInterval: ValueReaders.intValue(
        json['base_checkpoint_interval'],
      ),
      effectiveCheckpointInterval: ValueReaders.intValue(
        json['effective_checkpoint_interval'],
      ),
      baseBatchSteps: ValueReaders.intValue(json['base_batch_steps'], 1),
      effectiveBatchSteps: ValueReaders.intValue(
        json['effective_batch_steps'],
        1,
      ),
      baseBatchSeconds: ValueReaders.intValue(json['base_batch_seconds'], 7200),
      effectiveBatchSeconds: ValueReaders.intValue(
        json['effective_batch_seconds'],
        7200,
      ),
      riskLevel: ValueReaders.stringValue(
        json['risk_level'],
        LongTaskCheckpointCadenceRiskLevels.low,
      ).trim(),
      trailingRiskCount: ValueReaders.intValue(json['trailing_risk_count']),
      tighteningApplied: ValueReaders.boolValue(json['tightening_applied']),
      tightenAfterChapter: ValueReaders.boolValue(json['tighten_after_chapter']),
      schemaVersion: ValueReaders.intValue(json['schema_version'], 1),
      reasons: ValueReaders.stringList(json['reasons']),
      metadata: ValueReaders.deepCopyMap(ValueReaders.mapValue(json['metadata'])),
    );
  }

  JsonMap toJson() {
    // 中文注释: 对外暴露时保留 base/effective 双轨字段，方便宿主解释“原本计划”和“风险收紧后”差异。
    return <String, Object?>{
      'mode': mode,
      'runtime_baseline_id': runtimeBaselineId,
      'checkpoint_policy': checkpointPolicy,
      'base_checkpoint_interval': baseCheckpointInterval,
      'effective_checkpoint_interval': effectiveCheckpointInterval,
      'base_batch_steps': baseBatchSteps,
      'effective_batch_steps': effectiveBatchSteps,
      'base_batch_seconds': baseBatchSeconds,
      'effective_batch_seconds': effectiveBatchSeconds,
      'risk_level': riskLevel,
      'trailing_risk_count': trailingRiskCount,
      'tightening_applied': tighteningApplied,
      'tighten_after_chapter': tightenAfterChapter,
      'schema_version': schemaVersion,
      'reasons': reasons,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: 基础校验只保证 cadence 合同字段自洽，不在这里重跑风险识别逻辑。
    final result = <String>[];
    if (!LongTaskCheckpointCadenceRiskLevels.knownValues.contains(riskLevel)) {
      result.add('invalid_long_task_checkpoint_cadence_risk_level');
    }
    if (baseCheckpointInterval < 0 || effectiveCheckpointInterval < 0) {
      result.add('invalid_long_task_checkpoint_cadence_interval');
    }
    if (baseBatchSteps <= 0 || effectiveBatchSteps <= 0) {
      result.add('invalid_long_task_checkpoint_cadence_batch_steps');
    }
    if (baseBatchSeconds <= 0 || effectiveBatchSeconds <= 0) {
      result.add('invalid_long_task_checkpoint_cadence_batch_seconds');
    }
    if (trailingRiskCount < 0) {
      result.add('invalid_long_task_checkpoint_cadence_trailing_risk_count');
    }
    return result;
  }
}
