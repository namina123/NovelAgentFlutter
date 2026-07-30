import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/resource_manager_action_handler.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_agent_group_panel_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_create_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_agent_panel_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_project_panel_action_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workspace_command_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/workbench_agent_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'workbench agent panel exposes current agent summary and project group entry',
    (tester) async {
      final handler = _FakeResourceHandler();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 900,
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
                    summary: '当前项目已确定默认协作组，写作时会沿用这套协作摘要。',
                    actionTitle: '项目智能体组',
                    actionDescription: '查看当前项目协作摘要，并按需调整默认协作组。',
                    canConfigure: true,
                  ),
                  agentWorkspaceActions: [
                    WorkbenchProjectPanelActionViewData(
                      icon: Icons.auto_fix_high_outlined,
                      title: '技能装载',
                      description: '查看当前智能体在本项目中的技能组合、补充技能和禁用项。',
                      actionId: 'agent_skill_loadout',
                    ),
                    WorkbenchProjectPanelActionViewData(
                      icon: Icons.rule_folder_outlined,
                      title: '表达限制',
                      description: '进入项目级写作约束系统，管理内置或自定义表达限制方案，并按当前智能体进一步定向绑定。',
                      actionId: 'project_expression_constraints',
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

      expect(find.text('协作概览'), findsOneWidget);
      expect(find.text('项目协作基线'), findsNothing);
      expect(find.text('当前分工'), findsOneWidget);
      expect(find.text('当前智能体'), findsOneWidget);
      expect(find.text('审阅智能体'), findsWidgets);
      expect(find.text('项目基线组'), findsOneWidget);
      expect(find.text('长篇总控组'), findsWidgets);
      expect(find.text('组主智能体'), findsOneWidget);
      expect(find.text('综合创作智能体'), findsWidgets);
      expect(find.text('当前项目已接入 2 个可供会话使用的智能体。'), findsOneWidget);
      expect(find.text('工作入口'), findsOneWidget);
      expect(find.text('协作设置'), findsOneWidget);
      expect(find.text('技能装载'), findsOneWidget);
      expect(find.text('表达限制'), findsOneWidget);
      expect(find.textContaining('项目级写作约束系统'), findsNothing);
      expect(find.text('项目资料'), findsNothing);
      expect(find.text('项目信息'), findsNothing);

      await tester.tap(find.text('协作设置'));
      await tester.pumpAndSettle();

      expect(handler.projectAgentGroupRequestedCount, 1);
      expect(handler.projectAssetsRequestedCount, 0);
      expect(handler.agentEcosystemRequestedCount, 0);
      expect(handler.currentAgentSkillLoadoutRequestedCount, 0);
      expect(handler.currentAgentExpressionConstraintsRequestedCount, 0);

      await tester.tap(find.text('技能装载'));
      await tester.pumpAndSettle();

      expect(handler.currentAgentSkillLoadoutRequestedCount, 1);
      expect(handler.agentEcosystemRequestedCount, 0);

      await tester.ensureVisible(find.text('表达限制'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('表达限制'));
      await tester.pumpAndSettle();

      expect(handler.currentAgentExpressionConstraintsRequestedCount, 1);
      expect(handler.projectAssetsRequestedCount, 0);
    },
  );
}

class _FakeResourceHandler implements ResourceManagerActionHandler {
  int projectAgentGroupRequestedCount = 0;
  int projectAssetsRequestedCount = 0;
  int agentEcosystemRequestedCount = 0;
  int currentAgentSkillLoadoutRequestedCount = 0;
  int currentAgentExpressionConstraintsRequestedCount = 0;

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
  void onCurrentAgentExpressionConstraintsRequested() {
    currentAgentExpressionConstraintsRequestedCount++;
  }

  @override
  void onCurrentAgentSkillLoadoutRequested() {
    currentAgentSkillLoadoutRequestedCount++;
  }

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
