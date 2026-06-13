import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'continuous_task_run_phase.dart';
import 'continuous_task_stop_category.dart';
import 'continuous_task_terminal_disposition.dart';

class ContinuousTaskLifecycleState {
  const ContinuousTaskLifecycleState({
    this.runPhase = ContinuousTaskRunPhases.readyToStart,
    this.terminalDisposition = '',
    this.stopCategory = '',
    this.reason = '',
    this.metadata = const <String, Object?>{},
  });

  final String runPhase;
  final String terminalDisposition;
  final String stopCategory;
  final String reason;
  final JsonMap metadata;

  bool get isTerminal => runPhase == ContinuousTaskRunPhases.stopped;
  bool get isPausedLike =>
      runPhase == ContinuousTaskRunPhases.paused ||
      runPhase == ContinuousTaskRunPhases.waitingUser ||
      runPhase == ContinuousTaskRunPhases.manualAttention;
  bool get requiresUserAction =>
      runPhase == ContinuousTaskRunPhases.waitingUser;
  bool get requiresManualAttention =>
      runPhase == ContinuousTaskRunPhases.manualAttention;

  ContinuousTaskLifecycleState copyWith({
    String? runPhase,
    String? terminalDisposition,
    String? stopCategory,
    String? reason,
    JsonMap? metadata,
  }) {
    return ContinuousTaskLifecycleState(
      runPhase: runPhase ?? this.runPhase,
      terminalDisposition: terminalDisposition ?? this.terminalDisposition,
      stopCategory: stopCategory ?? this.stopCategory,
      reason: reason ?? this.reason,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ContinuousTaskLifecycleState.fromJson(JsonMap json) {
    return ContinuousTaskLifecycleState(
      runPhase: ValueReaders.stringValue(json['run_phase']).trim(),
      terminalDisposition: ValueReaders.stringValue(
        json['terminal_disposition'],
      ).trim(),
      stopCategory: ValueReaders.stringValue(json['stop_category']).trim(),
      reason: ValueReaders.stringValue(json['reason']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'run_phase': runPhase,
      'terminal_disposition': terminalDisposition,
      'stop_category': stopCategory,
      'reason': reason,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (!ContinuousTaskRunPhases.knownValues.contains(runPhase)) {
      result.add('invalid_continuous_task_run_phase');
    }
    if (terminalDisposition.isNotEmpty &&
        !ContinuousTaskTerminalDispositions.knownValues.contains(
          terminalDisposition,
        )) {
      result.add('invalid_continuous_task_terminal_disposition');
    }
    if (stopCategory.isNotEmpty &&
        !ContinuousTaskStopCategories.knownValues.contains(stopCategory)) {
      result.add('invalid_continuous_task_stop_category');
    }
    if (terminalDisposition.isNotEmpty &&
        runPhase != ContinuousTaskRunPhases.stopped) {
      result.add('continuous_task_terminal_disposition_requires_stopped_phase');
    }
    if (terminalDisposition == ContinuousTaskTerminalDispositions.completed &&
        stopCategory.isNotEmpty &&
        stopCategory != ContinuousTaskStopCategories.completedNaturally) {
      result.add('completed_terminal_requires_completion_stop_category');
    }
    if (terminalDisposition == ContinuousTaskTerminalDispositions.cancelled &&
        stopCategory.isNotEmpty &&
        stopCategory != ContinuousTaskStopCategories.cancelled) {
      result.add('cancelled_terminal_requires_cancelled_stop_category');
    }
    if (terminalDisposition == ContinuousTaskTerminalDispositions.failed &&
        (stopCategory == ContinuousTaskStopCategories.completedNaturally ||
            stopCategory == ContinuousTaskStopCategories.cancelled)) {
      result.add('failed_terminal_cannot_use_non_failure_stop_category');
    }
    return result;
  }
}
