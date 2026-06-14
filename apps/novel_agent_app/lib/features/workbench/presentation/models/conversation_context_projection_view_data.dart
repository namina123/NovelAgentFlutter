import 'package:flutter/foundation.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'conversation_context_compaction_segment_view_data.dart';

@immutable
class ConversationContextProjectionViewData {
  const ConversationContextProjectionViewData({
    required this.pressureSnapshot,
    required this.transcriptMessageCount,
    required this.workingContextMessageCount,
    required this.compactionSegments,
  });

  final SessionContextPressureSnapshot pressureSnapshot;
  final int transcriptMessageCount;
  final int workingContextMessageCount;
  final List<ConversationContextCompactionSegmentViewData> compactionSegments;

  int get archiveMessageCount => compactionSegments.fold<int>(
    0,
    (sum, segment) => sum + segment.sourceMessageCount,
  );

  bool get hasArchive => compactionSegments.isNotEmpty;

  String get pressureLevelLabel {
    // 中文注释: 压力等级在 GUI 上只呈现人话，稳定枚举留给 core contract。
    return switch (pressureSnapshot.pressureLevel) {
      SessionContextPressureLevel.safe => '安全',
      SessionContextPressureLevel.warning => '预警',
      SessionContextPressureLevel.critical => '紧张',
      SessionContextPressureLevel.overLimit => '越界',
    };
  }

  String get pressureSummary {
    // 中文注释: 压力摘要保留 token 口径和剩余量，让用户知道系统为何需要压缩。
    final used = _formatTokens(pressureSnapshot.estimate.totalInputTokens);
    final budget = _formatTokens(pressureSnapshot.inputBudgetTokens);
    final remaining = _formatTokens(
      pressureSnapshot.remainingInputTokens.abs(),
    );
    if (pressureSnapshot.hasOverflow) {
      return '$pressureLevelLabel · 已用 $used / $budget · 超出 $remaining';
    }
    final ratio = (pressureSnapshot.usedContextRatio * 100).round();
    return '$pressureLevelLabel · 已用 $used / $budget · 占用 $ratio%';
  }

  String get fullHistorySummary {
    // 中文注释: 完整历史只输出总消息数，避免把 transcript 再投影成一段很长的概览。
    return '$transcriptMessageCount 条';
  }

  String get archiveSummary {
    // 中文注释: 归档摘要同时保留“段数”和“压缩掉了多少来源消息”，方便用户理解折叠规模。
    if (!hasArchive) {
      return '未归档';
    }
    return '${compactionSegments.length} 段 / ${archiveMessageCount} 条';
  }

  String get workingWindowSummary {
    // 中文注释: 工作窗口摘要只保留当前实际送给模型的消息条数，避免和完整历史混淆。
    return '$workingContextMessageCount 条';
  }

  String get headlineSummary {
    // 中文注释: 头部摘要用于紧凑徽标，单行讲清压力、完整历史、归档和当前窗口四层事实。
    return '压力 $pressureSummary · 完整历史 $fullHistorySummary · 归档 $archiveSummary · 工作窗口 $workingWindowSummary';
  }

  String get archiveDetail {
    // 中文注释: 归档详情把最近几个压缩段的主题与来源规模串起来，供折叠面板和时间线条目复用。
    if (!hasArchive) {
      return '';
    }
    final lines = <String>[];
    for (final segment in compactionSegments) {
      final roleSummary = segment.sourceMessageRoles.isEmpty
          ? ''
          : ' · 角色 ${segment.sourceMessageRoles.join(' / ')}';
      lines.add(
        '${segment.title.isEmpty ? '归档段' : segment.title}：'
        '${segment.sourceSummary}$roleSummary',
      );
    }
    return lines.join('\n');
  }

  String get workingWindowDetail {
    // 中文注释: 当前工作窗口详情只描述“模型正在看什么”，不把完整历史重新铺开。
    return '当前工作窗口保留最近 $workingContextMessageCount 条消息，将直接参与下一次模型发送。';
  }

  String get fullHistoryDetail {
    // 中文注释: 完整历史详情只讲清“全量还在”，不在 GUI 里二次展开正文。
    return '完整转录共保留 $transcriptMessageCount 条消息，其中归档 $archiveSummary，当前工作窗口 $workingWindowSummary。';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ConversationContextProjectionViewData &&
            other.pressureSnapshot == pressureSnapshot &&
            other.transcriptMessageCount == transcriptMessageCount &&
            other.workingContextMessageCount == workingContextMessageCount &&
            listEquals(other.compactionSegments, compactionSegments);
  }

  @override
  int get hashCode => Object.hash(
    pressureSnapshot,
    transcriptMessageCount,
    workingContextMessageCount,
    Object.hashAll(compactionSegments),
  );

  String _formatTokens(int tokens) {
    // 中文注释: token 展示只做轻量千位分隔，方便用户直接扫一眼规模。
    final clean = tokens < 0 ? 0 : tokens;
    return clean.toString();
  }
}
