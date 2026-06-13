import 'task_runtime_constants.dart';

class TaskTransitionService {
  bool canTransition(String currentStatus, String nextStatus) {
    // 中文注释: 状态机白名单单独封装，避免写入层、调度层和 UI 各自复制状态迁移规则。
    if (currentStatus == nextStatus) {
      return true;
    }
    if (TaskRuntimeConstants.terminalStatuses.contains(currentStatus)) {
      return false;
    }
    if (currentStatus == TaskRuntimeConstants.statusPaused) {
      return <String>[
        TaskRuntimeConstants.statusQueued,
        TaskRuntimeConstants.statusSucceeded,
        TaskRuntimeConstants.statusCancelled,
      ].contains(nextStatus);
    }
    if (currentStatus == TaskRuntimeConstants.statusFailed) {
      return <String>[
        TaskRuntimeConstants.statusRetrying,
        TaskRuntimeConstants.statusCancelled,
        TaskRuntimeConstants.statusQueued,
      ].contains(nextStatus);
    }
    if (nextStatus == TaskRuntimeConstants.statusRetrying) {
      return currentStatus == TaskRuntimeConstants.statusFailed;
    }
    return TaskRuntimeConstants.validStatuses.contains(nextStatus);
  }
}
