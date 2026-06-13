import '../common/json_types.dart';
import '../common/value_readers.dart';

class ContinuousTaskSupervisorProfile {
  const ContinuousTaskSupervisorProfile({
    required this.profileId,
    required this.familyId,
    this.consumesStructuredSignalsOnly = true,
    this.controlsLifecycleTransitions = true,
    this.persistsStopOutcomes = true,
    this.supportsWaitingUser = true,
    this.supportsManualAttention = true,
    this.supportsRecovery = true,
    this.supportsBudgetPause = true,
    this.supportsCancel = true,
    this.metadata = const <String, Object?>{},
  });

  final String profileId;
  final String familyId;
  final bool consumesStructuredSignalsOnly;
  final bool controlsLifecycleTransitions;
  final bool persistsStopOutcomes;
  final bool supportsWaitingUser;
  final bool supportsManualAttention;
  final bool supportsRecovery;
  final bool supportsBudgetPause;
  final bool supportsCancel;
  final JsonMap metadata;

  ContinuousTaskSupervisorProfile copyWith({
    String? profileId,
    String? familyId,
    bool? consumesStructuredSignalsOnly,
    bool? controlsLifecycleTransitions,
    bool? persistsStopOutcomes,
    bool? supportsWaitingUser,
    bool? supportsManualAttention,
    bool? supportsRecovery,
    bool? supportsBudgetPause,
    bool? supportsCancel,
    JsonMap? metadata,
  }) {
    return ContinuousTaskSupervisorProfile(
      profileId: profileId ?? this.profileId,
      familyId: familyId ?? this.familyId,
      consumesStructuredSignalsOnly:
          consumesStructuredSignalsOnly ?? this.consumesStructuredSignalsOnly,
      controlsLifecycleTransitions:
          controlsLifecycleTransitions ?? this.controlsLifecycleTransitions,
      persistsStopOutcomes: persistsStopOutcomes ?? this.persistsStopOutcomes,
      supportsWaitingUser: supportsWaitingUser ?? this.supportsWaitingUser,
      supportsManualAttention:
          supportsManualAttention ?? this.supportsManualAttention,
      supportsRecovery: supportsRecovery ?? this.supportsRecovery,
      supportsBudgetPause: supportsBudgetPause ?? this.supportsBudgetPause,
      supportsCancel: supportsCancel ?? this.supportsCancel,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ContinuousTaskSupervisorProfile.fromJson(JsonMap json) {
    return ContinuousTaskSupervisorProfile(
      profileId: ValueReaders.stringValue(json['profile_id']).trim(),
      familyId: ValueReaders.stringValue(json['family_id']).trim(),
      consumesStructuredSignalsOnly: ValueReaders.boolValue(
        json['consumes_structured_signals_only'],
        true,
      ),
      controlsLifecycleTransitions: ValueReaders.boolValue(
        json['controls_lifecycle_transitions'],
        true,
      ),
      persistsStopOutcomes: ValueReaders.boolValue(
        json['persists_stop_outcomes'],
        true,
      ),
      supportsWaitingUser: ValueReaders.boolValue(
        json['supports_waiting_user'],
        true,
      ),
      supportsManualAttention: ValueReaders.boolValue(
        json['supports_manual_attention'],
        true,
      ),
      supportsRecovery: ValueReaders.boolValue(json['supports_recovery'], true),
      supportsBudgetPause: ValueReaders.boolValue(
        json['supports_budget_pause'],
        true,
      ),
      supportsCancel: ValueReaders.boolValue(json['supports_cancel'], true),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'profile_id': profileId,
      'family_id': familyId,
      'consumes_structured_signals_only': consumesStructuredSignalsOnly,
      'controls_lifecycle_transitions': controlsLifecycleTransitions,
      'persists_stop_outcomes': persistsStopOutcomes,
      'supports_waiting_user': supportsWaitingUser,
      'supports_manual_attention': supportsManualAttention,
      'supports_recovery': supportsRecovery,
      'supports_budget_pause': supportsBudgetPause,
      'supports_cancel': supportsCancel,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (profileId.trim().isEmpty) {
      result.add('missing_continuous_task_supervisor_profile_id');
    }
    if (familyId.trim().isEmpty) {
      result.add('missing_continuous_task_supervisor_family_id');
    }
    return result;
  }
}
