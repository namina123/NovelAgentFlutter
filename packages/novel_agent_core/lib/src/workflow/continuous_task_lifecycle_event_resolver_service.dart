import 'continuous_task_lifecycle_event.dart';
import 'continuous_task_lifecycle_state.dart';

class ContinuousTaskLifecycleEventResolverService {
  const ContinuousTaskLifecycleEventResolverService();

  ContinuousTaskLifecycleEvent fromTransition({
    required String fromRunPhase,
    required ContinuousTaskLifecycleState toState,
  }) {
    // 中文注释: resolver 只负责把 transition 事实投影成统一事件合同，不在这里额外补调度策略。
    return ContinuousTaskLifecycleEvent.fromTransition(
      fromRunPhase: fromRunPhase,
      toState: toState,
    );
  }
}

