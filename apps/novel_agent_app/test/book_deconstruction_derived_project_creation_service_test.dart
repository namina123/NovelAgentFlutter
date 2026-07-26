import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_derived_project_creation_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('派生服务会创建续写项目并写入结构资产与继承正文', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    final manifestCodec = ProjectManifestCodecService();
    final buildResult = BuildBookDeconstructionDraftUseCase().execute(
      sourceTitle: '海上城邦',
      sourceContent: '第一章 港口风暴\n主角在港口被迫卷入一场追捕。\n\n第二章 议会阴影\n城邦议会开始浮出水面。',
      sourceAbsolutePath: 'D:/Books/source_book.md',
      operatorNotes: '继续续写',
      styleSummary: '节奏偏商业。',
      worldRulesText: '航线掌握着超常权力。',
      characterLinesText: '林砚：主角',
      organizationLinesText: '议会：海上城邦中枢',
    );
    final service = BookDeconstructionDerivedProjectCreationService(
      createProjectWorkspaceUseCase: CreateProjectWorkspaceUseCase(
        projectRepository: _FakeProjectRepository(
          workspacePort: workspacePort,
          manifestCodecService: manifestCodec,
        ),
        projectWorkspacePort: workspacePort,
        projectContentRepository: _FakeProjectContentRepository(),
        projectReadableProjectionService:
            _FakeProjectReadableProjectionService(),
        projectManifestCodecService: manifestCodec,
      ),
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
    );

    final result = await service.execute(
      projectsRootPath: 'D:/Projects',
      sourceProject: const ProjectDescriptor(
        id: 'source',
        name: '拆书源项目',
        rootPath: 'D:/Projects/source',
        projectType: 'book_deconstruction',
      ),
      buildResult: buildResult,
      selectedItemIds: buildResult.applicationPlan.items
          .map((item) => item.id)
          .toSet(),
      selectedFollowupOptionId: 'continuation_novel',
    );

    expect(result.project.projectType, 'novel');
    expect(
      result.project.storageStrategy,
      ProjectStorageStrategy.markdownProjectStore,
    );
    final premisePath = buildResult.applicationPlan.items
        .firstWhere(
          (item) => item.sourceKind == BookDeconstructionArtifactKind.premise,
        )
        .relativePathHint;
    expect(
      workspacePort.readStoredTextFile(result.project.rootPath, premisePath),
      allOf(contains('# 核心前提'), contains('第一章 港口风暴')),
    );
    // 中文注释: 续写路线把分好的正文写进正文区域 chapters/（而非 inherited/ 镜像），
    // 文件名带可解析的"第N章"，续写在其后接写。
    final liveChapterPath = const BookDeconstructionTargetPathService()
        .liveChapterPath(sequence: 1, title: '第一章 港口风暴');
    expect(liveChapterPath, startsWith('chapters/'));
    expect(
      workspacePort.readStoredTextFile(
        result.project.rootPath,
        liveChapterPath,
      ),
      contains('主角在港口被迫卷入一场追捕'),
    );
    // inherited/ 镜像目录不应再出现续写正文（正文已落到正文区域）。
    final mirroredPath = const BookDeconstructionTargetPathService()
        .inheritedChapterPath(
          followupOptionId: 'continuation_novel',
          sequence: 1,
          title: '第一章 港口风暴',
        );
    expect(
      workspacePort.readStoredTextFile(result.project.rootPath, mirroredPath),
      isNull,
    );
    expect(
      workspacePort.readStoredTextFile(
        result.project.rootPath,
        'sources/original/book_deconstruction_1_海上城邦.md',
      ),
      contains('第一章 港口风暴'),
    );
  });

  test('派生服务会继承源项目的 sqlite 存储策略并把知识资产写入 sqlite', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    final manifestCodec = ProjectManifestCodecService();
    final buildResult = BuildBookDeconstructionDraftUseCase().execute(
      sourceTitle: '海上城邦',
      sourceContent: '第一章 港口风暴\n主角在港口被迫卷入一场追捕。\n\n第二章 议会阴影\n城邦议会开始浮出水面。',
      sourceAbsolutePath: 'D:/Books/source_book.md',
      operatorNotes: '继续续写',
      styleSummary: '节奏偏商业。',
      worldRulesText: '航线掌握着超常权力。',
      characterLinesText: '林砚：主角',
      organizationLinesText: '议会：海上城邦中枢',
    );
    final service = BookDeconstructionDerivedProjectCreationService(
      createProjectWorkspaceUseCase: CreateProjectWorkspaceUseCase(
        projectRepository: _FakeProjectRepository(
          workspacePort: workspacePort,
          manifestCodecService: manifestCodec,
        ),
        projectWorkspacePort: workspacePort,
        projectContentRepository: _FakeProjectContentRepository(),
        projectReadableProjectionService:
            _FakeProjectReadableProjectionService(),
        projectManifestCodecService: manifestCodec,
      ),
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
    );

    final result = await service.execute(
      projectsRootPath: 'D:/Projects',
      sourceProject: const ProjectDescriptor(
        id: 'source',
        name: '拆书源项目',
        rootPath: 'D:/Projects/source',
        projectType: 'book_deconstruction',
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      ),
      buildResult: buildResult,
      selectedItemIds: buildResult.applicationPlan.items
          .map((item) => item.id)
          .toSet(),
      selectedFollowupOptionId: 'continuation_novel',
    );

    expect(
      result.project.storageStrategy,
      ProjectStorageStrategy.sqliteProjectStore,
    );

    final knowledgeRepository = SqliteKnowledgeCardRepository();
    final cards = await knowledgeRepository.listKnowledgeCards(result.project);
    expect(cards, isNotEmpty);

    final referenceRepository = SqliteReferenceWorkRepository();
    final references = await referenceRepository.listReferenceWorks(
      result.project,
    );
    expect(references, isNotEmpty);

    expect(
      await ProjectStructuredContentBridgeService().readProjectedBodyText(
        result.project,
        'imports/source_original/book_deconstruction_1_海上城邦.md',
      ),
      contains('第一章 港口风暴'),
    );

    expect(
      workspacePort.readStoredTextFile(
        result.project.rootPath,
        InformationProjectionDocument.knowledgeSummaryRelativePath,
      ),
      isNull,
    );
  });

  test('SQLite 派生项目先归档原文主事实源，再写来源投影', () async {
    final events = <String>[];
    final workspacePort = _InMemoryProjectWorkspacePort(
      onWrite: (relativePath) => events.add('projection:$relativePath'),
    );
    final manifestCodec = ProjectManifestCodecService();
    final structuredBridge = _RecordingSourceArchiveBridgeService(events);
    final buildResult = BuildBookDeconstructionDraftUseCase().execute(
      sourceTitle: '海上城邦',
      sourceContent: '第一章 港口风暴\n主角在港口被迫卷入一场追捕。',
      sourceAbsolutePath: 'D:/Books/source_book.md',
    );
    final service = BookDeconstructionDerivedProjectCreationService(
      createProjectWorkspaceUseCase: CreateProjectWorkspaceUseCase(
        projectRepository: _FakeProjectRepository(
          workspacePort: workspacePort,
          manifestCodecService: manifestCodec,
        ),
        projectWorkspacePort: workspacePort,
        projectContentRepository: _FakeProjectContentRepository(),
        projectReadableProjectionService:
            _FakeProjectReadableProjectionService(),
        projectManifestCodecService: manifestCodec,
      ),
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
      structuredContentBridgeService: structuredBridge,
    );

    final result = await service.execute(
      projectsRootPath: 'D:/Projects',
      sourceProject: const ProjectDescriptor(
        id: 'sqlite-source',
        name: 'SQLite 拆书源项目',
        rootPath: 'D:/Projects/sqlite_source',
        projectType: 'book_deconstruction',
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      ),
      buildResult: buildResult,
      selectedItemIds: const <String>{},
      selectedFollowupOptionId: 'continuation_novel',
    );

    const archivePath = 'imports/source_original/book_deconstruction_1_海上城邦.md';
    final primaryIndex = events.indexOf('sqlite:$archivePath');
    final projectionIndex = events.indexOf('projection:$archivePath');
    expect(
      result.project.storageStrategy,
      ProjectStorageStrategy.sqliteProjectStore,
    );
    expect(primaryIndex, greaterThanOrEqualTo(0));
    expect(projectionIndex, greaterThanOrEqualTo(0));
    expect(primaryIndex, lessThan(projectionIndex));
  });

  test('派生服务会为长任务同人路线选择运行基准且不混入原作正文', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    final manifestCodec = ProjectManifestCodecService();
    final buildResult = BuildBookDeconstructionDraftUseCase().execute(
      sourceTitle: '海上城邦',
      sourceContent: '第一章 港口风暴\n主角在港口被迫卷入一场追捕。',
      sourceAbsolutePath: 'D:/Books/source_book.md',
      operatorNotes: '同人派生',
      styleSummary: '节奏偏商业。',
      worldRulesText: '航线掌握着超常权力。',
      characterLinesText: '林砚：主角',
      organizationLinesText: '议会：海上城邦中枢',
    );
    final service = BookDeconstructionDerivedProjectCreationService(
      createProjectWorkspaceUseCase: CreateProjectWorkspaceUseCase(
        projectRepository: _FakeProjectRepository(
          workspacePort: workspacePort,
          manifestCodecService: manifestCodec,
        ),
        projectWorkspacePort: workspacePort,
        projectContentRepository: _FakeProjectContentRepository(),
        projectReadableProjectionService:
            _FakeProjectReadableProjectionService(),
        projectManifestCodecService: manifestCodec,
      ),
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
    );

    final result = await service.execute(
      projectsRootPath: 'D:/Projects',
      sourceProject: const ProjectDescriptor(
        id: 'source',
        name: '拆书源项目',
        rootPath: 'D:/Projects/source',
        projectType: 'book_deconstruction',
      ),
      buildResult: buildResult,
      selectedItemIds: buildResult.applicationPlan.items
          .map((item) => item.id)
          .toSet(),
      selectedFollowupOptionId: 'fanfic_full_outline_consensus',
    );

    expect(result.project.projectType, 'long_novel');
    expect(result.project.runtimeBaselineId, 'chapter_collaboration_autorun');
    expect(
      workspacePort.readStoredTextFile(
        result.project.rootPath,
        'chapters/inherited/fanfic_full_outline_consensus/001_第一章_港口风暴.md',
      ),
      isNull,
    );
    expect(
      workspacePort.readStoredTextFile(
        result.project.rootPath,
        'tasks/plans/book_deconstruction_followups/fanfic_full_outline_consensus.md',
      ),
      contains('同人'),
    );
  });
}

class _FakeProjectRepository implements ProjectRepository {
  _FakeProjectRepository({
    required _InMemoryProjectWorkspacePort workspacePort,
    required ProjectManifestCodecService manifestCodecService,
  }) : _workspacePort = workspacePort,
       _manifestCodecService = manifestCodecService;

  final _InMemoryProjectWorkspacePort _workspacePort;
  final ProjectManifestCodecService _manifestCodecService;

  @override
  Future<ProjectDescriptor?> openByPath(String rootPath) async {
    final manifestContent = _workspacePort.readStoredTextFile(
      rootPath,
      ProjectManifestCodecService.manifestRelativePath,
    );
    if (manifestContent == null) {
      return null;
    }
    final projectName = rootPath
        .replaceAll('\\', '/')
        .split('/')
        .where((part) => part.isNotEmpty)
        .last;
    final manifest = _manifestCodecService.parse(
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

class _InMemoryProjectWorkspacePort implements ProjectWorkspacePort {
  _InMemoryProjectWorkspacePort({this.onWrite});

  final void Function(String relativePath)? onWrite;
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
    onWrite?.call(relativePath);
  }
}

class _RecordingSourceArchiveBridgeService
    extends ProjectStructuredContentBridgeService {
  _RecordingSourceArchiveBridgeService(this._events);

  final List<String> _events;

  @override
  Future<void> persistSourceOriginalArchive({
    required ProjectDescriptor project,
    required String archivePath,
    required String archiveTitle,
    required String sourceContent,
    String statePath = '',
  }) async {
    _events.add('sqlite:$archivePath');
  }
}
