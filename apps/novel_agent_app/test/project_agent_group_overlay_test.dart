import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_agent_member_summary.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/resource_manager_action_handler.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_agent_group_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_agent_group_unsupported_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_agent_group_workspace_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_create_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workspace_command_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/agent_group_option_card.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/project_agent_group_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'project agent group overlay uses the same card widget for supported and unsupported groups',
    (tester) async {
      final handler = _FakeResourceHandler();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Stack(
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
                        members: [
                          OpeningAgentMemberSummary(
                            agentId: 'default_generalist',
                            displayName: '综合创作智能体',
                            role: '负责统筹当前长篇协作。',
                            isPrimary: true,
                            thinkingSupported: true,
                          ),
                        ],
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
                  actionHandler: handler,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.byType(AgentGroupOptionCard), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('opening_group_starter_long_task')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('opening_unsupported_group_deconstruction'),
        ),
        findsNothing,
      );
      expect(find.text('当前不可用智能体组'), findsOneWidget);
      expect(find.text('1 项'), findsOneWidget);
      expect(find.text('当前组成员'), findsOneWidget);
      expect(find.text('综合创作智能体 · 主智能体'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('opening_group_starter_long_task')),
      );
      await tester.pumpAndSettle();

      expect(handler.selectedGroupId, 'starter_long_task');

      await tester.tap(
        find.byKey(const ValueKey<String>('opening_unsupported_groups')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AgentGroupOptionCard), findsNWidgets(2));
      expect(
        find.byKey(
          const ValueKey<String>('opening_unsupported_group_deconstruction'),
        ),
        findsOneWidget,
      );
      expect(find.text('当前不可用'), findsOneWidget);

      await tester.tapAt(
        tester.getCenter(
          find.byKey(
            const ValueKey<String>('opening_unsupported_group_deconstruction'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(handler.selectedGroupId, 'starter_long_task');
    },
  );
}

class _FakeResourceHandler implements ResourceManagerActionHandler {
  @override
  void onLongTaskRunResumeRequested(String runId) {}
  String selectedGroupId = '';

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
  void onProjectAgentGroupSelected(String groupId) {
    selectedGroupId = groupId;
  }

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
