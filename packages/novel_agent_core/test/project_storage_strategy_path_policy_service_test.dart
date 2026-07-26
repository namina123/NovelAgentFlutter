import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  const service = ProjectStorageStrategyPathPolicyService();

  group('ProjectStorageStrategyPathPolicyService', () {
    test('markdown strategy keeps existing workspace defaults', () {
      expect(
        service.defaultWorkspaceFileDirectory(
          ProjectStorageStrategy.markdownProjectStore,
        ),
        'chapters',
      );
      expect(
        service.defaultImportTargetDirectory(
          ProjectStorageStrategy.markdownProjectStore,
        ),
        'assets',
      );
      expect(
        service.directoryForContentType(
          storageStrategy: ProjectStorageStrategy.markdownProjectStore,
          contentType: 'source_original',
        ),
        'sources/original',
      );
    });

    test('sqlite strategy routes defaults into sqlite-facing surfaces', () {
      expect(
        service.defaultWorkspaceFileDirectory(
          ProjectStorageStrategy.sqliteProjectStore,
        ),
        'imports',
      );
      expect(
        service.defaultWorkspaceFolderDirectory(
          ProjectStorageStrategy.sqliteProjectStore,
        ),
        'imports',
      );
      expect(
        service.defaultImportTargetDirectory(
          ProjectStorageStrategy.sqliteProjectStore,
        ),
        'imports',
      );
      expect(
        service.directoryForContentType(
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          contentType: 'source_original',
        ),
        'imports/source_original',
      );
      expect(
        service.directoryForContentType(
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          contentType: 'chapter',
        ),
        'imports',
      );
      expect(
        service.directoryForContentType(
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
          contentType: 'timeline_record',
        ),
        'imports/analysis/assets/timeline',
      );
    });
  });
}
