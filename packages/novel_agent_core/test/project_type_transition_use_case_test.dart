import 'package:novel_agent_core/src/common/json_types.dart';
import 'package:novel_agent_core/src/project/project_descriptor.dart';
import 'package:novel_agent_core/src/project/project_manifest_codec_service.dart';
import 'package:novel_agent_core/src/project/project_runtime_profile_document_service.dart';
import 'package:novel_agent_core/src/project/project_storage_strategy.dart';
import 'package:novel_agent_core/src/project/project_type_transition_preparation_service.dart';
import 'package:novel_agent_core/src/use_cases/execute_project_type_transition_use_case.dart';
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
      final updateProjectManifestUseCase = UpdateProjectManifestUseCase(
        writeProjectTextFileUseCase: writeProjectTextFileUseCase,
        projectManifestCodecService: ProjectManifestCodecService(),
      );
      final executeUseCase = ExecuteProjectTypeTransitionUseCase(
        projectTypeTransitionPreparationService:
            const ProjectTypeTransitionPreparationService(),
        updateProjectManifestUseCase: updateProjectManifestUseCase,
        writeProjectTextFileUseCase: writeProjectTextFileUseCase,
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
        'premise/project_brief.md',
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
    'execute rejects long_novel to novel transition while a long task is still active',
    () async {
      // 中文注释: 活跃长任务存在时，回切普通小说必须被拒绝，避免把运行现场切回一个不完整的类型壳。
      final workspacePort = _FakeProjectWorkspacePort();
      final writeProjectTextFileUseCase = WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      );
      final updateProjectManifestUseCase = UpdateProjectManifestUseCase(
        writeProjectTextFileUseCase: writeProjectTextFileUseCase,
        projectManifestCodecService: ProjectManifestCodecService(),
      );
      final executeUseCase = ExecuteProjectTypeTransitionUseCase(
        projectTypeTransitionPreparationService:
            const ProjectTypeTransitionPreparationService(),
        updateProjectManifestUseCase: updateProjectManifestUseCase,
        writeProjectTextFileUseCase: writeProjectTextFileUseCase,
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
        executeUseCase.execute(
          project: project,
          targetProjectTypeId: 'novel',
          hasActiveLongTaskRun: true,
        ),
        throwsA(
          allOf(
            isA<StateError>(),
            predicate<StateError>(
              (error) => error.message?.contains('归档') ?? false,
            ),
          ),
        ),
      );
    },
  );
}

class _FakeProjectWorkspacePort implements ProjectWorkspacePort {
  final Map<String, String> _files = <String, String>{};

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
    _files[_key(rootPath, relativePath)] = content;
  }
}
