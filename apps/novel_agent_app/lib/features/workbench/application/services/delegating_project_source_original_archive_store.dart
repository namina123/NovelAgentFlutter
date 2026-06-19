import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_source_original_archive_store.dart';

class DelegatingProjectSourceOriginalArchiveStore
    implements ProjectSourceOriginalArchiveStore {
  DelegatingProjectSourceOriginalArchiveStore({
    required ProjectSourceOriginalArchiveStore markdownStore,
    required ProjectSourceOriginalArchiveStore sqliteStore,
  }) : _markdownStore = markdownStore,
       _sqliteStore = sqliteStore;

  final ProjectSourceOriginalArchiveStore _markdownStore;
  final ProjectSourceOriginalArchiveStore _sqliteStore;

  @override
  Future<void> persist({
    required ProjectDescriptor project,
    required String relativePath,
    required String title,
    required String content,
    String statePath = '',
  }) {
    switch (project.storageStrategy) {
      case ProjectStorageStrategy.markdownProjectStore:
        return _markdownStore.persist(
          project: project,
          relativePath: relativePath,
          title: title,
          content: content,
          statePath: statePath,
        );
      case ProjectStorageStrategy.sqliteProjectStore:
        return _sqliteStore.persist(
          project: project,
          relativePath: relativePath,
          title: title,
          content: content,
          statePath: statePath,
        );
    }
  }
}
