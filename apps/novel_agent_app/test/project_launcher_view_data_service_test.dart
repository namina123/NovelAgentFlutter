import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_launcher_view_data_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_creation_phase.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_launcher_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/project_create_panel.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('knowledge_base 创建时只暴露 SQLite 且文案指向资料知识库治理', () {
    // 中文注释: 这个回归确保 launcher 投影层先把知识库收束成 SQLite-only，再交给创建面渲染。
    final service = ProjectLauncherViewDataService();
    final viewData = service.build(
      mode: ProjectLauncherMode.create,
      projectsRootPath: 'D:/Projects',
      projects: const <JsonMap>[],
      selectedProjectTypeId: 'knowledge_base',
      selectedStorageStrategy: ProjectStorageStrategy.markdownProjectStore,
      creationPhase: ProjectCreationPhase.storageStrategy,
    );

    expect(viewData.draftTitle, '未命名资料知识库');
    expect(viewData.projectTypeOptions, hasLength(4));
    final knowledgeBaseOption = viewData.projectTypeOptions.singleWhere(
      (option) => option.id == 'knowledge_base',
    );
    expect(knowledgeBaseOption.title, '资料知识库 / 参考资产治理');
    expect(knowledgeBaseOption.description, contains('参考资产'));
    expect(viewData.storageStrategyOptions, hasLength(1));
    expect(viewData.storageStrategyOptions.single.id, 'sqlite_project_store');
    expect(viewData.storageStrategyOptions.single.title, 'SQLite 参考资产库');
    expect(viewData.selectedStorageStrategyId, 'sqlite_project_store');
  });

  testWidgets('knowledge_base 创建面板只显示 SQLite 存储选项', (tester) async {
    // 中文注释: widget 级回归确保创建面板真的只渲染 SQLite 选项，并且名称输入不再暗示小说场景。
    final service = ProjectLauncherViewDataService();
    final viewData = service.build(
      mode: ProjectLauncherMode.create,
      projectsRootPath: 'D:/Projects',
      projects: const <JsonMap>[],
      selectedProjectTypeId: 'knowledge_base',
      selectedStorageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      creationPhase: ProjectCreationPhase.storageStrategy,
      canDismiss: true,
    );

    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ProjectCreatePanel(
            title: viewData.title,
            description: viewData.description,
            projectsRootPath: viewData.projectsRootPath,
            status: viewData.status,
            draftTitle: viewData.draftTitle,
            projectTypeOptions: viewData.projectTypeOptions,
            selectedProjectTypeId: viewData.selectedProjectTypeId,
            storageStrategyOptions: viewData.storageStrategyOptions,
            selectedStorageStrategyId: viewData.selectedStorageStrategyId,
            creationPhase: viewData.creationPhase,
            bookDeconstructionFollowupOptions:
                viewData.bookDeconstructionFollowupOptions,
            selectedBookDeconstructionFollowupRouteId:
                viewData.selectedBookDeconstructionFollowupRouteId,
            runtimeBaselineOptions: viewData.runtimeBaselineOptions,
            selectedRuntimeBaselineId: viewData.selectedRuntimeBaselineId,
            selectedProjectTypeRequiresRuntimeBaseline:
                viewData.selectedProjectTypeRequiresRuntimeBaseline,
            continuityInput: viewData.continuityInput,
            allowOpenExisting: viewData.allowOpenExisting,
            onOpenExistingRequested: () {},
            onBackRequested: () {},
            onCreateSubmitted: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('SQLite 参考资产库'), findsOneWidget);
    expect(find.text('Markdown 项目'), findsNothing);
    expect(find.text('项目名称'), findsOneWidget);
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.decoration?.hintText, '输入要创建的资料知识库名称');
  });

  test('普通写作项目仍保留合法的 Markdown 与 SQLite 选项', () {
    // 中文注释: 这条回归保证本次收束不会误伤普通写作项目的双存储入口。
    final service = ProjectLauncherViewDataService();

    final novel = service.build(
      mode: ProjectLauncherMode.create,
      projectsRootPath: 'D:/Projects',
      projects: const <JsonMap>[],
      selectedProjectTypeId: 'novel',
    );
    final longNovel = service.build(
      mode: ProjectLauncherMode.create,
      projectsRootPath: 'D:/Projects',
      projects: const <JsonMap>[],
      selectedProjectTypeId: 'long_novel',
    );
    final bookDeconstruction = service.build(
      mode: ProjectLauncherMode.create,
      projectsRootPath: 'D:/Projects',
      projects: const <JsonMap>[],
      selectedProjectTypeId: 'book_deconstruction',
    );

    for (final viewData in <ProjectLauncherViewData>[
      novel,
      longNovel,
      bookDeconstruction,
    ]) {
      expect(viewData.storageStrategyOptions, hasLength(2));
      expect(
        viewData.storageStrategyOptions.map((option) => option.id),
        containsAll(<String>['markdown_project_store', 'sqlite_project_store']),
      );
    }
  });

  test('拆书创建第二步会暴露续写/同人承接路线', () {
    final service = ProjectLauncherViewDataService();
    final viewData = service.build(
      mode: ProjectLauncherMode.create,
      projectsRootPath: 'D:/Projects',
      projects: const <JsonMap>[],
      selectedProjectTypeId: 'book_deconstruction',
      creationPhase: ProjectCreationPhase.bookDeconstructionFollowup,
      selectedBookDeconstructionFollowupRouteId: 'fanfic',
    );

    expect(viewData.title, '第二步：选择拆书承接路线');
    expect(viewData.bookDeconstructionFollowupOptions, hasLength(2));
    expect(
      viewData.bookDeconstructionFollowupOptions.map((option) => option.id),
      containsAll(<String>['continuation', 'fanfic']),
    );
    expect(viewData.selectedBookDeconstructionFollowupRouteId, 'fanfic');
  });
}
