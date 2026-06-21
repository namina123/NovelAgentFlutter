import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/application/services/workbench_pane_view_data_mapper_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/resource_manager_action_handler.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_create_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_information_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/resource_manager_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'resource manager panel keeps only file tools and resource tree',
    (WidgetTester tester) async {
      final handler = _FakeResourceManagerActionHandler();
      const mapper = WorkbenchPaneViewDataMapperService();
      final baseViewData = WorkbenchViewData.initial().copyWith(
        projectName: '项目 A',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 720,
              child: ResourceManagerPanel(
                viewData: mapper.toResourceViewData(baseViewData),
                actionHandler: handler,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('快速操作'), findsOneWidget);
      expect(find.text('浏览'), findsOneWidget);
      expect(find.text('工作区入口'), findsNothing);
      expect(find.byTooltip('导入文件'), findsOneWidget);
      expect(find.byTooltip('新文件'), findsOneWidget);
      expect(find.byTooltip('保存当前文档'), findsOneWidget);
      expect(find.byTooltip('更多文件操作'), findsOneWidget);
      expect(find.byTooltip('新文件夹'), findsNothing);
      expect(find.byTooltip('模型与接口设置'), findsNothing);
      expect(find.byType(CustomScrollView), findsNothing);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    },
  );

  testWidgets(
    'resource manager panel keeps a single scroll model in compact height',
    (WidgetTester tester) async {
      final handler = _FakeResourceManagerActionHandler();
      const mapper = WorkbenchPaneViewDataMapperService();
      final baseViewData = WorkbenchViewData.initial().copyWith(
        projectName: '项目 A',
        resourceEntries: List<ResourceEntryViewData>.generate(
          16,
          (index) => ResourceEntryViewData(
            id: 'entry_$index',
            title: '文件 $index',
            relativePath: 'chapters/file_$index.md',
            depth: index.isEven ? 0 : 1,
            isDirectory: index == 0,
            childCount: index == 0 ? 15 : 0,
            hasChildren: index == 0,
            isExpanded: index == 0,
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 360,
              child: ResourceManagerPanel(
                viewData: mapper.toResourceViewData(baseViewData),
                actionHandler: handler,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(CustomScrollView), findsNothing);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('项目 A'), findsOneWidget);
    },
  );

  testWidgets(
    'resource manager file tools stay on one row at minimum sidebar width',
    (WidgetTester tester) async {
      final handler = _FakeResourceManagerActionHandler();
      const mapper = WorkbenchPaneViewDataMapperService();
      final baseViewData = WorkbenchViewData.initial().copyWith(
        projectName: '项目 A',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 252,
              height: 720,
              child: ResourceManagerPanel(
                viewData: mapper.toResourceViewData(baseViewData),
                actionHandler: handler,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final buttonFinders = [
        find.byTooltip('新文件'),
        find.byTooltip('导入文件'),
        find.byTooltip('新章节'),
        find.byTooltip('保存当前文档'),
        find.byTooltip('更多文件操作'),
      ];
      final topOffsets = buttonFinders
          .map((finder) => tester.getTopLeft(finder).dy)
          .toList(growable: false);

      final minTop = topOffsets.reduce(
        (left, right) => left < right ? left : right,
      );
      final maxTop = topOffsets.reduce(
        (left, right) => left > right ? left : right,
      );

      expect(maxTop - minTop, lessThan(10));

      await tester.tap(find.byTooltip('更多文件操作'));
      await tester.pumpAndSettle();

      expect(find.text('新文件夹'), findsOneWidget);

      await tester.tap(find.text('新文件夹'));
      await tester.pumpAndSettle();

      expect(handler.createFolderRequestedCount, 1);
    },
  );

  testWidgets(
    'resource manager panel keeps information summaries out of file sidebar',
    (WidgetTester tester) async {
      final handler = _FakeResourceManagerActionHandler();
      const mapper = WorkbenchPaneViewDataMapperService();
      final baseViewData = WorkbenchViewData.initial().copyWith(
        projectName: '项目 A',
        informationViewData: const WorkbenchInformationViewData(
          summary: '已整理 4 组资料摘要',
          usageSummary: '本轮已使用：知识、巧思；本轮未使用：研究、引用边界',
          entries: <WorkbenchInformationEntryViewData>[
            WorkbenchInformationEntryViewData(
              id: 'knowledge_projection',
              title: '知识摘要',
              subtitle: '已整理的长期设定与世界事实',
              summary: '查看当前 knowledge 卡片的用户可读摘要。',
              statusLabel: '知识',
              mountStatusLabel: '已挂载',
              usageLabel: '本轮已使用 1 次',
              sourceOfTruthSummary: '来源：project-information://knowledge_cards',
              sourceIdentitySummary:
                  '来源类型：来源-source-1 / `imports/reference/source-1.txt` / kind:`user`',
              actionLabel: '打开摘要',
              relativePath: 'knowledge/项目知识摘要.md',
            ),
            WorkbenchInformationEntryViewData(
              id: 'design_projection',
              title: '巧思与设计',
              subtitle: '角色设计、结构巧思与创作方案',
              summary: '查看 design element 的用户可读摘要。',
              statusLabel: '巧思',
              usageLabel: '本轮已使用 1 次',
              actionLabel: '打开摘要',
              relativePath: 'knowledge/设计元素摘要.md',
            ),
            WorkbenchInformationEntryViewData(
              id: 'research_projection',
              title: '研究摘要',
              subtitle: '资料研究、事实摘录与创作建议',
              summary: '查看 research note 的用户可读摘要。',
              statusLabel: '研究',
              mountStatusLabel: '已挂载',
              usageLabel: '本轮未使用',
              riskLabel: '资料太旧',
              sourceOfTruthSummary: '来源：project-information://research_notes',
              actionLabel: '打开摘要',
              relativePath: 'research/资料研究摘要.md',
            ),
            WorkbenchInformationEntryViewData(
              id: 'reference_projection',
              title: '引用边界',
              subtitle: '引用作品关系、用途边界与风险说明',
              summary: '查看 reference work 的边界与风险摘要。',
              statusLabel: '引用',
              usageLabel: '本轮未使用',
              riskLabel: '还没确认边界',
              actionLabel: '打开摘要',
              relativePath: 'references/引用作品边界.md',
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 720,
              child: ResourceManagerPanel(
                viewData: mapper.toResourceViewData(baseViewData),
                actionHandler: handler,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('资料与设定'), findsNothing);
      expect(find.text('知识摘要'), findsNothing);
      expect(find.text('巧思与设计'), findsNothing);
      expect(find.text('研究摘要'), findsNothing);
      expect(find.text('引用边界'), findsNothing);
      expect(find.text('待确认知识'), findsNothing);
      expect(find.text('浏览'), findsOneWidget);
    },
  );
}

class _FakeResourceManagerActionHandler
    implements ResourceManagerActionHandler {
  int createFolderRequestedCount = 0;
  final List<String> selectedEntries = <String>[];

  @override
  void onAgentEcosystemRequested() {}

  @override
  void onCreateChapterRequested() {}

  @override
  void onCreateFileRequested() {}

  @override
  void onCreateFolderRequested() {
    createFolderRequestedCount += 1;
  }

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
  void onResourceEntrySelected(String entryId) {
    selectedEntries.add(entryId);
  }

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
