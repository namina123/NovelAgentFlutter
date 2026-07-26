import 'dart:async';

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
      final controller = ProjectOpenController(projectOpenScanRuntime: runtime);

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

    test(
      'forceRefresh performs a new scan for manual refresh requests',
      () async {
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
      },
    );

    test('serializes a manual refresh behind an in-flight scan', () async {
      final runtime = _ControlledProjectOpenScanRuntime();
      final controller = ProjectOpenController(projectOpenScanRuntime: runtime);

      final initialRefresh = controller.refreshSnapshot(
        projectsRootPath: 'D:/Projects',
        recentProjectPath: '',
        currentProjectPath: '',
        allowImportLocal: true,
      );
      await Future<void>.delayed(Duration.zero);

      final manualRefresh = controller.refreshSnapshot(
        projectsRootPath: 'D:/Projects',
        recentProjectPath: '',
        currentProjectPath: '',
        allowImportLocal: true,
        forceRefresh: true,
      );
      await Future<void>.delayed(Duration.zero);

      expect(runtime.requests, hasLength(1));

      runtime.completeNext(status: 'stale');
      await Future<void>.delayed(Duration.zero);

      expect(runtime.requests, hasLength(2));

      runtime.completeNext(status: 'fresh');
      await initialRefresh;
      final latest = await manualRefresh;

      expect(latest.status, 'fresh');
      expect(controller.snapshot.status, 'fresh');
    });

    test(
      'serializes a library source change behind an in-flight scan',
      () async {
        final runtime = _ControlledProjectOpenScanRuntime();
        final controller = ProjectOpenController(
          projectOpenScanRuntime: runtime,
        );

        final initialRefresh = controller.refreshSnapshot(
          projectsRootPath: 'D:/Projects-A',
          recentProjectPath: '',
          currentProjectPath: '',
          allowImportLocal: true,
        );
        await Future<void>.delayed(Duration.zero);
        final rootSwitchRefresh = controller.refreshSnapshot(
          projectsRootPath: 'D:/Projects-B',
          recentProjectPath: '',
          currentProjectPath: '',
          allowImportLocal: true,
        );
        await Future<void>.delayed(Duration.zero);

        expect(runtime.requests, hasLength(1));

        runtime.completeNext(
          status: 'old root',
          projectsRootPath: 'D:/Projects-A',
        );
        await Future<void>.delayed(Duration.zero);

        expect(runtime.requests, hasLength(2));

        runtime.completeNext(
          status: 'new root',
          projectsRootPath: 'D:/Projects-B',
        );
        await initialRefresh;
        final latest = await rootSwitchRefresh;

        expect(latest.projectsRootPath, 'D:/Projects-B');
        expect(controller.snapshot.projectsRootPath, 'D:/Projects-B');
        expect(controller.snapshot.status, 'new root');
      },
    );

    test('clears stale status feedback on a later ordinary refresh', () async {
      var scanCount = 0;
      final runtime = _FakeProjectOpenScanRuntime(
        onScan: () {
          scanCount += 1;
          return ProjectOpenSnapshot(
            projectsRootPath: 'D:/Projects',
            recentProjectPath: '',
            currentProjectPath: '',
            allowImportLocal: true,
            records: const <ProjectOpenProjectRecord>[],
            selectedEntryId: '',
            status: '',
          );
        },
      );
      final controller = ProjectOpenController(projectOpenScanRuntime: runtime);

      await controller.refreshSnapshot(
        projectsRootPath: 'D:/Projects',
        recentProjectPath: '',
        currentProjectPath: '',
        allowImportLocal: true,
        status: '打开项目失败。',
        forceRefresh: true,
      );
      final refreshed = await controller.refreshSnapshot(
        projectsRootPath: 'D:/Projects',
        recentProjectPath: '',
        currentProjectPath: '',
        allowImportLocal: true,
      );

      expect(scanCount, 1);
      expect(refreshed.status, isEmpty);
    });

    test(
      'retains cached entries and reports feedback when scanning fails',
      () async {
        var scanCount = 0;
        final runtime = _FakeProjectOpenScanRuntime(
          onScan: () {
            scanCount += 1;
            if (scanCount == 1) {
              return ProjectOpenSnapshot(
                projectsRootPath: 'D:/Projects',
                recentProjectPath: '',
                currentProjectPath: '',
                allowImportLocal: true,
                records: <ProjectOpenProjectRecord>[
                  ProjectOpenProjectRecord(
                    id: 'novel',
                    title: '可继续打开的项目',
                    path: 'D:/Projects/novel',
                    projectTypeId: 'novel',
                    storageStrategyId: 'markdown_project_store',
                    runtimeBaselineId: '',
                    modifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
                    sourceBadges: const <String>['默认目录'],
                    isCurrentProject: false,
                  ),
                ],
                selectedEntryId: 'novel',
                status: '',
              );
            }
            throw StateError('drive temporarily unavailable');
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
        final recovered = await controller.refreshSnapshot(
          projectsRootPath: 'D:/Projects',
          recentProjectPath: '',
          currentProjectPath: '',
          allowImportLocal: true,
          forceRefresh: true,
        );

        expect(recovered.records.single.title, '可继续打开的项目');
        expect(recovered.selectedEntryId, 'novel');
        expect(recovered.status, contains('无法刷新作品库'));
      },
    );

    test(
      'preserves a newer user selection while a refresh is in flight',
      () async {
        final runtime = _ControlledProjectOpenScanRuntime();
        final controller = ProjectOpenController(
          projectOpenScanRuntime: runtime,
        );

        final refresh = controller.refreshSnapshot(
          projectsRootPath: 'D:/Projects',
          recentProjectPath: '',
          currentProjectPath: '',
          allowImportLocal: true,
        );
        await Future<void>.delayed(Duration.zero);
        controller.selectEntry('beta');
        final joinedRefresh = controller.refreshSnapshot(
          projectsRootPath: 'D:/Projects',
          recentProjectPath: '',
          currentProjectPath: '',
          allowImportLocal: true,
        );
        runtime.completeNext(
          status: '',
          records: <ProjectOpenProjectRecord>[
            _projectRecord(id: 'alpha'),
            _projectRecord(id: 'beta'),
          ],
          selectedEntryId: 'alpha',
        );

        final snapshot = await refresh;
        final joinedSnapshot = await joinedRefresh;

        expect(snapshot.selectedEntryId, 'beta');
        expect(joinedSnapshot.selectedEntryId, 'beta');
        expect(controller.snapshot.selectedEntryId, 'beta');
      },
    );

    test(
      'selectEntry updates cached snapshot selection without rescanning',
      () async {
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
      },
    );
  });
}

class _ControlledProjectOpenScanRuntime extends ProjectOpenScanRuntime {
  final List<Completer<ProjectOpenSnapshot>> requests =
      <Completer<ProjectOpenSnapshot>>[];

  @override
  Future<ProjectOpenSnapshot> scan({
    required String projectsRootPath,
    required String recentProjectPath,
    required String currentProjectPath,
    required bool allowImportLocal,
    String selectedEntryId = '',
    String status = '',
  }) {
    final completer = Completer<ProjectOpenSnapshot>();
    requests.add(completer);
    return completer.future;
  }

  void completeNext({
    required String status,
    List<ProjectOpenProjectRecord> records = const <ProjectOpenProjectRecord>[],
    String selectedEntryId = '',
    String projectsRootPath = 'D:/Projects',
  }) {
    final request = requests.firstWhere((item) => !item.isCompleted);
    request.complete(
      ProjectOpenSnapshot(
        projectsRootPath: projectsRootPath,
        recentProjectPath: '',
        currentProjectPath: '',
        allowImportLocal: true,
        records: records,
        selectedEntryId: selectedEntryId,
        status: status,
      ),
    );
  }
}

ProjectOpenProjectRecord _projectRecord({required String id}) {
  return ProjectOpenProjectRecord(
    id: id,
    title: id,
    path: 'D:/Projects/$id',
    projectTypeId: 'novel',
    storageStrategyId: 'markdown_project_store',
    runtimeBaselineId: '',
    modifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
    sourceBadges: const <String>['默认目录'],
    isCurrentProject: false,
  );
}

class _FakeProjectOpenScanRuntime extends ProjectOpenScanRuntime {
  _FakeProjectOpenScanRuntime({required this.onScan});

  final FutureOr<ProjectOpenSnapshot> Function() onScan;

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
