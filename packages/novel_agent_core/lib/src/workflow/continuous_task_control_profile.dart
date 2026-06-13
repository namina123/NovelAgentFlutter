import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'continuous_task_profile.dart';
import 'continuous_task_run_phase.dart';
import 'continuous_task_stop_category.dart';
import 'continuous_task_supervisor_profile.dart';
import 'continuous_task_watchdog_profile.dart';

class ContinuousTaskControlProfile {
  const ContinuousTaskControlProfile({
    required this.taskProfile,
    required this.watchdogProfile,
    required this.supervisorProfile,
    this.supportedRunPhases = const <String>[],
    this.supportedStopCategories = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final ContinuousTaskProfile taskProfile;
  final ContinuousTaskWatchdogProfile watchdogProfile;
  final ContinuousTaskSupervisorProfile supervisorProfile;
  final List<String> supportedRunPhases;
  final List<String> supportedStopCategories;
  final JsonMap metadata;

  bool get supportsStructuredPauseLifecycle =>
      taskProfile.supportsPause &&
      taskProfile.supportsResume &&
      watchdogProfile.pauseStopsWakeups &&
      supervisorProfile.controlsLifecycleTransitions;

  ContinuousTaskControlProfile copyWith({
    ContinuousTaskProfile? taskProfile,
    ContinuousTaskWatchdogProfile? watchdogProfile,
    ContinuousTaskSupervisorProfile? supervisorProfile,
    List<String>? supportedRunPhases,
    List<String>? supportedStopCategories,
    JsonMap? metadata,
  }) {
    return ContinuousTaskControlProfile(
      taskProfile: taskProfile ?? this.taskProfile,
      watchdogProfile: watchdogProfile ?? this.watchdogProfile,
      supervisorProfile: supervisorProfile ?? this.supervisorProfile,
      supportedRunPhases: supportedRunPhases ?? this.supportedRunPhases,
      supportedStopCategories:
          supportedStopCategories ?? this.supportedStopCategories,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ContinuousTaskControlProfile.fromJson(JsonMap json) {
    return ContinuousTaskControlProfile(
      taskProfile: ContinuousTaskProfile.fromJson(
        ValueReaders.mapValue(json['task_profile']),
      ),
      watchdogProfile: ContinuousTaskWatchdogProfile.fromJson(
        ValueReaders.mapValue(json['watchdog_profile']),
      ),
      supervisorProfile: ContinuousTaskSupervisorProfile.fromJson(
        ValueReaders.mapValue(json['supervisor_profile']),
      ),
      supportedRunPhases: ValueReaders.stringList(json['supported_run_phases']),
      supportedStopCategories: ValueReaders.stringList(
        json['supported_stop_categories'],
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'task_profile': taskProfile.toJson(),
      'watchdog_profile': watchdogProfile.toJson(),
      'supervisor_profile': supervisorProfile.toJson(),
      'supported_run_phases': List<String>.from(supportedRunPhases),
      'supported_stop_categories': List<String>.from(supportedStopCategories),
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[
      ...taskProfile.validateBasics(),
      ...watchdogProfile.validateBasics(),
      ...supervisorProfile.validateBasics(),
    ];
    if (taskProfile.familyId != watchdogProfile.familyId) {
      result.add('continuous_task_watchdog_family_mismatch');
    }
    if (taskProfile.familyId != supervisorProfile.familyId) {
      result.add('continuous_task_supervisor_family_mismatch');
    }
    if (!supportedRunPhases.every(
      ContinuousTaskRunPhases.knownValues.contains,
    )) {
      result.add('invalid_continuous_task_supported_run_phase');
    }
    if (!supportedStopCategories.every(
      ContinuousTaskStopCategories.knownValues.contains,
    )) {
      result.add('invalid_continuous_task_supported_stop_category');
    }
    return result;
  }
}
