import 'package:novel_agent_core/src/common/json_types.dart';
import 'package:novel_agent_core/src/ports/project_workspace_port.dart';
import 'package:novel_agent_core/src/project/project_descriptor.dart';
import 'package:novel_agent_core/src/project/project_manifest_codec_service.dart';
import 'package:novel_agent_core/src/project/project_runtime_profile_document_service.dart';
import 'package:novel_agent_core/src/project/project_storage_strategy.dart';
import 'package:novel_agent_core/src/use_cases/configure_long_novel_runtime_baseline_use_case.dart';
import 'package:novel_agent_core/src/use_cases/read_project_file_use_case.dart';
import 'package:novel_agent_core/src/use_cases/write_project_text_file_use_case.dart';
import 'package:test/test.dart';

void main() {
  test(
    'repairs a long_novel missing a runtime baseline without changing its project contract',
    () async {
      final workspacePort = _MemoryProjectWorkspacePort();
      final useCase = _useCase(workspacePort);
      const project = ProjectDescriptor(
        id: 'legacy-long-novel',
        name: '遗留长篇',
        rootPath: '/projects/legacy-long-novel',
        projectType: 'long_novel',
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        additionalTraitIds: <String>['book_deconstruction'],
      );
      final manifestCodec = ProjectManifestCodecService();
      await workspacePort.writeTextFile(
        project.rootPath,
        ProjectManifestCodecService.manifestRelativePath,
        manifestCodec.encode(
          manifestCodec.create(
            title: project.name,
            projectType: project.projectType,
            storageStrategy: project.storageStrategy,
          ),
        ),
      );

      final repaired = await useCase.execute(
        project: project,
        runtimeBaselineId: 'chapter_collaboration_autorun',
      );

      final manifest = manifestCodec.parse(
        workspacePort.readStoredTextFile(
          project.rootPath,
          ProjectManifestCodecService.manifestRelativePath,
        )!,
      );
      final runtimeProfile = ProjectRuntimeProfileDocumentService().parse(
        workspacePort.readStoredTextFile(
          project.rootPath,
          ProjectRuntimeProfileDocumentService.profileRelativePath,
        )!,
      );
      expect(repaired.projectType, 'long_novel');
      expect(
        repaired.storageStrategy,
        ProjectStorageStrategy.sqliteProjectStore,
      );
      expect(repaired.runtimeBaselineId, 'chapter_collaboration_autorun');
      expect(repaired.additionalTraitIds, <String>['book_deconstruction']);
      expect(manifest.projectType, 'long_novel');
      expect(manifest.runtimeBaselineId, 'chapter_collaboration_autorun');
      expect(manifest.additionalTraitIds, <String>['book_deconstruction']);
      expect(runtimeProfile.projectType, 'long_novel');
      expect(runtimeProfile.runtimeBaselineId, 'chapter_collaboration_autorun');
    },
  );

  test(
    'repairs a legacy manifest whose runtime baseline is no longer registered',
    () async {
      final workspacePort = _MemoryProjectWorkspacePort();
      final useCase = _useCase(workspacePort);
      const project = ProjectDescriptor(
        id: 'invalid-legacy-baseline',
        name: '过期基线长篇',
        rootPath: '/projects/invalid-legacy-baseline',
        projectType: 'long_novel',
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        ProjectManifestCodecService.manifestRelativePath,
        '''
{
  "title": "过期基线长篇",
  "project_type": "long_novel",
  "storage_strategy": "markdown_project_store",
  "runtime_baseline_id": "retired_baseline"
}
''',
      );

      final repaired = await useCase.execute(
        project: project,
        runtimeBaselineId: 'continuous_autonomous',
      );

      expect(repaired.runtimeBaselineId, 'continuous_autonomous');
      expect(
        ProjectManifestCodecService()
            .parse(
              workspacePort.readStoredTextFile(
                project.rootPath,
                ProjectManifestCodecService.manifestRelativePath,
              )!,
            )
            .runtimeBaselineId,
        'continuous_autonomous',
      );
    },
  );

  test(
    'keeps the source manifest when the runtime profile write fails',
    () async {
      final workspacePort = _MemoryProjectWorkspacePort();
      final useCase = _useCase(workspacePort);
      const project = ProjectDescriptor(
        id: 'profile-write-failure',
        name: '配置写入失败',
        rootPath: '/projects/profile-write-failure',
        projectType: 'long_novel',
      );
      final manifestCodec = ProjectManifestCodecService();
      await workspacePort.writeTextFile(
        project.rootPath,
        ProjectManifestCodecService.manifestRelativePath,
        manifestCodec.encode(
          manifestCodec.create(
            title: project.name,
            projectType: project.projectType,
          ),
        ),
      );
      workspacePort.failNextWriteFor(
        ProjectRuntimeProfileDocumentService.profileRelativePath,
      );

      await expectLater(
        useCase.execute(
          project: project,
          runtimeBaselineId: 'continuous_autonomous',
        ),
        throwsA(isA<StateError>()),
      );

      final manifestAfterFailure = manifestCodec.parse(
        workspacePort.readStoredTextFile(
          project.rootPath,
          ProjectManifestCodecService.manifestRelativePath,
        )!,
      );
      expect(manifestAfterFailure.runtimeBaselineId, isEmpty);
    },
  );

  test('rejects an invalid baseline before writing either document', () async {
    final workspacePort = _MemoryProjectWorkspacePort();
    final useCase = _useCase(workspacePort);
    const project = ProjectDescriptor(
      id: 'legacy-long-novel',
      name: '遗留长篇',
      rootPath: '/projects/legacy-long-novel',
      projectType: 'long_novel',
    );

    await expectLater(
      useCase.execute(project: project, runtimeBaselineId: 'not_registered'),
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
  });

  test('rejects a non-long-novel project without changing its type', () async {
    final workspacePort = _MemoryProjectWorkspacePort();
    final useCase = _useCase(workspacePort);
    const project = ProjectDescriptor(
      id: 'ordinary-project',
      name: '普通小说',
      rootPath: '/projects/ordinary-project',
      projectType: 'novel',
    );

    await expectLater(
      useCase.execute(
        project: project,
        runtimeBaselineId: 'continuous_autonomous',
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
  });

  test('does not configure a baseline while a long task is active', () async {
    final workspacePort = _MemoryProjectWorkspacePort();
    final useCase = _useCase(
      workspacePort,
      readHasActiveLongTaskRun: (_) async => true,
    );
    const project = ProjectDescriptor(
      id: 'active-long-novel',
      name: '运行中长篇',
      rootPath: '/projects/active-long-novel',
      projectType: 'long_novel',
    );

    await expectLater(
      useCase.execute(
        project: project,
        runtimeBaselineId: 'continuous_autonomous',
      ),
      throwsA(
        allOf(
          isA<StateError>(),
          predicate<StateError>((error) => error.message.contains('归档')),
        ),
      ),
    );
  });

  test(
    'restores source manifest and runtime profile when manifest commit fails',
    () async {
      final workspacePort = _MemoryProjectWorkspacePort();
      final useCase = _useCase(workspacePort);
      const project = ProjectDescriptor(
        id: 'retry-long-novel',
        name: '可重试长篇',
        rootPath: '/projects/retry-long-novel',
        projectType: 'long_novel',
      );
      final manifestCodec = ProjectManifestCodecService();
      final runtimeProfileDocumentService =
          ProjectRuntimeProfileDocumentService();
      await workspacePort.writeTextFile(
        project.rootPath,
        ProjectManifestCodecService.manifestRelativePath,
        manifestCodec.encode(
          manifestCodec.create(
            title: project.name,
            projectType: project.projectType,
          ),
        ),
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        ProjectRuntimeProfileDocumentService.profileRelativePath,
        runtimeProfileDocumentService.encode(
          runtimeProfileDocumentService.buildProfile(
            projectType: 'long_novel',
            runtimeBaselineId: '',
          ),
        ),
      );
      workspacePort.failNextWriteFor(
        ProjectManifestCodecService.manifestRelativePath,
      );

      await expectLater(
        useCase.execute(
          project: project,
          runtimeBaselineId: 'continuous_autonomous',
        ),
        throwsA(isA<StateError>()),
      );

      final manifestAfterFailure = manifestCodec.parse(
        workspacePort.readStoredTextFile(
          project.rootPath,
          ProjectManifestCodecService.manifestRelativePath,
        )!,
      );
      final runtimeProfileAfterFailure = runtimeProfileDocumentService.parse(
        workspacePort.readStoredTextFile(
          project.rootPath,
          ProjectRuntimeProfileDocumentService.profileRelativePath,
        )!,
      );
      expect(manifestAfterFailure.projectType, 'long_novel');
      expect(manifestAfterFailure.runtimeBaselineId, isEmpty);
      expect(runtimeProfileAfterFailure.projectType, 'long_novel');
      expect(runtimeProfileAfterFailure.runtimeBaselineId, isEmpty);
    },
  );
}

ConfigureLongNovelRuntimeBaselineUseCase _useCase(
  _MemoryProjectWorkspacePort workspacePort, {
  Future<bool> Function(ProjectDescriptor project)? readHasActiveLongTaskRun,
}) {
  final writer = WriteProjectTextFileUseCase(
    projectWorkspacePort: workspacePort,
  );
  return ConfigureLongNovelRuntimeBaselineUseCase(
    readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
    writeProjectTextFileUseCase: writer,
    readHasActiveLongTaskRun: readHasActiveLongTaskRun ?? (_) async => false,
  );
}

class _MemoryProjectWorkspacePort implements ProjectWorkspacePort {
  _MemoryProjectWorkspacePort();

  final Map<String, String> _files = <String, String>{};
  String _failOnceForRelativePath = '';
  var _hasFailed = false;

  void failNextWriteFor(String relativePath) {
    _failOnceForRelativePath = relativePath;
    _hasFailed = false;
  }

  String? readStoredTextFile(String rootPath, String relativePath) {
    return _files[_key(rootPath, relativePath)];
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
    if (!_hasFailed && relativePath == _failOnceForRelativePath) {
      _hasFailed = true;
      throw StateError('模拟写入失败：$relativePath');
    }
    _files[_key(rootPath, relativePath)] = content;
  }

  String _key(String rootPath, String relativePath) {
    return '${rootPath.replaceAll('\\', '/')}//${relativePath.replaceAll('\\', '/')}';
  }
}
