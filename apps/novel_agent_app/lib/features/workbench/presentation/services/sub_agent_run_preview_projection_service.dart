import '../models/sub_agent_run_preview_view_data.dart';
import '../models/sub_agent_run_view_data.dart';

class SubAgentRunPreviewProjectionService {
  const SubAgentRunPreviewProjectionService();

  SubAgentRunPreviewViewData build(SubAgentRunViewData run) {
    final status = _normalizeStatus(run.status);
    return SubAgentRunPreviewViewData(
      id: run.id,
      agentName: run.agentName.trim(),
      statusLabel: status.label,
      statusTone: status.tone,
      taskPreview: run.task.trim(),
      summaryPreview: _summaryPreview(run),
      toolCountLabel: '工具 ${run.toolCount}',
      isRunning: status.isRunning,
    );
  }

  _ResolvedPreviewStatus _normalizeStatus(String rawStatus) {
    final text = rawStatus.trim();
    if (text.isEmpty) {
      return const _ResolvedPreviewStatus(
        label: '待命',
        tone: SubAgentRunPreviewTone.neutral,
        isRunning: false,
      );
    }
    if (_containsAny(text, const ['失败', '异常', '中断', '取消'])) {
      return _ResolvedPreviewStatus(
        label: text,
        tone: SubAgentRunPreviewTone.danger,
        isRunning: false,
      );
    }
    if (_containsAny(text, const ['运行', '执行', '处理中', '生成中', '进行中'])) {
      return _ResolvedPreviewStatus(
        label: text,
        tone: SubAgentRunPreviewTone.active,
        isRunning: true,
      );
    }
    if (_containsAny(text, const ['完成', '已完成', '成功'])) {
      return _ResolvedPreviewStatus(
        label: text,
        tone: SubAgentRunPreviewTone.success,
        isRunning: false,
      );
    }
    return _ResolvedPreviewStatus(
      label: text,
      tone: SubAgentRunPreviewTone.neutral,
      isRunning: false,
    );
  }

  String _summaryPreview(SubAgentRunViewData run) {
    final summary = run.summary.trim();
    if (summary.isNotEmpty) {
      return summary;
    }
    for (final event in run.events.reversed) {
      final normalized = event.trim();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return '';
  }

  bool _containsAny(String text, List<String> fragments) {
    for (final fragment in fragments) {
      if (text.contains(fragment)) {
        return true;
      }
    }
    return false;
  }
}

class _ResolvedPreviewStatus {
  const _ResolvedPreviewStatus({
    required this.label,
    required this.tone,
    required this.isRunning,
  });

  final String label;
  final SubAgentRunPreviewTone tone;
  final bool isRunning;
}
