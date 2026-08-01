import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/application/services/workbench_pane_view_data_mapper_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/resource_manager_action_handler.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_group_selector_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_create_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/workbench_navigation_sidebar.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/workbench_object_panel_body.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('left sidebar keeps a continuous shell in compact height', (
    tester,
  ) async {
    const mapper = WorkbenchPaneViewDataMapperService();
    final base = WorkbenchViewData.initial().copyWith(
      projectName: '星港档案',
      projectSubtitle: '长篇科幻项目',
      contextSummary: '已载入人物、阵营与时间线约束。',
      workflowTitle: '长任务推进',
      workflowDescription: '连续推进当前项目章节。',
      modelLabel: 'GPT-4.1',
      resourceEntries: List<ResourceEntryViewData>.generate(
        18,
        (index) => ResourceEntryViewData(
          id: 'entry_$index',
          title: index == 0 ? 'chapters' : '文件 $index',
          relativePath: index == 0 ? 'chapters' : 'chapters/file_$index.md',
          depth: index == 0 ? 0 : 1,
          isDirectory: index == 0,
          childCount: index == 0 ? 17 : 0,
          hasChildren: index == 0,
          isExpanded: index == 0,
        ),
      ),
      groupSelector: const ConversationGroupSelectorViewData(
        currentGroupLabel: '长篇总控组',
        groupOptions: [],
        primaryAgentLabel: '综合创作智能体',
        primaryAgentDescription: '',
        canSwitchGroup: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 292,
            height: 380,
            child: WorkbenchNavigationSidebar(
              resourceListenable: ValueNotifier(
                mapper.toResourceViewData(base),
              ),
              canvasListenable: ValueNotifier(mapper.toCanvasViewData(base)),
              conversationListenable: ValueNotifier(
                mapper.toConversationViewData(base),
              ),
              resourceHandler: const _FakeResourceHandler(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('文件'), findsWidgets);
    expect(find.byType(WorkbenchObjectPanelBody), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('workbench_object_panel_body')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('resource_manager_scroll_view')),
      findsNothing,
    );
    expect(find.byType(CustomScrollView), findsNothing);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    await tester.tap(find.text('项目'));
    await tester.pumpAndSettle();

    expect(find.byType(WorkbenchObjectPanelBody), findsOneWidget);
    expect(find.text('项目摘要'), findsNothing);
    expect(find.text('当前项目动作'), findsOneWidget);
    expect(find.text('协作设置'), findsWidgets);
    expect(find.text('写作资料'), findsOneWidget);
    expect(find.text('资料库'), findsOneWidget);
    expect(find.text('长任务'), findsNothing);
  });
}

class _FakeResourceHandler implements ResourceManagerActionHandler {
  @override
  void onLongTaskRunResumeRequested(String runId) {}

  @override
  void onLongTaskStationRequested() {}
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
