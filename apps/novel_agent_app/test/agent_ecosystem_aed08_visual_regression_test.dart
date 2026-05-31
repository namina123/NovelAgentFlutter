import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/navigation/app_shell_navigation_action_handler.dart';
import 'package:novel_agent_app/app/routing/app_destination.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/agent_ecosystem/presentation/contracts/agent_ecosystem_action_handler.dart';
import 'package:novel_agent_app/features/agent_ecosystem/presentation/models/ecosystem_editor_view_data.dart';
import 'package:novel_agent_app/features/agent_ecosystem/presentation/models/ecosystem_import_command_view_data.dart';
import 'package:novel_agent_app/features/agent_ecosystem/presentation/models/project_skill_loadout_view_data.dart';
import 'package:novel_agent_app/features/agent_ecosystem/presentation/widgets/project_skill_loadout_detail_panel.dart';
import 'package:novel_agent_app/features/project_assets/presentation/contracts/project_assets_action_handler.dart';
import 'package:novel_agent_app/features/project_assets/presentation/models/project_assets_view_data.dart';
import 'package:novel_agent_app/features/project_assets/presentation/widgets/expression_constraint_binding_editor_panel.dart';
import 'package:novel_agent_app/features/project_assets/presentation/widgets/project_assets_entry_list_panel.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/resource_manager_action_handler.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_create_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/resource_entry_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_resource_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workspace_command_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/resource_manager_panel.dart';
import 'package:novel_agent_app/shared/widgets/app_shell_activity_rail.dart';
import 'package:novel_agent_app/shared/widgets/panel_surface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captures AED-08 visual verification screenshots', (
    WidgetTester tester,
  ) async {
    final artifactsDir = Directory(
      '${_resolveRepoRoot()}${Platform.pathSeparator}artifacts${Platform.pathSeparator}agent_ecosystem_aed08_screenshots',
    )..createSync(recursive: true);
    expect(artifactsDir.existsSync(), isTrue);

    await _captureNavigationRail(tester);
    await _captureResourcePanel(tester);
    await _captureSkillLoadoutDetail(tester);
    await _captureExpressionConstraintPanel(tester);

    for (final fileName in const <String>[
      'aed08_navigation_agent_ecosystem.png',
      'aed08_resource_panel_without_long_task.png',
      'aed08_skill_loadout_compact_detail.png',
      'aed08_expression_constraint_discovery.png',
    ]) {
      expect(
        File(
          '${artifactsDir.path}${Platform.pathSeparator}$fileName',
        ).existsSync(),
        isTrue,
        reason: '缺少截图产物：$fileName',
      );
    }
  });
}

Future<void> _captureNavigationRail(WidgetTester tester) async {
  _setViewport(tester, const Size(1200, 900));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey<String>('aed08_navigation_shell'),
            child: SizedBox(
              width: 88,
              height: 620,
              child: AppShellActivityRail(
                selectedDestination: AppDestination.agentEcosystem,
                actionHandler: const _FakeNavigationHandler(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('工作'), findsOneWidget);
  expect(find.text('工作台'), findsOneWidget);
  expect(find.text('智能体生态'), findsOneWidget);
  expect(find.text('长任务'), findsOneWidget);

  await expectLater(
    find.byKey(const ValueKey<String>('aed08_navigation_shell')),
    matchesGoldenFile(
      '../../../artifacts/agent_ecosystem_aed08_screenshots/aed08_navigation_agent_ecosystem.png',
    ),
  );
}

Future<void> _captureResourcePanel(WidgetTester tester) async {
  _setViewport(tester, const Size(1200, 900));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey<String>('aed08_resource_shell'),
            child: SizedBox(
              width: 320,
              height: 760,
              child: ResourceManagerPanel(
                viewData: const WorkbenchResourceViewData(
                  projectName: '星港档案',
                  projectSubtitle: '长篇科幻项目',
                  resourceEntries: <ResourceEntryViewData>[
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
                    ),
                    ResourceEntryViewData(
                      id: 'assets',
                      title: '资产',
                      relativePath: 'assets/',
                      depth: 0,
                      isDirectory: true,
                      hasChildren: true,
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

  expect(find.text('文件'), findsOneWidget);
  expect(find.text('项目目录'), findsOneWidget);
  expect(find.text('长任务运行'), findsNothing);
  expect(find.text('工作区入口'), findsNothing);

  await expectLater(
    find.byKey(const ValueKey<String>('aed08_resource_shell')),
    matchesGoldenFile(
      '../../../artifacts/agent_ecosystem_aed08_screenshots/aed08_resource_panel_without_long_task.png',
    ),
  );
}

Future<void> _captureSkillLoadoutDetail(WidgetTester tester) async {
  _setViewport(tester, const Size(1600, 1000));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey<String>('aed08_skill_loadout_shell'),
            child: SizedBox(
              width: 520,
              height: 860,
              child: ProjectSkillLoadoutDetailPanel(
                viewData: const ProjectSkillLoadoutDetailViewData(
                  agentId: 'reviewer',
                  agentName: '审阅智能体',
                  agentDescription: '负责当前项目的结构与表达修订。',
                  sourceLabel: '项目装载',
                  summary: '技能组 0 个，额外技能 0 个，禁用技能 0 个。',
                  expressionConstraintSummary:
                      '去 AI / 真实性 / 叙事边界这类内容不属于技能装载，请从“表达限制”进入项目级约束系统，并可继续按当前智能体定向绑定。',
                  hasPendingChanges: true,
                  skillGroups: <ProjectSkillLoadoutSelectableItemViewData>[],
                  extraSkills: <ProjectSkillLoadoutSelectableItemViewData>[],
                  resolvedSkills: <ProjectSkillLoadoutResolvedSkillViewData>[],
                  historyEntries: <ProjectSkillLoadoutHistoryItemViewData>[],
                  issues: <String>[],
                ),
                actionHandler: const _FakeAgentEcosystemActionHandler(),
                projectAvailable: true,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('应用装载'), findsOneWidget);
  expect(find.text('回到已保存'), findsOneWidget);
  expect(find.text('另存为技能组'), findsOneWidget);
  expect(find.text('记为历史快照'), findsNothing);
  expect(find.text('诊断'), findsNothing);

  await expectLater(
    find.byKey(const ValueKey<String>('aed08_skill_loadout_shell')),
    matchesGoldenFile(
      '../../../artifacts/agent_ecosystem_aed08_screenshots/aed08_skill_loadout_compact_detail.png',
    ),
  );
}

Future<void> _captureExpressionConstraintPanel(WidgetTester tester) async {
  _setViewport(tester, const Size(1600, 1000));
  final viewData = ProjectAssetsViewData(
    title: '项目资产',
    description: '表达限制是项目级写作约束系统；当前正从智能体 reviewer 进入，可继续为它定向绑定内置或自定义预设。',
    status: '已加载表达限制预设。',
    activeTabId: 'expression_constraints',
    entryAgentContextId: 'reviewer',
    tabs: const <ProjectAssetsTabViewData>[
      ProjectAssetsTabViewData(id: 'styles', label: '风格'),
      ProjectAssetsTabViewData(id: 'expression_constraints', label: '表达限制'),
      ProjectAssetsTabViewData(id: 'foreshadows', label: '伏笔'),
      ProjectAssetsTabViewData(id: 'timelines', label: '时间线'),
      ProjectAssetsTabViewData(id: 'relationships', label: '关系'),
      ProjectAssetsTabViewData(id: 'graph', label: '图谱'),
    ],
    entries: const <ProjectAssetEntryViewData>[
      ProjectAssetEntryViewData(
        id: 'de_ai',
        title: '去 AI 风',
        subtitle: '降低模板化表达、解释腔和过度工整的平衡句。',
        badge: '已启用',
        relativePath: 'builtin://expression_constraints/de_ai',
        meta: '自然表达 · 内置预设 · 全项目默认',
        isSelected: true,
      ),
    ],
    inspector: ProjectAssetsInspectorViewData.empty(),
    timeline: ProjectAssetsTimelineViewData.empty(),
    graph: ProjectAssetsGraphViewData.empty(),
    styleEditor: StyleProfileEditorViewData.empty(),
    expressionConstraintEditor: const ExpressionConstraintBindingEditorViewData(
      profileId: 'de_ai',
      displayName: '去 AI 风',
      summary: '降低模板化表达、解释腔和过度工整的平衡句。',
      kindLabel: '自然表达',
      sourcePath: 'builtin://expression_constraints/de_ai',
      entryAgentContextId: 'reviewer',
      recommendedScopeText: '项目类型 novel, long_novel',
      rules: <String>['少用工整排比。'],
      riskSignals: <String>['总而言之'],
      enabled: true,
      defaultForProject: true,
      availableAgentOptions: <ExpressionConstraintSelectableOptionViewData>[
        ExpressionConstraintSelectableOptionViewData(
          id: 'reviewer',
          label: '审阅智能体',
        ),
      ],
      availableModeOptions: <ExpressionConstraintSelectableOptionViewData>[
        ExpressionConstraintSelectableOptionViewData(
          id: 'full_outline_consensus',
          label: '全书共拟式长篇',
          note: '先一起谈清全书走向，再进入执行期。',
        ),
      ],
      availableStageOptions: <ExpressionConstraintSelectableOptionViewData>[
        ExpressionConstraintSelectableOptionViewData(
          id: 'book_premise',
          label: '故事总前提',
          note: '全书共拟式长篇',
          groupId: 'full_outline_consensus',
        ),
      ],
      selectedAgentIds: <String>['reviewer'],
      selectedModeIds: <String>['full_outline_consensus'],
      selectedStageIds: <String>['book_premise'],
      targetAgentIdsText: 'reviewer',
      targetModeIdsText: 'full_outline_consensus',
      targetStageIdsText: 'book_premise',
      weightText: '100',
      hasBinding: true,
      isBuiltin: true,
    ),
    foreshadowEditor: ForeshadowRecordEditorViewData.empty(),
    isLoading: false,
  );
  const actionHandler = _FakeProjectAssetsActionHandler();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: RepaintBoundary(
          key: const ValueKey<String>('aed08_expression_constraints_shell'),
          child: SizedBox(
            width: 1440,
            height: 900,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '项目资产',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  viewData.description,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  viewData.status,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5E6E74),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 320,
                        child: PanelSurface(
                          showBorder: true,
                          padding: EdgeInsets.zero,
                          child: ProjectAssetsEntryListPanel(
                            viewData: viewData,
                            actionHandler: actionHandler,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PanelSurface(
                          showBorder: true,
                          padding: EdgeInsets.zero,
                          child: ExpressionConstraintBindingEditorPanel(
                            viewData: viewData.expressionConstraintEditor,
                            onSaveRequested: actionHandler
                                .onProjectAssetsSaveExpressionConstraintBindingRequested,
                            onRemoveRequested: actionHandler
                                .onProjectAssetsRemoveExpressionConstraintBindingRequested,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('表达限制'), findsWidgets);
  expect(find.textContaining('项目级写作约束系统'), findsAtLeastNWidgets(1));
  expect(find.text('当前预设 ID：de_ai'), findsOneWidget);
  expect(find.text('内置预设'), findsWidgets);

  await expectLater(
    find.byKey(const ValueKey<String>('aed08_expression_constraints_shell')),
    matchesGoldenFile(
      '../../../artifacts/agent_ecosystem_aed08_screenshots/aed08_expression_constraint_discovery.png',
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
      '${current.path}${Platform.pathSeparator}docs${Platform.pathSeparator}agent-ecosystem-entry-density-session-order-2026-05-29.md',
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

class _FakeNavigationHandler implements AppShellNavigationActionHandler {
  const _FakeNavigationHandler();

  @override
  Future<void> onAppShellDestinationRequested(
    AppDestination destination,
  ) async {}
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

class _FakeAgentEcosystemActionHandler implements AgentEcosystemActionHandler {
  const _FakeAgentEcosystemActionHandler();

  @override
  void onAgentEcosystemBackRequested() {}

  @override
  void onCreateAgentGroupRequested() {}

  @override
  void onCreateAgentRequested() {}

  @override
  void onCreateSkillGroupRequested() {}

  @override
  void onCreateSkillRequested() {}

  @override
  void onEditEcosystemEntryRequested(String entryId) {}

  @override
  void onEcosystemEditorDeleteRequested(
    EcosystemEditorRequestViewData request,
  ) {}

  @override
  void onEcosystemEditorDismissed() {}

  @override
  void onEcosystemEditorSubmitted(EcosystemEditorRequestViewData request) {}

  @override
  void onEcosystemEntrySelected(String entryId) {}

  @override
  void onEcosystemImportDismissed() {}

  @override
  void onEcosystemImportSubmitted(EcosystemImportRequestViewData request) {}

  @override
  void onEcosystemRefreshRequested() {}

  @override
  void onEcosystemTabSelected(String tabId) {}

  @override
  void onGenerateIndexRequested() {}

  @override
  void onImportEcosystemPackageRequested() {}

  @override
  void onOpenEcosystemEntrySourceRequested(String entryId) {}

  @override
  void onProjectSkillLoadoutApplyRequested(String agentId) {}

  @override
  void onProjectSkillLoadoutDisabledSkillToggled(
    String agentId,
    String skillId,
    bool disabled,
  ) {}

  @override
  void onProjectSkillLoadoutExtraSkillToggled(
    String agentId,
    String skillId,
    bool selected,
  ) {}

  @override
  void onProjectSkillLoadoutHistoryCaptureRequested(
    String agentId,
    String title,
  ) {}

  @override
  void onProjectSkillLoadoutHistoryRestoreRequested(
    String agentId,
    String historyEntryId,
  ) {}

  @override
  void onProjectSkillLoadoutResetRequested(String agentId) {}

  @override
  void onProjectSkillLoadoutSaveAsGroupRequested(
    String agentId,
    String groupId,
    String displayName,
    String description,
  ) {}

  @override
  void onProjectSkillLoadoutSkillGroupToggled(
    String agentId,
    String groupId,
    bool selected,
  ) {}
}

class _FakeProjectAssetsActionHandler implements ProjectAssetsActionHandler {
  const _FakeProjectAssetsActionHandler();

  @override
  void onProjectAssetsBackRequested() {}

  @override
  void onProjectAssetsDeleteRequested({
    required String kind,
    required String id,
  }) {}

  @override
  void onProjectAssetsEntrySelected(String entryId) {}

  @override
  void onProjectAssetsExportBundleRequested(
    ProjectAssetBundleExportRequestViewData request,
  ) {}

  @override
  void onProjectAssetsImportBundleRequested(
    ProjectAssetBundleImportRequestViewData request,
  ) {}

  @override
  void onProjectAssetsNewRequested() {}

  @override
  void onProjectAssetsReferenceSelected(String referenceKey) {}

  @override
  void onProjectAssetsRefreshRequested() {}

  @override
  void onProjectAssetsRemoveExpressionConstraintBindingRequested(
    String profileId,
  ) {}

  @override
  void onProjectAssetsSaveExpressionConstraintBindingRequested(
    ExpressionConstraintBindingEditorRequestViewData request,
  ) {}

  @override
  void onProjectAssetsSaveForeshadowRequested(
    ForeshadowRecordEditorRequestViewData request,
  ) {}

  @override
  void onProjectAssetsSaveStyleRequested(
    StyleProfileEditorRequestViewData request,
  ) {}

  @override
  void onProjectAssetsTabSelected(String tabId) {}
}
