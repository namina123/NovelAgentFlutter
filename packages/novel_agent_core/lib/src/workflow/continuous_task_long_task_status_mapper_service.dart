import '../runtime/long_task_run_status.dart';
import 'continuous_task_lifecycle_state.dart';
import 'continuous_task_run_phase.dart';

class ContinuousTaskLongTaskStatusMapperService {
  const ContinuousTaskLongTaskStatusMapperService();

  LongTaskRunStatus toLongTaskStatus(ContinuousTaskLifecycleState state) {
    switch (state.runPhase) {
      case ContinuousTaskRunPhases.draftingGuidance:
        return LongTaskRunStatus.draftingGuidance;
      case ContinuousTaskRunPhases.readyToStart:
        return LongTaskRunStatus.readyToStart;
      case ContinuousTaskRunPhases.running:
        return LongTaskRunStatus.running;
      case ContinuousTaskRunPhases.waitingUser:
        return LongTaskRunStatus.waitingGate;
      case ContinuousTaskRunPhases.paused:
        return LongTaskRunStatus.paused;
      case ContinuousTaskRunPhases.recovering:
        return LongTaskRunStatus.recovering;
      case ContinuousTaskRunPhases.manualAttention:
        return LongTaskRunStatus.failedManualAttention;
      case ContinuousTaskRunPhases.stopped:
        return LongTaskRunStatus.stopped;
    }
    return LongTaskRunStatus.draftingGuidance;
  }
}
