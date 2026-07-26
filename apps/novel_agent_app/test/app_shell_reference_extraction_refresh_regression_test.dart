import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/project_assets/application/models/project_reference_extraction_execution_result.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_reference_extraction_execution_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_create_request_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_creation_phase.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'hfvv_viewmodel_harness_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'AppShellController project assets extraction refresh returns after projection files land',
    () async {
      final harness = await HfvvAppShellHarness.create(
        generateDraftUseCase: ScriptedGenerateDraftUseCase(
          resultBuilder:
              ({
                required ProjectDescriptor project,
                required String userPrompt,
                required String modelId,
              }) => DraftGenerationResult(
                project: project,
                projectInfo: const <String, Object?>{},
                userPrompt: userPrompt,
                prompt: userPrompt,
                modelId: modelId,
                draftMarkdown: '',
                contextPack: const <String, Object?>{},
                selectedPaths: const <String>[],
                executedTools: const <Object?>[],
                writtenPaths: const <String>[],
                changedPaths: const <String>[],
                transcriptMessages: const <JsonMap>[],
                waitingForUserChoice: false,
                reasoningContent: '',
                stoppedByToolError: false,
                toolErrorSummary: '',
              ),
        ),
        projectReferenceExtractionExecutionService:
            _SeededProjectionReferenceExtractionService(),
      );
      addTearDown(harness.controller.dispose);

      await harness.createProject(title: 'Reference Refresh Regression');

      await harness.controller.projectAssetsController
          .onProjectAssetsExtractReferenceRequested()
          .timeout(const Duration(seconds: 10));

      final projectPath = harness.workbench.projectPath;
      expect(projectPath, isNotEmpty);
      expect(
        File(
          '$projectPath${Platform.pathSeparator}knowledge${Platform.pathSeparator}项目知识摘要.md',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          '$projectPath${Platform.pathSeparator}knowledge${Platform.pathSeparator}设计元素摘要.md',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          '$projectPath${Platform.pathSeparator}research${Platform.pathSeparator}资料研究摘要.md',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          '$projectPath${Platform.pathSeparator}references${Platform.pathSeparator}引用作品边界.md',
        ).existsSync(),
        isTrue,
      );
      expect(
        harness.controller.projectAssetsController.viewData.isLoading,
        isFalse,
      );
      expect(
        harness.controller.projectAssetsController.viewData.status,
        contains('参考资料提取完成'),
      );
    },
  );

  test(
    'AppShellController runs book deconstruction analysis in staging-only mode',
    () async {
      final referenceExtractionService =
          _RecordingAnalysisOnlyReferenceExtractionService();
      final harness = await HfvvAppShellHarness.create(
        generateDraftUseCase: ScriptedGenerateDraftUseCase(
          resultBuilder:
              ({
                required ProjectDescriptor project,
                required String userPrompt,
                required String modelId,
              }) => DraftGenerationResult(
                project: project,
                projectInfo: const <String, Object?>{},
                userPrompt: userPrompt,
                prompt: userPrompt,
                modelId: modelId,
                draftMarkdown: '',
                contextPack: const <String, Object?>{},
                selectedPaths: const <String>[],
                executedTools: const <Object?>[],
                writtenPaths: const <String>[],
                changedPaths: const <String>[],
                transcriptMessages: const <JsonMap>[],
                waitingForUserChoice: false,
                reasoningContent: '',
                stoppedByToolError: false,
                toolErrorSummary: '',
              ),
        ),
        projectReferenceExtractionExecutionService: referenceExtractionService,
      );
      addTearDown(harness.controller.dispose);

      const request = ProjectCreateRequestViewData(
        title: 'Book Analysis Staging Regression',
        projectTypeId: BookDeconstructionConstants.projectTypeId,
        storageStrategyId: 'markdown_project_store',
        bookDeconstructionFollowupRouteId: 'continuation',
      );
      harness.controller.onCreateProjectRequested();
      await harness.waitUntil(
        () =>
            harness.workbench.projectLauncher?.creationPhase ==
            ProjectCreationPhase.projectType,
        description: 'book project type phase',
      );
      harness.controller.onProjectCreationSubmitted(request);
      await harness.waitUntil(
        () =>
            harness.workbench.projectLauncher?.creationPhase ==
            ProjectCreationPhase.bookDeconstructionFollowup,
        description: 'book deconstruction followup phase',
      );
      harness.controller.onProjectCreationSubmitted(request);
      await harness.waitUntil(
        () =>
            harness.workbench.projectLauncher?.creationPhase ==
            ProjectCreationPhase.storageStrategy,
        description: 'book storage strategy phase',
      );
      harness.controller.onProjectCreationSubmitted(request);
      await harness.waitUntil(
        () => harness.workbench.projectPath.trim().isNotEmpty,
        description: 'book project path after creation',
        timeout: const Duration(seconds: 15),
      );
      await harness.waitUntil(
        () => !harness.workbench.generationStatus.contains('正在加载项目'),
        description: 'book project load to settle',
      );
      final controller = harness.controller.bookDeconstructionController;
      controller.onBookDeconstructionSourceContentChanged(
        '第一章 港口风暴\n主角在港口被迫卷入一场追捕。',
      );
      await controller.onBookDeconstructionSplitRequested();
      expect(
        controller.viewData.canAnalyze,
        isTrue,
        reason: controller.viewData.status,
      );

      controller.onBookDeconstructionAnalysisUseModelChanged(true);
      controller.onBookDeconstructionAnalysisModelSelected(
        'hfvv-provider::hfvv-fake-model',
      );
      await controller.onBookDeconstructionAnalysisRequested();

      expect(referenceExtractionService.lastAnalysisOnly, isTrue);
      expect(referenceExtractionService.lastProviderId, 'hfvv-provider');
      expect(referenceExtractionService.lastModelId, 'hfvv-fake-model');
      expect(controller.viewData.analysisCompleted, isTrue);
      expect(controller.viewData.status, contains('仅暂存、尚未应用到项目资产'));
    },
  );
}

class _SeededProjectionReferenceExtractionService
    extends ProjectReferenceExtractionExecutionService {
  _SeededProjectionReferenceExtractionService()
    : super(
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

  @override
  Future<ProjectReferenceExtractionExecutionResult> pickAndExecute({
    required ProjectDescriptor project,
    String strategyProfileId = '',
    String overrideProviderId = '',
    String overrideModelId = '',
    bool analysisOnly = false,
  }) async {
    await _seedProjectionFiles(project.rootPath);
    return const ProjectReferenceExtractionExecutionResult(
      ok: true,
      didMutateProject: true,
      statusMessage:
          '参考资料提取完成：接纳 6 条，沉淀 18 条结构化条目。已生成 knowledge/项目知识摘要.md、research/资料研究摘要.md，可返回工作台资料区查看。',
    );
  }

  Future<void> _seedProjectionFiles(String rootPath) async {
    await _writeFile(rootPath, 'knowledge/项目知识摘要.md', '''---
projection_id: "project_knowledge_summary"
title: "项目知识摘要"
projection_only: true
source_of_truth_paths:
  - "project-information://knowledge_cards"
---

# 项目知识摘要

## 当前摘要概览

- 当前知识卡数：2

### 哈利

- Card ID：`ref_harry_character_001`
- 摘要：哈利在进入霍格沃茨前，对魔法世界几乎一无所知。
''');
    await _writeFile(rootPath, 'knowledge/设计元素摘要.md', '''---
projection_id: "project_design_summary"
title: "设计元素摘要"
projection_only: true
source_of_truth_paths:
  - "project-information://design_elements"
---

# 设计元素摘要

- 魔法学校入学入口
- 对角巷采购流程
''');
    await _writeFile(rootPath, 'research/资料研究摘要.md', '''---
projection_id: "project_research_summary"
title: "资料研究摘要"
projection_only: true
source_of_truth_paths:
  - "project-information://research_notes"
---

# 资料研究摘要

- 需要确认原作边界和改写偏移代价。
''');
    await _writeFile(rootPath, 'references/引用作品边界.md', '''---
projection_id: "reference_work_boundary_summary"
title: "引用作品边界"
projection_only: true
source_of_truth_paths:
  - "project-information://reference_works"
---

# 引用作品边界

- Requires Confirmation：true
- Allowed Usage Summary：仅使用结构化提取结果，不直接引用原文句段。
''');
    await _writeFile(
      rootPath,
      '.novel_agent/reference_extraction/staging/reference_extraction_gui_fake.json',
      '{"run_id":"reference_extraction_gui_fake","run_status":"completed_publishable"}\n',
    );
  }

  Future<void> _writeFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {
    final normalized = relativePath.replaceAll('/', Platform.pathSeparator);
    final file = File('$rootPath${Platform.pathSeparator}$normalized');
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }
}

class _RecordingAnalysisOnlyReferenceExtractionService
    extends ProjectReferenceExtractionExecutionService {
  _RecordingAnalysisOnlyReferenceExtractionService()
    : super(
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

  bool? lastAnalysisOnly;
  String lastProviderId = '';
  String lastModelId = '';

  @override
  Future<ProjectReferenceExtractionExecutionResult> pickAndExecute({
    required ProjectDescriptor project,
    String strategyProfileId = '',
    String overrideProviderId = '',
    String overrideModelId = '',
    bool analysisOnly = false,
  }) async {
    lastAnalysisOnly = analysisOnly;
    lastProviderId = overrideProviderId;
    lastModelId = overrideModelId;
    return const ProjectReferenceExtractionExecutionResult(
      ok: true,
      didMutateProject: false,
      statusMessage: '参考资料分析完成：结果已暂存，尚未应用到项目资产。',
      runId: 'reference-analysis-staging-regression',
      packageId: 'reference-analysis-staging-package',
      packageVersionId: 'v1',
    );
  }
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
