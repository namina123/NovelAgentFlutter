import '../models/user_option_view_data.dart';

abstract class ConversationActionHandler {
  void onModelSelected(String modelId);

  void onAgentSelected(String agentId);

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

  void onSendRequested(String text);
}
