import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/application/services/workbench_pane_view_data_mapper_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/conversation_action_handler.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/document_workspace_action_handler.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/resource_manager_action_handler.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_create_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/workbench_canvas_workspace_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'canvas workspace shell keeps auxiliary view lightweight and routes review into it',
    (tester) async {
      const mapper = WorkbenchPaneViewDataMapperService();
      final base = WorkbenchViewData.initial().copyWith(
        projectName: '星港档案',
        contextSummary: '已载入章节上下文。',
        workflowTitle: '章节协作',
        workflowDescription: '围绕正文进行协作与返工。',
        documents: const [
          DocumentTabViewData(
            id: 'doc_1',
            title: 'chapter_01.md',
            relativePath: 'chapters/chapter_01.md',
            isDirty: false,
            isActive: true,
          ),
        ],
        activeDocumentBody: '第一章的正文内容，用于审稿与重写预览。',
        activeDocumentTitle: 'chapter_01.md',
        activeDocumentPath: 'chapters/chapter_01.md',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 960,
              height: 900,
              child: WorkbenchCanvasWorkspaceShell(
                canvasViewData: mapper.toCanvasViewData(base),
                resourceListenable: ValueNotifier(
                  mapper.toResourceViewData(base),
                ),
                conversationListenable: ValueNotifier(
                  mapper.toConversationViewData(base),
                ),
                documentHandler: const _FakeDocumentHandler(),
                resourceHandler: const _FakeResourceHandler(),
                conversationHandler: const _FakeConversationHandler(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The auxiliary panel is collapsed by default (no peek bar rendered
      // initially), so neither the host title nor its panel blocks are visible.
      expect(find.text('即将参与的协作基线'), findsNothing);
      expect(find.text('当前审稿锚点'), findsNothing);

      await tester.tap(find.byTooltip('审稿'));
      await tester.pumpAndSettle();

      // Tapping 审稿 reveals the auxiliary host with the review-analysis panel.
      // The `审稿锚点` label appears twice (section title + auxiliary chip).
      expect(find.text('审稿锚点'), findsNWidgets(2));
      expect(find.text('当前审稿锚点'), findsOneWidget);

      await tester.tap(find.text('收起').last);
      await tester.pumpAndSettle();

      expect(find.text('当前审稿锚点'), findsNothing);
      expect(find.text('审稿锚点'), findsNothing);
    },
  );
}

class _FakeConversationHandler implements ConversationActionHandler {
  const _FakeConversationHandler();

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
  void onReasoningToggleChanged(bool enabled) {}

  @override
  void onQuickThemeRequested() {}

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
  void onUserOptionSelected(option) {}
}

class _FakeDocumentHandler implements DocumentWorkspaceActionHandler {
  const _FakeDocumentHandler();

  @override
  void onDocumentActionRequested(DocumentToolbarAction action) {}

  @override
  void onDocumentBodyChanged(String value) {}

  @override
  void onDocumentClosed(String documentId) {}

  @override
  void onDocumentSelected(String documentId) {}
}

class _FakeResourceHandler implements ResourceManagerActionHandler {
  const _FakeResourceHandler();

  @override
  void onAgentEcosystemRequested() {}

  @override
  void onCreateChapterRequested() {}

  @override
  void onCreateFileRequested() {}

  @override
  void onCreateFolderRequested() {}

  @override
  void onCreateProjectRequested() {}

  @override
  void onCurrentAgentExpressionConstraintsRequested() {}

  @override
  void onCurrentAgentSkillLoadoutRequested() {}

  @override
  void onEditProjectInfoRequested() {}

  @override
  void onProjectTypeTransitionRequested() {}

  @override
  void onImportRequested() {}

  @override
  void onModelSettingsRequested() {}

  @override
  void onOpenProjectRequested() {}

  @override
  void onProjectAgentGroupDismissed() {}

  @override
  void onProjectAgentGroupRequested() {}

  @override
  void onProjectAgentGroupSelected(String groupId) {}

  @override
  void onProjectAssetsRequested() {}

  @override
  void onProjectRagRequested() {}

  @override
  void onProjectCreationBackRequested() {}

  @override
  void onProjectCreationSubmitted(ProjectCreateRequestViewData request) {}

  @override
  void onProjectEntryOpened(String projectPath) {}

  @override
  void onProjectLauncherDismissed() {}

  @override
  void onProjectLauncherRefreshRequested() {}

  @override
  void onRefreshFilesRequested() {}

  @override
  void onResourceEntrySelected(String entryId) {}

  @override
  void onReviewsRequested() {}

  @override
  void onSaveCurrentRequested() {}

  @override
  void onTasksRequested() {}

  @override
  void onTemplatesRequested() {}

  @override
  void onWorkspaceCommandDismissed() {}

  @override
  void onWorkspaceImportFilesPickRequested(
    WorkspaceCommandRequestViewData request,
  ) {}

  @override
  void onWorkspaceImportDirectoryPickRequested(
    WorkspaceCommandRequestViewData request,
  ) {}

  @override
  void onWorkspaceCommandSubmitted(WorkspaceCommandRequestViewData request) {}
}
