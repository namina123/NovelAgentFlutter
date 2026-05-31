import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/application/services/workbench_pane_view_data_mapper_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/resource_manager_action_handler.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_create_request_view_data.dart';
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

      expect(find.text('文件'), findsOneWidget);
      expect(find.text('工作区入口'), findsNothing);
      expect(find.byTooltip('导入文件'), findsOneWidget);
      expect(find.byTooltip('新文件'), findsOneWidget);
      expect(find.byTooltip('保存当前文档'), findsOneWidget);
      expect(find.byTooltip('更多文件操作'), findsOneWidget);
      expect(find.byTooltip('新文件夹'), findsNothing);
      expect(find.byTooltip('模型与接口设置'), findsNothing);
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsNothing);
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

      expect(
        find.byKey(const ValueKey<String>('resource_manager_scroll_view')),
        findsOneWidget,
      );
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.text('项目目录'), findsOneWidget);
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
}

class _FakeResourceManagerActionHandler
    implements ResourceManagerActionHandler {
  int createFolderRequestedCount = 0;

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
