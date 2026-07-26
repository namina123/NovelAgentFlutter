import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'runtime profile repository falls back to the manifest descriptor on a type mismatch',
    () async {
      final workspacePort = _MemoryWorkspacePort();
      const project = ProjectDescriptor(
        id: 'ordinary-project',
        name: '普通小说',
        rootPath: '/projects/ordinary-project',
        projectType: 'novel',
      );
      final documentService = ProjectRuntimeProfileDocumentService();
      await workspacePort.writeTextFile(
        project.rootPath,
        ProjectRuntimeProfileDocumentService.profileRelativePath,
        documentService.encode(
          documentService.buildProfile(
            projectType: 'long_novel',
            runtimeBaselineId: 'continuous_autonomous',
          ),
        ),
      );

      final profile = await ProjectRuntimeProfileRepository(
        workspacePort: workspacePort,
        documentService: documentService,
      ).load(project);

      expect(profile.projectType, 'novel');
      expect(profile.runtimeBaselineId, isEmpty);
    },
  );

  test(
    'runtime profile repository does not let a stale baseline override the manifest descriptor',
    () async {
      final workspacePort = _MemoryWorkspacePort();
      const project = ProjectDescriptor(
        id: 'long-project',
        name: '长篇项目',
        rootPath: '/projects/long-project',
        projectType: 'long_novel',
        runtimeBaselineId: 'continuous_autonomous',
      );
      final documentService = ProjectRuntimeProfileDocumentService();
      await workspacePort.writeTextFile(
        project.rootPath,
        ProjectRuntimeProfileDocumentService.profileRelativePath,
        documentService.encode(
          documentService.buildProfile(
            projectType: 'long_novel',
            runtimeBaselineId: 'chapter_collaboration_autorun',
          ),
        ),
      );

      final profile = await ProjectRuntimeProfileRepository(
        workspacePort: workspacePort,
        documentService: documentService,
      ).load(project);

      expect(profile.projectType, 'long_novel');
      expect(profile.runtimeBaselineId, 'continuous_autonomous');
      expect(
        profile.initialRunOptions['runtime_baseline_id'],
        'continuous_autonomous',
      );
    },
  );
}

class _MemoryWorkspacePort implements ProjectWorkspacePort {
  final Map<String, String> _files = <String, String>{};

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
    _files[_key(rootPath, relativePath)] = content;
  }

  String _key(String rootPath, String relativePath) {
    return '${rootPath.replaceAll('\\', '/')}//${relativePath.replaceAll('\\', '/')}';
  }
}
