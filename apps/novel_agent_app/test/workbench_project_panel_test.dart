import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/resource_manager_action_handler.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_agent_group_panel_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_create_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_long_task_summary_view_data.dart';
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
                projectTypeId: 'novel',
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
                projectLongTaskSummary: ProjectLongTaskSummaryViewData(
                  title: '长任务运行',
                  summary: '运行中 1 · 待处理 1 · 共 2 条',
                  isLoading: false,
                  totalCount: 2,
                  activeCount: 1,
                  attentionCount: 1,
                  runs: <ProjectLongTaskRunSummaryViewData>[
                    ProjectLongTaskRunSummaryViewData(
                      id: 'run_waiting',
                      title: '连续不断的长任务',
                      subtitle: '按大纲自动推进',
                      statusLabel: '等待用户确认',
                      taskLabel: '检查点确认',
                      recentActivityLabel: '5 分钟前',
                      requiresAttention: true,
                      isActive: false,
                      attentionCalloutTitle: '当前运行停在待确认节点。',
                      attentionCalloutSummary: '',
                      diagnosisLabel: '',
                      diagnosisSummary: '当前运行正在等待用户确认。',
                      nextStepLabel: '下一步',
                      nextStepSummary: '先完成待确认事项，任务才会继续。',
                      reviewSummaryLine: '最近审稿：第 12 章审稿，建议补强冲突。',
                      repairSummaryLine: '返工状态：等待确认 · 第 12 章返工，待确认后进入返工。',
                      checkpointSummaryLine: '最近检查点：检查点确认，需要先确认本章检查点再继续。',
                      pendingSummaryLine: '待确认事项：待确认问题，请先确认是否接受当前审稿建议。',
                    ),
                  ],
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
                    icon: Icons.dataset_outlined,
                    title: '资料库',
                    description: '导入资料、提取语料并挂载到当前项目。',
                    actionId: 'project_rag',
                  ),
                  WorkbenchProjectPanelActionViewData(
                    icon: Icons.auto_awesome_mosaic_outlined,
                    title: '规则与资料卡',
                    description: '查看风格、表达限制、伏笔、时间线和项目资料卡。',
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

    expect(find.text('项目摘要'), findsNothing);
    expect(find.text('长任务现场'), findsOneWidget);
    expect(find.text('当前项目动作'), findsOneWidget);
    expect(find.text('协作设置'), findsWidgets);
    expect(find.text('写作资料'), findsOneWidget);
    expect(find.text('规则与资料卡'), findsOneWidget);
    expect(find.text('资料库'), findsOneWidget);
    expect(find.text('项目智能体组'), findsNothing);
    expect(find.text('当前运行停在待确认节点。'), findsOneWidget);
    expect(find.text('当前运行正在等待用户确认。'), findsOneWidget);
    expect(find.text('等待用户确认'), findsOneWidget);
    expect(find.textContaining('先完成待确认事项，任务才会继续。'), findsOneWidget);
    expect(find.textContaining('最近审稿：第 12 章审稿'), findsOneWidget);
    expect(find.textContaining('返工状态：等待确认'), findsOneWidget);
    expect(find.textContaining('最近检查点：检查点确认'), findsOneWidget);
    expect(find.textContaining('待确认事项：待确认问题'), findsOneWidget);
    expect(find.text('整理设定'), findsOneWidget);
    expect(find.text('写作准备'), findsOneWidget);
    expect(find.text('开始写作'), findsOneWidget);
    expect(find.text('协作设置'), findsWidgets);
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

    await tester.ensureVisible(find.text('整理设定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('整理设定'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('写作准备'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('写作准备'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('开始写作'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始写作'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('协作设置').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('协作设置').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('资料库'));
    await tester.tap(find.text('资料库'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('规则与资料卡'));
    await tester.tap(find.text('规则与资料卡'));
    await tester.pumpAndSettle();

    expect(handler.editProjectInfoRequestedCount, 1);
    expect(handler.refreshFilesRequestedCount, 2);
    expect(handler.projectAgentGroupRequestedCount, 1);
    expect(handler.projectAssetsRequestedCount, 1);
    expect(handler.projectRagRequestedCount, 1);
    expect(handler.templatesRequestedCount, 0);
    expect(handler.agentEcosystemRequestedCount, 0);
  });

  testWidgets('knowledge base project panel stays compact and hides writing-only sections', (
    WidgetTester tester,
  ) async {
    final handler = _FakeResourceHandler();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 760,
            child: WorkbenchProjectPanel(
              viewData: const WorkbenchProjectPanelViewData(
                projectName: '未命名资料知识库',
                projectSubtitle: 'knowledge_base · SQLite · 按大纲自动推进',
                projectTypeId: 'knowledge_base',
                workflowTitle: '知识库工作台',
                workflowDescription: '资料整理与提取',
                modelLabel: 'GUI Viewmodel Probe Provider · deepseek-v4-flash',
                agentGroupLabel: '默认知识库整理',
                primaryAgentLabel: '综合创作智能体',
                projectAgentGroupPanel: ProjectAgentGroupPanelViewData(
                  currentGroupLabel: '默认知识库整理',
                  primaryAgentLabel: '综合创作智能体',
                  summary: '',
                  actionTitle: '项目智能体组',
                  actionDescription: '调整当前项目的知识库整理协作组。',
                  canConfigure: true,
                ),
                projectLongTaskSummary: ProjectLongTaskSummaryViewData(
                  title: '长任务运行',
                  summary: '总数 0 · 运行中 0 · 待处理 0',
                  isLoading: false,
                  totalCount: 0,
                  activeCount: 0,
                  attentionCount: 0,
                  runs: <ProjectLongTaskRunSummaryViewData>[],
                ),
                hasActiveProject: true,
                primaryActions: [
                  WorkbenchProjectPanelActionViewData(
                    icon: Icons.badge_outlined,
                    title: '项目信息',
                    description: '查看或调整当前项目基础信息与关键元数据。',
                    actionId: 'edit_project_info',
                  ),
                ],
                assetActions: [],
              ),
              resourceHandler: handler,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('项目摘要'), findsNothing);
    expect(find.text('长任务现场'), findsNothing);
    expect(find.text('写作资料'), findsNothing);
    expect(find.text('资料库'), findsNothing);
    expect(find.text('规则与资料卡'), findsNothing);
    expect(find.text('当前项目动作'), findsOneWidget);
    expect(find.text('协作设置'), findsWidgets);
    expect(find.text('默认知识库整理'), findsWidgets);
  });
}

class _FakeResourceHandler implements ResourceManagerActionHandler {
  int editProjectInfoRequestedCount = 0;
  int refreshFilesRequestedCount = 0;
  int projectAgentGroupRequestedCount = 0;
  int projectAssetsRequestedCount = 0;
  int projectRagRequestedCount = 0;
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
  void onProjectRagRequested() {
    projectRagRequestedCount++;
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
  void onWorkspaceImportDirectoryPickRequested(
    WorkspaceCommandRequestViewData request,
  ) {}

  @override
  void onWorkspaceCommandSubmitted(WorkspaceCommandRequestViewData request) {}
}
