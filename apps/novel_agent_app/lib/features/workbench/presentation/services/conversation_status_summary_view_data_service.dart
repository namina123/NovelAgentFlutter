import '../models/conversation_status_summary_view_data.dart';
import '../models/tool_preview_mode.dart';
import '../models/workbench_conversation_view_data.dart';

class ConversationStatusSummaryViewDataService {
  const ConversationStatusSummaryViewDataService();

  ConversationStatusSummaryViewData build({
    required WorkbenchConversationViewData viewData,
  }) {
    // 中文注释: 常驻状态摘要在当前工作台里噪音大于收益，因此默认不生成，时间线和输入区只保留真正的运行反馈。
    return const ConversationStatusSummaryViewData(items: []);
  }

  bool showToolDetails(WorkbenchConversationViewData viewData) {
    return ToolPreviewMode.showsDetails(viewData.toolPreviewMode);
  }
}
