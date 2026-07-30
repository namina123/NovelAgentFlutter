import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/conversation_action_handler.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/resource_manager_action_handler.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_agent_selector_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_group_selector_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_input_capability_context.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_transcript_lane_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_agent_group_panel_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_create_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/resource_entry_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/selector_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/transcript_block_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/user_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_agent_panel_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_conversation_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_project_panel_action_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_resource_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workspace_command_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/conversation_sidebar.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/resource_manager_panel.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/workbench_agent_panel.dart';

import 'manual_golden_test_support.dart';

const _aesp08GoldenFileNames = <String>[
  'aesp08_resource_panel_single_row.png',
  'aesp08_resource_panel_legacy_mapping.png',
  'aesp08_agent_panel_entries.png',
  'aesp08_conversation_agent_selector.png',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captures AESP-08 visual verification screenshots', (
    tester,
  ) async {
    final artifactsDir = manualGoldenArtifactsDirectory(
      'workbench_aesp08_screenshots',
    );
    if (skipManualGoldenTestIfArtifactsAreMissing(
      artifactsDirectory: artifactsDir,
      expectedFileNames: _aesp08GoldenFileNames,
    )) {
      return;
    }

    await _captureFileToolsAndLegacyDirectoryMapping(tester);
    await _captureAgentPanelEntries(tester);
    await _captureConversationAgentSelector(tester);

  });
}

Future<void> _captureFileToolsAndLegacyDirectoryMapping(
  WidgetTester tester,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey<String>('aesp08_resource_single_row_shell'),
            child: SizedBox(
              width: 252,
              height: 780,
              child: ResourceManagerPanel(
                viewData: WorkbenchResourceViewData(
                  projectName: '星港档案',
                  projectSubtitle: '长篇科幻项目',
                  resourceEntries: const <ResourceEntryViewData>[
                    ResourceEntryViewData(
                      id: 'outline',
                      title: '大纲',
                      relativePath: 'outline',
                      depth: 0,
                      isDirectory: true,
                      hasChildren: true,
                      isExpanded: true,
                    ),
                    ResourceEntryViewData(
                      id: 'outline_file',
                      title: 'outline.md',
                      relativePath: 'outline/outline.md',
                      depth: 1,
                      isDirectory: false,
                    ),
                    ResourceEntryViewData(
                      id: 'volume_outlines',
                      title: '卷纲',
                      relativePath: 'volume_outlines',
                      depth: 0,
                      isDirectory: true,
                    ),
                    ResourceEntryViewData(
                      id: 'chapter_outlines',
                      title: '章纲',
                      relativePath: 'chapter_outlines',
                      depth: 0,
                      isDirectory: true,
                    ),
                    ResourceEntryViewData(
                      id: 'knowledge',
                      title: '知识',
                      relativePath: 'knowledge',
                      depth: 0,
                      isDirectory: true,
                    ),
                    ResourceEntryViewData(
                      id: 'styles',
                      title: '风格',
                      relativePath: 'styles',
                      depth: 0,
                      isDirectory: true,
                    ),
                    ResourceEntryViewData(
                      id: 'summaries',
                      title: '摘要',
                      relativePath: 'summaries',
                      depth: 0,
                      isDirectory: true,
                    ),
                    ResourceEntryViewData(
                      id: 'world',
                      title: '世界',
                      relativePath: 'world',
                      depth: 0,
                      isDirectory: true,
                    ),
                    ResourceEntryViewData(
                      id: 'reviews',
                      title: '审稿',
                      relativePath: 'reviews',
                      depth: 0,
                      isDirectory: true,
                    ),
                  ],
                ),
                actionHandler: const _FakeResourceManagerActionHandler(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.byTooltip('新文件'), findsOneWidget);
  expect(find.byTooltip('导入文件'), findsOneWidget);
  expect(find.byTooltip('新章节'), findsOneWidget);
  expect(find.byTooltip('保存当前文档'), findsOneWidget);
  expect(find.byTooltip('更多文件操作'), findsOneWidget);

  await expectLater(
    find.byKey(const ValueKey<String>('aesp08_resource_single_row_shell')),
    matchesGoldenFile(
      '../../../artifacts/workbench_aesp08_screenshots/aesp08_resource_panel_single_row.png',
    ),
  );

  await expectLater(
    find.byKey(const ValueKey<String>('aesp08_resource_single_row_shell')),
    matchesGoldenFile(
      '../../../artifacts/workbench_aesp08_screenshots/aesp08_resource_panel_legacy_mapping.png',
    ),
  );
}

Future<void> _captureAgentPanelEntries(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey<String>('aesp08_agent_panel_shell'),
            child: SizedBox(
              width: 320,
              height: 920,
              child: WorkbenchAgentPanel(
                viewData: const WorkbenchAgentPanelViewData(
                  projectName: '星港档案',
                  hasActiveProject: true,
                  currentAgentLabel: '审阅智能体',
                  currentAgentDescription: '负责当前会话的审阅与修订建议。',
                  currentAgentOptionCount: 2,
                  canSwitchAgent: true,
                  currentGroupLabel: '长篇总控组',
                  primaryAgentLabel: '综合创作智能体',
                  projectAgentGroupPanel: ProjectAgentGroupPanelViewData(
                    currentGroupLabel: '长篇总控组',
                    primaryAgentLabel: '综合创作智能体',
                    summary: '当前默认组：长篇总控组；主智能体：综合创作智能体。',
                    actionTitle: '项目智能体组',
                    actionDescription: '查看当前项目支持的智能体组，并调整默认协作基线。',
                    canConfigure: true,
                  ),
                  agentWorkspaceActions: <WorkbenchProjectPanelActionViewData>[
                    WorkbenchProjectPanelActionViewData(
                      icon: Icons.auto_fix_high_outlined,
                      title: '技能装载',
                      description: '查看当前智能体在本项目中的技能组合、补充技能和禁用项。',
                      actionId: 'agent_skill_loadout',
                    ),
                    WorkbenchProjectPanelActionViewData(
                      icon: Icons.rule_folder_outlined,
                      title: '表达限制',
                      description: '查看当前项目的表达限制，并按当前智能体进一步定向绑定。',
                      actionId: 'project_expression_constraints',
                    ),
                  ],
                ),
                resourceHandler: const _FakeResourceManagerActionHandler(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // The agent panel surfaces the collaboration overview, the current
  // division of labor, and the configured workspace actions.
  expect(find.text('协作概览'), findsOneWidget);
  expect(find.text('当前分工'), findsOneWidget);
  expect(find.text('技能装载'), findsOneWidget);
  expect(find.text('表达限制'), findsOneWidget);

  await expectLater(
    find.byKey(const ValueKey<String>('aesp08_agent_panel_shell')),
    matchesGoldenFile(
      '../../../artifacts/workbench_aesp08_screenshots/aesp08_agent_panel_entries.png',
    ),
  );
}

Future<void> _captureConversationAgentSelector(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey<String>('aesp08_conversation_selector_shell'),
            child: SizedBox(
              width: 420,
              height: 820,
              child: ConversationSidebar(
                viewData: WorkbenchConversationViewData(
                  hasActiveProject: true,
                  toolCoreStatus: '当前工具展示：紧凑',
                  modelLabel: 'GPT-5',
                  modelOptions: const <SelectorOptionViewData>[
                    SelectorOptionViewData(id: 'gpt-5', label: 'GPT-5'),
                  ],
                  groupSelector: const ConversationGroupSelectorViewData(
                    currentGroupLabel: '长篇总控组',
                    headerSubtitle: '长篇总控组',
                    groupOptions: <SelectorOptionViewData>[],
                    primaryAgentLabel: '综合创作智能体',
                    primaryAgentDescription: '负责统筹当前小说协作。',
                    canSwitchGroup: false,
                  ),
                  agentSelector: const ConversationAgentSelectorViewData(
                    currentAgentLabel: '审阅智能体',
                    currentAgentId: 'reviewer',
                    currentAgentDescription: '负责结构与表述修订',
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
                    headerSubtitle: '结构修订',
                  ),
                  inputCapabilityContext:
                      const ConversationInputCapabilityContext(
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
                  workflowTitle: '章节协作',
                  workflowDescription: '围绕当前文档继续推进这一章。',
                  primaryActions: const [],
                  openingPanel: null,
                  openingState: null,
                  composerHint: '告诉我这一轮想推进的目标。',
                  conversationEntries: const [],
                  transcriptBlocks: const [],
                  transcriptLanes: const ConversationTranscriptLaneViewData(
                    stableHistoryBlocks: <TranscriptBlockViewData>[],
                    currentRoundToolBlocks: <TranscriptBlockViewData>[],
                    streamingAppendixBlocks: <TranscriptBlockViewData>[],
                    footerBlocks: <TranscriptBlockViewData>[],
                  ),
                  pendingOptions: const [],
                  subAgentRuns: const [],
                  retryRequest: null,
                  sessionHistoryEntries: const [],
                  activeSessionId: 'session_aesp08',
                  showSessionHistory: false,
                  generationStatus: '',
                  isGenerating: false,
                ),
                actionHandler: const _FakeConversationActionHandler(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // The sidebar surfaces the workflow title and the configured agent label;
  // the agent selector chips render the agent option labels.
  expect(find.text('章节协作'), findsWidgets);
  expect(find.text('审阅智能体'), findsWidgets);

  await expectLater(
    find.byKey(const ValueKey<String>('aesp08_conversation_selector_shell')),
    matchesGoldenFile(
      '../../../artifacts/workbench_aesp08_screenshots/aesp08_conversation_agent_selector.png',
    ),
  );
}

class _FakeConversationActionHandler implements ConversationActionHandler {
  const _FakeConversationActionHandler();

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

class _FakeResourceManagerActionHandler
    implements ResourceManagerActionHandler {
  const _FakeResourceManagerActionHandler();

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
  void onWorkspaceCommandSubmitted(WorkspaceCommandRequestViewData request) {}

  @override
  void onWorkspaceImportFilesPickRequested(
    WorkspaceCommandRequestViewData request,
  ) {}

  @override
  void onWorkspaceImportDirectoryPickRequested(
    WorkspaceCommandRequestViewData request,
  ) {}
}
