import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/project_open/application/services/project_open_view_data_service.dart';
import 'package:novel_agent_app/features/project_open/presentation/models/project_open_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('ProjectOpenViewDataService', () {
    test(
      'build merges default root and recent project while prioritizing current project',
      () async {
        final rootDirectory = await Directory.systemTemp.createTemp(
          'project_open_view_data_service_test',
        );
        addTearDown(() async {
          if (await rootDirectory.exists()) {
            await rootDirectory.delete(recursive: true);
          }
        });

        final currentDirectory = Directory(
          '${rootDirectory.path}${Platform.pathSeparator}alpha_project',
        );
        final recentDirectory = Directory(
          '${rootDirectory.path}${Platform.pathSeparator}beta_project',
        );
        await currentDirectory.create(recursive: true);
        await recentDirectory.create(recursive: true);

        final snapshots = <String, ProjectWorkspaceSnapshot>{
          currentDirectory.path: _snapshotOf(
            name: 'Alpha Project',
            rootPath: currentDirectory.path,
            projectType: 'novel',
          ),
          recentDirectory.path: _snapshotOf(
            name: 'Beta Project',
            rootPath: recentDirectory.path,
            projectType: 'outline',
            runtimeBaselineId: 'continuous_autonomous',
          ),
        };

        final service = ProjectOpenViewDataService();
        final viewData = await service.build(
          projectsRootPath: rootDirectory.path,
          recentProjectPath: recentDirectory.path,
          currentProjectPath: currentDirectory.path,
          allowImportLocal: true,
          loadWorkspace: (rootPath) async => snapshots[rootPath],
        );

        expect(viewData.entries, hasLength(2));
        expect(viewData.entries.first.title, 'Alpha Project');
        expect(viewData.entries.first.isCurrentProject, isTrue);
        expect(viewData.selectedEntryId, viewData.entries.first.id);

        final recentEntry = viewData.entries.last;
        expect(recentEntry.title, 'Beta Project');
        expect(recentEntry.sourceBadges, containsAll(<String>['默认目录', '最近项目']));
        expect(recentEntry.runtimeBaselineLabel, 'continuous_autonomous');
      },
    );

    test(
      'selectEntry updates selected marker without rebuilding discovery result',
      () {
        final service = ProjectOpenViewDataService();
        final viewData = ProjectOpenViewData(
          title: '打开项目',
          description: 'desc',
          projectsRootPath: 'D:/Projects',
          currentProjectPath: '',
          allowImportLocal: true,
          selectedEntryId: 'a',
          status: '',
          entries: const <ProjectOpenEntryViewData>[
            ProjectOpenEntryViewData(
              id: 'a',
              title: 'A',
              path: 'D:/Projects/A',
              projectTypeLabel: '小说',
              storageLabel: 'Markdown',
              runtimeBaselineLabel: '未指定',
              lastModifiedLabel: '未知',
              sourceBadges: <String>['默认目录'],
              isCurrentProject: false,
              isSelected: true,
            ),
            ProjectOpenEntryViewData(
              id: 'b',
              title: 'B',
              path: 'D:/Projects/B',
              projectTypeLabel: '小说',
              storageLabel: 'Markdown',
              runtimeBaselineLabel: '未指定',
              lastModifiedLabel: '未知',
              sourceBadges: <String>['最近项目'],
              isCurrentProject: false,
              isSelected: false,
            ),
          ],
        );

        final selected = service.selectEntry(viewData, 'b');

        expect(selected.selectedEntryId, 'b');
        expect(selected.entries.first.isSelected, isFalse);
        expect(selected.entries.last.isSelected, isTrue);
      },
    );
  });
}

ProjectWorkspaceSnapshot _snapshotOf({
  required String name,
  required String rootPath,
  required String projectType,
  String runtimeBaselineId = '',
}) {
  return ProjectWorkspaceSnapshot(
    project: ProjectDescriptor(
      id: name,
      name: name,
      rootPath: rootPath,
      projectType: projectType,
      storageStrategy: ProjectStorageStrategy.markdownProjectStore,
      runtimeBaselineId: runtimeBaselineId,
    ),
    projectInfo: const <String, Object?>{},
    entries: const <JsonMap>[],
  );
}
