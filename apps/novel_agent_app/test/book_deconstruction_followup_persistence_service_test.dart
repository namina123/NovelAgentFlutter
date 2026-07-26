import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_followup_persistence_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('BookDeconstructionFollowupPersistenceService', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'book_deconstruction_followup_persistence_',
      );
      workspacePort = LocalProjectWorkspacePort();
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('SQLite 当前项目只持久化被选中的 live 章节，并保留文件投影', () async {
      final buildResult = _buildResult();
      final selectedItem = _chapterItems(buildResult).last;
      final selectedOutline = buildResult.extractionResult.chapterOutlines.last;
      final project = ProjectDescriptor(
        id: 'sqlite-live',
        name: 'SQLite 拆书项目',
        rootPath: tempDirectory.path,
        projectType: 'book_deconstruction',
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      );
      final service = _service(workspacePort);

      final paths = await service.persistChapters(
        project: project,
        buildResult: buildResult,
        asLiveNarrative: true,
        selectedItemIds: <String>{selectedItem.id},
      );

      final targetPathService = const BookDeconstructionTargetPathService();
      final selectedPath = targetPathService.liveChapterPath(
        sequence: selectedOutline.sequence,
        title: selectedOutline.title,
        storageStrategy: project.storageStrategy,
      );
      final skippedOutline = buildResult.extractionResult.chapterOutlines.first;
      final skippedPath = targetPathService.liveChapterPath(
        sequence: skippedOutline.sequence,
        title: skippedOutline.title,
        storageStrategy: project.storageStrategy,
      );
      expect(paths, <String>[selectedPath]);
      expect(
        await File(
          _absolutePath(project.rootPath, selectedPath),
        ).readAsString(),
        contains('城邦议会开始浮出水面'),
      );
      expect(
        await File(_absolutePath(project.rootPath, skippedPath)).exists(),
        isFalse,
      );
      expect(
        await ProjectStructuredContentBridgeService().readProjectedBodyText(
          project,
          selectedPath,
        ),
        contains('城邦议会开始浮出水面'),
      );
      expect(
        await ProjectStructuredContentBridgeService().readProjectedBodyText(
          project,
          skippedPath,
        ),
        isNull,
      );
    });

    test('SQLite 继承章节遵循选择集并写入正文主事实源', () async {
      final buildResult = _buildResult();
      final selectedItem = _chapterItems(buildResult).last;
      final selectedOutline = buildResult.extractionResult.chapterOutlines.last;
      final project = ProjectDescriptor(
        id: 'sqlite-inherited',
        name: 'SQLite 派生项目',
        rootPath: tempDirectory.path,
        projectType: 'novel',
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      );
      final service = _service(workspacePort);

      final result = await service.persist(
        project: project,
        buildResult: buildResult,
        followupOptionId: 'continuation_novel',
        selectedItemIds: <String>{selectedItem.id},
      );

      final selectedPath = const BookDeconstructionTargetPathService()
          .inheritedChapterPath(
            followupOptionId: 'continuation_novel',
            sequence: selectedOutline.sequence,
            title: selectedOutline.title,
            storageStrategy: project.storageStrategy,
          );
      expect(result.inheritedChapterPaths, <String>[selectedPath]);
      expect(
        await ProjectStructuredContentBridgeService().readProjectedBodyText(
          project,
          selectedPath,
        ),
        contains('城邦议会开始浮出水面'),
      );
    });

    test('SQLite 分章先写主事实源，再写 Markdown 投影', () async {
      final events = <String>[];
      final workspacePort = _OrderRecordingWorkspacePort(events);
      final structuredBridge = _OrderRecordingStructuredBridge(events);
      final buildResult = _buildResult();
      final selectedItem = _chapterItems(buildResult).first;
      const project = ProjectDescriptor(
        id: 'sqlite-order',
        name: 'SQLite 顺序测试',
        rootPath: '/projects/sqlite-order',
        projectType: 'book_deconstruction',
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      );
      final service = BookDeconstructionFollowupPersistenceService(
        writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
          projectWorkspacePort: workspacePort,
        ),
        structuredContentBridgeService: structuredBridge,
      );

      final paths = await service.persistChapters(
        project: project,
        buildResult: buildResult,
        asLiveNarrative: true,
        selectedItemIds: <String>{selectedItem.id},
      );

      expect(paths, hasLength(1));
      final path = paths.single;
      expect(events, <String>['sqlite:$path', 'projection:$path']);
    });
  });
}

BookDeconstructionFollowupPersistenceService _service(
  LocalProjectWorkspacePort workspacePort,
) {
  return BookDeconstructionFollowupPersistenceService(
    writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
      projectWorkspacePort: workspacePort,
    ),
  );
}

BookDeconstructionDraftBuildResult _buildResult() {
  return BuildBookDeconstructionDraftUseCase().execute(
    sourceTitle: '海上城邦',
    sourceContent: '第一章 港口风暴\n主角在港口被迫卷入一场追捕。\n\n第二章 议会阴影\n城邦议会开始浮出水面。',
    sourceAbsolutePath: 'D:/Books/source_book.md',
  );
}

List<BookDeconstructionApplicationItem> _chapterItems(
  BookDeconstructionDraftBuildResult buildResult,
) {
  return buildResult.applicationPlan.items
      .where(
        (item) =>
            item.sourceKind == BookDeconstructionArtifactKind.chapterOutline,
      )
      .toList(growable: false);
}

String _absolutePath(String rootPath, String relativePath) {
  return '$rootPath${Platform.pathSeparator}${relativePath.replaceAll('/', Platform.pathSeparator)}';
}

class _OrderRecordingStructuredBridge
    extends ProjectStructuredContentBridgeService {
  _OrderRecordingStructuredBridge(this._events);

  final List<String> _events;

  @override
  Future<void> persistChapterDelivery({
    required ProjectDescriptor project,
    required String chapterPath,
    required String chapterTitle,
    required String chapterContent,
    required String recordPath,
    required String status,
  }) async {
    _events.add('sqlite:$chapterPath');
  }
}

class _OrderRecordingWorkspacePort implements ProjectWorkspacePort {
  _OrderRecordingWorkspacePort(this._events);

  final List<String> _events;

  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async => const <JsonMap>[];

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async =>
      null;

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {
    _events.add('projection:$relativePath');
  }
}
