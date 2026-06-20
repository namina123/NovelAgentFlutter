import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/project_open/application/controllers/project_open_controller.dart';
import 'package:novel_agent_app/features/project_open/application/models/project_open_snapshot.dart';
import 'package:novel_agent_app/features/project_open/application/services/project_open_scan_runtime.dart';

void main() {
  group('ProjectOpenController', () {
    test('caches scan results for the same visibility key', () async {
      var scanCount = 0;
      final runtime = _FakeProjectOpenScanRuntime(
        onScan: () {
          scanCount += 1;
          return ProjectOpenSnapshot(
            projectsRootPath: 'D:/Projects',
            recentProjectPath: '',
            currentProjectPath: '',
            allowImportLocal: true,
            records: <ProjectOpenProjectRecord>[],
            selectedEntryId: '',
            status: '',
          );
        },
      );
      final controller = ProjectOpenController(
        projectOpenScanRuntime: runtime,
      );

      final first = await controller.refreshSnapshot(
        projectsRootPath: 'D:/Projects',
        recentProjectPath: '',
        currentProjectPath: '',
        allowImportLocal: true,
      );
      final second = await controller.refreshSnapshot(
        projectsRootPath: 'D:/Projects',
        recentProjectPath: '',
        currentProjectPath: '',
        allowImportLocal: true,
      );

      expect(scanCount, 1);
      expect(identical(first, second), isTrue);
    });

    test('forceRefresh performs a new scan for manual refresh requests', () async {
      var scanCount = 0;
      final runtime = _FakeProjectOpenScanRuntime(
        onScan: () {
          scanCount += 1;
          return ProjectOpenSnapshot(
            projectsRootPath: 'D:/Projects',
            recentProjectPath: '',
            currentProjectPath: '',
            allowImportLocal: true,
            records: <ProjectOpenProjectRecord>[],
            selectedEntryId: '',
            status: '',
          );
        },
      );
      final controller = ProjectOpenController(
        projectOpenScanRuntime: runtime,
      );

      await controller.refreshSnapshot(
        projectsRootPath: 'D:/Projects',
        recentProjectPath: '',
        currentProjectPath: '',
        allowImportLocal: true,
      );
      await controller.refreshSnapshot(
        projectsRootPath: 'D:/Projects',
        recentProjectPath: '',
        currentProjectPath: '',
        allowImportLocal: true,
        forceRefresh: true,
      );

      expect(scanCount, 2);
    });

    test('selectEntry updates cached snapshot selection without rescanning', () async {
      var scanCount = 0;
      final runtime = _FakeProjectOpenScanRuntime(
        onScan: () {
          scanCount += 1;
          return ProjectOpenSnapshot(
            projectsRootPath: 'D:/Projects',
            recentProjectPath: '',
            currentProjectPath: '',
            allowImportLocal: true,
            records: <ProjectOpenProjectRecord>[
              ProjectOpenProjectRecord(
                id: 'alpha',
                title: 'Alpha',
                path: 'D:/Projects/alpha',
                projectTypeId: 'novel',
                storageStrategyId: 'markdown_project_store',
                runtimeBaselineId: '',
                modifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
                sourceBadges: const <String>['默认目录'],
                isCurrentProject: true,
              ),
            ],
            selectedEntryId: 'alpha',
            status: '',
          );
        },
      );
      final controller = ProjectOpenController(
        projectOpenScanRuntime: runtime,
      );

      await controller.refreshSnapshot(
        projectsRootPath: 'D:/Projects',
        recentProjectPath: '',
        currentProjectPath: '',
        allowImportLocal: true,
      );
      final selected = controller.selectEntry('alpha');

      expect(scanCount, 1);
      expect(selected.selectedEntryId, 'alpha');
    });
  });
}

class _FakeProjectOpenScanRuntime extends ProjectOpenScanRuntime {
  _FakeProjectOpenScanRuntime({required this.onScan});

  final ProjectOpenSnapshot Function() onScan;

  @override
  Future<ProjectOpenSnapshot> scan({
    required String projectsRootPath,
    required String recentProjectPath,
    required String currentProjectPath,
    required bool allowImportLocal,
    String selectedEntryId = '',
    String status = '',
  }) async {
    return onScan();
  }
}
