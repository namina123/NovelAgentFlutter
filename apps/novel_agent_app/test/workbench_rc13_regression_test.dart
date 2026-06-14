import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/layout/app_layout_metrics.dart';
import 'package:novel_agent_app/app/layout/app_layout_mode.dart';
import 'package:novel_agent_app/app/layout/app_layout_scope.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/application/services/workbench_pane_view_data_mapper_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/conversation_action_handler.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/document_workspace_action_handler.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/resource_manager_action_handler.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_group_selector_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_entry_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_create_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_canvas_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_conversation_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_overlay_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_resource_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/pages/workbench_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desktop workbench recovery view stays user-facing and low-noise', (
    tester,
  ) async {
    _setDesktopViewport(tester);
    const mapper = WorkbenchPaneViewDataMapperService();
    final state = WorkbenchViewData.initial().copyWith(
      projectName: '星港档案',
      projectSubtitle: '长篇科幻项目',
      projectPath: 'D:/projects/starport_archive',
      modelLabel: 'GPT-5',
      modelOptions: const [],
      groupSelector: const ConversationGroupSelectorViewData(
        currentGroupLabel: '默认小说开局',
        groupOptions: [],
        headerSubtitle: '默认小说开局',
        primaryAgentLabel: '综合创作智能体',
        primaryAgentDescription: '负责统筹当前小说协作。',
        canSwitchGroup: false,
      ),
      contextSummary: '已载入角色、关系、时间线与当前章节上下文。',
      workflowTitle: '章节协作',
      workflowDescription: '围绕当前文档继续推进这一章。',
      conversationEntries: const [
        ConversationEntryViewData(
          id: 'assistant_1',
          kind: ConversationEntryKind.assistant,
          title: '综合创作智能体',
          body: '我已经接住当前章节与项目约束，接下来可以继续推进这一章的冲突升级。',
        ),
      ],
      documents: const [
        DocumentTabViewData(
          id: 'doc_1',
          title: 'chapter_12.md',
          relativePath: 'chapters/chapter_12.md',
          isDirty: false,
          isActive: true,
        ),
      ],
      activeDocumentTitle: 'chapter_12.md',
      activeDocumentPath: 'chapters/chapter_12.md',
      activeDocumentBody: '这一章的正文片段，用于验证正文对象区仍然保持主位。',
      activeDocumentCanRender: true,
      resourceEntries: const [
        ResourceEntryViewData(
          id: 'premise',
          title: '前提',
          relativePath: 'premise/',
          depth: 0,
          isDirectory: true,
          hasChildren: true,
          isExpanded: true,
        ),
        ResourceEntryViewData(
          id: 'premise_brief',
          title: 'project_brief.md',
          relativePath: 'premise/project_brief.md',
          depth: 1,
          isDirectory: false,
        ),
        ResourceEntryViewData(
          id: 'outlines',
          title: '大纲',
          relativePath: 'outlines/',
          depth: 0,
          isDirectory: true,
          hasChildren: true,
          isExpanded: true,
        ),
        ResourceEntryViewData(
          id: 'chapters',
          title: '正文',
          relativePath: 'chapters/',
          depth: 0,
          isDirectory: true,
          hasChildren: true,
          isExpanded: true,
        ),
        ResourceEntryViewData(
          id: 'chapter_12',
          title: 'chapter_12.md',
          relativePath: 'chapters/chapter_12.md',
          depth: 1,
          isDirectory: false,
          isSelected: true,
        ),
        ResourceEntryViewData(
          id: 'assets',
          title: '资产',
          relativePath: 'assets/',
          depth: 0,
          isDirectory: true,
          hasChildren: true,
        ),
        ResourceEntryViewData(
          id: 'tasks',
          title: '任务',
          relativePath: 'tasks/',
          depth: 0,
          isDirectory: true,
          hasChildren: true,
        ),
      ],
    );
    final resource = ValueNotifier(mapper.toResourceViewData(state));
    final canvas = ValueNotifier(mapper.toCanvasViewData(state));
    final conversation = ValueNotifier(mapper.toConversationViewData(state));

    await tester.pumpWidget(
      _buildWorkbenchHost(
        resource: resource,
        canvas: canvas,
        conversation: conversation,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('NovelAgent'), findsOneWidget);
    expect(find.text('文件'), findsWidgets);
    expect(find.text('会话'), findsOneWidget);
    expect(find.text('综合创作智能体'), findsWidgets);
    expect(find.text('default_generalist'), findsNothing);
    expect(find.text('结果面板'), findsNothing);
    expect(find.text('智能体配置'), findsNothing);
    expect(find.text('提示词模板'), findsNothing);
    expect(find.text('执行追踪'), findsNothing);
    expect(find.text('生成记录'), findsNothing);
    expect(find.text('刷新项目'), findsNothing);
    expect(find.text('继续生成'), findsNothing);

    await expectLater(
      find.byKey(const ValueKey<String>('rc13_workbench_desktop_shell')),
      matchesGoldenFile(
        '../../../artifacts/workbench_rc13_screenshots/workbench_desktop_recovery.png',
      ),
    );

    expect(
      File(
        '${_resolveRepoRoot()}${Platform.pathSeparator}artifacts${Platform.pathSeparator}workbench_rc13_screenshots${Platform.pathSeparator}workbench_desktop_recovery.png',
      ).existsSync(),
      isTrue,
    );
  });
}

Widget _buildWorkbenchHost({
  required ValueListenable<WorkbenchResourceViewData> resource,
  required ValueListenable<WorkbenchCanvasViewData> canvas,
  required ValueListenable<WorkbenchConversationViewData> conversation,
}) {
  final metrics = AppLayoutMetrics(
    size: const Size(1600, 1000),
    shortestSide: 1000,
    orientation: Orientation.landscape,
    viewInsetsBottom: 0,
    devicePixelRatio: 1,
    mode: AppLayoutMode.expanded,
    isTabletLike: true,
  );
  return MaterialApp(
    theme: AppTheme.light().copyWith(platform: TargetPlatform.windows),
    home: AppLayoutScope(
      metrics: metrics,
      child: Scaffold(
        body: RepaintBoundary(
          key: const ValueKey<String>('rc13_workbench_desktop_shell'),
          child: WorkbenchPage(
            resourceListenable: resource,
            canvasListenable: canvas,
            conversationListenable: conversation,
            overlayListenable: ValueNotifier(
              const WorkbenchOverlayViewData(
                projectLauncher: null,
                projectAgentGroupWorkspace: null,
                workspaceCommand: null,
              ),
            ),
            resourceHandler: const _FakeResourceHandler(),
            documentHandler: const _FakeDocumentHandler(),
            conversationHandler: const _FakeConversationHandler(),
          ),
        ),
      ),
    ),
  );
}

void _setDesktopViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1600, 1000);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

String _resolveRepoRoot() {
  var current = Directory.current.absolute;
  for (var depth = 0; depth < 6; depth += 1) {
    final docsFile = File(
      '${current.path}${Platform.pathSeparator}docs${Platform.pathSeparator}workbench-recovery-session-order-2026-05-29.md',
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
  void onWorkspaceCommandSubmitted(WorkspaceCommandRequestViewData request) {}
}
