import 'package:novel_agent_core/novel_agent_core.dart';

class StopDiagnosisTextService {
  const StopDiagnosisTextService();

  String renderGenericReasonLine(String code) {
    // 中文注释: 通用停止原因文案统一在这里映射，避免 run center / narrative 各自重复维护同一批停点文案。
    final label = _stopReasonLabel(code);
    if (label.isEmpty || label == code.trim()) {
      return '停止原因：$code';
    }
    return '停止原因：$label（$code）';
  }

  String renderDiagnosisLine(LongTaskStopDiagnosisProjection projection) {
    // 中文注释: 已投影的 stop diagnosis 优先直接渲染，CLI 不再自己推断运行状态。
    final label = projection.label.trim();
    final code = projection.code.trim();
    if (label.isEmpty) {
      return code.isEmpty ? '' : '停止原因：$code';
    }
    if (code.isEmpty || code == label) {
      return '停止原因：$label';
    }
    return '停止原因：$label（$code）';
  }

  String renderReferenceLifecycleLabel(ContinuousTaskLifecycleState lifecycle) {
    // 中文注释: 参考提取运行态文案也只做壳层映射，确保和生产层 lifecycle reason 保持同源。
    switch (lifecycle.reason.trim()) {
      case 'completed_publishable':
        return '已完成';
      case 'reference_coverage_followup_required':
        return '覆盖未完成';
      case 'reference_mount_confirmation_required':
        return '挂载等待确认';
      case 'reference_mount_incomplete':
        return '挂载未完成';
      case 'reference_continuity_conflict_requires_review':
        return '连续性待复核';
      default:
        return switch (lifecycle.runPhase) {
          ContinuousTaskRunPhases.running => '运行中',
          ContinuousTaskRunPhases.paused => '已暂停',
          ContinuousTaskRunPhases.waitingUser => '等待用户',
          ContinuousTaskRunPhases.manualAttention => '需人工处理',
          ContinuousTaskRunPhases.recovering => '恢复中',
          ContinuousTaskRunPhases.stopped => '已停止',
          _ => lifecycle.reason.trim().isEmpty ? '状态待确认' : lifecycle.reason,
        };
    }
  }

  String renderReferenceStopReasonLine(String reason) {
    // 中文注释: 参考提取的停止原因保持和生产生命周期理由同源，不在 CLI 层另造解释。
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      return '';
    }
    final label = switch (cleanReason) {
      'completed_publishable' => 'publishable 结果已完成',
      'reference_coverage_followup_required' => '覆盖不足，需继续提取',
      'reference_mount_confirmation_required' => '挂载需要显式确认',
      'reference_mount_incomplete' => '项目挂载未完成',
      'reference_continuity_conflict_requires_review' => '连续性冲突需要人工复核',
      _ => cleanReason,
    };
    return label == cleanReason
        ? '停止原因：$cleanReason'
        : '停止原因：$label（$cleanReason）';
  }

  String _stopReasonLabel(String code) {
    switch (code.trim()) {
      case 'max_steps':
      case 'max_seconds':
        return '预算边界已到';
      case 'completed':
      case 'no_runnable_task':
        return '当前目标已收尾';
      case 'waiting_user':
      case 'waiting_user_checkpoint':
      case 'waiting_user_choice':
      case 'waiting_gate':
      case 'information_waiting_user':
      case 'delivery_waiting_user_choice':
        return '等待用户确认';
      case 'failed_task':
      case 'delivery_repair_required':
      case 'information_repair_required':
        return '需修补后继续';
      case 'delivery_manual_attention':
      case 'content_quality_failed':
      case 'semantic_review_manual_attention':
      case 'chapter_gate_manual_attention':
        return '内容质量关口';
      case 'failed':
      case 'step_failed':
      case 'record_missing':
      case 'stale_running_task':
        return '技术失败';
      default:
        return code.trim();
    }
  }
}
