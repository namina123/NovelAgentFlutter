import '../models/user_option_view_data.dart';

abstract class ConversationActionHandler {
  void onModelSelected(String modelId);

  void onAgentGroupSelected(String groupId);

  void onConversationAgentSelected(String agentId);

  void onQuickThemeRequested();

  void onScreenModeRequested();

  void onDocumentsWorkspaceRequested();

  void onDocumentsWorkspaceDismissRequested();

  void onHistoryRequested();

  void onNewSessionRequested();

  void onSessionHistorySelected(String sessionId);

  void onUserOptionSelected(UserOptionViewData option);

  void onConversationSettingsRequested();

  void onPrimaryActionRequested(String actionId);

  void onRetryLastFailedRequested();

  void onOptimizeRequested();

  void onToolOptionsRequested();

  void onReasoningToggleChanged(bool enabled);

  void onStopRequested();

  void onAttachmentRequested();

  void onSendRequested(String text);

  /// 中文注释: 前台界面（如子智能体运行全屏）注册"接管系统返回键"的回调。
  /// 传非空时，系统返回键先交给它（用于关闭全屏，而不是退出应用）；传 null 取消接管。
  /// 子智能体全屏等本地态由此对壳层的返回键可见，无需把本地态搬到视图数据。
  void setForegroundBackHandler(void Function()? handler);
}
