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

    test('prepare rejects disabled short collection projects', () {
      // 中文注释: UI 已隐藏的禁用类型也必须在 core 创建入口被拒绝，避免 CLI/脚本绕过目录状态。
      final useCase = CreateProjectWorkspaceUseCase(
        projectRepository: _FakeProjectRepository(),
        projectWorkspacePort: _FakeProjectWorkspacePort(),
        projectContentRepository: _FakeProjectContentRepository(),
        projectReadableProjectionService:
            _FakeProjectReadableProjectionService(),
      );

      expect(
        () => useCase.prepare(
          const ProjectCreateRequest(
            title: '禁用短篇项目',
            projectTypeId: 'short_collection',
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('prepare rejects an unregistered explicit project type', () {
      // 中文注释: 空项目类型仍可走默认小说，但显式传错 ID 时不能静默落成另一种项目。
      final useCase = CreateProjectWorkspaceUseCase(
        projectRepository: _FakeProjectRepository(),
        projectWorkspacePort: _FakeProjectWorkspacePort(),
        projectContentRepository: _FakeProjectContentRepository(),
        projectReadableProjectionService:
            _FakeProjectReadableProjectionService(),
      );

      expect(
        () => useCase.prepare(
          const ProjectCreateRequest(
            title: '错误类型项目',
            projectTypeId: 'long_novel_typo',
          ),
        ),
        throwsA(isA<StateError>()),
      );
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
      'executePrepared persists knowledge base branch into manifest',
      () async {
        // 中文注释: 资料知识库的分支语义必须成为项目元数据的一部分，不能只停留在创建界面临时状态。
        final workspacePort = _FakeProjectWorkspacePort();
        final manifestCodec = ProjectManifestCodecService();
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
        );

        final plan = useCase.prepare(
          const ProjectCreateRequest(
            title: '哈利语料',
            projectTypeId: 'knowledge_base',
            projectBranchId: KnowledgeBaseBranchCatalogService.ragBranchId,
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

        expect(descriptor.projectType, 'knowledge_base');
        expect(
          descriptor.storageStrategy,
          ProjectStorageStrategy.sqliteProjectStore,
        );
        expect(
          descriptor.projectBranchId,
          KnowledgeBaseBranchCatalogService.ragBranchId,
        );
        expect(manifestContent, isNotNull);

        final manifest = manifestCodec.parse(manifestContent!);
        expect(
          manifest.projectBranchId,
          KnowledgeBaseBranchCatalogService.ragBranchId,
        );
      },
    );

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

    test(
      'executePrepared revalidates a caller-supplied creation plan',
      () async {
        // 中文注释: 计划对象是公开数据，不能靠伪造 readyToCreate 跳过长篇运行基准选择。
        final useCase = CreateProjectWorkspaceUseCase(
          projectRepository: _FakeProjectRepository(),
          projectWorkspacePort: _FakeProjectWorkspacePort(),
          projectContentRepository: _FakeProjectContentRepository(),
          projectReadableProjectionService:
              _FakeProjectReadableProjectionService(),
        );
        final forgedPlan = ProjectCreationPlan(
          request: const ProjectCreateRequest(
            title: '伪造长篇计划',
            projectTypeId: 'long_novel',
          ),
          projectTypeDefinition: const ProjectTypeDefinition(
            id: 'long_novel',
            name: '伪造长篇',
            description: '',
            defaultTitle: '伪造长篇',
          ),
          runtimeBaselineOptions: const <ProjectRuntimeBaselineDefinition>[],
          nextStep: ProjectCreationNextStep.readyToCreate,
        );

        await expectLater(
          useCase.executePrepared(
            projectsRootPath: '/projects',
            plan: forgedPlan,
          ),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'execute preserves a non-project folder with the requested title',
      () async {
        final workspacePort = _FakeProjectWorkspacePort(
          entriesByRoot: <String, List<JsonMap>>{
            '/projects/同名项目': <JsonMap>[
              <String, Object?>{
                'relative_path': '用户资料.txt',
                'display_name': '用户资料.txt',
                'is_dir': false,
              },
            ],
          },
        );
        final manifestCodec = ProjectManifestCodecService();
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
        );

        final project = await useCase.execute(
          projectsRootPath: '/projects',
          title: '同名项目',
        );

        expect(project.rootPath, '/projects/同名项目_2');
        expect(
          workspacePort.readStoredTextFile(
            '/projects/同名项目',
            ProjectManifestCodecService.manifestRelativePath,
          ),
          isNull,
        );
      },
    );

    test(
      'execute preserves a corrupt project folder with the requested title',
      () async {
        final workspacePort = _FakeProjectWorkspacePort();
        final manifestCodec = ProjectManifestCodecService();
        final useCase = CreateProjectWorkspaceUseCase(
          projectRepository: _FakeProjectRepository(
            workspacePort: workspacePort,
            manifestCodecService: manifestCodec,
            corruptRootPaths: const <String>{'/projects/损坏项目'},
          ),
          projectWorkspacePort: workspacePort,
          projectContentRepository: _FakeProjectContentRepository(),
          projectReadableProjectionService:
              _FakeProjectReadableProjectionService(),
          projectManifestCodecService: manifestCodec,
        );

        final project = await useCase.execute(
          projectsRootPath: '/projects',
          title: '损坏项目',
        );

        expect(project.rootPath, '/projects/损坏项目_2');
      },
    );
  });
}

class _FakeProjectRepository implements ProjectRepository {
  _FakeProjectRepository({
    _FakeProjectWorkspacePort? workspacePort,
    ProjectManifestCodecService? manifestCodecService,
    Set<String> corruptRootPaths = const <String>{},
  }) : _workspacePort = workspacePort,
       _manifestCodecService = manifestCodecService,
       _corruptRootPaths = corruptRootPaths;

  final _FakeProjectWorkspacePort? _workspacePort;
  final ProjectManifestCodecService? _manifestCodecService;
  final Set<String> _corruptRootPaths;

  @override
  Future<ProjectDescriptor?> openByPath(String rootPath) async {
    if (_corruptRootPaths.contains(rootPath)) {
      throw ProjectManifestCorruptionException(rootPath: rootPath);
    }
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
      projectBranchId: manifest.projectBranchId,
      runtimeBaselineId: manifest.runtimeBaselineId,
    );
  }
}

class _FakeProjectWorkspacePort implements ProjectWorkspacePort {
  _FakeProjectWorkspacePort({
    Map<String, List<JsonMap>> entriesByRoot = const <String, List<JsonMap>>{},
  }) : _entriesByRoot = entriesByRoot;

  final Map<String, String> _files = <String, String>{};
  final Map<String, List<JsonMap>> _entriesByRoot;

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
  }) async => _entriesByRoot[rootPath] ?? const <JsonMap>[];

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
