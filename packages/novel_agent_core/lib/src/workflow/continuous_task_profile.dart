import '../common/json_types.dart';
import '../common/value_readers.dart';

class ContinuousTaskProfile {
  const ContinuousTaskProfile({
    required this.familyId,
    required this.runKind,
    this.workflowStrategyId = '',
    this.modeId = '',
    this.supportsPause = true,
    this.supportsResume = true,
    this.supportsRetry = true,
    this.supportsRecovery = true,
    this.supportsCancel = true,
    this.usesDurableRunRecord = true,
    this.watchdogEligible = true,
    this.supervisorEligible = true,
    this.metadata = const <String, Object?>{},
  });

  final String familyId;
  final String runKind;
  final String workflowStrategyId;
  final String modeId;
  final bool supportsPause;
  final bool supportsResume;
  final bool supportsRetry;
  final bool supportsRecovery;
  final bool supportsCancel;
  final bool usesDurableRunRecord;
  final bool watchdogEligible;
  final bool supervisorEligible;
  final JsonMap metadata;

  bool get supportsLivenessControl {
    return watchdogEligible &&
        supervisorEligible &&
        usesDurableRunRecord &&
        supportsPause &&
        supportsResume;
  }

  ContinuousTaskProfile copyWith({
    String? familyId,
    String? runKind,
    String? workflowStrategyId,
    String? modeId,
    bool? supportsPause,
    bool? supportsResume,
    bool? supportsRetry,
    bool? supportsRecovery,
    bool? supportsCancel,
    bool? usesDurableRunRecord,
    bool? watchdogEligible,
    bool? supervisorEligible,
    JsonMap? metadata,
  }) {
    // 中文注释: profile copyWith 只服务合同演化与 focused tests，不在这里做 family-specific 默认推导。
    return ContinuousTaskProfile(
      familyId: familyId ?? this.familyId,
      runKind: runKind ?? this.runKind,
      workflowStrategyId: workflowStrategyId ?? this.workflowStrategyId,
      modeId: modeId ?? this.modeId,
      supportsPause: supportsPause ?? this.supportsPause,
      supportsResume: supportsResume ?? this.supportsResume,
      supportsRetry: supportsRetry ?? this.supportsRetry,
      supportsRecovery: supportsRecovery ?? this.supportsRecovery,
      supportsCancel: supportsCancel ?? this.supportsCancel,
      usesDurableRunRecord: usesDurableRunRecord ?? this.usesDurableRunRecord,
      watchdogEligible: watchdogEligible ?? this.watchdogEligible,
      supervisorEligible: supervisorEligible ?? this.supervisorEligible,
      metadata: metadata ?? this.metadata,
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'family_id': familyId,
      'run_kind': runKind,
      'workflow_strategy_id': workflowStrategyId,
      'mode_id': modeId,
      'supports_pause': supportsPause,
      'supports_resume': supportsResume,
      'supports_retry': supportsRetry,
      'supports_recovery': supportsRecovery,
      'supports_cancel': supportsCancel,
      'uses_durable_run_record': usesDurableRunRecord,
      'watchdog_eligible': watchdogEligible,
      'supervisor_eligible': supervisorEligible,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static ContinuousTaskProfile fromJson(JsonMap json) {
    // 中文注释: profile 反序列化保持宽容读取，方便后续让 reference extraction、goal mode 与 long task 共用同一稳定 JSON 合同。
    return ContinuousTaskProfile(
      familyId: ValueReaders.stringValue(json['family_id']).trim(),
      runKind: ValueReaders.stringValue(json['run_kind']).trim(),
      workflowStrategyId: ValueReaders.stringValue(
        json['workflow_strategy_id'],
      ).trim(),
      modeId: ValueReaders.stringValue(json['mode_id']).trim(),
      supportsPause: ValueReaders.boolValue(json['supports_pause'], true),
      supportsResume: ValueReaders.boolValue(json['supports_resume'], true),
      supportsRetry: ValueReaders.boolValue(json['supports_retry'], true),
      supportsRecovery: ValueReaders.boolValue(json['supports_recovery'], true),
      supportsCancel: ValueReaders.boolValue(json['supports_cancel'], true),
      usesDurableRunRecord: ValueReaders.boolValue(
        json['uses_durable_run_record'],
        true,
      ),
      watchdogEligible: ValueReaders.boolValue(json['watchdog_eligible'], true),
      supervisorEligible: ValueReaders.boolValue(
        json['supervisor_eligible'],
        true,
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (familyId.trim().isEmpty) {
      result.add('missing_continuous_task_family_id');
    }
    if (runKind.trim().isEmpty) {
      result.add('missing_continuous_task_run_kind');
    }
    return result;
  }
}
