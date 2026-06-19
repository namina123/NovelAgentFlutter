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
    'project import execution service writes auto deconstruction preview for book projects',
    () async {
      final hostPort = _FakeProjectToolHostPort(
        externalFiles: <String, String>{
          'C:/imports/source_book.md':
              '第一章 港口风暴\n主角在港口被迫卷入追捕。\n\n第二章 议会阴影\n城邦议会开始浮出水面。',
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
          id: 'project-2',
          name: '拆书项目',
          rootPath: 'D:/Projects/deconstruction_project',
          projectType: 'book_deconstruction',
        ),
        request: const ProjectImportRequest(
          sourcePaths: <String>['C:/imports/source_book.md'],
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
        'chapters/book_deconstruction_source_book.md',
      );
      expect(result.importedPaths, <String>['sources/original/source_book.md']);
      final previewContent = workspacePort.readStoredTextFile(
        'D:/Projects/deconstruction_project',
        'chapters/book_deconstruction_source_book.md',
      );
      expect(previewContent, isNotNull);
      expect(previewContent, contains('# 拆书结构化预演'));
      final archiveContent = workspacePort.readStoredTextFile(
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
        'chapters/book_deconstruction_source_book.md',
      );
      final previewContent = await bundle.projectWorkspacePort.readTextFile(
        'D:/Projects/deconstruction_epub_project',
        'chapters/book_deconstruction_source_book.md',
      );
      expect(previewContent, contains('# 拆书结构化预演'));
      final archiveContent = await bundle.projectWorkspacePort.readTextFile(
        'D:/Projects/deconstruction_epub_project',
        'sources/original/book_deconstruction_source_source_book.md',
      );
      expect(archiveContent, contains('Chapter 1: The Boy Who Lived'));
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
  }) : _externalFiles = Map<String, String>.from(externalFiles);

  final Map<String, String> _externalFiles;
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
    copiedFiles.add((
      absolutePath: absolutePath,
      rootPath: rootPath,
      targetRelativePath: targetRelativePath,
    ));
    _projectFiles[_projectKey(rootPath, targetRelativePath)] =
        _externalFiles[absolutePath] ?? '';
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
