import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/state/project_lifecycle_coordinator.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_launcher_view_data.dart';

void main() {
  group('ProjectLifecycleCoordinator', () {
    test(
      'returns create launcher hints when there is no default project',
      () async {
        final coordinator = ProjectLifecycleCoordinator(
          readSettings: () => null,
          loadProject:
              (
                _, {
                bool deferHydration = false,
                bool openDefaultDocument = true,
              }) async => false,
          readCurrentProject: () => null,
          isMobileProjectRootLocked: () => false,
        );

        final result = await coordinator.loadDefaultProject();

        expect(result.isLoaded, isFalse);
        expect(result.kind, ProjectLifecycleResolutionKind.missingSettings);
        expect(result.shouldShowLauncher, isTrue);
        expect(result.launcherMode, ProjectLauncherMode.create);
        expect(result.launcherStatus, contains('当前还没有可恢复的有效项目'));
      },
    );

    test(
      'loads the default project through the shared loadProject bridge',
      () async {
        final loadedPaths = <String>[];
        final coordinator = ProjectLifecycleCoordinator(
          readSettings: () => const AppSettings(
            defaultProviderId: '',
            defaultAgentId: '',
            defaultModelId: '',
            defaultProjectPath: 'D:/Projects/demo',
            autoSaveDrafts: true,
            providers: <ProviderEndpointSettings>[],
          ),
          loadProject:
              (
                rootPath, {
                bool deferHydration = false,
                bool openDefaultDocument = true,
              }) async {
                loadedPaths.add(rootPath);
                expect(deferHydration, isTrue);
                expect(openDefaultDocument, isFalse);
                return true;
              },
          readCurrentProject: () => null,
          isMobileProjectRootLocked: () => false,
        );

        final result = await coordinator.loadDefaultProject();

        expect(result.isLoaded, isTrue);
        expect(result.projectPath, 'D:/Projects/demo');
        expect(loadedPaths, <String>['D:/Projects/demo']);
      },
    );

    test(
      'returns failure resolution for empty project path without loading',
      () async {
        var called = false;
        final coordinator = ProjectLifecycleCoordinator(
          readSettings: () => null,
          loadProject:
              (
                _, {
                bool deferHydration = false,
                bool openDefaultDocument = true,
              }) async {
                called = true;
                return false;
              },
          readCurrentProject: () => null,
          isMobileProjectRootLocked: () => false,
        );

        final result = await coordinator.openProjectFromPath(
          '',
          failureLauncherMode: ProjectLauncherMode.guard,
          failureLauncherStatus: '未选择目录。',
        );

        expect(called, isFalse);
        expect(result.isLoaded, isFalse);
        expect(result.kind, ProjectLifecycleResolutionKind.invalidProjectPath);
        expect(result.shouldShowLauncher, isTrue);
        expect(result.launcherMode, ProjectLauncherMode.guard);
        expect(result.launcherStatus, '未选择目录。');
      },
    );

    test(
      'converts an explicit open exception into recovery feedback',
      () async {
        final coordinator = ProjectLifecycleCoordinator(
          readSettings: () => null,
          loadProject:
              (
                _, {
                bool deferHydration = false,
                bool openDefaultDocument = true,
              }) async {
                throw StateError('corrupt manifest');
              },
          readCurrentProject: () => null,
          isMobileProjectRootLocked: () => false,
        );

        final result = await coordinator.openProjectFromPath(
          'D:/Projects/broken',
          failureLauncherMode: ProjectLauncherMode.guard,
          failureLauncherStatus: '所选目录不是有效项目。',
        );

        expect(result.isLoaded, isFalse);
        expect(result.kind, ProjectLifecycleResolutionKind.invalidProjectPath);
        expect(result.shouldShowLauncher, isTrue);
        expect(result.launcherMode, ProjectLauncherMode.guard);
        expect(result.launcherStatus, '所选目录不是有效项目。');
      },
    );

    test('keeps a corrupt manifest project in an actionable recovery state',
        () async {
      final coordinator = ProjectLifecycleCoordinator(
        readSettings: () => null,
        loadProject:
            (
              _, {
              bool deferHydration = false,
              bool openDefaultDocument = true,
            }) async {
              throw const ProjectManifestCorruptionException(
                rootPath: 'D:/Projects/broken',
              );
            },
        readCurrentProject: () => null,
        isMobileProjectRootLocked: () => false,
      );

      final result = await coordinator.openProjectFromPath(
        'D:/Projects/broken',
        failureLauncherMode: ProjectLauncherMode.guard,
      );

      expect(result.isLoaded, isFalse);
      expect(result.shouldShowLauncher, isTrue);
      expect(result.launcherStatus, contains('项目清单损坏'));
      expect(result.launcherStatus, contains('未改写项目'));
    });

    test(
      'converts a default project load exception into create recovery',
      () async {
        final coordinator = ProjectLifecycleCoordinator(
          readSettings: () => const AppSettings(
            defaultProviderId: '',
            defaultAgentId: '',
            defaultModelId: '',
            defaultProjectPath: 'D:/Projects/broken',
            autoSaveDrafts: true,
            providers: <ProviderEndpointSettings>[],
          ),
          loadProject:
              (
                _, {
                bool deferHydration = false,
                bool openDefaultDocument = true,
              }) async {
                throw StateError('project files are unavailable');
              },
          readCurrentProject: () => null,
          isMobileProjectRootLocked: () => false,
        );

        final result = await coordinator.loadDefaultProject();

        expect(result.isLoaded, isFalse);
        expect(
          result.kind,
          ProjectLifecycleResolutionKind.invalidDefaultProjectPath,
        );
        expect(result.shouldShowLauncher, isTrue);
        expect(result.launcherMode, ProjectLauncherMode.create);
        expect(result.launcherStatus, contains('上次打开的项目不可用'));
      },
    );
  });
}
