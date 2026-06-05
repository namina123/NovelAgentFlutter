import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/resource_manager_action_handler.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_agent_group_panel_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_create_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_project_panel_action_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_project_panel_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workspace_command_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/workbench_project_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('workbench project panel stays minimal and project-scoped', (
    WidgetTester tester,
  ) async {
    final handler = _FakeResourceHandler();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 900,
            child: WorkbenchProjectPanel(
              viewData: const WorkbenchProjectPanelViewData(
                projectName: '星港档案',
                projectSubtitle: '长篇科幻项目',
                workflowTitle: '长任务推进',
                workflowDescription: '连续推进当前项目章节。',
                modelLabel: 'GPT-4.1',
                agentGroupLabel: '长篇总控组',
                primaryAgentLabel: '综合创作智能体',
                projectAgentGroupPanel: ProjectAgentGroupPanelViewData(
                  currentGroupLabel: '长篇总控组',
                  primaryAgentLabel: '综合创作智能体',
                  summary: '当前项目已确定默认协作组，写作时会沿用这套协作摘要。',
                  actionTitle: '项目智能体组',
                  actionDescription: '查看当前项目协作摘要，并按需调整默认协作组。',
                  canConfigure: true,
                ),
                hasActiveProject: true,
                primaryActions: [
                  WorkbenchProjectPanelActionViewData(
                    icon: Icons.badge_outlined,
                    title: '整理设定',
                    description: '查看或调整当前项目的基础信息、设定摘要和关键元数据。',
                    actionId: 'edit_project_info',
                  ),
                  WorkbenchProjectPanelActionViewData(
                    icon: Icons.edit_note_rounded,
                    title: '写作准备',
                    description: '确认当前作品的资料、文档和写作上下文已经同步到最新状态。',
                    actionId: 'refresh_project',
                  ),
                  WorkbenchProjectPanelActionViewData(
                    icon: Icons.play_circle_outline_rounded,
                    title: '开始写作',
                    description: '从当前作品继续写第一章、续写下一章或进入新的章节草稿。',
                    actionId: 'refresh_project',
                  ),
                ],
                assetActions: [
                  WorkbenchProjectPanelActionViewData(
                    icon: Icons.auto_awesome_mosaic_outlined,
                    title: '项目资产',
                    description: '查看和整理当前项目的风格、表达限制、伏笔、时间线与关系。',
                    actionId: 'project_assets',
                  ),
                ],
              ),
              resourceHandler: handler,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('项目摘要'), findsOneWidget);
    expect(find.text('当前项目动作'), findsOneWidget);
    expect(find.text('当前协作摘要'), findsOneWidget);
    expect(find.text('项目资料'), findsOneWidget);
    expect(find.text('项目资产'), findsOneWidget);
    expect(find.text('项目智能体组'), findsNothing);
    expect(find.text('整理设定'), findsOneWidget);
    expect(find.text('写作准备'), findsOneWidget);
    expect(find.text('开始写作'), findsOneWidget);
    expect(find.text('协作设置'), findsOneWidget);
    expect(find.text('当前会话智能体'), findsNothing);
    expect(find.text('审阅智能体'), findsNothing);
    expect(find.text('智能体生态'), findsNothing);
    expect(find.text('提示模板'), findsNothing);
    expect(find.text('项目资料与规则'), findsNothing);
    expect(find.text('打开项目'), findsNothing);
    expect(find.text('新建项目'), findsNothing);
    expect(find.textContaining('run_center_contract'), findsNothing);
    expect(find.textContaining('workflowStrategyId'), findsNothing);
    expect(find.textContaining('tool_call'), findsNothing);
    expect(find.textContaining('session.goal'), findsNothing);

    await tester.tap(find.text('整理设定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('写作准备'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始写作'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('协作设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('协作设置'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('项目资产'));
    await tester.tap(find.text('项目资产'));
    await tester.pumpAndSettle();

    expect(handler.editProjectInfoRequestedCount, 1);
    expect(handler.refreshFilesRequestedCount, 2);
    expect(handler.projectAgentGroupRequestedCount, 1);
    expect(handler.projectAssetsRequestedCount, 1);
    expect(handler.templatesRequestedCount, 0);
    expect(handler.agentEcosystemRequestedCount, 0);
  });
}

class _FakeResourceHandler implements ResourceManagerActionHandler {
  int editProjectInfoRequestedCount = 0;
  int refreshFilesRequestedCount = 0;
  int projectAgentGroupRequestedCount = 0;
  int projectAssetsRequestedCount = 0;
  int templatesRequestedCount = 0;
  int agentEcosystemRequestedCount = 0;

  @override
  void onAgentEcosystemRequested() {
    agentEcosystemRequestedCount++;
  }

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
  void onEditProjectInfoRequested() {
    editProjectInfoRequestedCount++;
  }

  @override
  void onImportRequested() {}

  @override
  void onModelSettingsRequested() {}

  @override
  void onOpenProjectRequested() {}

  @override
  void onProjectAgentGroupDismissed() {}

  @override
  void onProjectAgentGroupRequested() {
    projectAgentGroupRequestedCount++;
  }

  @override
  void onProjectAgentGroupSelected(String groupId) {}

  @override
  void onProjectAssetsRequested() {
    projectAssetsRequestedCount++;
  }

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
  void onRefreshFilesRequested() {
    refreshFilesRequestedCount++;
  }

  @override
  void onResourceEntrySelected(String entryId) {}

  @override
  void onReviewsRequested() {}

  @override
  void onSaveCurrentRequested() {}

  @override
  void onTasksRequested() {}

  @override
  void onTemplatesRequested() {
    templatesRequestedCount++;
  }

  @override
  void onWorkspaceCommandDismissed() {}

  @override
  void onWorkspaceImportFilesPickRequested(
    WorkspaceCommandRequestViewData request,
  ) {}

  @override
  void onWorkspaceCommandSubmitted(WorkspaceCommandRequestViewData request) {}
}
