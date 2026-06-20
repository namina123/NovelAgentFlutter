import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/project_open/application/models/project_open_snapshot.dart';
import 'package:novel_agent_app/features/project_open/application/services/project_open_view_data_service.dart';
import 'package:novel_agent_app/features/project_open/presentation/models/project_open_view_data.dart';

void main() {
  group('ProjectOpenViewDataService', () {
    test(
      'build maps snapshot records into project open view data',
      () {
        final service = ProjectOpenViewDataService();
        final snapshot = ProjectOpenSnapshot(
          projectsRootPath: 'D:/Projects',
          recentProjectPath: 'D:/Projects/beta_project',
          currentProjectPath: 'D:/Projects/alpha_project',
          allowImportLocal: true,
          selectedEntryId: 'alpha',
          status: '',
          records: <ProjectOpenProjectRecord>[
            ProjectOpenProjectRecord(
              id: 'alpha',
              title: 'Alpha Project',
              path: 'D:/Projects/alpha_project',
              projectTypeId: 'novel',
              storageStrategyId: 'markdown_project_store',
              runtimeBaselineId: '',
              modifiedAt: DateTime.fromMillisecondsSinceEpoch(0),
              sourceBadges: <String>['默认目录'],
              isCurrentProject: true,
            ),
            ProjectOpenProjectRecord(
              id: 'beta',
              title: 'Beta Project',
              path: 'D:/Projects/beta_project',
              projectTypeId: 'long_novel',
              storageStrategyId: 'sqlite_project_store',
              runtimeBaselineId: 'continuous_autonomous',
              modifiedAt: DateTime(2026, 6, 19, 14, 30),
              sourceBadges: <String>['最近项目'],
              isCurrentProject: false,
            ),
          ],
        );

        final viewData = service.build(snapshot);

        expect(viewData.entries, hasLength(2));
        expect(viewData.title, '作品库');
        expect(
          viewData.description,
          '先新建作品，或从默认项目目录继续打开已有作品。',
        );
        expect(viewData.projectsRootPath, 'D:/Projects');
        expect(viewData.currentProjectPath, 'D:/Projects/alpha_project');
        expect(viewData.entries.first.title, 'Alpha Project');
        expect(viewData.entries.first.isCurrentProject, isTrue);
        expect(viewData.selectedEntryId, 'alpha');
        expect(viewData.entries.last.title, 'Beta Project');
        expect(
          viewData.entries.last.sourceBadges,
          containsAll(<String>['最近项目']),
        );
        expect(viewData.entries.last.runtimeBaselineLabel, 'continuous_autonomous');
        expect(viewData.entries.first.runtimeBaselineLabel, '未指定');
      },
    );

    test(
      'selectEntry updates selected marker without rebuilding discovery result',
      () {
        final service = ProjectOpenViewDataService();
        final viewData = ProjectOpenViewData.initial().copyWith(
          entries: <ProjectOpenEntryViewData>[
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
          selectedEntryId: 'a',
        );

        final selected = service.selectEntry(viewData, 'b');

        expect(selected.selectedEntryId, 'b');
        expect(selected.entries.first.isSelected, isFalse);
        expect(selected.entries.last.isSelected, isTrue);
      },
    );
  });
}
