import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/conversation_status_summary_item_kind.dart';
import '../models/conversation_status_summary_item_view_data.dart';
import '../models/conversation_context_projection_view_data.dart';
import '../models/conversation_status_summary_view_data.dart';
import '../models/tool_preview_mode.dart';
import '../models/workbench_conversation_view_data.dart';

class ConversationStatusSummaryViewDataService {
  const ConversationStatusSummaryViewDataService();

  ConversationStatusSummaryViewData build({
    required WorkbenchConversationViewData viewData,
  }) {
    // 中文注释: 常驻状态摘要现在只从稳定的上下文投影读数据，不再由 widget 自己猜 pressure 或 archive 语义。
    final projection = viewData.conversationContextProjection;
    if (projection == null ||
        (projection.transcriptMessageCount <= 0 &&
            projection.workingContextMessageCount <= 0 &&
            !projection.hasArchive)) {
      return const ConversationStatusSummaryViewData(items: []);
    }
    return ConversationStatusSummaryViewData(
      items: [
        _pressureItem(projection),
        _fullHistoryItem(projection),
        _archiveItem(projection),
        _workingWindowItem(projection),
      ],
    );
  }

  bool showToolDetails(WorkbenchConversationViewData viewData) {
    return ToolPreviewMode.showsDetails(viewData.toolPreviewMode);
  }

  ConversationStatusSummaryItemViewData _pressureItem(
    ConversationContextProjectionViewData projection,
  ) {
    return ConversationStatusSummaryItemViewData(
      id: 'context_pressure',
      kind: ConversationStatusSummaryItemKind.context,
      label: '压力',
      summary: projection.pressureLevelLabel,
      detail: projection.pressureSummary,
      isHighlighted:
          projection.pressureSnapshot.pressureLevel !=
          SessionContextPressureLevel.safe,
      isInteractive: false,
      isExpanded: false,
      isBusy: false,
    );
  }

  ConversationStatusSummaryItemViewData _fullHistoryItem(
    ConversationContextProjectionViewData projection,
  ) {
    return ConversationStatusSummaryItemViewData(
      id: 'context_full_history',
      kind: ConversationStatusSummaryItemKind.context,
      label: '完整历史',
      summary: projection.fullHistorySummary,
      detail: projection.fullHistoryDetail,
      isHighlighted: false,
      isInteractive: false,
      isExpanded: false,
      isBusy: false,
    );
  }

  ConversationStatusSummaryItemViewData _archiveItem(
    ConversationContextProjectionViewData projection,
  ) {
    return ConversationStatusSummaryItemViewData(
      id: 'context_archive',
      kind: ConversationStatusSummaryItemKind.context,
      label: '归档压缩',
      summary: projection.archiveSummary,
      detail: projection.archiveDetail.isEmpty
          ? '当前还没有归档压缩段。'
          : projection.archiveDetail,
      isHighlighted: projection.hasArchive,
      isInteractive: projection.hasArchive,
      isExpanded: projection.hasArchive,
      isBusy: false,
    );
  }

  ConversationStatusSummaryItemViewData _workingWindowItem(
    ConversationContextProjectionViewData projection,
  ) {
    return ConversationStatusSummaryItemViewData(
      id: 'context_working_window',
      kind: ConversationStatusSummaryItemKind.context,
      label: '工作窗口',
      summary: projection.workingWindowSummary,
      detail: projection.workingWindowDetail,
      isHighlighted: false,
      isInteractive: false,
      isExpanded: false,
      isBusy: false,
    );
  }
}
