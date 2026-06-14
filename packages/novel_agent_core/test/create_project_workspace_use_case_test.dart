import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('CreateProjectWorkspaceUseCase', () {
    test('prepare requires runtime baseline for long task project', () {
      // 中文注释: 长任务项目在真正落盘前必须先补选运行基准，避免项目类型和运行方式继续耦成一团。
      final useCase = CreateProjectWorkspaceUseCase(
        projectRepository: _FakeProjectRepository(),
        projectWorkspacePort: _FakeProjectWorkspacePort(),
        projectContentRepository: _FakeProjectContentRepository(),
        projectReadableProjectionService:
            _FakeProjectReadableProjectionService(),
      );

      final plan = useCase.prepare(
        const ProjectCreateRequest(title: '长篇测试', projectTypeId: 'long_novel'),
      );

      expect(plan.canCreate, isFalse);
      expect(plan.nextStep, ProjectCreationNextStep.selectRuntimeBaseline);
      expect(plan.runtimeBaselineOptions, isNotEmpty);
    });

    test('prepare becomes ready after runtime baseline is selected', () {
      // 中文注释: 一旦长任务项目补齐运行基准，创建计划就应该收束到可正式创建的状态。
      final useCase = CreateProjectWorkspaceUseCase(
        projectRepository: _FakeProjectRepository(),
        projectWorkspacePort: _FakeProjectWorkspacePort(),
        projectContentRepository: _FakeProjectContentRepository(),
        projectReadableProjectionService:
            _FakeProjectReadableProjectionService(),
      );

      final plan = useCase.prepare(
        const ProjectCreateRequest(
          title: '长篇测试',
          projectTypeId: 'long_novel',
          runtimeBaselineId: 'continuous_autonomous',
        ),
      );

      expect(plan.canCreate, isTrue);
      expect(plan.request.runtimeBaselineId, 'continuous_autonomous');
      expect(plan.nextStep, ProjectCreationNextStep.readyToCreate);
    });

    test('prepare keeps book deconstruction project ready immediately', () {
      // 中文注释: 拆书项目是平行项目策略，不应像长任务那样被要求先选择运行基准。
      final useCase = CreateProjectWorkspaceUseCase(
        projectRepository: _FakeProjectRepository(),
        projectWorkspacePort: _FakeProjectWorkspacePort(),
        projectContentRepository: _FakeProjectContentRepository(),
        projectReadableProjectionService:
            _FakeProjectReadableProjectionService(),
      );

      final plan = useCase.prepare(
        const ProjectCreateRequest(
          title: '拆书测试',
          projectTypeId: BookDeconstructionConstants.projectTypeId,
        ),
      );

      expect(plan.canCreate, isTrue);
      expect(
        plan.request.projectTypeId,
        BookDeconstructionConstants.projectTypeId,
      );
      expect(plan.request.runtimeBaselineId, isEmpty);
      expect(plan.runtimeBaselineOptions, isEmpty);
      expect(plan.nextStep, ProjectCreationNextStep.readyToCreate);
    });

    test('prepare normalizes knowledge base to sqlite storage', () {
      // 中文注释: 知识库创建在 core 层就应该被收束到 SQLite，避免调用方先传出 Markdown 再靠 UI 纠偏。
      final useCase = CreateProjectWorkspaceUseCase(
        projectRepository: _FakeProjectRepository(),
        projectWorkspacePort: _FakeProjectWorkspacePort(),
        projectContentRepository: _FakeProjectContentRepository(),
        projectReadableProjectionService:
            _FakeProjectReadableProjectionService(),
      );

      final plan = useCase.prepare(
        const ProjectCreateRequest(
          title: '知识库测试',
          projectTypeId: 'knowledge_base',
          storageStrategy: ProjectStorageStrategy.markdownProjectStore,
        ),
      );

      expect(
        plan.request.storageStrategy,
        ProjectStorageStrategy.sqliteProjectStore,
      );
      expect(
        plan.projectTypeDefinition.supportedStorageStrategies,
        <ProjectStorageStrategy>[ProjectStorageStrategy.sqliteProjectStore],
      );
      expect(plan.canCreate, isTrue);
    });

    test(
      'executePrepared persists runtime baseline into manifest and profile',
      () async {
        // 中文注释: 这里验证长任务项目完成基准补选后，会把领域结果同时写入项目元数据和初始运行配置。
        final workspacePort = _FakeProjectWorkspacePort();
        final manifestCodec = ProjectManifestCodecService();
        final runtimeProfileDocumentService =
            ProjectRuntimeProfileDocumentService();
        final useCase = CreateProjectWorkspaceUseCase(
          projectRepository: _FakeProjectRepository(
            workspacePort: workspacePort,
            manifestCodecService: manifestCodec,
          ),
          projectWorkspacePort: workspacePort,
          projectContentRepository: _FakeProjectContentRepository(),
          projectReadableProjectionService:
              _FakeProjectReadableProjectionService(),
          projectManifestCodecService: manifestCodec,
          projectRuntimeProfileDocumentService: runtimeProfileDocumentService,
        );

        final plan = useCase.prepare(
          const ProjectCreateRequest(
            title: '长篇测试',
            projectTypeId: 'long_novel',
            runtimeBaselineId: 'chapter_collaboration_autorun',
          ),
        );
        final descriptor = await useCase.executePrepared(
          projectsRootPath: '/projects',
          plan: plan,
        );
        final manifestContent = workspacePort.readStoredTextFile(
          descriptor.rootPath,
          ProjectManifestCodecService.manifestRelativePath,
        );
        final runtimeProfileContent = workspacePort.readStoredTextFile(
          descriptor.rootPath,
          ProjectRuntimeProfileDocumentService.profileRelativePath,
        );

        expect(descriptor.runtimeBaselineId, 'chapter_collaboration_autorun');
        expect(manifestContent, isNotNull);
        expect(runtimeProfileContent, isNotNull);

        final manifest = manifestCodec.parse(manifestContent!);
        final runtimeProfile = runtimeProfileDocumentService.parse(
          runtimeProfileContent!,
        );

        expect(manifest.runtimeBaselineId, 'chapter_collaboration_autorun');
        expect(
          runtimeProfile.runtimeBaselineId,
          'chapter_collaboration_autorun',
        );
        expect(
          runtimeProfile.runtimeMode,
          TaskRuntimeConstants.modeHumanOutlineAiDraft,
        );
        expect(
          ValueReaders.stringValue(
            runtimeProfile.initialRunOptions['runtime_baseline_id'],
          ),
          'chapter_collaboration_autorun',
        );
      },
    );
  });
}

class _FakeProjectRepository implements ProjectRepository {
  _FakeProjectRepository({
    _FakeProjectWorkspacePort? workspacePort,
    ProjectManifestCodecService? manifestCodecService,
  }) : _workspacePort = workspacePort,
       _manifestCodecService = manifestCodecService;

  final _FakeProjectWorkspacePort? _workspacePort;
  final ProjectManifestCodecService? _manifestCodecService;

  @override
  Future<ProjectDescriptor?> openByPath(String rootPath) async {
    final workspacePort = _workspacePort;
    final manifestCodecService = _manifestCodecService;
    if (workspacePort == null || manifestCodecService == null) {
      return null;
    }
    final manifestContent = workspacePort.readStoredTextFile(
      rootPath,
      ProjectManifestCodecService.manifestRelativePath,
    );
    if (manifestContent == null) {
      return null;
    }
    final projectName = rootPath
        .split('/')
        .where((part) => part.isNotEmpty)
        .last;
    final manifest = manifestCodecService.parse(
      manifestContent,
      fallbackTitle: projectName,
    );
    return ProjectDescriptor(
      id: projectName,
      name: manifest.title,
      rootPath: rootPath,
      projectType: manifest.projectType,
      storageStrategy: manifest.storageStrategy,
      runtimeBaselineId: manifest.runtimeBaselineId,
    );
  }
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

class _FakeProjectContentRepository implements ProjectContentRepository {
  @override
  Future<void> initializeProjectContent({
    required String rootPath,
    required ProjectManifest manifest,
    required ProjectDirectoryLayout layout,
  }) async {}
}

class _FakeProjectReadableProjectionService
    implements ProjectReadableProjectionService {
  @override
  Future<void> ensureReadableProjection({
    required String rootPath,
    required ProjectManifest manifest,
    required ProjectDirectoryLayout layout,
  }) async {}
}
