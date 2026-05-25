import 'long_task_run_status.dart';
import 'run_instance.dart';

class LongTaskRunStateMachine {
  const LongTaskRunStateMachine();

  bool canTransition(LongTaskRunStatus current, LongTaskRunStatus next) {
    if (current == next) {
      return true;
    }
    return allowedNextStatuses(current).contains(next);
  }

  List<LongTaskRunStatus> allowedNextStatuses(LongTaskRunStatus current) {
    // 中文注释: 这里先立最小全局状态机边界，只表达运行态推进，不掺自动恢复或宿主生命周期细节。
    switch (current) {
      case LongTaskRunStatus.draftingGuidance:
        return const <LongTaskRunStatus>[
          LongTaskRunStatus.readyToStart,
          LongTaskRunStatus.paused,
          LongTaskRunStatus.stopped,
        ];
      case LongTaskRunStatus.readyToStart:
        return const <LongTaskRunStatus>[
          LongTaskRunStatus.running,
          LongTaskRunStatus.paused,
          LongTaskRunStatus.stopped,
        ];
      case LongTaskRunStatus.running:
        return const <LongTaskRunStatus>[
          LongTaskRunStatus.waitingGate,
          LongTaskRunStatus.paused,
          LongTaskRunStatus.recovering,
          LongTaskRunStatus.failedManualAttention,
          LongTaskRunStatus.stopped,
        ];
      case LongTaskRunStatus.waitingGate:
        return const <LongTaskRunStatus>[
          LongTaskRunStatus.running,
          LongTaskRunStatus.paused,
          LongTaskRunStatus.failedManualAttention,
          LongTaskRunStatus.stopped,
        ];
      case LongTaskRunStatus.paused:
        return const <LongTaskRunStatus>[
          LongTaskRunStatus.running,
          LongTaskRunStatus.recovering,
          LongTaskRunStatus.stopped,
        ];
      case LongTaskRunStatus.recovering:
        return const <LongTaskRunStatus>[
          LongTaskRunStatus.running,
          LongTaskRunStatus.paused,
          LongTaskRunStatus.failedManualAttention,
          LongTaskRunStatus.stopped,
        ];
      case LongTaskRunStatus.failedManualAttention:
        return const <LongTaskRunStatus>[
          LongTaskRunStatus.paused,
          LongTaskRunStatus.recovering,
          LongTaskRunStatus.running,
          LongTaskRunStatus.stopped,
        ];
      case LongTaskRunStatus.stopped:
        return const <LongTaskRunStatus>[];
    }
  }

  RunInstance transition(
    RunInstance instance,
    LongTaskRunStatus next, {
    DateTime? occurredAt,
    String note = '',
    String stopReason = '',
  }) {
    if (!canTransition(instance.status, next)) {
      throw StateError(
        'Invalid long task run transition: ${instance.status.id} -> ${next.id}',
      );
    }
    final now = occurredAt ?? DateTime.now();
    return instance.copyWith(
      status: next,
      updatedAt: now,
      startedAt: _startedAtAfter(instance, next, now),
      clearStartedAt: false,
      stoppedAt: _stoppedAtAfter(instance, next, now),
      clearStoppedAt: next != LongTaskRunStatus.stopped,
      note: note.trim().isEmpty ? instance.note : note.trim(),
      stopReason: next == LongTaskRunStatus.stopped ? stopReason.trim() : '',
    );
  }

  DateTime? _startedAtAfter(
    RunInstance instance,
    LongTaskRunStatus next,
    DateTime now,
  ) {
    if (instance.startedAt != null) {
      return instance.startedAt;
    }
    return next == LongTaskRunStatus.running ? now : null;
  }

  DateTime? _stoppedAtAfter(
    RunInstance instance,
    LongTaskRunStatus next,
    DateTime now,
  ) {
    if (next == LongTaskRunStatus.stopped) {
      return now;
    }
    return null;
  }
}
