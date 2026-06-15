import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'continuous_task_lifecycle_state.dart';
import 'continuous_task_run_phase.dart';
import 'continuous_task_stop_category.dart';
import 'continuous_task_terminal_disposition.dart';

abstract final class ContinuousTaskLifecycleEventKinds {
  static const String start = 'start';
  static const String continueRun = 'continue';
  static const String pause = 'pause';
  static const String resume = 'resume';
  static const String recover = 'recover';
  static const String waitingUser = 'waiting_user';
  static const String manualAttention = 'manual_attention';
  static const String finish = 'finish';
  static const String fail = 'fail';
  static const String cancel = 'cancel';
  static const String stop = 'stop';

  static const List<String> knownValues = <String>[
    start,
    continueRun,
    pause,
    resume,
    recover,
    waitingUser,
    manualAttention,
    finish,
    fail,
    cancel,
    stop,
  ];
}

class ContinuousTaskLifecycleEvent {
  const ContinuousTaskLifecycleEvent({
    this.kind = '',
    this.fromRunPhase = '',
    this.toRunPhase = '',
    this.stopCategory = '',
    this.terminalDisposition = '',
    this.reason = '',
    this.metadata = const <String, Object?>{},
  });

  final String kind;
  final String fromRunPhase;
  final String toRunPhase;
  final String stopCategory;
  final String terminalDisposition;
  final String reason;
  final JsonMap metadata;

  bool get isTerminal =>
      toRunPhase == ContinuousTaskRunPhases.stopped &&
      kind.trim().isNotEmpty &&
      kind != ContinuousTaskLifecycleEventKinds.pause &&
      kind != ContinuousTaskLifecycleEventKinds.resume &&
      kind != ContinuousTaskLifecycleEventKinds.continueRun &&
      kind != ContinuousTaskLifecycleEventKinds.recover &&
      kind != ContinuousTaskLifecycleEventKinds.start &&
      kind != ContinuousTaskLifecycleEventKinds.waitingUser &&
      kind != ContinuousTaskLifecycleEventKinds.manualAttention;

  bool get isPauseLike =>
      kind == ContinuousTaskLifecycleEventKinds.pause ||
      kind == ContinuousTaskLifecycleEventKinds.waitingUser ||
      kind == ContinuousTaskLifecycleEventKinds.manualAttention;

  bool get isResumeLike =>
      kind == ContinuousTaskLifecycleEventKinds.resume ||
      kind == ContinuousTaskLifecycleEventKinds.continueRun ||
      kind == ContinuousTaskLifecycleEventKinds.start;

  bool get isFailureLike =>
      kind == ContinuousTaskLifecycleEventKinds.fail ||
      kind == ContinuousTaskLifecycleEventKinds.cancel ||
      kind == ContinuousTaskLifecycleEventKinds.stop;

  bool get isWaitingUserLike =>
      kind == ContinuousTaskLifecycleEventKinds.waitingUser;

  bool get isManualAttentionLike =>
      kind == ContinuousTaskLifecycleEventKinds.manualAttention;

  ContinuousTaskLifecycleEvent copyWith({
    String? kind,
    String? fromRunPhase,
    String? toRunPhase,
    String? stopCategory,
    String? terminalDisposition,
    String? reason,
    JsonMap? metadata,
  }) {
    // 中文注释: 事件对象需要稳定的 copyWith，方便把同一条生命周期事实在不同 projection 里安全补字段。
    return ContinuousTaskLifecycleEvent(
      kind: kind ?? this.kind,
      fromRunPhase: fromRunPhase ?? this.fromRunPhase,
      toRunPhase: toRunPhase ?? this.toRunPhase,
      stopCategory: stopCategory ?? this.stopCategory,
      terminalDisposition: terminalDisposition ?? this.terminalDisposition,
      reason: reason ?? this.reason,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ContinuousTaskLifecycleEvent.fromJson(JsonMap json) {
    // 中文注释: 事件反序列化允许从持久化合同直接回读，避免宿主再把 transition 语义猜回去。
    return ContinuousTaskLifecycleEvent(
      kind: ValueReaders.stringValue(json['kind']).trim(),
      fromRunPhase: ValueReaders.stringValue(json['from_run_phase']).trim(),
      toRunPhase: ValueReaders.stringValue(json['to_run_phase']).trim(),
      stopCategory: ValueReaders.stringValue(json['stop_category']).trim(),
      terminalDisposition: ValueReaders.stringValue(
        json['terminal_disposition'],
      ).trim(),
      reason: ValueReaders.stringValue(json['reason']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: 事件投影显式保留 from/to phase 与终态信息，让 watcher、supervisor 与 probe 看到同一条正式事实。
    return <String, Object?>{
      'kind': kind,
      'from_run_phase': fromRunPhase,
      'to_run_phase': toRunPhase,
      'stop_category': stopCategory,
      'terminal_disposition': terminalDisposition,
      'reason': reason,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: 这里只校验事件合同自身自洽，不在这里重写 supervisor 或 watchdog 的业务判定。
    final result = <String>[];
    if (!ContinuousTaskLifecycleEventKinds.knownValues.contains(kind)) {
      result.add('invalid_continuous_task_lifecycle_event_kind');
    }
    if (fromRunPhase.isNotEmpty &&
        !ContinuousTaskRunPhases.knownValues.contains(fromRunPhase)) {
      result.add('invalid_continuous_task_lifecycle_event_from_run_phase');
    }
    if (toRunPhase.isNotEmpty &&
        !ContinuousTaskRunPhases.knownValues.contains(toRunPhase)) {
      result.add('invalid_continuous_task_lifecycle_event_to_run_phase');
    }
    if (stopCategory.isNotEmpty &&
        !ContinuousTaskStopCategories.knownValues.contains(stopCategory)) {
      result.add('invalid_continuous_task_lifecycle_event_stop_category');
    }
    if (terminalDisposition.isNotEmpty &&
        !ContinuousTaskTerminalDispositions.knownValues.contains(
          terminalDisposition,
        )) {
      result.add('invalid_continuous_task_lifecycle_event_terminal_disposition');
    }
    if (reason.trim().isEmpty) {
      result.add('missing_continuous_task_lifecycle_event_reason');
    }
    if (_isTerminalKind(kind) && toRunPhase != ContinuousTaskRunPhases.stopped) {
      result.add('terminal_lifecycle_event_requires_stopped_phase');
    }
    if (kind == ContinuousTaskLifecycleEventKinds.waitingUser &&
        toRunPhase != ContinuousTaskRunPhases.waitingUser) {
      result.add('waiting_user_event_requires_waiting_user_phase');
    }
    if (kind == ContinuousTaskLifecycleEventKinds.manualAttention &&
        toRunPhase != ContinuousTaskRunPhases.manualAttention) {
      result.add('manual_attention_event_requires_manual_attention_phase');
    }
    if (kind == ContinuousTaskLifecycleEventKinds.pause &&
        toRunPhase != ContinuousTaskRunPhases.paused) {
      result.add('pause_event_requires_paused_phase');
    }
    if (kind == ContinuousTaskLifecycleEventKinds.recover &&
        toRunPhase != ContinuousTaskRunPhases.recovering) {
      result.add('recover_event_requires_recovering_phase');
    }
    if (kind == ContinuousTaskLifecycleEventKinds.resume &&
        toRunPhase != ContinuousTaskRunPhases.running) {
      result.add('resume_event_requires_running_phase');
    }
    if (kind == ContinuousTaskLifecycleEventKinds.continueRun &&
        toRunPhase != ContinuousTaskRunPhases.running) {
      result.add('continue_event_requires_running_phase');
    }
    if (kind == ContinuousTaskLifecycleEventKinds.start &&
        toRunPhase != ContinuousTaskRunPhases.readyToStart &&
        toRunPhase != ContinuousTaskRunPhases.running) {
      result.add('start_event_requires_initial_running_phase');
    }
    return result;
  }

  static ContinuousTaskLifecycleEvent fromTransition({
    required String fromRunPhase,
    required ContinuousTaskLifecycleState toState,
  }) {
    // 中文注释: transition 工厂把状态和前态拼成统一事件，方便 supervisor/watchdog 在同一合同里解释“为什么变成这样”。
    final cleanFromRunPhase = fromRunPhase.trim();
    final kind = _kindFromTransition(
      cleanFromRunPhase,
      toState.runPhase,
      toState.stopCategory,
      toState.terminalDisposition,
    );
    return ContinuousTaskLifecycleEvent(
      kind: kind,
      fromRunPhase: cleanFromRunPhase,
      toRunPhase: toState.runPhase,
      stopCategory: toState.stopCategory,
      terminalDisposition: toState.terminalDisposition,
      reason: _reasonFromState(toState, kind),
      metadata: <String, Object?>{
        ...ValueReaders.deepCopyMap(toState.metadata),
        'source_contract': 'continuous_task_lifecycle_state_transition',
        'event_kind': kind,
        'from_run_phase': cleanFromRunPhase,
        'to_run_phase': toState.runPhase,
      },
    );
  }

  static String _kindFromTransition(
    String fromRunPhase,
    String toRunPhase,
    String stopCategory,
    String terminalDisposition,
  ) {
    // 中文注释: 这里把状态投影回最小事件种类，避免上层为了解释流转而重复猜测调度语义。
    if (toRunPhase == ContinuousTaskRunPhases.stopped) {
      switch (terminalDisposition) {
        case ContinuousTaskTerminalDispositions.completed:
          return ContinuousTaskLifecycleEventKinds.finish;
        case ContinuousTaskTerminalDispositions.cancelled:
          return ContinuousTaskLifecycleEventKinds.cancel;
        case ContinuousTaskTerminalDispositions.failed:
          return ContinuousTaskLifecycleEventKinds.fail;
        case ContinuousTaskTerminalDispositions.stopped:
        case '':
          return ContinuousTaskLifecycleEventKinds.stop;
      }
      if (stopCategory == ContinuousTaskStopCategories.completedNaturally) {
        return ContinuousTaskLifecycleEventKinds.finish;
      }
      if (stopCategory == ContinuousTaskStopCategories.cancelled) {
        return ContinuousTaskLifecycleEventKinds.cancel;
      }
      if (stopCategory == ContinuousTaskStopCategories.technicalFailure ||
          stopCategory == ContinuousTaskStopCategories.deliveryFailure ||
          stopCategory == ContinuousTaskStopCategories.recoveryExhausted) {
        return ContinuousTaskLifecycleEventKinds.fail;
      }
      return ContinuousTaskLifecycleEventKinds.stop;
    }
    if (toRunPhase == ContinuousTaskRunPhases.waitingUser) {
      return ContinuousTaskLifecycleEventKinds.waitingUser;
    }
    if (toRunPhase == ContinuousTaskRunPhases.manualAttention) {
      return ContinuousTaskLifecycleEventKinds.manualAttention;
    }
    if (toRunPhase == ContinuousTaskRunPhases.recovering) {
      return ContinuousTaskLifecycleEventKinds.recover;
    }
    if (toRunPhase == ContinuousTaskRunPhases.paused) {
      return ContinuousTaskLifecycleEventKinds.pause;
    }
    if (toRunPhase == ContinuousTaskRunPhases.readyToStart ||
        toRunPhase == ContinuousTaskRunPhases.draftingGuidance) {
      return ContinuousTaskLifecycleEventKinds.start;
    }
    if (fromRunPhase == ContinuousTaskRunPhases.paused ||
        fromRunPhase == ContinuousTaskRunPhases.waitingUser ||
        fromRunPhase == ContinuousTaskRunPhases.manualAttention ||
        fromRunPhase == ContinuousTaskRunPhases.recovering) {
      return ContinuousTaskLifecycleEventKinds.resume;
    }
    return ContinuousTaskLifecycleEventKinds.continueRun;
  }

  static String _reasonFromState(
    ContinuousTaskLifecycleState state,
    String kind,
  ) {
    // 中文注释: 事件原因优先沿用状态里的正式 reason，只有缺失时才回落到种类名，避免空壳事件。
    final reason = state.reason.trim();
    if (reason.isNotEmpty) {
      return reason;
    }
    if (kind == ContinuousTaskLifecycleEventKinds.finish &&
        state.stopCategory.trim().isNotEmpty) {
      return state.stopCategory.trim();
    }
    if (kind == ContinuousTaskLifecycleEventKinds.fail &&
        state.stopCategory.trim().isNotEmpty) {
      return state.stopCategory.trim();
    }
    return kind;
  }

  static bool _isTerminalKind(String kind) {
    // 中文注释: 终态事件只认 finish / fail / cancel / stop 四种出口，避免后续再长出隐式终态种类。
    return kind == ContinuousTaskLifecycleEventKinds.finish ||
        kind == ContinuousTaskLifecycleEventKinds.fail ||
        kind == ContinuousTaskLifecycleEventKinds.cancel ||
        kind == ContinuousTaskLifecycleEventKinds.stop;
  }
}
