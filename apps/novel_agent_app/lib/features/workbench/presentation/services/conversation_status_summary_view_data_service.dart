import '../models/conversation_status_summary_view_data.dart';
import '../models/tool_preview_mode.dart';
import '../models/workbench_conversation_view_data.dart';

class ConversationStatusSummaryViewDataService {
  const ConversationStatusSummaryViewDataService();

  ConversationStatusSummaryViewData build({
    required WorkbenchConversationViewData viewData,
  }) {
    // 中文注释: 工具状态 chips 已退出主界面；这里保留空投影，避免未来重新接入时再改调用边界。
    return const ConversationStatusSummaryViewData(items: []);
  }

  bool showToolDetails(WorkbenchConversationViewData viewData) {
    return ToolPreviewMode.showsDetails(viewData.toolPreviewMode);
  }
}
