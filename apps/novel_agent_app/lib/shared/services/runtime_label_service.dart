import 'package:novel_agent_core/novel_agent_core.dart';

class RuntimeLabelService {
  const RuntimeLabelService();

  String runtimeModeLabel(String mode) {
    switch (mode.trim()) {
      case TaskRuntimeConstants.modeSingleChapterAtomic:
        return '单章原子式';
      case TaskRuntimeConstants.modeSupervisedChapterQueue:
        return '逐章审批式';
      case TaskRuntimeConstants.modeHumanOutlineAiDraft:
        return '按大纲自动推进';
      case TaskRuntimeConstants.modeSeedToFullNovel:
        return '灵感直推长篇';
      default:
        return mode.trim().isEmpty ? '未指定模式' : mode.trim();
    }
  }

  String taskStatusLabel(String status) {
    switch (status.trim()) {
      case TaskRuntimeConstants.statusQueued:
        return '排队';
      case TaskRuntimeConstants.statusPlanning:
        return '规划';
      case TaskRuntimeConstants.statusRunning:
        return '运行中';
      case TaskRuntimeConstants.statusWaitingUser:
        return '等待确认';
      case TaskRuntimeConstants.statusPaused:
        return '已暂停';
      case TaskRuntimeConstants.statusRetrying:
        return '重试中';
      case TaskRuntimeConstants.statusSucceeded:
        return '已完成';
      case TaskRuntimeConstants.statusFailed:
        return '失败';
      case TaskRuntimeConstants.statusCancelled:
        return '已取消';
      default:
        return status.trim().isEmpty ? '待办' : status.trim();
    }
  }

  String longTaskRunStatusLabel(LongTaskRunStatus status) {
    switch (status) {
      case LongTaskRunStatus.draftingGuidance:
        return '引导中';
      case LongTaskRunStatus.readyToStart:
        return '待启动';
      case LongTaskRunStatus.running:
        return '运行中';
      case LongTaskRunStatus.waitingGate:
        return '等待关口';
      case LongTaskRunStatus.paused:
        return '已暂停';
      case LongTaskRunStatus.recovering:
        return '恢复中';
      case LongTaskRunStatus.failedManualAttention:
        return '等待人工处理';
      case LongTaskRunStatus.stopped:
        return '已停止';
    }
  }

  String longTaskRunStatusLabelById(String statusId) {
    return longTaskRunStatusLabel(LongTaskRunStatus.fromId(statusId));
  }

  String blockerLabel(String reason) {
    switch (reason.trim()) {
      case 'no_tasks':
        return '没有任务';
      case 'waiting_user':
        return '等待人工确认';
      case 'waiting_user_checkpoint':
        return '等待检查点确认';
      case 'waiting_user_choice':
        return '等待用户选项';
      case 'paused':
        return '任务已暂停';
      case 'failed':
        return '存在失败任务';
      case 'blocked_dependencies':
        return '依赖尚未完成';
      case 'no_runnable_task':
        return '没有可运行任务';
      case 'waiting_gate':
        return '等待章级关口';
      case 'step_failed':
        return '上一步执行失败';
      case 'max_steps':
        return '已到本批步数上限';
      case 'completed':
        return '本批运行完成';
      case 'manual_pause':
        return '人工暂停';
      case 'manual_attention':
      case 'failed_manual_attention':
        return '等待人工处理';
      case 'user_requested_from_station':
        return '用户在长任务站停止';
      default:
        return reason.trim().isEmpty ? '无' : reason.trim();
    }
  }

  String schedulerActionLabel(String action) {
    switch (action.trim()) {
      case 'dispatch_batch':
        return '继续推进';
      case 'await_user':
        return '等待人工处理';
      case 'await_user_resume':
        return '等待恢复';
      case 'pause_for_review':
        return '等待复核';
      case 'pause_for_failure':
        return '等待处理失败';
      case 'resume_run':
        return '可恢复';
      case 'start_new_run':
        return '可启动新运行';
      case 'finish_run':
        return '可收尾';
      case 'stop_run':
        return '准备停止';
      case 'read_only':
        return '只读查看';
      case 'disabled':
        return '未启用';
      default:
        return action.trim().isEmpty ? '空闲' : action.trim();
    }
  }

  String workerStateLabel(String state) {
    switch (state.trim()) {
      case 'ready':
        return '可运行';
      case 'blocked':
        return '受阻';
      case 'paused':
        return '已暂停';
      case 'finished':
        return '已结束';
      case 'disabled':
        return '未启用';
      case 'stopped':
        return '已停止';
      default:
        return state.trim().isEmpty ? '空闲' : state.trim();
    }
  }

  String storageStrategyLabel(ProjectStorageStrategy strategy) {
    switch (strategy) {
      case ProjectStorageStrategy.markdownProjectStore:
        return 'Markdown';
      case ProjectStorageStrategy.sqliteProjectStore:
        return 'SQLite';
    }
  }
}
