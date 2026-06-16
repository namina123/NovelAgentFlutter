import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LoadProjectWorkspaceUseCase', () {
    test(
      'migrates legacy project overview into canonical overview path on load',
      () async {
        final workspacePort = _FakeProjectWorkspacePort(<String, String>{
          'premise/project_brief.md': '# 项目概览\n\n旧入口内容',
        });
        final useCase = LoadProjectWorkspaceUseCase(
          projectRepository: _FakeProjectRepository(
            const ProjectDescriptor(
              id: 'project',
              name: '测试项目',
              rootPath: 'D:/Projects/demo',
              projectType: 'novel',
            ),
          ),
          projectWorkspacePort: workspacePort,
        );

        final snapshot = await useCase.execute('D:/Projects/demo');

        expect(snapshot, isNotNull);
        expect(
          workspacePort.files[ProjectSupportDocumentCatalog
              .projectOverviewRelativePath],
          '# 项目概览\n\n旧入口内容',
        );
        expect(
          snapshot!.entries.any(
            (entry) =>
                entry['relative_path'] ==
                ProjectSupportDocumentCatalog.projectOverviewRelativePath,
          ),
          isTrue,
        );
      },
    );
  });
}

class _FakeProjectRepository implements ProjectRepository {
  _FakeProjectRepository(this._project);

  final ProjectDescriptor _project;

  @override
  Future<ProjectDescriptor?> openByPath(String rootPath) async {
    if (rootPath != _project.rootPath) {
      return null;
    }
    return _project;
  }
}

class _FakeProjectWorkspacePort implements ProjectWorkspacePort {
  _FakeProjectWorkspacePort(Map<String, String> files)
    : files = Map<String, String>.from(files);

  final Map<String, String> files;

  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async {
    final entries = <JsonMap>[];
    final directories = <String>{};
    for (final path in files.keys) {
      final normalized = _normalize(path);
      if (normalized.isEmpty) {
        continue;
      }
      final parts = normalized.split('/');
      for (var index = 0; index < parts.length - 1; index++) {
        final directory = parts.take(index + 1).join('/');
        directories.add(directory);
      }
      entries.add(<String, Object?>{
        'relative_path': normalized,
        'display_name': parts.last,
        'is_dir': false,
      });
    }
    for (final directory in directories) {
      entries.add(<String, Object?>{
        'relative_path': directory,
        'display_name': directory.split('/').last,
        'is_dir': true,
      });
    }
    entries.sort(
      (left, right) => left['relative_path'].toString().compareTo(
        right['relative_path'].toString(),
      ),
    );
    return entries;
  }

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async {
    return files[_normalize(relativePath)];
  }

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {
    files[_normalize(relativePath)] = content;
  }

  String _normalize(String relativePath) {
    return relativePath.trim().replaceAll('\\', '/');
  }
}
