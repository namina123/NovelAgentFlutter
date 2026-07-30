import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/conversation_action_handler.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/opening_agent_group_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/opening_panel_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/opening_unsupported_group_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/user_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/opening_session_panel.dart';

void main() {
  testWidgets('opening session panel uses a natural empty availability summary', (
    tester,
  ) async {
    // 中文注释: 这里专门锁住空态文案，避免 opening 面板再把内部“适配信息未返回”之类的口吻直接漏给用户。
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: OpeningSessionPanel(
            viewData: const OpeningPanelViewData(
              title: '开局继续',
              summary: '这里显示开局协作的简短提示。',
              currentGroupDisplayName: '',
              selectionHint: '',
              supportedGroups: <OpeningAgentGroupOptionViewData>[],
              unsupportedGroups: <OpeningUnsupportedGroupViewData>[],
            ),
            actionHandler: _FakeConversationActionHandler(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('暂无更多说明'), findsOneWidget);
    expect(find.text('暂未返回额外适配信息'), findsNothing);
  });
}

class _FakeConversationActionHandler implements ConversationActionHandler {
  @override
  void onAgentGroupSelected(String groupId) {}

  @override
  void onAttachmentRequested() {}

  @override
  void onConversationAgentSelected(String agentId) {}

  @override
  void onConversationSettingsRequested() {}

  @override
  void onDocumentsWorkspaceDismissRequested() {}

  @override
  void onDocumentsWorkspaceRequested() {}

  @override
  void onHistoryRequested() {}

  @override
  void onModelSelected(String modelId) {}

  @override
  void onNewSessionRequested() {}

  @override
  void onOptimizeRequested() {}

  @override
  void onPrimaryActionRequested(String actionId) {}

  @override
  void onQuickThemeRequested() {}

  @override
  void onReasoningToggleChanged(bool enabled) {}

  @override
  void onRetryLastFailedRequested() {}

  @override
  void onScreenModeRequested() {}

  @override
  void onSendRequested(String text) {}

  @override
  void onSessionHistorySelected(String sessionId) {}

  @override
  void onStopRequested() {}

  @override
  void onToolOptionsRequested() {}

  @override
  void onUserOptionSelected(UserOptionViewData option) {}

  @override
  void setForegroundBackHandler(VoidCallback? handler) {}
}
