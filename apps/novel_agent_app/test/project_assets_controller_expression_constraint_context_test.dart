import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/project_assets/application/controllers/project_assets_controller.dart';
import 'package:novel_agent_app/features/project_assets/application/models/project_assets_catalog.dart';
import 'package:novel_agent_app/features/project_assets/application/models/project_assets_tab_id.dart';
import 'package:novel_agent_app/features/project_assets/application/models/project_rag_analysis_summary.dart';
import 'package:novel_agent_app/features/project_assets/application/models/project_rag_extraction_execution_result.dart';
import 'package:novel_agent_app/features/project_assets/application/models/project_reference_extraction_execution_result.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_assets_loader_service.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_expression_constraint_workspace_service.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_rag_extraction_execution_service.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_reference_extraction_execution_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test(
    'openExpressionConstraintsForAgent switches to expression constraints tab and keeps agent context',
    () {
      final controller = ProjectAssetsController(
        projectAssetLibraryService: _NoopProjectAssetLibraryService(),
        expressionConstraintWorkspaceService:
            ProjectExpressionConstraintWorkspaceService(
              loadProfiles: (project) async =>
                  const <ExpressionConstraintProfile>[],
              loadBindings: (_) async =>
                  const <ProjectExpressionConstraintBinding>[],
              saveBindings: (project, bindings) async {},
            ),
        loaderService: _NoopProjectAssetsLoaderService(),
        readCurrentProject: () => null,
        readAvailableProjectAgents: () => const <JsonMap>[],
        syncWorkbenchResources: () async {},
        onBackRequested: () {},
        referenceExtractionExecutionService: _noopReferenceExtractionService(),
      );

      controller.openExpressionConstraintsForAgent('reviewer');

      expect(
        controller.viewData.activeTabId,
        ProjectAssetsTabId.expressionConstraints,
      );
      expect(controller.viewData.entryAgentContextId, 'reviewer');
    },
  );

  test(
    'onProjectAssetsExtractReferenceRequested syncs workspace and reports extraction status',
    () async {
      var syncCount = 0;
      final loader = _RecordingProjectAssetsLoaderService();
      final extractionService = _FakeSuccessfulReferenceExtractionService();
      final controller = ProjectAssetsController(
        projectAssetLibraryService: _NoopProjectAssetLibraryService(),
        expressionConstraintWorkspaceService:
            ProjectExpressionConstraintWorkspaceService(
              loadProfiles: (project) async =>
                  const <ExpressionConstraintProfile>[],
              loadBindings: (_) async =>
                  const <ProjectExpressionConstraintBinding>[],
              saveBindings: (project, bindings) async {},
            ),
        loaderService: loader,
        readCurrentProject: () => const ProjectDescriptor(
          id: 'project_a',
          name: '测试项目',
          rootPath: 'D:/Projects/demo',
        ),
        readAvailableProjectAgents: () => const <JsonMap>[],
        syncWorkbenchResources: () async {
          syncCount++;
        },
        onBackRequested: () {},
        referenceExtractionExecutionService: extractionService,
      );

      await controller.onProjectAssetsExtractReferenceRequested(
        strategyProfileId: 'reference_extraction.fact_focused',
      );

      expect(syncCount, 1);
      expect(loader.loadCount, 1);
      expect(
        extractionService.lastStrategyProfileId,
        'reference_extraction.fact_focused',
      );
      expect(controller.viewData.status, contains('接纳 2 条'));
      expect(controller.viewData.status, contains('knowledge/项目知识摘要.md'));
      expect(controller.viewData.isLoading, isFalse);
      expect(
        controller.viewData.activeTabId,
        ProjectAssetsTabId.referenceExtraction,
      );
      expect(
        controller.viewData.referenceExtractionStrategyPicker.selectedProfileId,
        'reference_extraction.fact_focused',
      );
    },
  );

  test(
    'onProjectAssetsReferenceSelected navigates by shared reference contract instead of parsing GUI-side key text',
    () async {
      final controller = ProjectAssetsController(
        projectAssetLibraryService: _NoopProjectAssetLibraryService(),
        expressionConstraintWorkspaceService:
            ProjectExpressionConstraintWorkspaceService(
              loadProfiles: (project) async =>
                  const <ExpressionConstraintProfile>[],
              loadBindings: (_) async =>
                  const <ProjectExpressionConstraintBinding>[],
              saveBindings: (project, bindings) async {},
            ),
        loaderService: _GraphSeededProjectAssetsLoaderService(),
        readCurrentProject: () => const ProjectDescriptor(
          id: 'project_a',
          name: '测试项目',
          rootPath: 'D:/Projects/demo',
        ),
        readAvailableProjectAgents: () => const <JsonMap>[],
        syncWorkbenchResources: () async {},
        onBackRequested: () {},
        referenceExtractionExecutionService: _noopReferenceExtractionService(),
      );

      await controller.refresh();
      controller.onProjectAssetsReferenceSelected('timeline:event-1');

      expect(controller.viewData.activeTabId, ProjectAssetsTabId.timelines);
      expect(
        controller.viewData.timeline.items
            .singleWhere((item) => item.isSelected)
            .id,
        'event-1',
      );
    },
  );

  test(
    'onProjectAssetsExtractRagRequested reflects progress status before completion',
    () async {
      final controller = ProjectAssetsController(
        projectAssetLibraryService: _NoopProjectAssetLibraryService(),
        expressionConstraintWorkspaceService:
            ProjectExpressionConstraintWorkspaceService(
              loadProfiles: (project) async =>
                  const <ExpressionConstraintProfile>[],
              loadBindings: (_) async =>
                  const <ProjectExpressionConstraintBinding>[],
              saveBindings: (project, bindings) async {},
            ),
        loaderService: _NoopProjectAssetsLoaderService(),
        readCurrentProject: () => const ProjectDescriptor(
          id: 'project_rag',
          name: '语料项目',
          rootPath: 'D:/Projects/rag_demo',
        ),
        readAvailableProjectAgents: () => const <JsonMap>[],
        syncWorkbenchResources: () async {},
        onBackRequested: () {},
        ragExtractionExecutionService:
            _FakeProgressRagExtractionExecutionService(),
        referenceExtractionExecutionService: _noopReferenceExtractionService(),
      );

      await controller.onProjectAssetsExtractRagRequested();

      expect(controller.viewData.ragExtraction.status, contains('构建完成'));
      expect(controller.viewData.ragExtraction.isLoading, isFalse);
      expect(controller.viewData.activeTabId, ProjectAssetsTabId.ragExtraction);
      expect(
        controller.viewData.ragExtraction.normalizationNote,
        contains('先整理'),
      );
      expect(
        controller.viewData.ragExtraction.analysisSummary.storyOutlineSummary,
        contains('镜潮回扣'),
      );
      expect(
        controller.viewData.ragExtraction.analysisSummary.characterNames,
        contains('林砚'),
      );
    },
  );

  test(
    'knowledge_base rag project uses dedicated rag workspace surface',
    () async {
      final controller = ProjectAssetsController(
        projectAssetLibraryService: _NoopProjectAssetLibraryService(),
        expressionConstraintWorkspaceService:
            ProjectExpressionConstraintWorkspaceService(
              loadProfiles: (project) async =>
                  const <ExpressionConstraintProfile>[],
              loadBindings: (_) async =>
                  const <ProjectExpressionConstraintBinding>[],
              saveBindings: (project, bindings) async {},
            ),
        loaderService: _NoopProjectAssetsLoaderService(),
        readCurrentProject: () => const ProjectDescriptor(
          id: 'kb_rag',
          name: '哈利资料语料库',
          rootPath: 'D:/Projects/hp_rag',
          projectType: 'knowledge_base',
          projectBranchId: KnowledgeBaseBranchCatalogService.ragBranchId,
        ),
        readAvailableProjectAgents: () => const <JsonMap>[],
        syncWorkbenchResources: () async {},
        onBackRequested: () {},
        referenceExtractionExecutionService: _noopReferenceExtractionService(),
      );

      await controller.refresh();

      expect(controller.viewData.useDedicatedRagWorkspace, isTrue);
      expect(controller.viewData.tabs, hasLength(1));
      expect(
        controller.viewData.tabs.single.id,
        ProjectAssetsTabId.ragExtraction,
      );
    },
  );

  test(
    'knowledge_base structured project opens in structured library surface',
    () async {
      final controller = ProjectAssetsController(
        projectAssetLibraryService: _NoopProjectAssetLibraryService(),
        expressionConstraintWorkspaceService:
            ProjectExpressionConstraintWorkspaceService(
              loadProfiles: (project) async =>
                  const <ExpressionConstraintProfile>[],
              loadBindings: (_) async =>
                  const <ProjectExpressionConstraintBinding>[],
              saveBindings: (project, bindings) async {},
            ),
        loaderService: _NoopProjectAssetsLoaderService(),
        readCurrentProject: () => const ProjectDescriptor(
          id: 'kb_structured',
          name: '哈利资料库',
          rootPath: 'D:/Projects/hp_kb',
          projectType: 'knowledge_base',
          projectBranchId: KnowledgeBaseBranchCatalogService.structuredBranchId,
        ),
        readAvailableProjectAgents: () => const <JsonMap>[],
        syncWorkbenchResources: () async {},
        onBackRequested: () {},
        referenceExtractionExecutionService: _noopReferenceExtractionService(),
      );

      await controller.refresh();

      expect(controller.viewData.useDedicatedRagWorkspace, isFalse);
      expect(controller.viewData.title, '资料库');
      expect(
        controller.viewData.activeTabId,
        ProjectAssetsTabId.referenceExtraction,
      );
      expect(controller.viewData.description, contains('结构化资料库'));
    },
  );
}

ProjectReferenceExtractionExecutionService _noopReferenceExtractionService() {
  return ProjectReferenceExtractionExecutionService(
    readSettings: () => null,
    llmGatewayFactory: (_, networkSettings) => _NoopLlmGateway(),
    executeReferenceExtraction:
        ({
          required project,
          required llmGateway,
          required modelId,
          required request,
        }) async {
          throw UnimplementedError();
        },
  );
}

class _NoopProjectAssetLibraryService extends ProjectAssetLibraryService {
  _NoopProjectAssetLibraryService()
    : super(
        workspacePort: _NoopProjectWorkspacePort(),
        projectToolHostPort: _NoopProjectToolHostPort(),
      );
}

class _NoopProjectAssetsLoaderService extends ProjectAssetsLoaderService {
  _NoopProjectAssetsLoaderService()
    : super(
        projectAssetLibraryService: _NoopProjectAssetLibraryService(),
        timelineRepository: _NoopProjectTimelineRepository(),
        relationshipRepository: _NoopProjectRelationshipRepository(),
        expressionConstraintWorkspaceService:
            ProjectExpressionConstraintWorkspaceService(
              loadProfiles: (project) async =>
                  const <ExpressionConstraintProfile>[],
              loadBindings: (_) async =>
                  const <ProjectExpressionConstraintBinding>[],
              saveBindings: (project, bindings) async {},
            ),
      );

  @override
  Future<ProjectAssetsCatalog> load(ProjectDescriptor project) async {
    return ProjectAssetsCatalog.empty();
  }
}

class _RecordingProjectAssetsLoaderService extends ProjectAssetsLoaderService {
  _RecordingProjectAssetsLoaderService()
    : super(
        projectAssetLibraryService: _NoopProjectAssetLibraryService(),
        timelineRepository: _NoopProjectTimelineRepository(),
        relationshipRepository: _NoopProjectRelationshipRepository(),
        expressionConstraintWorkspaceService:
            ProjectExpressionConstraintWorkspaceService(
              loadProfiles: (project) async =>
                  const <ExpressionConstraintProfile>[],
              loadBindings: (_) async =>
                  const <ProjectExpressionConstraintBinding>[],
              saveBindings: (project, bindings) async {},
            ),
      );

  int loadCount = 0;

  @override
  Future<ProjectAssetsCatalog> load(ProjectDescriptor project) async {
    loadCount++;
    return ProjectAssetsCatalog.empty();
  }
}

class _GraphSeededProjectAssetsLoaderService
    extends ProjectAssetsLoaderService {
  _GraphSeededProjectAssetsLoaderService()
    : super(
        projectAssetLibraryService: _NoopProjectAssetLibraryService(),
        timelineRepository: _NoopProjectTimelineRepository(),
        relationshipRepository: _NoopProjectRelationshipRepository(),
        expressionConstraintWorkspaceService:
            ProjectExpressionConstraintWorkspaceService(
              loadProfiles: (project) async =>
                  const <ExpressionConstraintProfile>[],
              loadBindings: (_) async =>
                  const <ProjectExpressionConstraintBinding>[],
              saveBindings: (project, bindings) async {},
            ),
      );

  @override
  Future<ProjectAssetsCatalog> load(ProjectDescriptor project) async {
    final referenceIndex = const SharedNarrativeAssetReferenceIndexService()
        .buildIndex(
          foreshadows: const <ForeshadowRecord>[
            ForeshadowRecord(
              id: 'hook',
              title: '开场伏笔',
              status: 'planted',
              relatedTimelineIds: <String>['event-1'],
            ),
          ],
          timelines: const <TimelineRecord>[
            TimelineRecord(
              id: 'event-1',
              displayName: '主角进入学院',
              sequence: 1,
              relatedForeshadowIds: <String>['hook'],
            ),
          ],
          relationships: const <RelationshipRecord>[],
        );
    return ProjectAssetsCatalog(
      foreshadows: const <ForeshadowRecord>[
        ForeshadowRecord(id: 'hook', title: '开场伏笔', status: 'planted'),
      ],
      timelines: const <TimelineRecord>[
        TimelineRecord(id: 'event-1', displayName: '主角进入学院', sequence: 1),
      ],
      referenceIndex: referenceIndex,
    );
  }
}

class _NoopProjectWorkspacePort implements ProjectWorkspacePort {
  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async => const <JsonMap>[];

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async =>
      null;

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {}
}

class _NoopProjectToolHostPort implements ProjectToolHostPort {
  @override
  Future<void> copyExternalFile(
    String absolutePath,
    String rootPath,
    String targetRelativePath,
  ) async {}

  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<void> deleteEntry(String rootPath, String relativePath) async {}

  @override
  Future<bool> entryExists(String rootPath, String relativePath) async => false;

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async => const <JsonMap>[];

  @override
  Future<void> moveEntry(
    String rootPath,
    String sourceRelativePath,
    String targetRelativePath,
  ) async {}

  @override
  Future<String?> readExternalTextFile(String absolutePath) async => null;

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async =>
      null;

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {}

  @override
  Future<void> writeExternalTextFile(
    String absolutePath,
    String content,
  ) async {}
}

class _NoopProjectTimelineRepository extends ProjectTimelineRepository {
  _NoopProjectTimelineRepository()
    : super(hostPort: _NoopProjectToolHostPort());
}

class _NoopProjectRelationshipRepository extends ProjectRelationshipRepository {
  _NoopProjectRelationshipRepository()
    : super(hostPort: _NoopProjectToolHostPort());
}

class _NoopLlmGateway implements LlmGateway {
  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<JsonMap> requestChatLegacy({
    required List<JsonMap> messages,
    required String modelId,
    List<JsonMap> tools = const <JsonMap>[],
    JsonMap options = const <String, Object?>{},
    List<ChatInputAttachment> attachments = const <ChatInputAttachment>[],
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> requestText({
    required String prompt,
    required String modelId,
  }) {
    throw UnimplementedError();
  }
}

class _FakeSuccessfulReferenceExtractionService
    extends ProjectReferenceExtractionExecutionService {
  _FakeSuccessfulReferenceExtractionService()
    : super(
        readSettings: _readSettings,
        llmGatewayFactory: _gatewayFactory,
        executeReferenceExtraction: _executeReferenceExtraction,
      );

  String lastStrategyProfileId = '';

  static AppSettings? _readSettings() => null;

  static LlmGateway _gatewayFactory(
    ProviderEndpointSettings _,
    JsonMap networkSettings,
  ) {
    return _NoopLlmGateway();
  }

  static Future<ProjectReferenceExtractionResult> _executeReferenceExtraction({
    required ProjectDescriptor project,
    required LlmGateway llmGateway,
    required String modelId,
    required ProjectReferenceExtractionRequest request,
  }) async {
    return const ProjectReferenceExtractionResult(
      runId: 'run_1',
      packageId: 'pkg_a',
      packageVersionId: 'v1',
      sourceFilePath: 'D:/source/book.txt',
      sourceDecodeMode: 'utf8',
      groupResolutionKind: 'single_agent_fallback',
      selectedGroupId: 'reference_extraction_group',
      strategyProfileId: 'reference_extraction.standard',
      executionConcurrencyMode: ReferenceExtractionConcurrencyModes.single,
      proposalCount: 4,
      acceptedProposalCount: 2,
      finalizedEntryCount: 7,
      generatedProjectionPaths: <String>['knowledge/项目知识摘要.md'],
    );
  }

  @override
  Future<ProjectReferenceExtractionExecutionResult> pickAndExecute({
    required ProjectDescriptor project,
    String strategyProfileId = '',
    String overrideProviderId = '',
    String overrideModelId = '',
  }) async {
    lastStrategyProfileId = strategyProfileId;
    return const ProjectReferenceExtractionExecutionResult(
      ok: true,
      didMutateProject: true,
      statusMessage:
          '参考资料提取完成：接纳 2 条，沉淀 7 条结构化条目。已生成 knowledge/项目知识摘要.md，可返回工作台资料区查看。',
    );
  }
}

class _FakeProgressRagExtractionExecutionService
    extends ProjectRagExtractionExecutionService {
  @override
  Future<ProjectRagExtractionExecutionResult> pickAndExecute({
    required ProjectDescriptor project,
    String modeId = '',
    Future<void> Function(String statusMessage)? onProgress,
  }) async {
    if (onProgress != null) {
      await onProgress('正在读取 txt 源文...');
      await onProgress('正在构建语料分片... 12 / 48');
      await onProgress('正在写入语料元数据... 32 / 48 分片');
    }
    return const ProjectRagExtractionExecutionResult(
      ok: true,
      didMutateProject: false,
      statusMessage: 'txt 语料构建完成。',
      analysisSummary: ProjectRagAnalysisSummary(
        storyOutlineSummary: '镜潮回扣在学院钟声里反复出现，推动主角意识到循环异样。',
        premiseSummary: '主角在异样钟声和回扣线索中逐步确认异常。',
        styleSummary: '章节推进明确，对话与场景线索较集中。',
        chapterTitles: <String>['第一章', '第二章'],
        characterNames: <String>['林砚'],
        organizationNames: <String>['黑潮议会'],
        worldRuleTitles: <String>['原文推断世界规则'],
        relationshipPairs: <String>['林砚 / 黑潮议会'],
        timelineLabels: <String>['第一章'],
        foreshadowTitles: <String>['第一章 的潜在线索'],
      ),
      normalizationNote: '已先整理源文为可提取纯文本，再继续构建语料。',
    );
  }
}
