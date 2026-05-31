import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/models/project_import_request.dart';
import 'package:novel_agent_app/features/workbench/application/services/project_import_execution_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

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
      expect(
        result.autoDeconstructionPreviewPath,
        'chapters/book_deconstruction_source_book.md',
      );
      final previewContent = workspacePort.readStoredTextFile(
        'D:/Projects/deconstruction_project',
        'chapters/book_deconstruction_source_book.md',
      );
      expect(previewContent, isNotNull);
      expect(previewContent, contains('# 拆书结构化预演'));
      expect(result.summary, contains('自动拆书预演纪要已写入'));
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
