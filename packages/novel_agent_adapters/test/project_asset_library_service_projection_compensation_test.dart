import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_adapters/src/storage/sqlite_project_body_text_repository.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectAssetLibraryService projection compensation', () {
    late Directory projectDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectWorkspaceToolHostAdapter hostPort;
    late ProjectDescriptor project;

    setUp(() async {
      projectDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-asset-projection-',
      );
      workspacePort = LocalProjectWorkspacePort();
      hostPort = ProjectWorkspaceToolHostAdapter(
        workspacePort: workspacePort,
        fileMutationAdapter: LocalProjectFileMutationAdapter(),
      );
      project = ProjectDescriptor(
        id: 'asset-projection-test',
        name: 'Asset projection test',
        rootPath: projectDirectory.path,
        projectType: 'standard_novel',
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      );
      final manifestCodec = ProjectManifestCodecService();
      final manifest = manifestCodec.create(
        title: project.name,
        projectType: project.projectType,
        storageStrategy: project.storageStrategy,
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        ProjectManifestCodecService.manifestRelativePath,
        manifestCodec.encode(manifest),
      );
    });

    ProjectAssetLibraryService serviceWithFailingProjection(
      String failRelativePath,
    ) {
      return ProjectAssetLibraryService(
        workspacePort: workspacePort,
        projectToolHostPort: hostPort,
        writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
          projectWorkspacePort: _WriteThenFailProjectWorkspacePort(
            delegate: workspacePort,
            failRelativePath: failRelativePath,
          ),
        ),
      );
    }

    tearDown(() async {
      if (await projectDirectory.exists()) {
        await projectDirectory.delete(recursive: true);
      }
    });

    test(
      'removes a newly persisted style record when its projection fails',
      () async {
        const relativePath = 'assets/styles/failing_style.style.md';
        final service = serviceWithFailingProjection(relativePath);

        await expectLater(
          service.saveStyle(project, const <String, Object?>{
            'id': 'failing_style',
            'display_name': 'Failing style',
            'summary': 'This record must not remain after a failed write.',
          }),
          throwsA(isA<StateError>()),
        );

        final repository = SqliteProjectBodyTextRepository();
        expect(
          await repository.loadDocument(
            projectRootPath: project.rootPath,
            documentId: relativePath,
          ),
          isNull,
        );
        expect(
          await workspacePort.readTextFile(project.rootPath, relativePath),
          isNull,
        );
      },
    );

    test(
      'restores an existing foreshadow record and projection after a failed write',
      () async {
        const relativePath = 'assets/foreshadows/returning_hint.foreshadow.md';
        final initialService = ProjectAssetLibraryService(
          workspacePort: workspacePort,
          projectToolHostPort: hostPort,
        );
        await initialService.saveForeshadow(project, const <String, Object?>{
          'id': 'returning_hint',
          'title': 'Original hint',
          'status': 'planted',
          'summary': 'Original projection content.',
        });
        final repository = SqliteProjectBodyTextRepository();
        final before = await repository.loadDocument(
          projectRootPath: project.rootPath,
          documentId: relativePath,
        );
        final projectionBefore = await workspacePort.readTextFile(
          project.rootPath,
          relativePath,
        );
        expect(before, isNotNull);
        expect(projectionBefore, isNotNull);

        final service = serviceWithFailingProjection(relativePath);
        await expectLater(
          service.saveForeshadow(project, const <String, Object?>{
            'id': 'returning_hint',
            'title': 'Updated hint',
            'status': 'resolved',
            'summary': 'This update must be rolled back.',
          }),
          throwsA(isA<StateError>()),
        );

        final restored = await repository.loadDocument(
          projectRootPath: project.rootPath,
          documentId: relativePath,
        );
        expect(restored, isNotNull);
        expect(restored!.combinedText(), before!.combinedText());
        expect(restored.title, before.title);
        expect(
          await workspacePort.readTextFile(project.rootPath, relativePath),
          projectionBefore,
        );
      },
    );

    test(
      'rolls back every processed asset when direct bundle import fails',
      () async {
        const failingPath = 'assets/foreshadows/import_hint.foreshadow.md';
        final failingHost = ProjectWorkspaceToolHostAdapter(
          workspacePort: _WriteThenFailProjectWorkspacePort(
            delegate: workspacePort,
            failRelativePath: failingPath,
          ),
          fileMutationAdapter: LocalProjectFileMutationAdapter(),
        );
        final service = ProjectAssetLibraryService(
          workspacePort: workspacePort,
          projectToolHostPort: failingHost,
        );
        final bundleDocumentService = ProjectAssetBundleDocumentService();
        final bundleContent = bundleDocumentService.encodeBundle(
          bundleDocumentService.buildBundle(
            styles: const <StyleProfile>[
              StyleProfile(
                id: 'import_style',
                displayName: 'Imported style',
                summary: 'Must be rolled back with the failed import.',
              ),
            ],
            foreshadows: const <ForeshadowRecord>[
              ForeshadowRecord(
                id: 'import_hint',
                title: 'Imported hint',
                status: 'planted',
                summary: 'The projection write fails after this is persisted.',
              ),
            ],
          ),
        );

        await expectLater(
          service.importBundle(project, bundleContent: bundleContent),
          throwsA(isA<StateError>()),
        );

        final repository = SqliteProjectBodyTextRepository();
        for (final relativePath in const <String>[
          'assets/styles/import_style.style.md',
          failingPath,
        ]) {
          expect(
            await repository.loadDocument(
              projectRootPath: project.rootPath,
              documentId: relativePath,
            ),
            isNull,
          );
          expect(
            await workspacePort.readTextFile(project.rootPath, relativePath),
            isNull,
          );
        }
      },
    );
  });
}

class _WriteThenFailProjectWorkspacePort implements ProjectWorkspacePort {
  _WriteThenFailProjectWorkspacePort({
    required ProjectWorkspacePort delegate,
    required this.failRelativePath,
  }) : _delegate = delegate;

  final ProjectWorkspacePort _delegate;
  final String failRelativePath;

  @override
  Future<void> createDirectory(String rootPath, String relativePath) {
    return _delegate.createDirectory(rootPath, relativePath);
  }

  @override
  Future<List<JsonMap>> listEntries(String rootPath, {bool recursive = true}) {
    return _delegate.listEntries(rootPath, recursive: recursive);
  }

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) {
    return _delegate.readTextFile(rootPath, relativePath);
  }

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {
    await _delegate.writeTextFile(rootPath, relativePath, content);
    if (relativePath == failRelativePath) {
      throw StateError('simulated projection write failure');
    }
  }
}
