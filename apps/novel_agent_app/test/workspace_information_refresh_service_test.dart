import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/models/workspace_information_scan_result.dart';
import 'package:novel_agent_app/features/workbench/application/services/workspace_information_projection_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/workspace_information_refresh_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/workspace_information_scan_runtime.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('WorkspaceInformationRefreshService', () {
    test('reuses cached view data until invalidated', () async {
      var scanCount = 0;
      final service = WorkspaceInformationRefreshService(
        scanRuntime: _FakeWorkspaceInformationScanRuntime(
          onScan: () {
            scanCount += 1;
            return WorkspaceInformationScanResult(
              projectRootPath: 'D:/Projects/demo',
              workspaceEntries: const <JsonMap>[],
              fileContents: const <String, String>{},
              sourcePaths: const <String>[],
            );
          },
        ),
        projectionService: const WorkspaceInformationProjectionService(),
      );

      final project = _project('D:/Projects/demo');
      final first = await service.build(
        project: project,
        workspaceEntries: const <JsonMap>[],
      );
      final second = await service.build(
        project: project,
        workspaceEntries: const <JsonMap>[],
      );

      expect(scanCount, 1);
      expect(identical(first, second), isTrue);

      service.invalidateProject(project.rootPath);

      final third = await service.build(
        project: project,
        workspaceEntries: const <JsonMap>[],
      );

      expect(scanCount, 2);
      expect(identical(second, third), isFalse);
    });

    test('forceRefresh bypasses the cache', () async {
      var scanCount = 0;
      final service = WorkspaceInformationRefreshService(
        scanRuntime: _FakeWorkspaceInformationScanRuntime(
          onScan: () {
            scanCount += 1;
            return WorkspaceInformationScanResult(
              projectRootPath: 'D:/Projects/demo',
              workspaceEntries: const <JsonMap>[],
              fileContents: const <String, String>{},
              sourcePaths: const <String>[],
            );
          },
        ),
        projectionService: const WorkspaceInformationProjectionService(),
      );

      final project = _project('D:/Projects/demo');
      await service.build(
        project: project,
        workspaceEntries: const <JsonMap>[],
      );
      await service.build(
        project: project,
        workspaceEntries: const <JsonMap>[],
        forceRefresh: true,
      );

      expect(scanCount, 2);
    });
  });
}

class _FakeWorkspaceInformationScanRuntime extends WorkspaceInformationScanRuntime {
  _FakeWorkspaceInformationScanRuntime({required this.onScan});

  final WorkspaceInformationScanResult Function() onScan;

  @override
  Future<WorkspaceInformationScanResult> scan({
    required String projectRootPath,
    required List<JsonMap> workspaceEntries,
  }) async {
    return onScan();
  }
}

ProjectDescriptor _project(String rootPath) {
  return ProjectDescriptor(
    id: rootPath,
    name: '测试项目',
    rootPath: rootPath,
    projectType: 'novel',
    storageStrategy: ProjectStorageStrategy.markdownProjectStore,
  );
}
