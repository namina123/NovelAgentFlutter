import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart';
import 'package:novel_agent_app/features/workbench/application/models/project_import_request.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_import_execution_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../tool/real_gui_book_deconstruction_import_probe.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'project import execution service imports files without auto deconstruction by default',
    () async {
      final hostPort = _FakeProjectToolHostPort(
        externalFiles: <String, String>{'C:/imports/reference.txt': '第一章 港口风暴'},
      );
      final workspacePort = _InMemoryProjectWorkspacePort();
      final importUseCase = ImportProjectFilesUseCase(
        projectToolHostPort: hostPort,
      );
      final service = ProjectImportExecutionService(
        importProjectFilesUseCase: importUseCase,
        projectToolHostPort: hostPort,
        writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
          projectWorkspacePort: workspacePort,
        ),
        narrativePersistenceService:
            BookDeconstructionNarrativePersistenceService(
              workspacePort: workspacePort,
            ),
      );

      final result = await service.execute(
        project: const ProjectDescriptor(
          id: 'project-1',
          name: '普通项目',
          rootPath: 'D:/Projects/novel_project',
          projectType: 'novel',
        ),
        request: const ProjectImportRequest(
          sourcePaths: <String>['C:/imports/reference.txt'],
          targetDirectory: 'assets',
          autoDeconstruct: false,
        ),
      );

      expect(result.ok, isTrue);
      expect(result.importedPaths, <String>['assets/reference.txt']);
      expect(result.autoDeconstructionApplied, isFalse);
      expect(result.smartAnalysisApplied, isFalse);
      expect(result.smartAnalysisReportPath, isEmpty);
      expect(hostPort.copiedFiles.single, (
        absolutePath: 'C:/imports/reference.txt',
        rootPath: 'D:/Projects/novel_project',
        targetRelativePath: 'assets/reference.txt',
      ));
    },
  );

  test(
    'project import writes knowledge-base source text to SQLite before its projection',
    () async {
      final events = <String>[];
      final hostPort = _FakeProjectToolHostPort(
        externalFiles: <String, String>{
          'C:/imports/research.md': '# 世界观资料\n\n城邦拥有三层议会。',
        },
        onCopy: (relativePath) => events.add('projection:$relativePath'),
      );
      final workspacePort = _InMemoryProjectWorkspacePort();
      final reader = _StubSourceDocumentReaderService(
        const ReferenceSourceDocumentFileReadResult(
          sourceFilePath: 'C:/imports/research.md',
          sourceTitle: '世界观资料',
          sourceText: '# 世界观资料\n\n城邦拥有三层议会。',
          decodeMode: 'plain_text',
        ),
      );
      final structuredBridge = _RecordingStructuredContentBridgeService(events);
      final service = ProjectImportExecutionService(
        importProjectFilesUseCase: ImportProjectFilesUseCase(
          projectToolHostPort: hostPort,
        ),
        projectToolHostPort: hostPort,
        writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
          projectWorkspacePort: workspacePort,
        ),
        narrativePersistenceService:
            BookDeconstructionNarrativePersistenceService(
              workspacePort: workspacePort,
            ),
        sourceDocumentReaderService: reader,
        structuredContentBridgeService: structuredBridge,
      );

      final result = await service.execute(
        project: const ProjectDescriptor(
          id: 'knowledge-project',
          name: '知识库',
          rootPath: 'D:/Projects/knowledge_project',
          projectType: 'knowledge_base',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        ),
        request: const ProjectImportRequest(
          sourcePaths: <String>['C:/imports/research.md'],
          targetDirectory: 'imports',
          autoDeconstruct: false,
        ),
      );

      expect(result.ok, isTrue);
      expect(reader.readCalls, 1);
      expect(structuredBridge.documentPath, 'imports/research.md');
      expect(structuredBridge.documentKind, 'knowledge');
      expect(structuredBridge.content, contains('三层议会'));
      expect(events, <String>[
        'sqlite:knowledge:imports/research.md',
        'projection:imports/research.md',
      ]);
    },
  );

  test(
    'project import keeps unsupported binary files as attachments',
    () async {
      final events = <String>[];
      final hostPort = _FakeProjectToolHostPort(
        onCopy: (relativePath) => events.add('projection:$relativePath'),
      );
      final workspacePort = _InMemoryProjectWorkspacePort();
      final reader = _StubSourceDocumentReaderService(
        const ReferenceSourceDocumentFileReadResult(
          sourceFilePath: 'C:/imports/cover.png',
          sourceTitle: 'cover',
          sourceText: 'should not be read',
          decodeMode: 'plain_text',
        ),
      );
      final structuredBridge = _RecordingStructuredContentBridgeService(events);
      final service = ProjectImportExecutionService(
        importProjectFilesUseCase: ImportProjectFilesUseCase(
          projectToolHostPort: hostPort,
        ),
        projectToolHostPort: hostPort,
        writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
          projectWorkspacePort: workspacePort,
        ),
        narrativePersistenceService:
            BookDeconstructionNarrativePersistenceService(
              workspacePort: workspacePort,
            ),
        sourceDocumentReaderService: reader,
        structuredContentBridgeService: structuredBridge,
      );

      final result = await service.execute(
        project: const ProjectDescriptor(
          id: 'sqlite-project',
          name: 'SQLite 项目',
          rootPath: 'D:/Projects/sqlite_project',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        ),
        request: const ProjectImportRequest(
          sourcePaths: <String>['C:/imports/cover.png'],
          targetDirectory: 'imports',
          autoDeconstruct: false,
        ),
      );

      expect(result.ok, isTrue);
      expect(reader.readCalls, 0);
      expect(structuredBridge.persistedDocumentCount, 0);
      expect(events, <String>['projection:imports/cover.png']);
    },
  );

  test(
    'SQLite text import stops before projection when the primary structured write fails',
    () async {
      // 中文注释: 已可解析的资料必须先进入 SQLite 主事实源，不能在主库失败后静默
      // 退化成仅复制 Markdown 投影，否则重开时会失去真实资料内容。
      final events = <String>[];
      final hostPort = _FakeProjectToolHostPort(
        onCopy: (relativePath) => events.add('projection:$relativePath'),
      );
      final workspacePort = _InMemoryProjectWorkspacePort();
      final service = ProjectImportExecutionService(
        importProjectFilesUseCase: ImportProjectFilesUseCase(
          projectToolHostPort: hostPort,
        ),
        projectToolHostPort: hostPort,
        writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
          projectWorkspacePort: workspacePort,
        ),
        narrativePersistenceService: BookDeconstructionNarrativePersistenceService(
          workspacePort: workspacePort,
        ),
        sourceDocumentReaderService: _StubSourceDocumentReaderService(
          const ReferenceSourceDocumentFileReadResult(
            sourceFilePath: 'C:/imports/research.md',
            sourceTitle: '世界观资料',
            sourceText: '城邦拥有三层议会。',
            decodeMode: 'plain_text',
          ),
        ),
        structuredContentBridgeService: _RecordingStructuredContentBridgeService(
          events,
          failPersist: true,
        ),
      );

      await expectLater(
        service.execute(
          project: const ProjectDescriptor(
            id: 'failed-primary-import',
            name: '资料知识库',
            rootPath: 'D:/Projects/failed_primary_import',
            projectType: 'knowledge_base',
            storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          ),
          request: const ProjectImportRequest(
            sourcePaths: <String>['C:/imports/research.md'],
            targetDirectory: 'imports',
            autoDeconstruct: false,
          ),
        ),
        throwsA(isA<StateError>()),
      );

      expect(events, isEmpty);
      expect(hostPort.copiedFiles, isEmpty);
    },
  );

  test(
    'SQLite text import restores its primary source when the projection copy fails',
    () async {
      final projectDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_import_projection_rollback_test_',
      );
      try {
        final hostPort = _FakeProjectToolHostPort(throwOnCopy: true);
        final workspacePort = _InMemoryProjectWorkspacePort();
        final service = ProjectImportExecutionService(
          importProjectFilesUseCase: ImportProjectFilesUseCase(
            projectToolHostPort: hostPort,
          ),
          projectToolHostPort: hostPort,
          writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
            projectWorkspacePort: workspacePort,
          ),
          narrativePersistenceService:
              BookDeconstructionNarrativePersistenceService(
                workspacePort: workspacePort,
              ),
          sourceDocumentReaderService: _StubSourceDocumentReaderService(
            const ReferenceSourceDocumentFileReadResult(
              sourceFilePath: 'C:/imports/research.md',
              sourceTitle: '世界观资料',
              sourceText: '城邦拥有三层议会。',
              decodeMode: 'plain_text',
            ),
          ),
        );
        final project = ProjectDescriptor(
          id: 'projection-copy-failure-import',
          name: '资料知识库',
          rootPath: projectDirectory.path,
          projectType: 'knowledge_base',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        );

        await expectLater(
          service.execute(
            project: project,
            request: const ProjectImportRequest(
              sourcePaths: <String>['C:/imports/research.md'],
              targetDirectory: 'imports',
              autoDeconstruct: false,
            ),
          ),
          throwsA(isA<StateError>()),
        );

        expect(
          await ProjectStructuredContentBridgeService().readProjectedBodyText(
            project,
            'imports/research.md',
          ),
          isNull,
        );
        expect(hostPort.copiedFiles, isEmpty);
      } finally {
        if (await projectDirectory.exists()) {
          await projectDirectory.delete(recursive: true);
        }
      }
    },
  );

  test(
    'project import execution service writes auto deconstruction preview for book projects',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'project_import_execution_markdown_test_',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });
      final sourcePath =
          '${tempDirectory.path}${Platform.pathSeparator}source_book.md';
      const sourceContent = '第一章 港口风暴\n主角在港口被迫卷入追捕。\n\n第二章 议会阴影\n城邦议会开始浮出水面。';
      await File(sourcePath).writeAsString(sourceContent);
      final hostPort = _FakeProjectToolHostPort(
        externalFiles: <String, String>{sourcePath: sourceContent},
      );
      final workspacePort = _InMemoryProjectWorkspacePort();
      final importUseCase = ImportProjectFilesUseCase(
        projectToolHostPort: hostPort,
      );
      final service = ProjectImportExecutionService(
        importProjectFilesUseCase: importUseCase,
        projectToolHostPort: hostPort,
        writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
          projectWorkspacePort: workspacePort,
        ),
        narrativePersistenceService:
            BookDeconstructionNarrativePersistenceService(
              workspacePort: workspacePort,
            ),
      );

      final result = await service.execute(
        project: const ProjectDescriptor(
          id: 'project-2',
          name: '拆书项目',
          rootPath: 'D:/Projects/deconstruction_project',
          projectType: 'book_deconstruction',
        ),
        request: ProjectImportRequest(
          sourcePaths: <String>[sourcePath],
          targetDirectory: 'chapters',
          autoDeconstruct: true,
        ),
      );

      expect(result.ok, isTrue);
      expect(result.autoDeconstructionApplied, isTrue);
      expect(result.smartAnalysisApplied, isFalse);
      expect(result.smartAnalysisReportPath, isEmpty);
      expect(
        result.autoDeconstructionPreviewPath,
        'analysis/deconstruction/book_deconstruction_source_book.md',
      );
      expect(result.importedPaths, <String>['sources/original/source_book.md']);
      final previewContent = workspacePort.readStoredTextFile(
        'D:/Projects/deconstruction_project',
        'analysis/deconstruction/book_deconstruction_source_book.md',
      );
      expect(previewContent, isNotNull);
      expect(previewContent, contains('# 拆书结构化预演'));
      final archiveContent = await hostPort.readTextFile(
        'D:/Projects/deconstruction_project',
        'sources/original/book_deconstruction_source_source_book.md',
      );
      expect(archiveContent, contains('第一章 港口风暴'));
      final claimsLog = workspacePort.readStoredTextFile(
        'D:/Projects/deconstruction_project',
        '.novel_agent/continuity/claims/claims.jsonl',
      );
      expect(claimsLog, contains('analysis.deconstruction.story_outline'));
      expect(result.summary, contains('自动拆书预演纪要已写入'));
      expect(result.summary, contains('原文文本归档已写入'));
    },
  );

  test(
    'project import execution service can auto deconstruct epub sources for book projects',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'project_import_execution_epub_test_',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final epubPath =
          '${tempDirectory.path}${Platform.pathSeparator}source_book.epub';
      await File(epubPath).writeAsBytes(buildProbeSampleEpubBytes());

      final bundle = AdapterBundle.standard(
        workingDirectoryPath: tempDirectory.path,
        settingsRootPath:
            '${tempDirectory.path}${Platform.pathSeparator}settings',
        defaultProjectRootPath:
            '${tempDirectory.path}${Platform.pathSeparator}projects',
        allowConfiguredProjectPathOverride: false,
      );
      final importUseCase = ImportProjectFilesUseCase(
        projectToolHostPort: bundle.projectToolHostPort,
      );
      final service = ProjectImportExecutionService(
        importProjectFilesUseCase: importUseCase,
        projectToolHostPort: bundle.projectToolHostPort,
        writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
          projectWorkspacePort: bundle.projectWorkspacePort,
        ),
        narrativePersistenceService:
            BookDeconstructionNarrativePersistenceService(
              workspacePort: bundle.projectWorkspacePort,
            ),
      );

      final result = await service.execute(
        project: const ProjectDescriptor(
          id: 'project-epub',
          name: '拆书项目',
          rootPath: 'D:/Projects/deconstruction_epub_project',
          projectType: 'book_deconstruction',
        ),
        request: ProjectImportRequest(
          sourcePaths: <String>[epubPath],
          targetDirectory: 'sources/original',
          autoDeconstruct: true,
        ),
      );

      expect(result.ok, isTrue);
      expect(result.autoDeconstructionApplied, isTrue);
      expect(
        result.autoDeconstructionPreviewPath,
        'analysis/deconstruction/book_deconstruction_source_book.md',
      );
      final previewContent = await bundle.projectWorkspacePort.readTextFile(
        'D:/Projects/deconstruction_epub_project',
        'analysis/deconstruction/book_deconstruction_source_book.md',
      );
      expect(previewContent, contains('# 拆书结构化预演'));
      final archiveContent = await bundle.projectToolHostPort.readTextFile(
        'D:/Projects/deconstruction_epub_project',
        'sources/original/book_deconstruction_source_source_book.md',
      );
      expect(archiveContent, contains('第一章 港口风暴'));
      expect(archiveContent, contains('第二章 议会阴影'));
    },
  );

  test(
    'project import execution service writes smart analysis report for general projects',
    () async {
      final hostPort = _FakeProjectToolHostPort(
        externalFiles: <String, String>{
          'C:/imports/outline.md': '第一章 港口风暴\n这是一个章节式小说来源草稿。',
        },
      );
      final workspacePort = _InMemoryProjectWorkspacePort();
      final importUseCase = ImportProjectFilesUseCase(
        projectToolHostPort: hostPort,
      );
      final service = ProjectImportExecutionService(
        importProjectFilesUseCase: importUseCase,
        projectToolHostPort: hostPort,
        writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
          projectWorkspacePort: workspacePort,
        ),
        narrativePersistenceService:
            BookDeconstructionNarrativePersistenceService(
              workspacePort: workspacePort,
            ),
      );

      final result = await service.execute(
        project: const ProjectDescriptor(
          id: 'project-3',
          name: '一般项目',
          rootPath: 'D:/Projects/general_project',
          projectType: 'novel',
        ),
        request: const ProjectImportRequest(
          sourcePaths: <String>['C:/imports/outline.md'],
          targetDirectory: 'assets',
          autoDeconstruct: false,
          smartAnalysis: true,
          smartAnalysisProviderId: 'provider-a',
          smartAnalysisModelId: 'model-a',
        ),
      );

      expect(result.ok, isTrue);
      expect(result.autoDeconstructionApplied, isFalse);
      expect(result.smartAnalysisApplied, isTrue);
      expect(
        result.smartAnalysisReportPath,
        'analysis/project_import_analysis.md',
      );
      final reportContent = workspacePort.readStoredTextFile(
        'D:/Projects/general_project',
        'analysis/project_import_analysis.md',
      );
      expect(reportContent, isNotNull);
      expect(reportContent, contains('# 导入智能分析'));
      expect(reportContent, contains('内置导入分析智能体'));
      expect(reportContent, contains('model-a'));
      expect(reportContent, contains('provider-a'));
      expect(reportContent, contains('novel_source_text'));
      expect(result.summary, contains('智能分析报告已写入'));
    },
  );

  test(
    'project import execution service can smart-analyze mixed directory imports with epub content',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'project_import_execution_mixed_directory_test_',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final sourceRoot = Directory(
        '${tempDirectory.path}${Platform.pathSeparator}sources',
      )..createSync(recursive: true);
      final textsRoot = Directory(
        '${sourceRoot.path}${Platform.pathSeparator}texts',
      )..createSync(recursive: true);
      final seriesRoot = Directory(
        '${sourceRoot.path}${Platform.pathSeparator}series',
      )..createSync(recursive: true);
      final ignoredRoot = Directory(
        '${sourceRoot.path}${Platform.pathSeparator}ignored',
      )..createSync(recursive: true);
      await File(
        '${textsRoot.path}${Platform.pathSeparator}chapter_01.txt',
      ).writeAsString('第一章 港口风暴');
      await File(
        '${textsRoot.path}${Platform.pathSeparator}outline.md',
      ).writeAsString('这是一个章节式小说来源草稿。');
      await File(
        '${seriesRoot.path}${Platform.pathSeparator}probe_story.epub',
      ).writeAsBytes(buildProbeSampleEpubBytes());
      await File(
        '${ignoredRoot.path}${Platform.pathSeparator}cover.png',
      ).writeAsBytes(<int>[0x89, 0x50, 0x4E, 0x47]);

      final bundle = AdapterBundle.standard(
        workingDirectoryPath: tempDirectory.path,
        settingsRootPath:
            '${tempDirectory.path}${Platform.pathSeparator}settings',
        defaultProjectRootPath:
            '${tempDirectory.path}${Platform.pathSeparator}projects',
        allowConfiguredProjectPathOverride: false,
      );
      final importUseCase = ImportProjectFilesUseCase(
        projectToolHostPort: bundle.projectToolHostPort,
        sourceImportDiscoveryPort: const SourceImportDiscoveryService(),
      );
      final service = ProjectImportExecutionService(
        importProjectFilesUseCase: importUseCase,
        projectToolHostPort: bundle.projectToolHostPort,
        writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
          projectWorkspacePort: bundle.projectWorkspacePort,
        ),
        narrativePersistenceService:
            BookDeconstructionNarrativePersistenceService(
              workspacePort: bundle.projectWorkspacePort,
            ),
        sourceDocumentReaderService:
            const ReferenceSourceDocumentFileReaderService(),
      );

      final projectRoot =
          '${tempDirectory.path}${Platform.pathSeparator}projects${Platform.pathSeparator}general_directory_project';
      final result = await service.execute(
        project: ProjectDescriptor(
          id: 'project-4',
          name: '一般目录项目',
          rootPath: projectRoot,
          projectType: 'novel',
        ),
        request: ProjectImportRequest(
          sourcePaths: <String>[sourceRoot.path],
          targetDirectory: 'assets/bundle',
          autoDeconstruct: false,
          smartAnalysis: true,
          smartAnalysisProviderId: 'provider-a',
          smartAnalysisModelId: 'model-a',
        ),
      );

      expect(result.ok, isTrue);
      expect(
        result.importedPaths,
        contains('assets/bundle/texts/chapter_01.txt'),
      );
      expect(result.importedPaths, contains('assets/bundle/texts/outline.md'));
      expect(
        result.importedPaths,
        contains('assets/bundle/series/probe_story.epub'),
      );
      expect(result.smartAnalysisApplied, isTrue);
      final reportContent = await bundle.projectWorkspacePort.readTextFile(
        projectRoot,
        'analysis/project_import_analysis.md',
      );
      expect(reportContent, isNotNull);
      expect(reportContent, contains('# 导入智能分析'));
      expect(reportContent, contains('probe_story.epub'));
      expect(result.summary, contains('智能分析报告已写入'));
    },
  );
}

class _FakeProjectToolHostPort implements ProjectToolHostPort {
  _FakeProjectToolHostPort({
    Map<String, String> externalFiles = const <String, String>{},
    this.onCopy,
    this.throwOnCopy = false,
  }) : _externalFiles = Map<String, String>.from(externalFiles);

  final Map<String, String> _externalFiles;
  final void Function(String relativePath)? onCopy;
  final bool throwOnCopy;
  final List<
    ({String absolutePath, String rootPath, String targetRelativePath})
  >
  copiedFiles =
      <({String absolutePath, String rootPath, String targetRelativePath})>[];
  final Map<String, String> _projectFiles = <String, String>{};

  @override
  Future<void> copyExternalFile(
    String absolutePath,
    String rootPath,
    String targetRelativePath,
  ) async {
    if (throwOnCopy) {
      throw StateError('模拟 Markdown 投影复制失败');
    }
    copiedFiles.add((
      absolutePath: absolutePath,
      rootPath: rootPath,
      targetRelativePath: targetRelativePath,
    ));
    _projectFiles[_projectKey(rootPath, targetRelativePath)] =
        _externalFiles[absolutePath] ?? '';
    onCopy?.call(targetRelativePath);
  }

  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<void> deleteEntry(String rootPath, String relativePath) async {
    _projectFiles.remove(_projectKey(rootPath, relativePath));
  }

  @override
  Future<bool> entryExists(String rootPath, String relativePath) async {
    return _projectFiles.containsKey(_projectKey(rootPath, relativePath));
  }

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async {
    return const <JsonMap>[];
  }

  @override
  Future<void> moveEntry(
    String rootPath,
    String sourceRelativePath,
    String targetRelativePath,
  ) async {
    final value = _projectFiles.remove(
      _projectKey(rootPath, sourceRelativePath),
    );
    if (value != null) {
      _projectFiles[_projectKey(rootPath, targetRelativePath)] = value;
    }
  }

  @override
  Future<String?> readExternalTextFile(String absolutePath) async {
    return _externalFiles[absolutePath];
  }

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async {
    return _projectFiles[_projectKey(rootPath, relativePath)];
  }

  @override
  Future<void> writeExternalTextFile(
    String absolutePath,
    String content,
  ) async {
    _externalFiles[absolutePath] = content;
  }

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {
    _projectFiles[_projectKey(rootPath, relativePath)] = content;
  }

  String _projectKey(String rootPath, String relativePath) {
    return '${rootPath.replaceAll('\\', '/')}//${relativePath.replaceAll('\\', '/')}';
  }
}

class _StubSourceDocumentReaderService
    extends ReferenceSourceDocumentFileReaderService {
  _StubSourceDocumentReaderService(this._result);

  final ReferenceSourceDocumentFileReadResult _result;
  int readCalls = 0;

  @override
  Future<ReferenceSourceDocumentFileReadResult> read({
    required String sourceFilePath,
  }) async {
    readCalls += 1;
    return _result;
  }
}

class _RecordingStructuredContentBridgeService
    extends ProjectStructuredContentBridgeService {
  _RecordingStructuredContentBridgeService(
    this._events, {
    this.failPersist = false,
  });

  final List<String> _events;
  final bool failPersist;
  int persistedDocumentCount = 0;
  String documentPath = '';
  String documentKind = '';
  String content = '';

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
    if (failPersist) {
      throw StateError('模拟 SQLite 主库写入失败');
    }
    persistedDocumentCount += 1;
    this.documentPath = documentPath;
    this.documentKind = documentKind;
    this.content = content;
    _events.add('sqlite:$documentKind:$documentPath');
  }
}

class _InMemoryProjectWorkspacePort implements ProjectWorkspacePort {
  final Map<String, String> _files = <String, String>{};

  String? readStoredTextFile(String rootPath, String relativePath) {
    return _files[_key(rootPath, relativePath)];
  }

  String _key(String rootPath, String relativePath) {
    return '${rootPath.replaceAll('\\', '/')}//${relativePath.replaceAll('\\', '/')}';
  }

  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async {
    return const <JsonMap>[];
  }

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async {
    return readStoredTextFile(rootPath, relativePath);
  }

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {
    _files[_key(rootPath, relativePath)] = content;
  }
}
