import 'package:novel_agent_core/src/common/json_types.dart';
import 'package:novel_agent_core/src/project/project_descriptor.dart';
import 'package:novel_agent_core/src/project/project_manifest_codec_service.dart';
import 'package:novel_agent_core/src/project/project_runtime_profile_document_service.dart';
import 'package:novel_agent_core/src/project/project_storage_strategy.dart';
import 'package:novel_agent_core/src/project/project_support_document_catalog.dart';
import 'package:novel_agent_core/src/project/project_type_transition_preparation_service.dart';
import 'package:novel_agent_core/src/use_cases/execute_project_type_transition_use_case.dart';
import 'package:novel_agent_core/src/use_cases/read_project_file_use_case.dart';
import 'package:novel_agent_core/src/use_cases/update_project_manifest_use_case.dart';
import 'package:novel_agent_core/src/use_cases/write_project_text_file_use_case.dart';
import 'package:novel_agent_core/src/ports/project_workspace_port.dart';
import 'package:test/test.dart';

void main() {
  test(
    'preparation service accepts a selected runtime baseline for long task transitions',
    () {
      // 中文注释: 这里验证准备服务能把“当前项目事实 + 用户选定基准”收成一份可执行计划。
      const preparationService = ProjectTypeTransitionPreparationService();
      final plan = preparationService.prepare(
        project: const ProjectDescriptor(
          id: 'novel-1',
          name: '测试项目',
          rootPath: '/projects/novel-1',
          projectType: 'novel',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        ),
        targetProjectTypeId: 'long_novel',
        runtimeBaselineId: 'continuous_autonomous',
      );

      expect(plan.canTransition, isTrue);
      expect(plan.requiresRuntimeBaselineSelection, isFalse);
      expect(plan.targetRuntimeBaselineId, 'continuous_autonomous');
      expect(plan.blockers, isEmpty);
    },
  );

  test(
    'execute writes manifest, brief and runtime profile for novel to long_novel transition',
    () async {
      // 中文注释: 这里验证转换执行用例会把 manifest、简介和运行配置一起切到新的类型合同。
      final workspacePort = _FakeProjectWorkspacePort();
      final writeProjectTextFileUseCase = WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      );
      final executeUseCase = ExecuteProjectTypeTransitionUseCase(
        projectTypeTransitionPreparationService:
            const ProjectTypeTransitionPreparationService(),
        writeProjectTextFileUseCase: writeProjectTextFileUseCase,
        readHasActiveLongTaskRun: _noActiveLongTaskRun,
        projectRuntimeProfileDocumentService:
            ProjectRuntimeProfileDocumentService(),
      );
      final project = const ProjectDescriptor(
        id: 'novel-1',
        name: '测试项目',
        rootPath: '/projects/novel-1',
        projectType: 'novel',
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      );

      final updatedProject = await executeUseCase.execute(
        project: project,
        targetProjectTypeId: 'long_novel',
        runtimeBaselineId: 'continuous_autonomous',
      );
      final manifestCodec = ProjectManifestCodecService();
      final runtimeProfileCodec = ProjectRuntimeProfileDocumentService();
      final manifestContent = workspacePort.readStoredTextFile(
        project.rootPath,
        ProjectManifestCodecService.manifestRelativePath,
      );
      final briefContent = workspacePort.readStoredTextFile(
        project.rootPath,
        ProjectSupportDocumentCatalog.projectOverviewRelativePath,
      );
      final runtimeProfileContent = workspacePort.readStoredTextFile(
        project.rootPath,
        ProjectRuntimeProfileDocumentService.profileRelativePath,
      );

      expect(updatedProject.projectType, 'long_novel');
      expect(
        updatedProject.storageStrategy,
        ProjectStorageStrategy.sqliteProjectStore,
      );
      expect(updatedProject.runtimeBaselineId, 'continuous_autonomous');
      expect(manifestContent, isNotNull);
      expect(briefContent, isNotNull);
      expect(runtimeProfileContent, isNotNull);

      final manifest = manifestCodec.parse(manifestContent!);
      final runtimeProfile = runtimeProfileCodec.parse(runtimeProfileContent!);

      expect(manifest.projectType, 'long_novel');
      expect(
        manifest.storageStrategy,
        ProjectStorageStrategy.sqliteProjectStore,
      );
      expect(manifest.runtimeBaselineId, 'continuous_autonomous');
      expect(briefContent, contains('长任务长篇'));
      expect(runtimeProfile.projectType, 'long_novel');
      expect(runtimeProfile.runtimeBaselineId, 'continuous_autonomous');
    },
  );

  test(
    'execute rejects a same-type long_novel baseline change without writing runtime configuration',
    () async {
      final workspacePort = _FakeProjectWorkspacePort();
      final writeProjectTextFileUseCase = WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      );
      final transitionUseCase = ExecuteProjectTypeTransitionUseCase(
        projectTypeTransitionPreparationService:
            const ProjectTypeTransitionPreparationService(),
        writeProjectTextFileUseCase: writeProjectTextFileUseCase,
        readHasActiveLongTaskRun: _noActiveLongTaskRun,
      );
      const project = ProjectDescriptor(
        id: 'same-type-long-novel',
        name: '已配置长篇',
        rootPath: '/projects/same-type-long-novel',
        projectType: 'long_novel',
        runtimeBaselineId: 'continuous_autonomous',
        additionalTraitIds: <String>['book_deconstruction'],
      );

      await expectLater(
        transitionUseCase.execute(
          project: project,
          targetProjectTypeId: 'long_novel',
          runtimeBaselineId: 'chapter_collaboration_autorun',
        ),
        throwsA(isA<StateError>()),
      );

      expect(
        workspacePort.readStoredTextFile(
          project.rootPath,
          ProjectManifestCodecService.manifestRelativePath,
        ),
        isNull,
      );
      expect(
        workspacePort.readStoredTextFile(
          project.rootPath,
          ProjectRuntimeProfileDocumentService.profileRelativePath,
        ),
        isNull,
      );
    },
  );

  test(
    'runtime profile failure leaves the source manifest retryable after reopening',
    () async {
      final workspacePort = _FakeProjectWorkspacePort(
        failOnceForRelativePath:
            ProjectRuntimeProfileDocumentService.profileRelativePath,
      );
      final writeProjectTextFileUseCase = WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      );
      final transitionUseCase = ExecuteProjectTypeTransitionUseCase(
        projectTypeTransitionPreparationService:
            const ProjectTypeTransitionPreparationService(),
        writeProjectTextFileUseCase: writeProjectTextFileUseCase,
        readHasActiveLongTaskRun: _noActiveLongTaskRun,
      );
      const sourceProject = ProjectDescriptor(
        id: 'retry-runtime-profile',
        name: '可重试转换',
        rootPath: '/projects/retry-runtime-profile',
        projectType: 'novel',
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      );
      final manifestCodec = ProjectManifestCodecService();
      await workspacePort.writeTextFile(
        sourceProject.rootPath,
        ProjectManifestCodecService.manifestRelativePath,
        manifestCodec.encode(
          manifestCodec.create(
            title: sourceProject.name,
            projectType: sourceProject.projectType,
            storageStrategy: sourceProject.storageStrategy,
          ),
        ),
      );

      await expectLater(
        transitionUseCase.execute(
          project: sourceProject,
          targetProjectTypeId: 'long_novel',
          runtimeBaselineId: 'continuous_autonomous',
        ),
        throwsA(isA<StateError>()),
      );

      final manifestAfterFailure = manifestCodec.parse(
        workspacePort.readStoredTextFile(
          sourceProject.rootPath,
          ProjectManifestCodecService.manifestRelativePath,
        )!,
      );
      expect(manifestAfterFailure.projectType, 'novel');
      final runtimeProfileAfterFailure = ProjectRuntimeProfileDocumentService()
          .parse(
            workspacePort.readStoredTextFile(
              sourceProject.rootPath,
              ProjectRuntimeProfileDocumentService.profileRelativePath,
            )!,
          );
      expect(runtimeProfileAfterFailure.projectType, 'novel');
      expect(runtimeProfileAfterFailure.runtimeBaselineId, isEmpty);

      final reopenedProject = ProjectDescriptor(
        id: sourceProject.id,
        name: sourceProject.name,
        rootPath: sourceProject.rootPath,
        projectType: manifestAfterFailure.projectType,
        storageStrategy: manifestAfterFailure.storageStrategy,
        runtimeBaselineId: manifestAfterFailure.runtimeBaselineId,
        additionalTraitIds: manifestAfterFailure.additionalTraitIds,
      );
      final retriedProject = await transitionUseCase.execute(
        project: reopenedProject,
        targetProjectTypeId: 'long_novel',
        runtimeBaselineId: 'continuous_autonomous',
      );

      expect(retriedProject.projectType, 'long_novel');
      expect(
        manifestCodec
            .parse(
              workspacePort.readStoredTextFile(
                sourceProject.rootPath,
                ProjectManifestCodecService.manifestRelativePath,
              )!,
            )
            .projectType,
        'long_novel',
      );
      expect(
        workspacePort.readStoredTextFile(
          sourceProject.rootPath,
          ProjectRuntimeProfileDocumentService.profileRelativePath,
        ),
        isNotNull,
      );
    },
  );

  test(
    'overview failure leaves the source manifest retryable after reopening',
    () async {
      final workspacePort = _FakeProjectWorkspacePort(
        failOnceForRelativePath:
            ProjectSupportDocumentCatalog.projectOverviewRelativePath,
      );
      final writeProjectTextFileUseCase = WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      );
      final transitionUseCase = ExecuteProjectTypeTransitionUseCase(
        projectTypeTransitionPreparationService:
            const ProjectTypeTransitionPreparationService(),
        writeProjectTextFileUseCase: writeProjectTextFileUseCase,
        readHasActiveLongTaskRun: _noActiveLongTaskRun,
      );
      const sourceProject = ProjectDescriptor(
        id: 'retry-overview',
        name: '概览失败可重试转换',
        rootPath: '/projects/retry-overview',
        projectType: 'novel',
      );
      final manifestCodec = ProjectManifestCodecService();
      await workspacePort.writeTextFile(
        sourceProject.rootPath,
        ProjectManifestCodecService.manifestRelativePath,
        manifestCodec.encode(
          manifestCodec.create(
            title: sourceProject.name,
            projectType: sourceProject.projectType,
          ),
        ),
      );

      await expectLater(
        transitionUseCase.execute(
          project: sourceProject,
          targetProjectTypeId: 'long_novel',
          runtimeBaselineId: 'continuous_autonomous',
        ),
        throwsA(isA<StateError>()),
      );

      final manifestAfterFailure = manifestCodec.parse(
        workspacePort.readStoredTextFile(
          sourceProject.rootPath,
          ProjectManifestCodecService.manifestRelativePath,
        )!,
      );
      expect(manifestAfterFailure.projectType, 'novel');
      final runtimeProfileAfterFailure = ProjectRuntimeProfileDocumentService()
          .parse(
            workspacePort.readStoredTextFile(
              sourceProject.rootPath,
              ProjectRuntimeProfileDocumentService.profileRelativePath,
            )!,
          );
      expect(runtimeProfileAfterFailure.projectType, 'novel');
      expect(runtimeProfileAfterFailure.runtimeBaselineId, isEmpty);

      final reopenedProject = ProjectDescriptor(
        id: sourceProject.id,
        name: sourceProject.name,
        rootPath: sourceProject.rootPath,
        projectType: manifestAfterFailure.projectType,
        storageStrategy: manifestAfterFailure.storageStrategy,
        runtimeBaselineId: manifestAfterFailure.runtimeBaselineId,
        additionalTraitIds: manifestAfterFailure.additionalTraitIds,
      );
      await transitionUseCase.execute(
        project: reopenedProject,
        targetProjectTypeId: 'long_novel',
        runtimeBaselineId: 'continuous_autonomous',
      );

      expect(
        manifestCodec
            .parse(
              workspacePort.readStoredTextFile(
                sourceProject.rootPath,
                ProjectManifestCodecService.manifestRelativePath,
              )!,
            )
            .projectType,
        'long_novel',
      );
      expect(
        workspacePort.readStoredTextFile(
          sourceProject.rootPath,
          ProjectSupportDocumentCatalog.projectOverviewRelativePath,
        ),
        contains('长任务长篇'),
      );
    },
  );

  test(
    'execute merges existing and explicitly preserved traits in its returned project descriptor',
    () async {
      final workspacePort = _FakeProjectWorkspacePort();
      final writeProjectTextFileUseCase = WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      );
      final executeUseCase = ExecuteProjectTypeTransitionUseCase(
        projectTypeTransitionPreparationService:
            const ProjectTypeTransitionPreparationService(),
        writeProjectTextFileUseCase: writeProjectTextFileUseCase,
        readHasActiveLongTaskRun: _noActiveLongTaskRun,
      );
      const project = ProjectDescriptor(
        id: 'book-project-1',
        name: '拆书项目',
        rootPath: '/projects/book-project-1',
        projectType: 'book_deconstruction',
        additionalTraitIds: <String>['book_deconstruction', 'custom_scope'],
      );

      final transitionedProject = await executeUseCase.execute(
        project: project,
        targetProjectTypeId: 'novel',
        preserveAdditionalTraitIds: const <String>[
          'book_deconstruction',
          'long_running_context',
        ],
      );

      expect(transitionedProject.projectType, 'novel');
      expect(transitionedProject.additionalTraitIds, <String>[
        'book_deconstruction',
        'custom_scope',
        'long_running_context',
      ]);
      final manifest = ProjectManifestCodecService().parse(
        workspacePort.readStoredTextFile(
          project.rootPath,
          ProjectManifestCodecService.manifestRelativePath,
        )!,
      );
      expect(manifest.additionalTraitIds, <String>[
        'book_deconstruction',
        'custom_scope',
        'long_running_context',
      ]);
    },
  );

  test(
    'execute preserves deconstruction capability for an unannotated source project',
    () async {
      // 中文注释: 原生拆书项目的能力来自类型默认 trait，转换时不能要求每个调用方都显式补传。
      final workspacePort = _FakeProjectWorkspacePort();
      final writer = WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      );
      final useCase = ExecuteProjectTypeTransitionUseCase(
        projectTypeTransitionPreparationService:
            const ProjectTypeTransitionPreparationService(),
        writeProjectTextFileUseCase: writer,
        readHasActiveLongTaskRun: _noActiveLongTaskRun,
      );
      const sourceProject = ProjectDescriptor(
        id: 'native-book-project',
        name: '原生拆书项目',
        rootPath: '/projects/native-book-project',
        projectType: 'book_deconstruction',
      );

      final transitioned = await useCase.execute(
        project: sourceProject,
        targetProjectTypeId: 'novel',
      );

      expect(transitioned.projectType, 'novel');
      expect(transitioned.additionalTraitIds, contains('book_deconstruction'));
      final manifest = ProjectManifestCodecService().parse(
        workspacePort.readStoredTextFile(
          sourceProject.rootPath,
          ProjectManifestCodecService.manifestRelativePath,
        )!,
      );
      expect(manifest.additionalTraitIds, contains('book_deconstruction'));
    },
  );

  test(
    'manifest update preserves traits carried by the current descriptor',
    () async {
      final workspacePort = _FakeProjectWorkspacePort();
      final writeProjectTextFileUseCase = WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      );
      final useCase = UpdateProjectManifestUseCase(
        writeProjectTextFileUseCase: writeProjectTextFileUseCase,
        projectManifestCodecService: ProjectManifestCodecService(),
      );
      const project = ProjectDescriptor(
        id: 'composite-project-1',
        name: '已复合项目',
        rootPath: '/projects/composite-project-1',
        projectType: 'novel',
        additionalTraitIds: <String>['book_deconstruction', 'custom_scope'],
      );

      await useCase.execute(project: project, title: '编辑后的项目标题');

      final manifest = ProjectManifestCodecService().parse(
        workspacePort.readStoredTextFile(
          project.rootPath,
          ProjectManifestCodecService.manifestRelativePath,
        )!,
      );
      expect(manifest.additionalTraitIds, <String>[
        'book_deconstruction',
        'custom_scope',
      ]);
    },
  );

  test(
    'manifest metadata update retains the descriptor project type and runtime baseline',
    () async {
      final workspacePort = _FakeProjectWorkspacePort();
      final writer = WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      );
      final useCase = UpdateProjectManifestUseCase(
        writeProjectTextFileUseCase: writer,
        projectManifestCodecService: ProjectManifestCodecService(),
      );
      const project = ProjectDescriptor(
        id: 'metadata-only-project',
        name: '长篇项目',
        rootPath: '/projects/metadata-only-project',
        projectType: 'long_novel',
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        runtimeBaselineId: 'continuous_autonomous',
      );

      await useCase.execute(project: project, title: '只改标题的长篇');
      final manifest = ProjectManifestCodecService().parse(
        workspacePort.readStoredTextFile(
          project.rootPath,
          ProjectManifestCodecService.manifestRelativePath,
        )!,
      );
      expect(manifest.projectType, 'long_novel');
      expect(
        manifest.storageStrategy,
        ProjectStorageStrategy.sqliteProjectStore,
      );
      expect(manifest.runtimeBaselineId, 'continuous_autonomous');
    },
  );

  test(
    'manifest write failure restores the previous project overview',
    () async {
      // 中文注释: 项目概览会先于 manifest 写入；manifest 失败时不能让概览抢先
      // 声称项目已经完成类型转换，否则用户重开后会面对两份相互矛盾的项目描述。
      final workspacePort = _FakeProjectWorkspacePort(
        failOnceForRelativePath:
            ProjectManifestCodecService.manifestRelativePath,
      );
      const project = ProjectDescriptor(
        id: 'overview-rollback-project',
        name: '源普通小说',
        rootPath: '/projects/overview-rollback-project',
        projectType: 'novel',
      );
      const sourceOverview = '# 项目概览\n\n- 项目类型：小说\n';
      await workspacePort.writeTextFile(
        project.rootPath,
        ProjectSupportDocumentCatalog.projectOverviewRelativePath,
        sourceOverview,
      );
      final writer = WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      );
      final useCase = UpdateProjectManifestUseCase(
        writeProjectTextFileUseCase: writer,
        readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
      );

      await expectLater(
        useCase.execute(project: project, title: '目标长篇'),
        throwsA(isA<StateError>()),
      );

      expect(
        workspacePort.readStoredTextFile(
          project.rootPath,
          ProjectSupportDocumentCatalog.projectOverviewRelativePath,
        ),
        sourceOverview,
      );
      expect(
        workspacePort.readStoredTextFile(
          project.rootPath,
          ProjectManifestCodecService.manifestRelativePath,
        ),
        isNull,
      );
    },
  );

  test(
    'manifest metadata update preserves storage, branch, runtime baseline and traits',
    () async {
      // 中文注释: 这些字段不只是展示元数据；改写它们会改变主存储或项目能力，必须
      // 先走带迁移/活跃任务校验的专用流程，不能由普通资料编辑静默绕过。
      final workspacePort = _FakeProjectWorkspacePort();
      final writer = WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      );
      final useCase = UpdateProjectManifestUseCase(
        writeProjectTextFileUseCase: writer,
        projectManifestCodecService: ProjectManifestCodecService(),
      );
      const project = ProjectDescriptor(
        id: 'metadata-contract-project',
        name: '长篇项目',
        rootPath: '/projects/metadata-contract-project',
        projectType: 'long_novel',
        storageStrategy: ProjectStorageStrategy.markdownProjectStore,
        runtimeBaselineId: 'continuous_autonomous',
        additionalTraitIds: <String>['book_deconstruction'],
      );

      await useCase.execute(project: project, title: '更新说明的长篇');
      final manifest = ProjectManifestCodecService().parse(
        workspacePort.readStoredTextFile(
          project.rootPath,
          ProjectManifestCodecService.manifestRelativePath,
        )!,
      );
      expect(manifest.projectType, 'long_novel');
      expect(
        manifest.storageStrategy,
        ProjectStorageStrategy.markdownProjectStore,
      );
      expect(manifest.projectBranchId, isEmpty);
      expect(manifest.runtimeBaselineId, 'continuous_autonomous');
      expect(manifest.additionalTraitIds, <String>['book_deconstruction']);
    },
  );

  test(
    'execute rejects long_novel to novel transition while a long task is still active',
    () async {
      // 中文注释: 活跃长任务存在时，回切普通小说必须被拒绝，避免把运行现场切回一个不完整的类型壳。
      final workspacePort = _FakeProjectWorkspacePort();
      final writeProjectTextFileUseCase = WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      );
      final executeUseCase = ExecuteProjectTypeTransitionUseCase(
        projectTypeTransitionPreparationService:
            const ProjectTypeTransitionPreparationService(),
        writeProjectTextFileUseCase: writeProjectTextFileUseCase,
        readHasActiveLongTaskRun: (_) async => true,
        projectRuntimeProfileDocumentService:
            ProjectRuntimeProfileDocumentService(),
      );
      final project = const ProjectDescriptor(
        id: 'long-1',
        name: '长任务项目',
        rootPath: '/projects/long-1',
        projectType: 'long_novel',
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        runtimeBaselineId: 'continuous_autonomous',
      );

      await expectLater(
        executeUseCase.execute(project: project, targetProjectTypeId: 'novel'),
        throwsA(
          allOf(
            isA<StateError>(),
            predicate<StateError>((error) => error.message.contains('归档')),
          ),
        ),
      );
    },
  );
}

Future<bool> _noActiveLongTaskRun(ProjectDescriptor project) async => false;

class _FakeProjectWorkspacePort implements ProjectWorkspacePort {
  _FakeProjectWorkspacePort({this.failOnceForRelativePath = ''});

  final Map<String, String> _files = <String, String>{};
  final String failOnceForRelativePath;
  var _hasFailed = false;

  String? readStoredTextFile(String rootPath, String relativePath) {
    return _files[_key(rootPath, relativePath)];
  }

  String _key(String rootPath, String relativePath) {
    return '${rootPath.replaceAll('\\', '/')}//${relativePath.replaceAll('\\', '/')}';
  }

  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async {
    return const <JsonMap>[];
  }

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async {
    return readStoredTextFile(rootPath, relativePath);
  }

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {
    if (!_hasFailed && relativePath == failOnceForRelativePath) {
      _hasFailed = true;
      throw StateError('模拟写入失败：$relativePath');
    }
    _files[_key(rootPath, relativePath)] = content;
  }
}
