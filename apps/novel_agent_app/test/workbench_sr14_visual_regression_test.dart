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
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_agent_selector_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_entry_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_group_selector_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_input_capability_context.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_opening_state_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/opening_agent_group_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/opening_panel_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/opening_unsupported_group_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_create_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_long_task_summary_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/selector_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/user_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_canvas_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_conversation_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_overlay_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_resource_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/pages/workbench_page.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/conversation_sidebar.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/workbench_navigation_sidebar.dart';
import 'package:novel_agent_app/shared/widgets/panel_surface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captures SR-14 final visual verification screenshots', (
    tester,
  ) async {
    const mapper = WorkbenchPaneViewDataMapperService();

    _setViewport(tester, const Size(1600, 1000));
    final desktopState = _desktopWorkbenchState();
    final desktopResource = ValueNotifier(
      mapper.toResourceViewData(desktopState),
    );
    final desktopCanvas = ValueNotifier(mapper.toCanvasViewData(desktopState));
    final desktopConversation = ValueNotifier(
      mapper.toConversationViewData(desktopState),
    );
    await tester.pumpWidget(
      _buildWorkbenchHost(
        resource: desktopResource,
        canvas: desktopCanvas,
        conversation: desktopConversation,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('工作台对象'), findsOneWidget);
    expect(find.text('正文工作区'), findsOneWidget);
    expect(find.text('当前会话智能体'), findsOneWidget);

    await expectLater(
      find.byKey(const ValueKey<String>('sr14_workbench_desktop_shell')),
      matchesGoldenFile(
        '../../../artifacts/workbench_sr14_screenshots/sr14_workbench_desktop_three_pane.png',
      ),
    );

    _setViewport(tester, const Size(1200, 900));
    final compactState = _desktopWorkbenchState();
    await tester.pumpWidget(
      _buildCompactSidebarHost(
        child: SizedBox(
          width: 292,
          height: 380,
          child: WorkbenchNavigationSidebar(
            resourceListenable: ValueNotifier(
              mapper.toResourceViewData(compactState),
            ),
            canvasListenable: ValueNotifier(
              mapper.toCanvasViewData(compactState),
            ),
            conversationListenable: ValueNotifier(
              mapper.toConversationViewData(compactState),
            ),
            resourceHandler: const _FakeResourceHandler(),
          ),
        ),
        boundaryKey: const ValueKey<String>('sr14_left_sidebar_compact_shell'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('工作台对象'), findsOneWidget);
    expect(find.text('文件'), findsWidgets);
    expect(find.byType(CustomScrollView), findsOneWidget);

    await expectLater(
      find.byKey(const ValueKey<String>('sr14_left_sidebar_compact_shell')),
      matchesGoldenFile(
        '../../../artifacts/workbench_sr14_screenshots/sr14_left_sidebar_compact_height.png',
      ),
    );

    _setViewport(tester, const Size(1200, 1600));
    await tester.pumpWidget(
      _buildConversationHost(
        boundaryKey: const ValueKey<String>('sr14_conversation_empty_shell'),
        viewData: mapper.toConversationViewData(_emptyConversationState()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('下一步：智能开局'), findsOneWidget);
    expect(find.text('项目智能体组'), findsNothing);

    await expectLater(
      find.byKey(const ValueKey<String>('sr14_conversation_empty_shell')),
      matchesGoldenFile(
        '../../../artifacts/workbench_sr14_screenshots/sr14_conversation_empty_state.png',
      ),
    );

    _setViewport(tester, const Size(1200, 1600));
    await tester.pumpWidget(
      _buildConversationHost(
        boundaryKey: const ValueKey<String>('sr14_conversation_active_shell'),
        viewData: mapper.toConversationViewData(_activeConversationState()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('深度思考'), findsOneWidget);
    expect(find.text('发送'), findsOneWidget);
    expect(find.text('审阅智能体'), findsWidgets);
    expect(find.text('把会话结尾再压低一点，别急着给角色台阶。'), findsOneWidget);

    await expectLater(
      find.byKey(const ValueKey<String>('sr14_conversation_active_shell')),
      matchesGoldenFile(
        '../../../artifacts/workbench_sr14_screenshots/sr14_conversation_active_state.png',
      ),
    );

    for (final fileName in const <String>[
      'sr14_workbench_desktop_three_pane.png',
      'sr14_left_sidebar_compact_height.png',
      'sr14_conversation_empty_state.png',
      'sr14_conversation_active_state.png',
    ]) {
      expect(
        File(
          '${_resolveRepoRoot()}${Platform.pathSeparator}artifacts${Platform.pathSeparator}workbench_sr14_screenshots${Platform.pathSeparator}$fileName',
        ).existsSync(),
        isTrue,
        reason: '缺少截图产物：$fileName',
      );
    }
  });
}

WorkbenchViewData _desktopWorkbenchState() {
  return WorkbenchViewData.initial().copyWith(
    projectName: '星港档案',
    projectSubtitle: '长篇科幻项目',
    projectPath: 'D:/projects/starport_archive',
    modelLabel: 'GPT-5',
    modelOptions: const <SelectorOptionViewData>[
      SelectorOptionViewData(id: 'gpt-5', label: 'GPT-5'),
      SelectorOptionViewData(id: 'gpt-4.1', label: 'GPT-4.1'),
    ],
    groupSelector: const ConversationGroupSelectorViewData(
      currentGroupLabel: '默认小说开局',
      groupOptions: <SelectorOptionViewData>[],
      headerSubtitle: '默认小说开局',
      primaryAgentLabel: '综合创作智能体',
      primaryAgentDescription: '负责统筹当前小说协作。',
      canSwitchGroup: false,
    ),
    agentSelector: const ConversationAgentSelectorViewData(
      currentAgentLabel: '综合创作智能体',
      currentAgentId: 'default_generalist',
      currentAgentDescription: '负责当前会话的正文推进',
      agentOptions: <SelectorOptionViewData>[
        SelectorOptionViewData(
          id: 'default_generalist',
          label: '综合创作智能体',
          note: '负责当前会话的正文推进',
        ),
        SelectorOptionViewData(
          id: 'reviewer',
          label: '审阅智能体',
          note: '负责结构与表述修订',
        ),
      ],
      canSwitchAgent: true,
      headerSubtitle: '正文推进',
    ),
    inputCapabilityContext: const ConversationInputCapabilityContext(
      hasActiveProject: true,
      isGenerating: false,
      hostSupportsAttachmentPicking: true,
      modelSupportsReasoning: true,
      modelSupportsFileAttachments: false,
      modelSupportsImageAttachments: false,
      modelSupportsAttachmentUrlsOnly: false,
      modelSupportsMultiAttachments: false,
      collaborationSupportsReasoning: true,
      collaborationSupportsAttachments: false,
      collaborationSupportsToolOptions: false,
      reasoningEnabled: true,
      productExposesReasoningToggle: true,
      productExposesAttachmentEntry: false,
      productExposesStopAction: false,
      productExposesToolOptionsAction: false,
      productExposesOptimizeAction: false,
    ),
    contextSummary: '已载入角色、关系、时间线与当前章节上下文。',
    toolCoreStatus: '当前工具展示：紧凑',
    workflowTitle: '章节协作',
    workflowDescription: '围绕当前文档继续推进这一章。',
    composerHint: '告诉我这一轮想推进的目标。',
    conversationEntries: const <ConversationEntryViewData>[
      ConversationEntryViewData(
        id: 'user_1',
        kind: ConversationEntryKind.user,
        title: '你',
        body: '把这一章的冲突再往前推半步，但先别收尾。',
      ),
      ConversationEntryViewData(
        id: 'assistant_1',
        kind: ConversationEntryKind.assistant,
        title: '综合创作智能体',
        body: '我已经接住当前章节与项目约束，下一步会先抬高两位主角的分歧，再把代价压到下一段。',
      ),
    ],
    documents: const <DocumentTabViewData>[
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
    resourceEntries: const <ResourceEntryViewData>[
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
    projectLongTaskSummary: const ProjectLongTaskSummaryViewData(
      title: '长任务运行',
      summary: '运行中 1 · 待处理 1 · 共 2 条',
      isLoading: false,
      totalCount: 2,
      activeCount: 1,
      attentionCount: 1,
      runs: <ProjectLongTaskRunSummaryViewData>[
        ProjectLongTaskRunSummaryViewData(
          id: 'run_1',
          title: '连续不断的长任务',
          subtitle: '按大纲自动推进',
          statusLabel: '等待人工处理',
          taskLabel: '第 10 章返工',
          recentActivityLabel: '5 分钟前',
          requiresAttention: true,
          isActive: false,
        ),
      ],
    ),
  );
}

WorkbenchViewData _emptyConversationState() {
  return WorkbenchViewData.initial().copyWith(
    projectName: '星港档案',
    projectSubtitle: '长篇科幻项目',
    projectPath: 'D:/projects/starport_archive',
    modelLabel: 'GPT-5',
    workflowTitle: '协作开局',
    workflowDescription: '先确认这一轮从哪里开始，我会继续追问直到能正式开工。',
    groupSelector: const ConversationGroupSelectorViewData(
      currentGroupLabel: '长篇总控组',
      groupOptions: <SelectorOptionViewData>[],
      primaryAgentLabel: '综合创作智能体',
      primaryAgentDescription: '负责统筹当前长篇协作。',
      canSwitchGroup: false,
    ),
    agentSelector: const ConversationAgentSelectorViewData(
      currentAgentLabel: '综合创作智能体',
      currentAgentId: 'default_generalist',
      currentAgentDescription: '负责当前会话的开局整理与推进',
      agentOptions: <SelectorOptionViewData>[
        SelectorOptionViewData(id: 'default_generalist', label: '综合创作智能体'),
      ],
      canSwitchAgent: false,
      headerSubtitle: '开局整理',
    ),
    inputCapabilityContext: const ConversationInputCapabilityContext(
      hasActiveProject: true,
      isGenerating: false,
      hostSupportsAttachmentPicking: true,
      modelSupportsReasoning: true,
      modelSupportsFileAttachments: false,
      modelSupportsImageAttachments: false,
      modelSupportsAttachmentUrlsOnly: false,
      modelSupportsMultiAttachments: false,
      collaborationSupportsReasoning: true,
      collaborationSupportsAttachments: false,
      collaborationSupportsToolOptions: false,
      reasoningEnabled: true,
      productExposesReasoningToggle: true,
      productExposesAttachmentEntry: false,
      productExposesStopAction: false,
      productExposesToolOptionsAction: false,
      productExposesOptimizeAction: false,
    ),
    primaryActions: const <PrimaryActionViewData>[
      PrimaryActionViewData(
        id: 'session.goal.smart_opening',
        title: '智能开局',
        description: '先给我一个方向，我会继续追问直到能正式开工。',
        commandId: 'session.goal',
      ),
    ],
    openingState: const ConversationOpeningStateViewData(
      firstPrompt: '先告诉我你想从哪个方向开始，我会继续追问直到能正式开工。',
      nextStepLabel: '智能开局',
      hasProjectFoundation: false,
      hasResolvedGroup: true,
      missingRequirementTitles: <String>[],
      preferSingleAction: true,
      nextAction: PrimaryActionViewData(
        id: 'session.goal.smart_opening',
        title: '智能开局',
        description: '先给我一个方向，我会继续追问直到能正式开工。',
        commandId: 'session.goal',
      ),
    ),
    openingPanel: const OpeningPanelViewData(
      title: '项目智能体组',
      summary: '当前默认组：长篇总控组。当前项目协作基线已就绪。',
      currentGroupDisplayName: '长篇总控组',
      selectionHint: '默认只显示当前项目可直接使用的智能体组。',
      supportedGroups: <OpeningAgentGroupOptionViewData>[
        OpeningAgentGroupOptionViewData(
          groupId: 'starter_long_task',
          displayName: '长篇总控组',
          description: '负责长篇开局与节奏收束。',
          isCurrent: true,
          isDegraded: false,
          isStarterGroup: true,
        ),
      ],
      unsupportedGroups: <OpeningUnsupportedGroupViewData>[],
    ),
  );
}

WorkbenchViewData _activeConversationState() {
  return WorkbenchViewData.initial().copyWith(
    projectName: '星港档案',
    projectSubtitle: '长篇科幻项目',
    projectPath: 'D:/projects/starport_archive',
    modelLabel: 'GPT-5',
    modelOptions: const <SelectorOptionViewData>[
      SelectorOptionViewData(id: 'gpt-5', label: 'GPT-5'),
      SelectorOptionViewData(id: 'gpt-4.1', label: 'GPT-4.1'),
    ],
    workflowTitle: '章节协作',
    workflowDescription: '围绕当前章节继续推进。',
    contextSummary: '已载入角色、阵营与时间线约束。',
    groupSelector: const ConversationGroupSelectorViewData(
      currentGroupLabel: '长篇总控组',
      groupOptions: <SelectorOptionViewData>[],
      primaryAgentLabel: '综合创作智能体',
      primaryAgentDescription: '负责统筹当前长篇协作。',
      canSwitchGroup: false,
    ),
    agentSelector: const ConversationAgentSelectorViewData(
      currentAgentLabel: '审阅智能体',
      currentAgentId: 'reviewer',
      currentAgentDescription: '负责当前会话的审阅与修订建议',
      agentOptions: <SelectorOptionViewData>[
        SelectorOptionViewData(
          id: 'default_generalist',
          label: '综合创作智能体',
          note: '负责当前会话的正文推进',
        ),
        SelectorOptionViewData(
          id: 'reviewer',
          label: '审阅智能体',
          note: '负责结构与表述修订',
        ),
      ],
      canSwitchAgent: true,
      headerSubtitle: '质量审阅',
    ),
    inputCapabilityContext: const ConversationInputCapabilityContext(
      hasActiveProject: true,
      isGenerating: false,
      hostSupportsAttachmentPicking: true,
      modelSupportsReasoning: true,
      modelSupportsFileAttachments: false,
      modelSupportsImageAttachments: false,
      modelSupportsAttachmentUrlsOnly: false,
      modelSupportsMultiAttachments: false,
      collaborationSupportsReasoning: true,
      collaborationSupportsAttachments: false,
      collaborationSupportsToolOptions: false,
      reasoningEnabled: true,
      productExposesReasoningToggle: true,
      productExposesAttachmentEntry: false,
      productExposesStopAction: false,
      productExposesToolOptionsAction: false,
      productExposesOptimizeAction: false,
    ),
    conversationEntries: const <ConversationEntryViewData>[
      ConversationEntryViewData(
        id: 'user_1',
        kind: ConversationEntryKind.user,
        title: '你',
        body: '把会话结尾再压低一点，别急着给角色台阶。',
      ),
      ConversationEntryViewData(
        id: 'tool_1',
        kind: ConversationEntryKind.tool,
        title: '读取文件',
        body: 'chapters/chapter_12.md',
        detailTitle: '工具调用',
        detailSummary: '已读取设定目录与章节草稿',
        detailBody: '读取了 chapter_12.md 与 premise/project_brief.md。',
      ),
      ConversationEntryViewData(
        id: 'assistant_1',
        kind: ConversationEntryKind.assistant,
        title: '审阅智能体',
        body: '可以把最后一段的解释性句子再削掉半句，让情绪停在动作与停顿上。',
      ),
    ],
    composerHint: '继续告诉我你希望这一轮怎么改。',
  );
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
          key: const ValueKey<String>('sr14_workbench_desktop_shell'),
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

Widget _buildCompactSidebarHost({
  required Widget child,
  required Key boundaryKey,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Center(
        child: RepaintBoundary(key: boundaryKey, child: child),
      ),
    ),
  );
}

Widget _buildConversationHost({
  required Key boundaryKey,
  required WorkbenchConversationViewData viewData,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Center(
        child: RepaintBoundary(
          key: boundaryKey,
          child: SizedBox(
            width: 390,
            height: 920,
            child: PanelSurface(
              role: PanelSurfaceRole.sidebar,
              child: ConversationSidebar(
                viewData: viewData,
                actionHandler: const _FakeConversationHandler(),
                showWorkspaceShortcuts: true,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

String _resolveRepoRoot() {
  var current = Directory.current.absolute;
  for (var depth = 0; depth < 6; depth += 1) {
    final docsFile = File(
      '${current.path}${Platform.pathSeparator}docs${Platform.pathSeparator}workbench-sidebars-relayout-session-order-2026-05-29.md',
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
  void onImportRequested() {}

  @override
  void onLongTaskStationRequested() {}

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
