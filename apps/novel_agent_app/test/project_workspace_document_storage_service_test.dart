import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_workspace_document_storage_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test(
    'SQLite workbench save updates the primary structured document before its Markdown projection',
    () async {
      final projectDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_workspace_storage_test_',
      );
      try {
        final workspacePort = _MemoryWorkspacePort();
        final service = ProjectWorkspaceDocumentStorageService(
          readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
          saveDraftUseCase: SaveDraftUseCase(
            projectWorkspacePort: workspacePort,
          ),
        );
        final project = ProjectDescriptor(
          id: 'sqlite-project',
          name: 'SQLite 小说',
          rootPath: projectDirectory.path,
          projectType: 'novel',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        );

        await service.save(
          project: project,
          relativePath: 'chapters/chapter_01.md',
          title: '第一章',
          content: 'SQLite 主事实源正文',
        );

        expect(
          await workspacePort.readTextFile(
            project.rootPath,
            'chapters/chapter_01.md',
          ),
          'SQLite 主事实源正文',
        );
        expect(
          await service.read(
            project: project,
            relativePath: 'chapters/chapter_01.md',
          ),
          'SQLite 主事实源正文',
        );
        expect(
          await ProjectStructuredContentBridgeService().readProjectedBodyText(
            project,
            'chapters/chapter_01.md',
          ),
          'SQLite 主事实源正文',
        );
      } finally {
        if (await projectDirectory.exists()) {
          await projectDirectory.delete(recursive: true);
        }
      }
    },
  );

  test(
    'SQLite workbench save restores the primary document when its Markdown projection fails',
    () async {
      final projectDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_workspace_storage_rollback_test_',
      );
      try {
        final workspacePort = _MemoryWorkspacePort(failWrites: true);
        final service = ProjectWorkspaceDocumentStorageService(
          readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
          saveDraftUseCase: SaveDraftUseCase(
            projectWorkspacePort: workspacePort,
          ),
        );
        final project = ProjectDescriptor(
          id: 'sqlite-projection-failure',
          name: 'SQLite 投影失败',
          rootPath: projectDirectory.path,
          projectType: 'novel',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        );

        await expectLater(
          service.save(
            project: project,
            relativePath: 'chapters/chapter_01.md',
            title: '第一章',
            content: '不应留下的正文',
          ),
          throwsA(isA<StateError>()),
        );

        expect(
          await ProjectStructuredContentBridgeService().readProjectedBodyText(
            project,
            'chapters/chapter_01.md',
          ),
          isNull,
        );
      } finally {
        if (await projectDirectory.exists()) {
          await projectDirectory.delete(recursive: true);
        }
      }
    },
  );

  test(
    'SQLite workbench edits keep inherited deconstruction chapters in the primary source',
    () async {
      final projectDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_workspace_inherited_storage_test_',
      );
      try {
        final workspacePort = LocalProjectWorkspacePort();
        final service = ProjectWorkspaceDocumentStorageService(
          readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
          saveDraftUseCase: SaveDraftUseCase(
            projectWorkspacePort: workspacePort,
          ),
        );
        final project = ProjectDescriptor(
          id: 'sqlite-inherited-project',
          name: 'SQLite 派生小说',
          rootPath: projectDirectory.path,
          projectType: 'novel',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        );
        const inheritedPath =
            'imports/derived/continuation/continuation_novel/001_第一章.md';
        final bridge = ProjectStructuredContentBridgeService();
        await bridge.persistChapterDelivery(
          project: project,
          chapterPath: inheritedPath,
          chapterTitle: '第一章',
          chapterContent: '原始继承正文',
          recordPath: '',
          status: 'archived',
        );

        await service.save(
          project: project,
          relativePath: inheritedPath,
          title: '第一章',
          content: '修订后的继承正文',
        );

        expect(
          await bridge.readProjectedBodyText(project, inheritedPath),
          '修订后的继承正文',
        );
      } finally {
        if (await projectDirectory.exists()) {
          await projectDirectory.delete(recursive: true);
        }
      }
    },
  );

  test(
    'SQLite projection save preserves the projection document kind',
    () async {
      final workspacePort = _MemoryWorkspacePort();
      final bridge = _RecordingStructuredContentBridgeService();
      final service = ProjectWorkspaceDocumentStorageService(
        readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
        saveDraftUseCase: SaveDraftUseCase(projectWorkspacePort: workspacePort),
        structuredContentBridgeService: bridge,
      );
      const project = ProjectDescriptor(
        id: 'sqlite-projection-kind',
        name: 'SQLite 投影类型',
        rootPath: '/projects/sqlite-projection-kind',
        projectType: 'knowledge_base',
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      );

      await service.save(
        project: project,
        relativePath: 'imports/analysis/outlines/main.md',
        title: '总纲',
        content: '总纲内容',
      );

      expect(bridge.lastDocumentPath, 'imports/analysis/outlines/main.md');
      expect(bridge.lastDocumentKind, 'outline');
    },
  );

  test(
    'knowledge base manual files under imports persist as knowledge instead of chapters',
    () async {
      // 中文注释: 资料知识库的默认新建目录就是 imports/，手工创建和外部导入必须
      // 落到同一知识类主事实源，不能让文件名路径把资料误标成小说章节。
      final workspacePort = _MemoryWorkspacePort();
      final bridge = _RecordingStructuredContentBridgeService();
      final service = ProjectWorkspaceDocumentStorageService(
        readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
        saveDraftUseCase: SaveDraftUseCase(projectWorkspacePort: workspacePort),
        structuredContentBridgeService: bridge,
      );
      const project = ProjectDescriptor(
        id: 'knowledge-base-manual-file',
        name: '资料知识库',
        rootPath: '/projects/knowledge-base-manual-file',
        projectType: 'knowledge_base',
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      );

      await service.persistPrimarySource(
        project: project,
        relativePath: 'imports/source-notes.md',
        title: '来源笔记',
        content: '资料正文',
      );

      expect(bridge.lastDocumentPath, 'imports/source-notes.md');
      expect(bridge.lastDocumentKind, 'knowledge');
    },
  );

  test(
    'SQLite create-file persists its primary document before the Markdown projection',
    () async {
      final events = <String>[];
      final workspacePort = _MemoryWorkspacePort();
      final bridge = _RecordingStructuredContentBridgeService(events: events);
      final storageService = ProjectWorkspaceDocumentStorageService(
        readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
        saveDraftUseCase: SaveDraftUseCase(projectWorkspacePort: workspacePort),
        structuredContentBridgeService: bridge,
      );
      final hostPort = _RecordingProjectToolHostPort(events);
      const project = ProjectDescriptor(
        id: 'sqlite-create-file',
        name: 'SQLite 新建文件',
        rootPath: '/projects/sqlite-create-file',
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      );

      await CreateProjectEntryUseCase(projectToolHostPort: hostPort).execute(
        project: project,
        relativePath: 'chapters/chapter_01.md',
        content: '第一章正文',
        prepareFileWrite:
            ({required project, required relativePath, required content}) {
              return storageService.persistPrimarySource(
                project: project,
                relativePath: relativePath,
                title: '第一章',
                content: content,
              );
            },
      );

      expect(events, <String>[
        'sqlite:chapters/chapter_01.md',
        'projection:chapters/chapter_01.md',
      ]);
      expect(bridge.lastDocumentKind, 'chapter');
    },
  );
}

class _RecordingStructuredContentBridgeService
    extends ProjectStructuredContentBridgeService {
  _RecordingStructuredContentBridgeService({this.events});

  final List<String>? events;
  String lastDocumentPath = '';
  String lastDocumentKind = '';

  @override
  Future<void> persistStructuredDocument({
    required ProjectDescriptor project,
    required String documentPath,
    required String documentKind,
    required String title,
    required String content,
    String statePath = '',
    String status = 'applied',
  }) async {
    lastDocumentPath = documentPath;
    lastDocumentKind = documentKind;
    events?.add('sqlite:$documentPath');
  }
}

class _RecordingProjectToolHostPort implements ProjectToolHostPort {
  _RecordingProjectToolHostPort(this._events);

  final List<String> _events;
  final Map<String, String> _files = <String, String>{};

  @override
  Future<void> copyExternalFile(
    String absolutePath,
    String rootPath,
    String targetRelativePath,
  ) async {}

  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<void> deleteEntry(String rootPath, String relativePath) async {
    _files.remove(relativePath);
  }

  @override
  Future<bool> entryExists(String rootPath, String relativePath) async {
    return _files.containsKey(relativePath);
  }

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async => const <JsonMap>[];

  @override
  Future<void> moveEntry(
    String rootPath,
    String sourceRelativePath,
    String targetRelativePath,
  ) async {
    final content = _files.remove(sourceRelativePath);
    if (content != null) {
      _files[targetRelativePath] = content;
    }
  }

  @override
  Future<String?> readExternalTextFile(String absolutePath) async => null;

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async {
    return _files[relativePath];
  }

  @override
  Future<void> writeExternalTextFile(
    String absolutePath,
    String content,
  ) async {}

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {
    _files[relativePath] = content;
    _events.add('projection:$relativePath');
  }
}

class _MemoryWorkspacePort implements ProjectWorkspacePort {
  _MemoryWorkspacePort({this.failWrites = false});

  final Map<String, String> _files = <String, String>{};
  final bool failWrites;

  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async => const <JsonMap>[];

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async {
    return _files[_key(rootPath, relativePath)];
  }

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {
    if (failWrites) {
      throw StateError('模拟 Markdown 投影写入失败');
    }
    _files[_key(rootPath, relativePath)] = content;
  }

  String _key(String rootPath, String relativePath) {
    return '${rootPath.replaceAll('\\', '/')}//${relativePath.replaceAll('\\', '/')}';
  }
}
