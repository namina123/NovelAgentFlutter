import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/application/services/workbench_pane_view_data_mapper_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/conversation_action_handler.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_group_selector_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_input_capability_context.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/opening_agent_group_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/opening_panel_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/selector_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/user_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/conversation_sidebar.dart';
import 'package:novel_agent_app/shared/widgets/panel_surface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'conversation sidebar shows public stop action and keeps attachment hidden',
    (tester) async {
      _setViewport(tester);
      await tester.pumpWidget(
        _buildSidebarHost(
          const ValueKey<String>('wr17_stop_sidebar'),
          WorkbenchViewData.initial().copyWith(
            projectPath: 'D:/projects/wr17_probe',
            isGenerating: true,
            generationStatus: '正在请求模型生成内容...',
            groupSelector: const ConversationGroupSelectorViewData(
              currentGroupLabel: '长篇总控组',
              groupOptions: <SelectorOptionViewData>[],
              primaryAgentLabel: '综合创作智能体',
              primaryAgentDescription: '负责统筹当前长篇协作。',
              canSwitchGroup: false,
            ),
            inputCapabilityContext: const ConversationInputCapabilityContext(
              hasActiveProject: true,
              isGenerating: true,
              hostSupportsAttachmentPicking: true,
              modelSupportsReasoning: true,
              modelSupportsFileAttachments: true,
              modelSupportsImageAttachments: false,
              modelSupportsAttachmentUrlsOnly: false,
              modelSupportsMultiAttachments: false,
              collaborationSupportsReasoning: true,
              collaborationSupportsAttachments: true,
              collaborationSupportsToolOptions: false,
              reasoningEnabled: true,
              productExposesReasoningToggle: true,
              productExposesAttachmentEntry: false,
              productExposesStopAction: true,
              productExposesToolOptionsAction: false,
              productExposesOptimizeAction: false,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('停止'), findsOneWidget);
      expect(find.text('发送'), findsNothing);
      expect(find.text('附件'), findsNothing);
    },
  );

  testWidgets(
    'conversation sidebar hides reasoning toggle when model does not support it',
    (tester) async {
      _setViewport(tester);
      await tester.pumpWidget(
        _buildSidebarHost(
          const ValueKey<String>('wr17_no_reasoning_sidebar'),
          WorkbenchViewData.initial().copyWith(
            projectPath: 'D:/projects/wr17_probe',
            groupSelector: const ConversationGroupSelectorViewData(
              currentGroupLabel: '默认小说开局',
              groupOptions: <SelectorOptionViewData>[],
              primaryAgentLabel: '综合创作智能体',
              primaryAgentDescription: '负责统筹当前小说协作。',
              canSwitchGroup: false,
            ),
            inputCapabilityContext: const ConversationInputCapabilityContext(
              hasActiveProject: true,
              isGenerating: false,
              hostSupportsAttachmentPicking: true,
              modelSupportsReasoning: false,
              modelSupportsFileAttachments: true,
              modelSupportsImageAttachments: false,
              modelSupportsAttachmentUrlsOnly: false,
              modelSupportsMultiAttachments: false,
              collaborationSupportsReasoning: true,
              collaborationSupportsAttachments: true,
              collaborationSupportsToolOptions: false,
              reasoningEnabled: false,
              productExposesReasoningToggle: true,
              productExposesAttachmentEntry: false,
              productExposesStopAction: true,
              productExposesToolOptionsAction: false,
              productExposesOptimizeAction: false,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('深度思考'), findsNothing);
      expect(find.byType(Switch), findsNothing);
    },
  );

  testWidgets('captures WR-17 regression screenshots', (tester) async {
    _setViewport(tester);
    await tester.pumpWidget(
      _buildSidebarHost(
        const ValueKey<String>('wr17_long_task_sidebar'),
        WorkbenchViewData.initial().copyWith(
          projectPath: 'D:/projects/wr17_long_task',
          workflowTitle: '长任务开局',
          workflowDescription: '当前仍需补充少量长任务开局信息。',
          primaryActions: const [
            PrimaryActionViewData(
              id: 'opening.launch_long_task',
              title: '启动长任务',
              description: '继续补齐当前长任务开局信息；条件收束后会直接进入正式任务链。',
              commandId: 'opening.launch_long_task',
            ),
          ],
          groupSelector: const ConversationGroupSelectorViewData(
            currentGroupLabel: '默认长任务开局',
            groupOptions: <SelectorOptionViewData>[
              SelectorOptionViewData(
                id: 'starter_long_novel_generalist',
                label: '默认长任务开局',
              ),
            ],
            primaryAgentLabel: '综合创作智能体',
            primaryAgentDescription: '负责统筹当前长篇协作。',
            canSwitchGroup: true,
          ),
          openingPanel: const OpeningPanelViewData(
            title: '项目智能体组',
            summary: '当前默认组：默认长任务开局。仍需补充：缺少长任务模式。',
            currentGroupDisplayName: '默认长任务开局',
            selectionHint: '默认只显示当前项目可直接使用的智能体组。',
            supportedGroups: [
              OpeningAgentGroupOptionViewData(
                groupId: 'starter_long_novel_generalist',
                displayName: '默认长任务开局',
                description: '负责长篇开局与节奏收束。',
                isCurrent: true,
                isDegraded: false,
                isStarterGroup: true,
              ),
            ],
            unsupportedGroups: [],
          ),
          inputCapabilityContext: const ConversationInputCapabilityContext(
            hasActiveProject: true,
            isGenerating: false,
            hostSupportsAttachmentPicking: true,
            modelSupportsReasoning: true,
            modelSupportsFileAttachments: true,
            modelSupportsImageAttachments: false,
            modelSupportsAttachmentUrlsOnly: false,
            modelSupportsMultiAttachments: false,
            collaborationSupportsReasoning: true,
            collaborationSupportsAttachments: true,
            collaborationSupportsToolOptions: false,
            reasoningEnabled: true,
            productExposesReasoningToggle: true,
            productExposesAttachmentEntry: false,
            productExposesStopAction: true,
            productExposesToolOptionsAction: false,
            productExposesOptimizeAction: false,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await expectLater(
      find.byKey(const ValueKey<String>('wr17_long_task_sidebar')),
      matchesGoldenFile(
        '../../../artifacts/wr17_screenshots/wr17_long_task_opening.png',
      ),
    );
    await tester.pumpWidget(
      _buildSidebarHost(
        const ValueKey<String>('wr17_stop_capture_sidebar'),
        WorkbenchViewData.initial().copyWith(
          projectPath: 'D:/projects/wr17_probe',
          isGenerating: true,
          generationStatus: '正在停止当前生成...',
          conversationEntries: const [],
          workflowTitle: '开始会话',
          workflowDescription: '当前请求正在停止。',
          groupSelector: const ConversationGroupSelectorViewData(
            currentGroupLabel: '长篇总控组',
            groupOptions: <SelectorOptionViewData>[],
            primaryAgentLabel: '综合创作智能体',
            primaryAgentDescription: '负责统筹当前长篇协作。',
            canSwitchGroup: false,
          ),
          inputCapabilityContext: const ConversationInputCapabilityContext(
            hasActiveProject: true,
            isGenerating: true,
            hostSupportsAttachmentPicking: true,
            modelSupportsReasoning: true,
            modelSupportsFileAttachments: true,
            modelSupportsImageAttachments: false,
            modelSupportsAttachmentUrlsOnly: false,
            modelSupportsMultiAttachments: false,
            collaborationSupportsReasoning: true,
            collaborationSupportsAttachments: true,
            collaborationSupportsToolOptions: false,
            reasoningEnabled: true,
            productExposesReasoningToggle: true,
            productExposesAttachmentEntry: false,
            productExposesStopAction: true,
            productExposesToolOptionsAction: false,
            productExposesOptimizeAction: false,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await expectLater(
      find.byKey(const ValueKey<String>('wr17_stop_capture_sidebar')),
      matchesGoldenFile(
        '../../../artifacts/wr17_screenshots/wr17_generating_stop.png',
      ),
    );
    expect(
      File(
        '${_resolveRepoRoot()}${Platform.pathSeparator}artifacts${Platform.pathSeparator}wr17_screenshots${Platform.pathSeparator}wr17_long_task_opening.png',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '${_resolveRepoRoot()}${Platform.pathSeparator}artifacts${Platform.pathSeparator}wr17_screenshots${Platform.pathSeparator}wr17_generating_stop.png',
      ).existsSync(),
      isTrue,
    );
  });
}

Widget _buildSidebarHost(Key boundaryKey, WorkbenchViewData source) {
  const mapper = WorkbenchPaneViewDataMapperService();
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Center(
        child: TickerMode(
          enabled: false,
          child: RepaintBoundary(
            key: boundaryKey,
            child: SizedBox(
              width: 390,
              height: 920,
              child: PanelSurface(
                role: PanelSurfaceRole.sidebar,
                child: ConversationSidebar(
                  viewData: mapper.toConversationViewData(source),
                  actionHandler: const _FakeConversationActionHandler(),
                  showWorkspaceShortcuts: true,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void _setViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1600, 1600);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

String _resolveRepoRoot() {
  var current = Directory.current.absolute;
  for (var depth = 0; depth < 6; depth += 1) {
    final docsFile = File(
      '${current.path}${Platform.pathSeparator}docs${Platform.pathSeparator}workbench-remaining-session-order-2026-05-28.md',
    );
    if (docsFile.existsSync()) {
      return current.path;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      break;
    }
    current = parent;
  }
  return Directory.current.absolute.path;
}

class _FakeConversationActionHandler implements ConversationActionHandler {
  const _FakeConversationActionHandler();

  @override
  void onAgentGroupSelected(String groupId) {}

  @override
  void onConversationAgentSelected(String agentId) {}

  @override
  void onAttachmentRequested() {}

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
}
