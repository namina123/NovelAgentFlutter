import '../common/json_types.dart';
import '../common/value_readers.dart';

class ContinuousTaskWatchdogProfile {
  const ContinuousTaskWatchdogProfile({
    required this.profileId,
    required this.familyId,
    this.requiresHeartbeat = true,
    this.usesDurableLease = true,
    this.reconcilesOrphanDispatch = true,
    this.pauseStopsWakeups = true,
    this.resumeRequiresSupervisorDispatch = true,
    this.lowFrequency = true,
    this.singleActiveWorker = true,
    this.metadata = const <String, Object?>{},
  });

  final String profileId;
  final String familyId;
  final bool requiresHeartbeat;
  final bool usesDurableLease;
  final bool reconcilesOrphanDispatch;
  final bool pauseStopsWakeups;
  final bool resumeRequiresSupervisorDispatch;
  final bool lowFrequency;
  final bool singleActiveWorker;
  final JsonMap metadata;

  ContinuousTaskWatchdogProfile copyWith({
    String? profileId,
    String? familyId,
    bool? requiresHeartbeat,
    bool? usesDurableLease,
    bool? reconcilesOrphanDispatch,
    bool? pauseStopsWakeups,
    bool? resumeRequiresSupervisorDispatch,
    bool? lowFrequency,
    bool? singleActiveWorker,
    JsonMap? metadata,
  }) {
    return ContinuousTaskWatchdogProfile(
      profileId: profileId ?? this.profileId,
      familyId: familyId ?? this.familyId,
      requiresHeartbeat: requiresHeartbeat ?? this.requiresHeartbeat,
      usesDurableLease: usesDurableLease ?? this.usesDurableLease,
      reconcilesOrphanDispatch:
          reconcilesOrphanDispatch ?? this.reconcilesOrphanDispatch,
      pauseStopsWakeups: pauseStopsWakeups ?? this.pauseStopsWakeups,
      resumeRequiresSupervisorDispatch:
          resumeRequiresSupervisorDispatch ??
          this.resumeRequiresSupervisorDispatch,
      lowFrequency: lowFrequency ?? this.lowFrequency,
      singleActiveWorker: singleActiveWorker ?? this.singleActiveWorker,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ContinuousTaskWatchdogProfile.fromJson(JsonMap json) {
    return ContinuousTaskWatchdogProfile(
      profileId: ValueReaders.stringValue(json['profile_id']).trim(),
      familyId: ValueReaders.stringValue(json['family_id']).trim(),
      requiresHeartbeat: ValueReaders.boolValue(
        json['requires_heartbeat'],
        true,
      ),
      usesDurableLease: ValueReaders.boolValue(
        json['uses_durable_lease'],
        true,
      ),
      reconcilesOrphanDispatch: ValueReaders.boolValue(
        json['reconciles_orphan_dispatch'],
        true,
      ),
      pauseStopsWakeups: ValueReaders.boolValue(
        json['pause_stops_wakeups'],
        true,
      ),
      resumeRequiresSupervisorDispatch: ValueReaders.boolValue(
        json['resume_requires_supervisor_dispatch'],
        true,
      ),
      lowFrequency: ValueReaders.boolValue(json['low_frequency'], true),
      singleActiveWorker: ValueReaders.boolValue(
        json['single_active_worker'],
        true,
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'profile_id': profileId,
      'family_id': familyId,
      'requires_heartbeat': requiresHeartbeat,
      'uses_durable_lease': usesDurableLease,
      'reconciles_orphan_dispatch': reconcilesOrphanDispatch,
      'pause_stops_wakeups': pauseStopsWakeups,
      'resume_requires_supervisor_dispatch': resumeRequiresSupervisorDispatch,
      'low_frequency': lowFrequency,
      'single_active_worker': singleActiveWorker,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (profileId.trim().isEmpty) {
      result.add('missing_continuous_task_watchdog_profile_id');
    }
    if (familyId.trim().isEmpty) {
      result.add('missing_continuous_task_watchdog_family_id');
    }
    return result;
  }
}
