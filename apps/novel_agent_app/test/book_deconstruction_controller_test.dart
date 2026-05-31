import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/controllers/book_deconstruction_controller.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('拆书控制器可完成预览并写入应用前确认纪要', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    final controller = BookDeconstructionController(
      projectToolHostPort: _FakeProjectToolHostPort(),
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
      readCurrentProject: () => const ProjectDescriptor(
        id: 'project-1',
        name: '拆书测试项目',
        rootPath: 'D:/Projects/deconstruction_project',
        projectType: 'book_deconstruction',
      ),
      syncWorkbenchResources: () async {
        workspacePort.syncCount += 1;
      },
      onBackRequested: () {},
    );

    await controller.initialize();
    controller.onBookDeconstructionSourceTitleChanged('海上城邦');
    controller.onBookDeconstructionSourceContentChanged(
      '第一章 港口风暴\n主角在港口被迫卷入一场追捕。\n\n第二章 议会阴影\n城邦议会开始浮出水面。',
    );
    controller.onBookDeconstructionCharacterLinesChanged('林砚：被迫卷入城邦风暴的主角');

    await controller.onBookDeconstructionBuildPreviewRequested();

    expect(controller.viewData.previewSections, isNotEmpty);
    expect(controller.viewData.planGroups, isNotEmpty);

    final firstItemId = controller.viewData.planGroups.first.items.first.id;
    controller.onBookDeconstructionPlanItemSelectionChanged(
      itemId: firstItemId,
      selected: false,
    );

    await controller.onBookDeconstructionConfirmRequested();

    final content = workspacePort.readStoredTextFile(
      'D:/Projects/deconstruction_project',
      'analysis/book_deconstruction_preview.md',
    );
    expect(content, isNotNull);
    expect(content, contains('# 拆书结构化预演'));
    expect(
      controller.viewData.confirmedPreviewPath,
      'analysis/book_deconstruction_preview.md',
    );
    expect(workspacePort.syncCount, 1);
  });
}

class _FakeProjectToolHostPort implements ProjectToolHostPort {
  @override
  Future<void> copyExternalFile(
    String absolutePath,
    String rootPath,
    String targetRelativePath,
  ) async {}

  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<void> deleteEntry(String rootPath, String relativePath) async {}

  @override
  Future<bool> entryExists(String rootPath, String relativePath) async => false;

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
  ) async {}

  @override
  Future<String?> readExternalTextFile(String absolutePath) async => null;

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async =>
      null;

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
  ) async {}
}

class _InMemoryProjectWorkspacePort implements ProjectWorkspacePort {
  final Map<String, String> _files = <String, String>{};
  int syncCount = 0;

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
