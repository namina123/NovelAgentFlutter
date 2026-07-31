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
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_input_capability_state.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_agent_group_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_agent_group_unsupported_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_agent_group_workspace_view_data.dart';
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
import 'package:novel_agent_app/features/workbench/presentation/widgets/conversation_input_dock.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/conversation_model_strip.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/project_agent_group_overlay.dart';

import 'manual_golden_test_support.dart';
import 'test_font_loader.dart';

const String _chapterTwelveBody = '''
港务塔的玻璃幕墙把整片外环灯带压成一层冷白色的雾，林澈站在观景廊桥尽头，没有立刻推门进去。他能看见控制台前的人影在来回切换窗口，像是在故意把所有动作做得平静、无害，可越是克制，越说明里面已经有人替他做出了决定。

他把袖口里那枚旧式存储片又按紧了一次。那东西本来只是一段备份日志，按理说不该让任何一条巡检线在凌晨两点同时改道，也不该让审计系统在三分钟内接连吞掉两次权限回滚。可事实摆在眼前，星港的调度主机已经开始把某些通行记录从公共索引里抹掉，像是在替一个尚未公开的命令腾位置。

门禁识别到他时迟疑了半秒，细窄的蓝线在掌纹边缘停顿，最后还是退开。黎向晚没有回头，只把主屏上的分区图缩小了一层，像是给他留出一个可以开口的位置。

“你晚了七分钟。”她说。

“我先去看了外环货运线。”林澈把存储片放到桌面，“如果你准备告诉我一切都还在计划之内，那你最好先解释，为什么十二号泊位的出港许可会提前写入明早的军用清单。”

黎向晚终于转过身，神色并不惊讶，反而像是在确认他究竟看到了多少。她没有碰那枚存储片，只是把自己的终端推过来，上面停着一份尚未签发的撤离序列，名单短得不像正式预案，却偏偏囊括了前哨站最关键的四个维护岗位。

“因为有人打算把这次试航伪装成故障疏散。”她低声说，“一旦广播发出去，所有人都会以为只是常规演练。真正的货舱会在第八分钟脱离母港，等我们反应过来，追踪权就已经不在站内了。”

廊桥外有一艘拖船缓慢滑过，尾焰在视野里拖出沉闷的一笔。林澈忽然意识到，眼前最危险的并不是那份清单本身，而是黎向晚把它拿给他看这件事。她等于把自己从调度链条里撕开了一道口子，而这道口子一旦暴露，就再也缝不回去。

“你想让我做什么？”

“别现在给答案。”黎向晚看着他，“我只需要你在四点之前决定，究竟要把这份记录送去审计处，还是跟我一起把那艘船拦在出港线里。”''';

const String _desktopUserPrompt = '''
把这一章的冲突继续向前推，但别急着给任何人立场上的胜负。我要的感觉是两个人都已经知道局面变了，却还在试探谁先承认这一点。

另外，林澈这段别说太满，保留一点他其实也没准备好的空白。''';

const String _desktopAssistantReply = '''
可以，我会把这一轮重点放在“信息先到，态度后到”的张力上。

具体写法上，先让林澈带着证据进门，但不马上摊牌。这样读者会先感到他掌握了筹码，却还没看清他愿不愿意真正掀桌。黎向晚则不用急着解释动机，她只需要拿出那份撤离序列，就足够让空气变重。

下一段我会把两人的分歧压在行动选择上，而不是口头辩赢。这样章末能停在更危险的位置，也更方便后面继续抬高代价。''';

const _ia07GoldenFileNames = <String>[
  'ia07_input_empty_state.png',
  'ia07_input_generating_stop.png',
  'ia07_workbench_desktop_three_pane.png',
  'ia07_agent_panel_collapsed.png',
  'ia07_agent_panel_expanded.png',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await GoldenTestFontLoader.ensureLoaded();
  });

  testWidgets('captures IA-07 polish verification screenshots', (tester) async {
    final artifactsDir = manualGoldenArtifactsDirectory(
      'workbench_ia07_screenshots',
    );
    if (skipManualGoldenTestIfArtifactsAreMissing(
      artifactsDirectory: artifactsDir,
      expectedFileNames: _ia07GoldenFileNames,
    )) {
      return;
    }

    await _captureInputEmptyState(tester);
    await _captureInputStopState(tester);
    await _captureDesktopWorkbenchState(tester);
    await _captureAgentOverlayCollapsedState(tester);
    await _captureAgentOverlayExpandedState(tester);

  });
}

Future<void> _captureInputEmptyState(WidgetTester tester) async {
  final textController = TextEditingController();
  final scrollController = ScrollController();
  addTearDown(() {
    textController.dispose();
    scrollController.dispose();
  });

  _setViewport(tester, const Size(1200, 900));
  await tester.pumpWidget(
    MaterialApp(
      theme: GoldenTestFontLoader.applyToTheme(AppTheme.light()),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey<String>('ia07_input_empty_shell'),
            child: SizedBox(
              width: 420,
              child: ConversationInputDock(
                controller: textController,
                scrollController: scrollController,
                hintText: '告诉我这一轮你想推进什么，我会直接接着做。',
                capabilities: const ConversationInputCapabilityState(
                  supportsReasoningToggle: true,
                  showReasoningToggle: true,
                  reasoningEnabled: true,
                  supportsOptimizeAction: false,
                  showOptimizeAction: false,
                  supportsToolOptionsAction: false,
                  showToolOptionsAction: false,
                  supportsStopAction: false,
                  showStopAction: false,
                  supportsAttachmentEntry: false,
                  showAttachmentEntry: false,
                  canSendAction: true,
                  submitLabel: '发送',
                ),
                actionHandler: const _FakeConversationHandler(),
                onSendRequested: () {},
                modelLabel: 'GPT-5',
                modelOptions: const <SelectorOptionViewData>[
                  SelectorOptionViewData(id: 'gpt-5', label: 'GPT-5'),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.byType(ConversationModelStrip), findsOneWidget);
  expect(find.text('深度思考'), findsOneWidget);
  expect(find.text('发送'), findsOneWidget);

  await expectLater(
    find.byKey(const ValueKey<String>('ia07_input_empty_shell')),
    matchesGoldenFile(
      '../../../artifacts/workbench_ia07_screenshots/ia07_input_empty_state.png',
    ),
  );
}

Future<void> _captureInputStopState(WidgetTester tester) async {
  final textController = TextEditingController(text: '继续压低这段语气。');
  final scrollController = ScrollController();
  addTearDown(() {
    textController.dispose();
    scrollController.dispose();
  });

  _setViewport(tester, const Size(1200, 900));
  await tester.pumpWidget(
    MaterialApp(
      theme: GoldenTestFontLoader.applyToTheme(AppTheme.light()),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey<String>('ia07_input_stop_shell'),
            child: SizedBox(
              width: 420,
              child: ConversationInputDock(
                controller: textController,
                scrollController: scrollController,
                hintText: '告诉我这一轮你想推进什么，我会直接接着做。',
                capabilities: const ConversationInputCapabilityState(
                  supportsReasoningToggle: true,
                  showReasoningToggle: true,
                  reasoningEnabled: true,
                  supportsOptimizeAction: false,
                  showOptimizeAction: false,
                  supportsToolOptionsAction: false,
                  showToolOptionsAction: false,
                  supportsStopAction: true,
                  showStopAction: true,
                  supportsAttachmentEntry: false,
                  showAttachmentEntry: false,
                  canSendAction: false,
                  submitLabel: '生成中',
                ),
                actionHandler: const _FakeConversationHandler(),
                onSendRequested: () {},
                modelLabel: 'GPT-5',
                modelOptions: const <SelectorOptionViewData>[
                  SelectorOptionViewData(id: 'gpt-5', label: 'GPT-5'),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('停止'), findsOneWidget);
  expect(find.text('发送'), findsNothing);

  await expectLater(
    find.byKey(const ValueKey<String>('ia07_input_stop_shell')),
    matchesGoldenFile(
      '../../../artifacts/workbench_ia07_screenshots/ia07_input_generating_stop.png',
    ),
  );
}

Future<void> _captureDesktopWorkbenchState(WidgetTester tester) async {
  const mapper = WorkbenchPaneViewDataMapperService();
  final state = _desktopWorkbenchState();

  _setViewport(tester, const Size(1600, 1000));
  await tester.pumpWidget(
    _buildWorkbenchHost(
      resource: ValueNotifier<WorkbenchResourceViewData>(
        mapper.toResourceViewData(state),
      ),
      canvas: ValueNotifier<WorkbenchCanvasViewData>(
        mapper.toCanvasViewData(state),
      ),
      conversation: ValueNotifier<WorkbenchConversationViewData>(
        mapper.toConversationViewData(state),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('NovelAgent'), findsOneWidget);
  expect(find.text('chapter_12.md'), findsWidgets);
  expect(
    find.byKey(const ValueKey<String>('conversation_header_agent_selector')),
    findsOneWidget,
  );

  await expectLater(
    find.byKey(const ValueKey<String>('ia07_workbench_desktop_shell')),
    matchesGoldenFile(
      '../../../artifacts/workbench_ia07_screenshots/ia07_workbench_desktop_three_pane.png',
    ),
  );
}

Future<void> _captureAgentOverlayCollapsedState(WidgetTester tester) async {
  await tester.pumpWidget(_buildProjectAgentOverlayHost());
  await tester.pumpAndSettle();

  expect(find.text('当前不可用智能体组'), findsOneWidget);
  expect(
    find.byKey(
      const ValueKey<String>('opening_unsupported_group_deconstruction'),
    ),
    findsNothing,
  );

  await expectLater(
    find.byKey(const ValueKey<String>('ia07_agent_overlay_shell')),
    matchesGoldenFile(
      '../../../artifacts/workbench_ia07_screenshots/ia07_agent_panel_collapsed.png',
    ),
  );
}

Future<void> _captureAgentOverlayExpandedState(WidgetTester tester) async {
  await tester.pumpWidget(_buildProjectAgentOverlayHost());
  await tester.pumpAndSettle();

  await tester.tap(
    find.byKey(const ValueKey<String>('opening_unsupported_groups')),
  );
  await tester.pumpAndSettle();

  expect(
    find.byKey(
      const ValueKey<String>('opening_unsupported_group_deconstruction'),
    ),
    findsOneWidget,
  );
  expect(find.text('当前不可用'), findsOneWidget);

  await expectLater(
    find.byKey(const ValueKey<String>('ia07_agent_overlay_shell')),
    matchesGoldenFile(
      '../../../artifacts/workbench_ia07_screenshots/ia07_agent_panel_expanded.png',
    ),
  );
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
    contextSummary: '',
    toolCoreStatus: '紧凑',
    workflowTitle: '章节协作',
    workflowDescription: '继续推进当前章节。',
    composerHint: '告诉我这一轮想推进的目标。',
    conversationEntries: const <ConversationEntryViewData>[
      ConversationEntryViewData(
        id: 'user_1',
        kind: ConversationEntryKind.user,
        title: '你',
        body: _desktopUserPrompt,
      ),
      ConversationEntryViewData(
        id: 'assistant_1',
        kind: ConversationEntryKind.assistant,
        title: '综合创作智能体',
        body: _desktopAssistantReply,
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
    activeDocumentBody: _chapterTwelveBody,
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
    theme: GoldenTestFontLoader.applyToTheme(
      AppTheme.light().copyWith(platform: TargetPlatform.windows),
    ),
    home: AppLayoutScope(
      metrics: metrics,
      child: Scaffold(
        body: RepaintBoundary(
          key: const ValueKey<String>('ia07_workbench_desktop_shell'),
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

Widget _buildProjectAgentOverlayHost() {
  return MaterialApp(
    theme: GoldenTestFontLoader.applyToTheme(AppTheme.light()),
    home: Scaffold(
      body: RepaintBoundary(
        key: const ValueKey<String>('ia07_agent_overlay_shell'),
        child: Stack(
          children: [
            ProjectAgentGroupOverlay(
              viewData: const ProjectAgentGroupWorkspaceViewData(
                title: '项目智能体组',
                description: '这里负责当前项目默认智能体组配置。',
                currentGroupLabel: '长篇总控组',
                primaryAgentLabel: '综合创作智能体',
                primaryAgentDescription: '负责统筹当前长篇协作。',
                selectionHint: '默认只显示当前项目可直接使用的智能体组。',
                supportedGroups: [
                  ProjectAgentGroupOptionViewData(
                    groupId: 'starter_long_task',
                    displayName: '长篇总控组',
                    description: '负责长篇开局与节奏收束。',
                    isCurrent: true,
                    isDegraded: false,
                  ),
                ],
                unsupportedGroups: [
                  ProjectAgentGroupUnsupportedViewData(
                    groupId: 'deconstruction',
                    displayName: '拆书组',
                    description: '只适用于拆书项目。',
                    reasonSummary: '项目类型与该智能体组的适用范围不匹配。',
                    reasonDetails: ['项目类型与该智能体组的适用范围不匹配。'],
                  ),
                ],
              ),
              actionHandler: const _FakeResourceHandler(),
            ),
          ],
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

  @override
  void setForegroundBackHandler(VoidCallback? handler) {}
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
  @override
  void onLongTaskRunResumeRequested(String runId) {}
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
  void onRuntimeBaselineConfigurationRequested() {}

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
  void onDeleteResourceEntryRequested(String entryId) {}

  @override
  void onRenameResourceEntryRequested(String entryId, String nextName) {}

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
