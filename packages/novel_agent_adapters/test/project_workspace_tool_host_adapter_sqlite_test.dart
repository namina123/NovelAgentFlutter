import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:novel_agent_core/src/project/project_body_text_repository.dart';
import 'package:test/test.dart';

import 'package:novel_agent_adapters/src/storage/sqlite_project_body_text_repository.dart';
import 'package:novel_agent_adapters/src/tools/project_file_write_tool_executor.dart';

void main() {
  group('ProjectWorkspaceToolHostAdapter SQLite writes', () {
    late Directory projectDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectWorkspaceToolHostAdapter hostPort;
    late ProjectDescriptor project;

    setUp(() async {
      projectDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-host-sqlite-',
      );
      workspacePort = LocalProjectWorkspacePort();
      hostPort = ProjectWorkspaceToolHostAdapter(
        workspacePort: workspacePort,
        fileMutationAdapter: LocalProjectFileMutationAdapter(),
      );
      project = ProjectDescriptor(
        id: 'sqlite-host-project',
        name: 'SQLite 宿主测试',
        rootPath: projectDirectory.path,
        projectType: 'novel',
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      );
      final manifest = ProjectManifestCodecService().create(
        title: project.name,
        projectType: project.projectType,
        storageStrategy: project.storageStrategy,
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        ProjectManifestCodecService.manifestRelativePath,
        ProjectManifestCodecService().encode(manifest),
      );
    });

    tearDown(() async {
      if (await projectDirectory.exists()) {
        await projectDirectory.delete(recursive: true);
      }
    });

    test(
      'writes character package content to SQLite before its Markdown projection',
      () async {
        await hostPort.writeTextFile(
          project.rootPath,
          'assets/characters/hero.md',
          '# 主角\n\n角色资料',
        );

        final document = await SqliteProjectBodyTextRepository().loadDocument(
          projectRootPath: project.rootPath,
          documentId: 'assets/characters/hero.md',
        );

        expect(document, isNotNull);
        expect(document!.documentKind, 'character');
        expect(document.combinedText(), contains('角色资料'));
        expect(
          await workspacePort.readTextFile(
            project.rootPath,
            'assets/characters/hero.md',
          ),
          contains('角色资料'),
        );
      },
    );

    test(
      'preserves domain metadata when updating an existing SQLite projection',
      () async {
        final bridge = ProjectStructuredContentBridgeService();
        await bridge.persistChapterDelivery(
          project: project,
          chapterPath: 'chapters/chapter_01.md',
          chapterTitle: '第一章',
          chapterContent: '初版正文',
          recordPath: 'records/chapter_01.json',
          status: 'delivered',
        );

        await hostPort.writeTextFile(
          project.rootPath,
          'chapters/chapter_01.md',
          '修订后的正文',
        );

        final document = await SqliteProjectBodyTextRepository().loadDocument(
          projectRootPath: project.rootPath,
          documentId: 'chapters/chapter_01.md',
        );

        expect(document, isNotNull);
        expect(document!.combinedText(), '修订后的正文');
        expect(document.status, 'delivered');
        expect(document.statePath, 'records/chapter_01.json');
      },
    );

    test(
      'updates inherited deconstruction chapter primary content before its SQLite projection',
      () async {
        const inheritedPath =
            'imports/derived/continuation/continuation_novel/001_第一章.md';
        final bridge = ProjectStructuredContentBridgeService();
        await bridge.persistChapterDelivery(
          project: project,
          chapterPath: inheritedPath,
          chapterTitle: '第一章',
          chapterContent: '原始继承正文',
          recordPath: '',
          status: 'archived',
        );

        await hostPort.writeTextFile(
          project.rootPath,
          inheritedPath,
          '工具修订后的继承正文',
        );

        expect(
          (await SqliteProjectBodyTextRepository().loadDocument(
            projectRootPath: project.rootPath,
            documentId: inheritedPath,
          ))?.combinedText(),
          '工具修订后的继承正文',
        );
      },
    );

    test(
      'direct host move and delete keep SQLite and Markdown in sync',
      () async {
        await hostPort.writeTextFile(
          project.rootPath,
          'chapters/direct_host.md',
          '直接宿主正文',
        );

        await hostPort.moveEntry(
          project.rootPath,
          'chapters/direct_host.md',
          'chapters/direct_host_revised.md',
        );

        final repository = SqliteProjectBodyTextRepository();
        expect(
          await workspacePort.readTextFile(
            project.rootPath,
            'chapters/direct_host.md',
          ),
          isNull,
        );
        expect(
          await workspacePort.readTextFile(
            project.rootPath,
            'chapters/direct_host_revised.md',
          ),
          '直接宿主正文',
        );
        expect(
          await repository.loadDocument(
            projectRootPath: project.rootPath,
            documentId: 'chapters/direct_host.md',
          ),
          isNull,
        );
        expect(
          (await repository.loadDocument(
            projectRootPath: project.rootPath,
            documentId: 'chapters/direct_host_revised.md',
          ))?.combinedText(),
          '直接宿主正文',
        );

        await hostPort.deleteEntry(
          project.rootPath,
          'chapters/direct_host_revised.md',
        );

        expect(
          await workspacePort.readTextFile(
            project.rootPath,
            'chapters/direct_host_revised.md',
          ),
          isNull,
        );
        expect(
          await repository.loadDocument(
            projectRootPath: project.rootPath,
            documentId: 'chapters/direct_host_revised.md',
          ),
          isNull,
        );
      },
    );

    test('direct host restores both projections when a move fails', () async {
      final bridge = ProjectStructuredContentBridgeService();
      await bridge.persistChapterDelivery(
        project: project,
        chapterPath: 'chapters/direct_move_failure.md',
        chapterTitle: '直接移动失败',
        chapterContent: '原始正文',
        recordPath: 'records/direct_move_failure.json',
        status: 'delivered',
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        'chapters/direct_move_failure.md',
        '原始正文',
      );
      final failingHost = ProjectWorkspaceToolHostAdapter(
        workspacePort: workspacePort,
        fileMutationAdapter: _MoveThenFailFileMutationAdapter(),
      );

      await expectLater(
        failingHost.moveEntry(
          project.rootPath,
          'chapters/direct_move_failure.md',
          'chapters/direct_move_failure_revised.md',
        ),
        throwsA(
          predicate<Object>(
            (error) => error.toString().contains('projection move failure'),
          ),
        ),
      );

      final repository = SqliteProjectBodyTextRepository();
      expect(
        await workspacePort.readTextFile(
          project.rootPath,
          'chapters/direct_move_failure.md',
        ),
        '原始正文',
      );
      expect(
        await workspacePort.readTextFile(
          project.rootPath,
          'chapters/direct_move_failure_revised.md',
        ),
        isNull,
      );
      expect(
        (await repository.loadDocument(
          projectRootPath: project.rootPath,
          documentId: 'chapters/direct_move_failure.md',
        ))?.combinedText(),
        '原始正文',
      );
      expect(
        await repository.loadDocument(
          projectRootPath: project.rootPath,
          documentId: 'chapters/direct_move_failure_revised.md',
        ),
        isNull,
      );
    });

    test(
      'direct host retains the move error when SQLite restore also fails',
      () async {
        const sourcePath = 'chapters/direct_move_rollback_failure.md';
        await ProjectStructuredContentBridgeService().persistChapterDelivery(
          project: project,
          chapterPath: sourcePath,
          chapterTitle: '直接回滚失败',
          chapterContent: '原始正文',
          recordPath: '',
          status: 'delivered',
        );
        await workspacePort.writeTextFile(project.rootPath, sourcePath, '原始正文');
        final failingHost = ProjectWorkspaceToolHostAdapter(
          workspacePort: workspacePort,
          fileMutationAdapter: _MoveThenFailFileMutationAdapter(),
          structuredContentBridgeService: ProjectStructuredContentBridgeService(
            bodyTextRepository:
                _FailingSourceRestoreAfterMoveBodyTextRepository(
                  delegate: SqliteProjectBodyTextRepository(),
                  sourceDocumentId: sourcePath,
                ),
          ),
        );

        await expectLater(
          failingHost.moveEntry(
            project.rootPath,
            sourcePath,
            'chapters/direct_move_rollback_failure_revised.md',
          ),
          throwsA(
            predicate<Object>(
              (error) => error.toString().contains('projection move failure'),
            ),
          ),
        );
      },
    );

    test('direct host restores both projections when a delete fails', () async {
      final bridge = ProjectStructuredContentBridgeService();
      await bridge.persistChapterDelivery(
        project: project,
        chapterPath: 'chapters/direct_delete_failure.md',
        chapterTitle: '直接删除失败',
        chapterContent: '原始正文',
        recordPath: 'records/direct_delete_failure.json',
        status: 'delivered',
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        'chapters/direct_delete_failure.md',
        '原始正文',
      );
      final failingHost = ProjectWorkspaceToolHostAdapter(
        workspacePort: workspacePort,
        fileMutationAdapter: _DeleteThenFailFileMutationAdapter(),
      );

      await expectLater(
        failingHost.deleteEntry(
          project.rootPath,
          'chapters/direct_delete_failure.md',
        ),
        throwsA(
          predicate<Object>(
            (error) => error.toString().contains('projection delete failure'),
          ),
        ),
      );

      final repository = SqliteProjectBodyTextRepository();
      expect(
        await workspacePort.readTextFile(
          project.rootPath,
          'chapters/direct_delete_failure.md',
        ),
        '原始正文',
      );
      expect(
        (await repository.loadDocument(
          projectRootPath: project.rootPath,
          documentId: 'chapters/direct_delete_failure.md',
        ))?.combinedText(),
        '原始正文',
      );
    });

    test(
      'low-level file tools keep SQLite document identity through move and delete',
      () async {
        final executor = ProjectFileWriteToolExecutor(hostPort: hostPort);
        final writeResult = await executor
            .writeProjectFile(project, const <String, Object?>{
              'relative_path': 'chapters/chapter_02.md',
              'content_type': 'chapter',
              'title': '第二章',
              'content': '第二章正文',
            });
        expect(ValueReaders.boolValue(writeResult['ok']), isTrue);

        final moveResult = await executor
            .moveProjectFile(project, const <String, Object?>{
              'relative_path': 'chapters/chapter_02.md',
              'target_relative_path': 'chapters/chapter_02_revised.md',
            });
        expect(ValueReaders.boolValue(moveResult['ok']), isTrue);
        final repository = SqliteProjectBodyTextRepository();
        expect(
          await repository.loadDocument(
            projectRootPath: project.rootPath,
            documentId: 'chapters/chapter_02.md',
          ),
          isNull,
        );
        expect(
          await repository.loadDocument(
            projectRootPath: project.rootPath,
            documentId: 'chapters/chapter_02_revised.md',
          ),
          isNotNull,
        );

        final deleteResult = await executor.deleteProjectFile(
          project,
          const <String, Object?>{
            'relative_path': 'chapters/chapter_02_revised.md',
            'create_backup': false,
          },
        );
        expect(ValueReaders.boolValue(deleteResult['ok']), isTrue);
        expect(
          await repository.loadDocument(
            projectRootPath: project.rootPath,
            documentId: 'chapters/chapter_02_revised.md',
          ),
          isNull,
        );
      },
    );

    test(
      'overwrite move replaces the target projection and SQLite record',
      () async {
        final executor = ProjectFileWriteToolExecutor(hostPort: hostPort);
        await executor.writeProjectFile(project, const <String, Object?>{
          'relative_path': 'chapters/source.md',
          'content_type': 'chapter',
          'title': '源章节',
          'content': '源正文',
        });
        await executor.writeProjectFile(project, const <String, Object?>{
          'relative_path': 'chapters/target.md',
          'content_type': 'chapter',
          'title': '目标章节',
          'content': '旧目标正文',
        });

        final result = await executor
            .moveProjectFile(project, const <String, Object?>{
              'relative_path': 'chapters/source.md',
              'target_relative_path': 'chapters/target.md',
              'overwrite': true,
            });

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          await workspacePort.readTextFile(
            project.rootPath,
            'chapters/target.md',
          ),
          '源正文',
        );
        final repository = SqliteProjectBodyTextRepository();
        expect(
          await repository.loadDocument(
            projectRootPath: project.rootPath,
            documentId: 'chapters/source.md',
          ),
          isNull,
        );
        final targetDocument = await repository.loadDocument(
          projectRootPath: project.rootPath,
          documentId: 'chapters/target.md',
        );
        expect(targetDocument, isNotNull);
        expect(targetDocument!.combinedText(), '源正文');
      },
    );

    test(
      'compensates SQLite and projection state when a document move fails',
      () async {
        final repository = SqliteProjectBodyTextRepository();
        final bridge = ProjectStructuredContentBridgeService(
          bodyTextRepository: repository,
        );
        await bridge.persistChapterDelivery(
          project: project,
          chapterPath: 'chapters/chapter_03.md',
          chapterTitle: '第三章',
          chapterContent: '原始正文',
          recordPath: 'records/chapter_03.json',
          status: 'delivered',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          'chapters/chapter_03.md',
          '原始正文',
        );
        final failingBridge = ProjectStructuredContentBridgeService(
          bodyTextRepository: _FailingDeleteBodyTextRepository(
            delegate: repository,
            failDocumentId: 'chapters/chapter_03.md',
          ),
        );
        final executor = ProjectFileWriteToolExecutor(
          hostPort: hostPort,
          structuredContentBridgeService: failingBridge,
        );

        await expectLater(
          executor.moveProjectFile(project, const <String, Object?>{
            'relative_path': 'chapters/chapter_03.md',
            'target_relative_path': 'chapters/chapter_03_revised.md',
          }),
          throwsA(isA<StateError>()),
        );

        expect(
          await workspacePort.readTextFile(
            project.rootPath,
            'chapters/chapter_03.md',
          ),
          '原始正文',
        );
        expect(
          await workspacePort.readTextFile(
            project.rootPath,
            'chapters/chapter_03_revised.md',
          ),
          isNull,
        );
        expect(
          await repository.loadDocument(
            projectRootPath: project.rootPath,
            documentId: 'chapters/chapter_03.md',
          ),
          isNotNull,
        );
        expect(
          await repository.loadDocument(
            projectRootPath: project.rootPath,
            documentId: 'chapters/chapter_03_revised.md',
          ),
          isNull,
        );
      },
    );

    test(
      'move preserves the original SQLite error when rollback also fails',
      () async {
        final repository = SqliteProjectBodyTextRepository();
        await ProjectStructuredContentBridgeService(
          bodyTextRepository: repository,
        ).persistChapterDelivery(
          project: project,
          chapterPath: 'chapters/chapter_rollback.md',
          chapterTitle: '回滚章节',
          chapterContent: '原始正文',
          recordPath: '',
          status: 'delivered',
        );
        final bridge = ProjectStructuredContentBridgeService(
          bodyTextRepository: _FailingMoveRollbackBodyTextRepository(
            delegate: repository,
            sourceDocumentId: 'chapters/chapter_rollback.md',
          ),
        );

        await expectLater(
          bridge.moveStructuredDocument(
            project: project,
            sourcePath: 'chapters/chapter_rollback.md',
            targetPath: 'chapters/chapter_rollback_revised.md',
            targetDocumentKind: 'chapter',
          ),
          throwsA(
            predicate<Object>(
              (error) => error.toString().contains('primary move failure'),
            ),
          ),
        );
      },
    );

    test('restores SQLite document when projection deletion fails', () async {
      final bridge = ProjectStructuredContentBridgeService();
      await bridge.persistChapterDelivery(
        project: project,
        chapterPath: 'chapters/chapter_04.md',
        chapterTitle: '第四章',
        chapterContent: '待删除正文',
        recordPath: 'records/chapter_04.json',
        status: 'delivered',
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        'chapters/chapter_04.md',
        '待删除正文',
      );
      final failingHost = _FailingDeleteProjectWorkspaceToolHostAdapter(
        workspacePort: workspacePort,
        fileMutationAdapter: LocalProjectFileMutationAdapter(),
      );
      final executor = ProjectFileWriteToolExecutor(hostPort: failingHost);

      await expectLater(
        executor.deleteProjectFile(project, const <String, Object?>{
          'relative_path': 'chapters/chapter_04.md',
          'create_backup': false,
        }),
        throwsA(isA<StateError>()),
      );

      expect(
        await workspacePort.readTextFile(
          project.rootPath,
          'chapters/chapter_04.md',
        ),
        '待删除正文',
      );
      final document = await SqliteProjectBodyTextRepository().loadDocument(
        projectRootPath: project.rootPath,
        documentId: 'chapters/chapter_04.md',
      );
      expect(document, isNotNull);
      expect(document!.status, 'delivered');
      expect(document.statePath, 'records/chapter_04.json');
    });

    test(
      'specialized asset repositories retain SQLite primary records without a manifest-backed host',
      () async {
        final rawRoot = Directory('${projectDirectory.path}\\repository-only');
        await rawRoot.create(recursive: true);
        final sqliteProject = ProjectDescriptor(
          id: 'repository-only-sqlite',
          name: '仓储 SQLite 测试',
          rootPath: rawRoot.path,
          projectType: 'novel',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        );
        final characterRepository = ProjectCharacterProfileRepository(
          hostPort: hostPort,
        );
        final organizationRepository = ProjectOrganizationProfileRepository(
          hostPort: hostPort,
        );
        final timelineRepository = ProjectTimelineRepository(
          hostPort: hostPort,
        );
        final relationshipRepository = ProjectRelationshipRepository(
          hostPort: hostPort,
        );
        final foreshadowRepository = ProjectForeshadowRepository(
          hostPort: hostPort,
        );

        await characterRepository.saveProfile(
          sqliteProject,
          profile: const CharacterProfile(
            id: 'hero',
            displayName: '主角',
            summary: '沉稳。',
          ),
        );
        await organizationRepository.saveProfile(
          sqliteProject,
          profile: const OrganizationProfile(
            id: 'guild',
            displayName: '行会',
            summary: '地下组织。',
          ),
        );
        await timelineRepository.save(
          sqliteProject,
          const TimelineRecord(
            id: 'event_01',
            displayName: '相遇',
            summary: '两人在雨夜相遇。',
          ),
        );
        await relationshipRepository.save(
          sqliteProject,
          const RelationshipRecord(
            id: 'bond_01',
            displayName: '同盟',
            leftEntityId: 'hero',
            rightEntityId: 'guild',
            summary: '互相利用。',
          ),
        );
        await foreshadowRepository.save(
          sqliteProject,
          const ForeshadowRecord(
            id: 'hint_01',
            title: '雨夜来信',
            status: 'planted',
            summary: '信封带有陌生印记。',
          ),
        );

        final repository = SqliteProjectBodyTextRepository();
        for (final entry in const <(String, String)>[
          ('assets/characters/hero.md', 'character'),
          ('assets/organizations/guild.md', 'organization_profile'),
          ('assets/timeline/event_01.timeline.md', 'timeline_record'),
          (
            'assets/relationships/bond_01.relationship.md',
            'relationship_record',
          ),
          ('assets/foreshadows/hint_01.foreshadow.md', 'foreshadow_record'),
        ]) {
          final document = await repository.loadDocument(
            projectRootPath: sqliteProject.rootPath,
            documentId: entry.$1,
          );
          expect(document, isNotNull);
          expect(document!.documentKind, entry.$2);
        }

        final fileMutations = LocalProjectFileMutationAdapter();
        await fileMutations.deleteEntry(
          sqliteProject.rootPath,
          'assets/characters/hero.md',
        );
        await fileMutations.deleteEntry(
          sqliteProject.rootPath,
          'assets/organizations/guild.md',
        );
        await fileMutations.deleteEntry(
          sqliteProject.rootPath,
          'assets/timeline/event_01.timeline.md',
        );
        await fileMutations.deleteEntry(
          sqliteProject.rootPath,
          'assets/relationships/bond_01.relationship.md',
        );
        await fileMutations.deleteEntry(
          sqliteProject.rootPath,
          'assets/foreshadows/hint_01.foreshadow.md',
        );

        expect(
          (await characterRepository.readProfile(
            sqliteProject,
            characterId: 'hero',
            displayName: '主角',
          ))?.displayName,
          '主角',
        );
        expect(
          (await organizationRepository.listProfiles(
            sqliteProject,
          )).single.displayName,
          '行会',
        );
        expect(
          (await timelineRepository.list(sqliteProject)).single.displayName,
          '相遇',
        );
        expect(
          (await relationshipRepository.readById(
            sqliteProject,
            'bond_01',
          ))?.displayName,
          '同盟',
        );
        expect(
          (await foreshadowRepository.list(sqliteProject)).single.title,
          '雨夜来信',
        );
      },
    );

    test(
      'bundle apply persists typed SQLite assets without a manifest-backed host',
      () async {
        final rawRoot = Directory(
          '${projectDirectory.path}\\bundle-apply-only',
        );
        await rawRoot.create(recursive: true);
        final sqliteProject = ProjectDescriptor(
          id: 'bundle-apply-sqlite',
          name: '包应用 SQLite 测试',
          rootPath: rawRoot.path,
          projectType: 'novel',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        );
        final service = ProjectBundleApplyService(hostPort: hostPort);

        await service.applyToProject(
          sqliteProject,
          const ProjectBundleWritePlan(
            bundleKind: 'facility_audit',
            title: '资产包',
            sourcePath: 'fixtures/assets.bundle.md',
            files: <ProjectBundleWriteFile>[
              ProjectBundleWriteFile(
                entryKind: 'character',
                entryId: 'hero',
                targetPath: 'assets/characters/hero.md',
                content: '# 主角',
              ),
              ProjectBundleWriteFile(
                entryKind: 'organization',
                entryId: 'guild',
                targetPath: 'assets/organizations/guild.md',
                content: '# 行会',
              ),
              ProjectBundleWriteFile(
                entryKind: 'foreshadow',
                entryId: 'hint_01',
                targetPath: 'assets/foreshadows/hint_01.foreshadow.md',
                content: '# 雨夜来信',
              ),
              ProjectBundleWriteFile(
                entryKind: 'timeline',
                entryId: 'event_01',
                targetPath: 'assets/timeline/event_01.timeline.md',
                content: '# 相遇',
              ),
              ProjectBundleWriteFile(
                entryKind: 'relationship',
                entryId: 'bond_01',
                targetPath: 'assets/relationships/bond_01.relationship.md',
                content: '# 同盟',
              ),
            ],
          ),
        );

        final repository = SqliteProjectBodyTextRepository();
        for (final entry in const <(String, String)>[
          ('assets/characters/hero.md', 'character'),
          ('assets/organizations/guild.md', 'organization_profile'),
          ('assets/foreshadows/hint_01.foreshadow.md', 'foreshadow_record'),
          ('assets/timeline/event_01.timeline.md', 'timeline_record'),
          (
            'assets/relationships/bond_01.relationship.md',
            'relationship_record',
          ),
        ]) {
          expect(
            (await repository.loadDocument(
              projectRootPath: sqliteProject.rootPath,
              documentId: entry.$1,
            ))?.documentKind,
            entry.$2,
          );
        }
      },
    );

    test(
      'asset bundle import writes SQLite records before file projections',
      () async {
        final rawRoot = Directory(
          '${projectDirectory.path}\\asset-bundle-only',
        );
        await rawRoot.create(recursive: true);
        final sqliteProject = ProjectDescriptor(
          id: 'asset-bundle-sqlite',
          name: '资产包 SQLite 测试',
          rootPath: rawRoot.path,
          projectType: 'novel',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        );
        final documentService = ProjectAssetBundleDocumentService();
        final bundleContent = documentService.encodeBundle(
          documentService.buildBundle(
            styles: const <StyleProfile>[
              StyleProfile(
                id: 'bundle_style',
                displayName: '包风格',
                summary: '简练。',
              ),
            ],
            foreshadows: const <ForeshadowRecord>[
              ForeshadowRecord(
                id: 'bundle_hint',
                title: '包伏笔',
                status: 'planted',
                summary: '异样来信。',
              ),
            ],
          ),
        );
        final service = ProjectAssetLibraryService(
          workspacePort: workspacePort,
          projectToolHostPort: hostPort,
        );

        final result = await service.importBundle(
          sqliteProject,
          bundleContent: bundleContent,
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        final repository = SqliteProjectBodyTextRepository();
        expect(
          (await repository.loadDocument(
            projectRootPath: sqliteProject.rootPath,
            documentId: 'assets/styles/bundle_style.style.md',
          ))?.documentKind,
          'style',
        );
        expect(
          (await repository.loadDocument(
            projectRootPath: sqliteProject.rootPath,
            documentId: 'assets/foreshadows/bundle_hint.foreshadow.md',
          ))?.documentKind,
          'foreshadow_record',
        );
        final fileMutations = LocalProjectFileMutationAdapter();
        await fileMutations.deleteEntry(
          sqliteProject.rootPath,
          'assets/styles/bundle_style.style.md',
        );
        await fileMutations.deleteEntry(
          sqliteProject.rootPath,
          'assets/foreshadows/bundle_hint.foreshadow.md',
        );
        expect(
          ValueReaders.stringValue(
            (await service.listStyles(sqliteProject)).single['id'],
          ),
          'bundle_style',
        );
        expect(
          ValueReaders.stringValue(
            (await service.listForeshadows(sqliteProject)).single['id'],
          ),
          'bundle_hint',
        );
        expect(
          ValueReaders.boolValue(
            (await service.deleteStyle(sqliteProject, 'bundle_style'))['ok'],
          ),
          isTrue,
        );
        expect(
          await repository.loadDocument(
            projectRootPath: sqliteProject.rootPath,
            documentId: 'assets/styles/bundle_style.style.md',
          ),
          isNull,
        );
      },
    );

    test(
      'asset save restores its SQLite record when the projection write fails',
      () async {
        const relativePath = 'assets/styles/failing_style.style.md';
        final service = ProjectAssetLibraryService(
          workspacePort: workspacePort,
          projectToolHostPort: hostPort,
          writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
            projectWorkspacePort: _FailingWriteProjectWorkspacePort(
              delegate: workspacePort,
              failRelativePath: relativePath,
            ),
          ),
        );

        await expectLater(
          service.saveStyle(project, const <String, Object?>{
            'id': 'failing_style',
            'display_name': '失败风格',
            'summary': '不应留下半完成记录。',
          }),
          throwsA(isA<StateError>()),
        );

        expect(
          await SqliteProjectBodyTextRepository().loadDocument(
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
  });
}

class _MoveThenFailFileMutationAdapter extends LocalProjectFileMutationAdapter {
  @override
  Future<void> moveEntry(
    String rootPath,
    String sourceRelativePath,
    String targetRelativePath,
  ) async {
    await super.moveEntry(rootPath, sourceRelativePath, targetRelativePath);
    throw StateError('projection move failure');
  }
}

class _DeleteThenFailFileMutationAdapter
    extends LocalProjectFileMutationAdapter {
  @override
  Future<void> deleteEntry(String rootPath, String relativePath) async {
    await super.deleteEntry(rootPath, relativePath);
    throw StateError('projection delete failure');
  }
}

class _FailingDeleteBodyTextRepository implements ProjectBodyTextRepository {
  _FailingDeleteBodyTextRepository({
    required ProjectBodyTextRepository delegate,
    required this.failDocumentId,
  }) : _delegate = delegate;

  final ProjectBodyTextRepository _delegate;
  final String failDocumentId;

  @override
  Future<void> deleteDocument({
    required String projectRootPath,
    required String documentId,
  }) {
    if (documentId == failDocumentId) {
      return Future<void>.error(StateError('simulated SQLite delete failure'));
    }
    return _delegate.deleteDocument(
      projectRootPath: projectRootPath,
      documentId: documentId,
    );
  }

  @override
  Future<SqliteProjectBodyTextDocument?> loadDocument({
    required String projectRootPath,
    required String documentId,
  }) {
    return _delegate.loadDocument(
      projectRootPath: projectRootPath,
      documentId: documentId,
    );
  }

  @override
  Future<List<SqliteProjectBodyTextDocument>> listDocuments({
    required String projectRootPath,
    String documentKind = '',
  }) {
    return _delegate.listDocuments(
      projectRootPath: projectRootPath,
      documentKind: documentKind,
    );
  }

  @override
  Future<void> saveDocument({
    required String projectRootPath,
    required SqliteProjectBodyTextDocument document,
  }) {
    return _delegate.saveDocument(
      projectRootPath: projectRootPath,
      document: document,
    );
  }
}

class _FailingDeleteProjectWorkspaceToolHostAdapter
    extends ProjectWorkspaceToolHostAdapter {
  _FailingDeleteProjectWorkspaceToolHostAdapter({
    required super.workspacePort,
    required super.fileMutationAdapter,
  });

  @override
  Future<void> deleteEntry(String rootPath, String relativePath) {
    return Future<void>.error(
      StateError('simulated projection delete failure'),
    );
  }
}

class _FailingMoveRollbackBodyTextRepository
    implements ProjectBodyTextRepository {
  _FailingMoveRollbackBodyTextRepository({
    required ProjectBodyTextRepository delegate,
    required this.sourceDocumentId,
  }) : _delegate = delegate;

  final ProjectBodyTextRepository _delegate;
  final String sourceDocumentId;
  bool _sourceDeleteAttempted = false;

  @override
  Future<void> deleteDocument({
    required String projectRootPath,
    required String documentId,
  }) {
    if (documentId == sourceDocumentId) {
      _sourceDeleteAttempted = true;
      return Future<void>.error(StateError('primary move failure'));
    }
    return _delegate.deleteDocument(
      projectRootPath: projectRootPath,
      documentId: documentId,
    );
  }

  @override
  Future<SqliteProjectBodyTextDocument?> loadDocument({
    required String projectRootPath,
    required String documentId,
  }) {
    return _delegate.loadDocument(
      projectRootPath: projectRootPath,
      documentId: documentId,
    );
  }

  @override
  Future<List<SqliteProjectBodyTextDocument>> listDocuments({
    required String projectRootPath,
    String documentKind = '',
  }) {
    return _delegate.listDocuments(
      projectRootPath: projectRootPath,
      documentKind: documentKind,
    );
  }

  @override
  Future<void> saveDocument({
    required String projectRootPath,
    required SqliteProjectBodyTextDocument document,
  }) {
    if (_sourceDeleteAttempted && document.documentId == sourceDocumentId) {
      return Future<void>.error(StateError('rollback restore failure'));
    }
    return _delegate.saveDocument(
      projectRootPath: projectRootPath,
      document: document,
    );
  }
}

class _FailingSourceRestoreAfterMoveBodyTextRepository
    implements ProjectBodyTextRepository {
  _FailingSourceRestoreAfterMoveBodyTextRepository({
    required ProjectBodyTextRepository delegate,
    required this.sourceDocumentId,
  }) : _delegate = delegate;

  final ProjectBodyTextRepository _delegate;
  final String sourceDocumentId;
  var _sourceDeleteSucceeded = false;

  @override
  Future<void> deleteDocument({
    required String projectRootPath,
    required String documentId,
  }) async {
    await _delegate.deleteDocument(
      projectRootPath: projectRootPath,
      documentId: documentId,
    );
    if (documentId == sourceDocumentId) {
      _sourceDeleteSucceeded = true;
    }
  }

  @override
  Future<SqliteProjectBodyTextDocument?> loadDocument({
    required String projectRootPath,
    required String documentId,
  }) {
    return _delegate.loadDocument(
      projectRootPath: projectRootPath,
      documentId: documentId,
    );
  }

  @override
  Future<List<SqliteProjectBodyTextDocument>> listDocuments({
    required String projectRootPath,
    String documentKind = '',
  }) {
    return _delegate.listDocuments(
      projectRootPath: projectRootPath,
      documentKind: documentKind,
    );
  }

  @override
  Future<void> saveDocument({
    required String projectRootPath,
    required SqliteProjectBodyTextDocument document,
  }) {
    if (_sourceDeleteSucceeded && document.documentId == sourceDocumentId) {
      return Future<void>.error(StateError('rollback restore failure'));
    }
    return _delegate.saveDocument(
      projectRootPath: projectRootPath,
      document: document,
    );
  }
}

class _FailingWriteProjectWorkspacePort implements ProjectWorkspacePort {
  _FailingWriteProjectWorkspacePort({
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
  ) {
    if (relativePath == failRelativePath) {
      return Future<void>.error(
        StateError('simulated projection write failure'),
      );
    }
    return _delegate.writeTextFile(rootPath, relativePath, content);
  }
}
