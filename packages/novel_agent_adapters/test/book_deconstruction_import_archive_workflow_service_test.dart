import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  test('BookDeconstructionImportArchiveWorkflowService 会读取源文件并归档到来源层', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'book_deconstruction_import_archive_workflow_test_',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });
    final sourceFile = File(
      '${tempDirectory.path}${Platform.pathSeparator}source_book.md',
    );
    await sourceFile.writeAsString('第一章 港口风暴\n主角在港口被迫卷入一场追捕。');

    final workspacePort = _InMemoryProjectWorkspacePort();
    final workflowService = BookDeconstructionImportArchiveWorkflowService(
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
    );

    final result = await workflowService.execute(
      project: const ProjectDescriptor(
        id: 'project-1',
        name: '拆书测试项目',
        rootPath: 'D:/Projects/book_deconstruction_import_test',
        projectType: 'book_deconstruction',
      ),
      sourceFilePath: sourceFile.path,
    );

    final archivePath = const BookDeconstructionTargetPathService()
        .sourceArchivePath(sourceFile.path);
    expect(result.sourceFilePath, sourceFile.path);
    expect(result.sourceTitle, 'source_book.md');
    expect(result.archivePath, archivePath);
    final archivedText = await workspacePort.readTextFile(
      'D:/Projects/book_deconstruction_import_test',
      archivePath,
    );
    expect(archivedText, contains('第一章 港口风暴'));
  });
}

class _InMemoryProjectWorkspacePort implements ProjectWorkspacePort {
  final Map<String, String> _files = <String, String>{};

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
    return _files[_key(rootPath, relativePath)];
  }

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {
    _files[_key(rootPath, relativePath)] = content;
  }

  String _key(String rootPath, String relativePath) {
    return '${rootPath.replaceAll('\\', '/')}//${relativePath.replaceAll('\\', '/')}';
  }
}
