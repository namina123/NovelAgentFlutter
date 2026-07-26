import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_application_plan_materialization_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test(
    'SQLite materialization remaps selected plan items and writes primary facts before projections',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'book_deconstruction_materialization_sqlite_',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });
      final workspacePort = LocalProjectWorkspacePort();
      final project = ProjectDescriptor(
        id: 'sqlite-materialization',
        name: 'SQLite 拆书项目',
        rootPath: tempDirectory.path,
        projectType: 'book_deconstruction',
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      );
      // Build with the legacy default deliberately: materialization must bind
      // paths to the project it is actually committing into.
      final buildResult = BuildBookDeconstructionDraftUseCase().execute(
        sourceTitle: '海上城邦',
        sourceContent: '第一章 港口风暴\n主角在港口卷入追捕。',
        sourceAbsolutePath: 'D:/Books/source_book.md',
        styleSummary: '节奏快，强调港口意象。',
        characterLinesText: '林砚：被迫卷入风暴的主角',
      );
      final selectedItems = <BookDeconstructionApplicationItem>[
        buildResult.applicationPlan.items.firstWhere(
          (item) =>
              item.sourceKind == BookDeconstructionArtifactKind.storyOutline,
        ),
        buildResult.applicationPlan.items.firstWhere(
          (item) =>
              item.sourceKind == BookDeconstructionArtifactKind.chapterOutline,
        ),
        buildResult.applicationPlan.items.firstWhere(
          (item) =>
              item.sourceKind == BookDeconstructionArtifactKind.styleProfile,
        ),
      ];
      final unselectedCharacterItem = buildResult.applicationPlan.items
          .firstWhere(
            (item) =>
                item.sourceKind ==
                BookDeconstructionArtifactKind.characterProfile,
          );
      final materializationService =
          BookDeconstructionApplicationPlanMaterializationService(
            writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
              projectWorkspacePort: workspacePort,
            ),
          );

      final changedPaths = await materializationService.materialize(
        project: project,
        buildResult: buildResult,
        selectedItemIds: selectedItems.map((item) => item.id).toSet(),
      );

      final storyPath =
          'imports/analysis/outlines/book_deconstruction_story_outline.md';
      final chapterPath =
          'imports/analysis/chapter_outlines/book_deconstruction_chapter_1.md';
      final styleItem = selectedItems.firstWhere(
        (item) =>
            item.sourceKind == BookDeconstructionArtifactKind.styleProfile,
      );
      final stylePath = const BookDeconstructionTargetPathService().assetPath(
        BookDeconstructionArtifactKind.styleProfile,
        styleItem.sourceId,
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      );
      final unselectedCharacterPath =
          const BookDeconstructionTargetPathService().assetPath(
            BookDeconstructionArtifactKind.characterProfile,
            unselectedCharacterItem.sourceId,
            storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          );

      expect(
        changedPaths,
        unorderedEquals(<String>[storyPath, chapterPath, stylePath]),
      );
      for (final path in <String>[storyPath, chapterPath, stylePath]) {
        expect(
          await File(_absolutePath(project.rootPath, path)).exists(),
          isTrue,
        );
      }

      final bridge = ProjectStructuredContentBridgeService();
      expect(
        await bridge.readProjectedBodyText(project, storyPath),
        contains('拆书故事总纲'),
      );
      expect(
        await bridge.readProjectedBodyText(project, chapterPath),
        contains('港口风暴'),
      );
      expect(
        await bridge.readProjectedBodyText(project, stylePath),
        contains('节奏快'),
      );
      expect(
        await bridge.readProjectedBodyText(project, unselectedCharacterPath),
        isNull,
      );
    },
  );
}

String _absolutePath(String rootPath, String relativePath) {
  return '$rootPath${Platform.pathSeparator}${relativePath.replaceAll('/', Platform.pathSeparator)}';
}
