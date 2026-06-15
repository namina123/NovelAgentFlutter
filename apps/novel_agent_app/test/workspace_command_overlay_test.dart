import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/presentation/contracts/resource_manager_action_handler.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_create_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/selector_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workspace_command_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/workspace_command_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'workspace command overlay forwards import file pick request and syncs updated file selection',
    (WidgetTester tester) async {
      final handler = _FakeResourceManagerActionHandler();
      var viewData = const WorkspaceCommandViewData(
        mode: WorkspaceCommandMode.importFiles,
        title: '导入文件',
        description: '选择一个或多个本地文件。',
        confirmLabel: '导入文件',
        status: '',
        projectTitle: '',
        projectType: 'book_deconstruction',
        genre: '',
        premise: '',
        notes: '',
        relativePath: '',
        entryName: '',
        content: '',
        sourcePathsText: '',
        targetDirectory: 'chapters',
        autoDeconstruct: false,
        canAutoDeconstruct: true,
        importFileSelectionHint: '请选择一个或多个本地文件。',
        importOutputHint: '自动拆书预演纪要会写回当前项目。',
      );

      Future<void> pumpOverlay() async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Stack(
                children: [
                  WorkspaceCommandOverlay(
                    viewData: viewData,
                    actionHandler: handler,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
      }

      await pumpOverlay();

      await tester.enterText(
        find.byType(TextField).at(1),
        'analysis/deconstruction',
      );
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.text('选择文件'));
      await tester.pumpAndSettle();

      expect(handler.lastPickRequest, isNotNull);
      expect(
        handler.lastPickRequest!.targetDirectory,
        'analysis/deconstruction',
      );
      expect(handler.lastPickRequest!.autoDeconstruct, isTrue);

      viewData = viewData.copyWith(
        sourcePathsText: 'C:/imports/source_book.md',
        autoDeconstruct: true,
        importFileSelectionHint: '已选择 1 个文件。',
      );
      await pumpOverlay();

      expect(find.text('C:/imports/source_book.md'), findsOneWidget);
      expect(find.text('已选择 1 个文件。'), findsOneWidget);
    },
  );

  testWidgets(
    'workspace command overlay exposes smart analysis for general project import',
    (WidgetTester tester) async {
      final handler = _FakeResourceManagerActionHandler();
      const viewData = WorkspaceCommandViewData(
        mode: WorkspaceCommandMode.importFiles,
        title: '导入文件',
        description: '选择一个或多个本地文件。',
        confirmLabel: '导入文件',
        status: '',
        projectTitle: '',
        projectType: 'novel',
        genre: '',
        premise: '',
        notes: '',
        relativePath: '',
        entryName: '',
        content: '',
        sourcePathsText: '',
        targetDirectory: 'assets',
        autoDeconstruct: false,
        smartAnalysis: true,
        canSmartAnalyze: true,
        analysisAgentId: 'analysis-agent',
        analysisAgentGroupId: 'analysis-group',
        canAutoDeconstruct: false,
        importFileSelectionHint: '请选择一个或多个本地文件。',
        importOutputHint: '导入后会先做智能分析。',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Stack(
              children: [
                WorkspaceCommandOverlay(
                  viewData: viewData,
                  actionHandler: handler,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('智能分析'), findsOneWidget);
      expect(find.text('分析智能体'), findsOneWidget);
      expect(find.text('分析智能体组'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, '导入文件'));
      await tester.pump();

      expect(handler.lastSubmittedRequest, isNotNull);
      expect(handler.lastSubmittedRequest!.smartAnalysis, isTrue);
      expect(handler.lastSubmittedRequest!.analysisAgentId, 'analysis-agent');
      expect(
        handler.lastSubmittedRequest!.analysisAgentGroupId,
        'analysis-group',
      );
    },
  );

  testWidgets(
    'workspace command overlay carries project type transition target and runtime baseline',
    (WidgetTester tester) async {
      final handler = _FakeResourceManagerActionHandler();
      final viewData = const WorkspaceCommandViewData(
        mode: WorkspaceCommandMode.transitionProjectType,
        title: '项目类型转换',
        description: '将当前项目切换到另一个类型。',
        confirmLabel: '执行转换',
        status: '转换条件已满足。',
        projectTitle: '星港档案',
        projectType: 'long_novel',
        transitionTargetProjectTypeId: 'long_novel',
        transitionRuntimeBaselineId: 'continuous_autonomous',
        transitionTargetProjectTypeOptions: <SelectorOptionViewData>[
          SelectorOptionViewData(
            id: 'long_novel',
            label: '长篇长任务',
            note: '适合长篇推进和多步骤协作。',
          ),
        ],
        transitionRuntimeBaselineOptions: <SelectorOptionViewData>[
          SelectorOptionViewData(
            id: 'continuous_autonomous',
            label: '连续托管式',
            note: '人类先给灵感、边界和长期约束。',
          ),
          SelectorOptionViewData(
            id: 'chapter_collaboration_autorun',
            label: '逐章协作式自动推进',
            note: '每章都走生成、审稿与返工链。',
          ),
        ],
        transitionRequiresRuntimeBaselineSelection: true,
        genre: '',
        premise: '',
        notes: '',
        relativePath: '',
        entryName: '',
        content: '',
        sourcePathsText: '',
        targetDirectory: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Stack(
              children: [
                WorkspaceCommandOverlay(
                  viewData: viewData,
                  actionHandler: handler,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('目标项目类型'), findsOneWidget);
      expect(find.text('运行基准'), findsOneWidget);
      expect(find.text('长篇长任务'), findsOneWidget);
      expect(find.text('连续托管式'), findsOneWidget);
      expect(find.text('执行转换'), findsOneWidget);

      await tester.tap(find.text('连续托管式'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('逐章协作式自动推进').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('执行转换'));
      await tester.pump();

      expect(handler.lastSubmittedRequest, isNotNull);
      expect(
        handler.lastSubmittedRequest!.mode,
        WorkspaceCommandMode.transitionProjectType,
      );
      expect(
        handler.lastSubmittedRequest!.transitionTargetProjectTypeId,
        'long_novel',
      );
      expect(
        handler.lastSubmittedRequest!.transitionRuntimeBaselineId,
        'chapter_collaboration_autorun',
      );
    },
  );
}

class _FakeResourceManagerActionHandler
    implements ResourceManagerActionHandler {
  WorkspaceCommandRequestViewData? lastPickRequest;
  WorkspaceCommandRequestViewData? lastSubmittedRequest;

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
  ) {
    lastPickRequest = request;
  }

  @override
  void onWorkspaceCommandSubmitted(WorkspaceCommandRequestViewData request) {
    lastSubmittedRequest = request;
  }
}
