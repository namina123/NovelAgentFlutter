import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/controllers/book_deconstruction_controller.dart';
import 'package:novel_agent_app/features/project_assets/application/models/project_reference_extraction_execution_result.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_confirmation_journal_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_confirm_workflow_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_derived_project_creation_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_draft_builder_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/desktop_book_deconstruction_source_picker_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/selector_option_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

const String _splitModelKey = 'provider-1::test-model';

List<SelectorOptionViewData> _modelOptions() {
  return const <SelectorOptionViewData>[
    SelectorOptionViewData(
      id: _splitModelKey,
      label: 'Provider · test-model',
      note: 'provider-1',
    ),
  ];
}

ExecuteProjectTypeTransitionUseCase _transitionUseCase(
  ProjectWorkspacePort workspacePort,
) {
  final writer = WriteProjectTextFileUseCase(
    projectWorkspacePort: workspacePort,
  );
  return ExecuteProjectTypeTransitionUseCase(
    projectTypeTransitionPreparationService:
        const ProjectTypeTransitionPreparationService(),
    writeProjectTextFileUseCase: writer,
    readHasActiveLongTaskRun: (_) async => false,
    readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
  );
}

void main() {
  test('拆书控制器可完成纯净分章并写入应用前确认纪要', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const currentProject = ProjectDescriptor(
      id: 'project-1',
      name: '拆书测试项目',
      rootPath: 'D:/Projects/deconstruction_project',
      projectType: 'book_deconstruction',
    );
    final controller = BookDeconstructionController(
      readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
      readCurrentProject: () => currentProject,
      syncWorkbenchResources: () async {
        workspacePort.syncCount += 1;
      },
      onBackRequested: () {},
      readImportAssistantModelOptions: _modelOptions,
      projectTypeTransitionUseCase: _transitionUseCase(workspacePort),
    );

    await controller.initialize();
    controller.onBookDeconstructionSourceTitleChanged('海上城邦');
    controller.onBookDeconstructionSourceContentChanged(
      '第一章 港口风暴\n主角在港口被迫卷入一场追捕。\n\n第二章 议会阴影\n城邦议会开始浮出水面。',
    );

    // 中文注释: 拆书 = 纯净分章（extractKnowledge:false），不产出知识抽取资产。
    await controller.onBookDeconstructionSplitRequested();

    // 中文注释: 纯拆书（extractKnowledge:false）下分章结果只落在 planGroups（分章结果），
    // previewSections 不再含章节骨架（已与章纲合并为单一"分章结果"）。
    expect(controller.viewData.planGroups, isNotEmpty);

    final firstItemId = controller.viewData.planGroups.first.items.first.id;
    controller.onBookDeconstructionPlanItemSelectionChanged(
      itemId: firstItemId,
      selected: false,
    );
    controller.onBookDeconstructionTargetWritingTypeSelected('novel');

    await controller.onBookDeconstructionConfirmRequested();

    final content = workspacePort.readStoredTextFile(
      'D:/Projects/deconstruction_project',
      'analysis/book_deconstruction_preview.md',
    );
    expect(content, isNotNull);
    expect(content, contains('# 拆书结构化预演'));
    final structuredSource = workspacePort.readStoredTextFile(
      'D:/Projects/deconstruction_project',
      'analysis/book_deconstruction_structured_source.md',
    );
    expect(structuredSource, isNotNull);
    expect(structuredSource, contains('## 规范化正文'));
    expect(structuredSource, contains('第一章 港口风暴'));
    expect(
      controller.viewData.confirmedPreviewPath,
      'analysis/book_deconstruction_preview.md',
    );
    expect(workspacePort.syncCount, 1);
  });

  test('确认后变更应用选择会使预演确认失效', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const currentProject = ProjectDescriptor(
      id: 'project-confirmation-payload-change',
      name: '确认载荷变更测试',
      rootPath: 'D:/Projects/deconstruction_confirmation_payload_change',
      projectType: 'book_deconstruction',
    );
    final controller = BookDeconstructionController(
      readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
      readCurrentProject: () => currentProject,
      syncWorkbenchResources: () async {},
      onBackRequested: () {},
      readImportAssistantModelOptions: _modelOptions,
      projectTypeTransitionUseCase: _transitionUseCase(workspacePort),
    );
    addTearDown(controller.dispose);

    await controller.initialize();
    controller.onBookDeconstructionSourceTitleChanged('确认载荷');
    controller.onBookDeconstructionSourceContentChanged(
      '第一章 港口风暴\n主角在港口被迫卷入一场追捕。\n\n第二章 议会阴影\n城邦议会开始浮出水面。',
    );
    await controller.onBookDeconstructionSplitRequested();
    controller.onBookDeconstructionTargetWritingTypeSelected('novel');
    await controller.onBookDeconstructionConfirmRequested();

    expect(
      controller.viewData.confirmedPreviewPath,
      'analysis/book_deconstruction_preview.md',
    );
    controller.onBookDeconstructionPlanItemSelectionChanged(
      itemId: controller.viewData.planGroups.first.items.first.id,
      selected: false,
    );

    expect(controller.viewData.confirmedPreviewPath, isEmpty);
    expect(controller.viewData.status, contains('确认条件已变更'));
  });

  test('拆书控制器导入时会把原文归档到来源层并把预演留在 analysis 层', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'book_deconstruction_controller_archive_test_',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });
    final sourceFile = File(
      '${tempDirectory.path}${Platform.pathSeparator}source_book.md',
    );
    await sourceFile.writeAsString('第一章 港口风暴\n主角在港口被迫卷入一场追捕。');
    final workspacePort = _InMemoryProjectWorkspacePort();
    const currentProject = ProjectDescriptor(
      id: 'project-2',
      name: '拆书测试项目二',
      rootPath: 'D:/Projects/deconstruction_project_archive',
      projectType: 'book_deconstruction',
    );
    final controller = BookDeconstructionController(
      readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
      readCurrentProject: () => currentProject,
      syncWorkbenchResources: () async {
        workspacePort.syncCount += 1;
      },
      onBackRequested: () {},
      readImportAssistantModelOptions: _modelOptions,
      sourcePickerService: _FakeDesktopBookDeconstructionSourcePickerService(
        sourceFile.path,
      ),
      projectTypeTransitionUseCase: _transitionUseCase(workspacePort),
    );

    await controller.initialize();
    await controller.onBookDeconstructionImportFileRequested();

    final archivePath = const BookDeconstructionTargetPathService()
        .sourceArchivePath(sourceFile.path);
    expect(
      workspacePort.readStoredTextFile(currentProject.rootPath, archivePath),
      contains('第一章 港口风暴'),
    );
    expect(controller.viewData.sourceAbsolutePath, sourceFile.path);
    expect(controller.viewData.sourceContent, contains('港口风暴'));

    await controller.onBookDeconstructionSplitRequested();
    controller.onBookDeconstructionTargetWritingTypeSelected('novel');
    controller.onBookDeconstructionPlanItemSelectionChanged(
      itemId: controller.viewData.planGroups.first.items.first.id,
      selected: true,
    );
    await controller.onBookDeconstructionConfirmRequested();

    expect(
      workspacePort.readStoredTextFile(
        currentProject.rootPath,
        'analysis/book_deconstruction_preview.md',
      ),
      contains('# 拆书结构化预演'),
    );
    // 中文注释: 续写开关默认关闭 → 分章作为参考资料写进 analysis/，不进正文。
    expect(
      workspacePort.readStoredTextFile(
        currentProject.rootPath,
        'analysis/book_deconstruction_chapter_001_第一章_港口风暴.md',
      ),
      contains('主角在港口被迫卷入一场追捕'),
    );
  });

  test('拆书控制器会读取项目级默认承接路线作为初始选项', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const currentProject = ProjectDescriptor(
      id: 'project-setup',
      name: '拆书测试项目默认路线',
      rootPath: 'D:/Projects/deconstruction_project_setup',
      projectType: 'book_deconstruction',
    );
    await workspacePort.writeTextFile(
      currentProject.rootPath,
      BookDeconstructionProjectSetupDocumentService.relativePath,
      BookDeconstructionProjectSetupDocumentService().encode(
        const BookDeconstructionProjectSetup(
          followupRouteId: 'fanfic',
          preferredFollowupOptionId: 'fanfic_seed_autopilot_novel',
          preferredContinuationDirection:
              BookDeconstructionContinuationDirection.longTaskPreferred,
        ),
      ),
    );
    final controller = BookDeconstructionController(
      readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
      readCurrentProject: () => currentProject,
      syncWorkbenchResources: () async {},
      onBackRequested: () {},
      readImportAssistantModelOptions: _modelOptions,
    );

    await controller.initialize();

    expect(
      controller.viewData.selectedFollowupOptionId,
      'fanfic_seed_autopilot_novel',
    );
  });

  test('拆书控制器可直接派生并打开后续项目', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const currentProject = ProjectDescriptor(
      id: 'project-3',
      name: '拆书测试项目三',
      rootPath: 'D:/Projects/deconstruction_project_derived',
      projectType: 'book_deconstruction',
    );
    ProjectDescriptor? openedProject;
    String openedPath = '';
    final controller = BookDeconstructionController(
      readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
      readCurrentProject: () => currentProject,
      syncWorkbenchResources: () async {
        workspacePort.syncCount += 1;
      },
      onBackRequested: () {},
      readImportAssistantModelOptions: _modelOptions,
      projectsRootPath: 'D:/Projects',
      derivedProjectCreationService:
          BookDeconstructionDerivedProjectCreationService(
            createProjectWorkspaceUseCase: CreateProjectWorkspaceUseCase(
              projectRepository: _FakeProjectRepository(
                workspacePort: workspacePort,
                manifestCodecService: ProjectManifestCodecService(),
              ),
              projectWorkspacePort: workspacePort,
              projectContentRepository: _FakeProjectContentRepository(),
              projectReadableProjectionService:
                  _FakeProjectReadableProjectionService(),
            ),
            writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
              projectWorkspacePort: workspacePort,
            ),
            narrativePersistenceService:
                BookDeconstructionNarrativePersistenceService(
                  workspacePort: workspacePort,
                ),
          ),
      openDerivedProjectRequested: (project, preferredOpenPath) async {
        openedProject = project;
        openedPath = preferredOpenPath;
      },
      projectTypeTransitionUseCase: _transitionUseCase(workspacePort),
    );

    await controller.initialize();
    controller.onBookDeconstructionSourceTitleChanged('海上城邦');
    controller.onBookDeconstructionSourceContentChanged(
      '第一章 港口风暴\n主角在港口被迫卷入一场追捕。\n\n第二章 议会阴影\n城邦议会开始浮出水面。',
    );

    await controller.onBookDeconstructionSplitRequested();
    controller.onBookDeconstructionSelectAllRequested();
    controller.onBookDeconstructionFollowupOptionSelected('continuation_novel');
    controller.onBookDeconstructionTargetWritingTypeSelected('novel');
    expect(controller.viewData.selectedFollowupOptionId, 'continuation_novel');
    expect(controller.viewData.canCreateDerivedProject, isTrue);
    await controller.onBookDeconstructionCreateDerivedProjectRequested();

    expect(
      controller.viewData.status,
      isNot(anyOf(contains('派生项目失败'), contains('暂不可用'), contains('请先'))),
    );
    expect(openedProject, isNotNull);
    expect(openedProject!.projectType, 'novel');
    expect(openedProject!.name, '海上城邦 - 一般小说');
    expect(
      openedPath,
      'tasks/plans/book_deconstruction_followups/continuation_novel.md',
    );
  });

  test('拆书控制器在派生项目接线缺失时保持禁用而不回吐未接入文案', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const currentProject = ProjectDescriptor(
      id: 'project-4',
      name: '拆书测试项目四',
      rootPath: 'D:/Projects/deconstruction_project_unwired',
      projectType: 'book_deconstruction',
    );
    final controller = BookDeconstructionController(
      readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
      readCurrentProject: () => currentProject,
      syncWorkbenchResources: () async {
        workspacePort.syncCount += 1;
      },
      onBackRequested: () {},
      readImportAssistantModelOptions: _modelOptions,
    );

    await controller.initialize();

    expect(controller.viewData.canCreateDerivedProject, isFalse);
    await controller.onBookDeconstructionCreateDerivedProjectRequested();
    expect(controller.viewData.status, '当前派生项目创建暂不可用。');
    expect(controller.viewData.status, isNot(contains('未接入')));
  });

  test('分析（可选）勾选模型后会用所选模型调用内置智能体并如实呈现', () async {
    // 中文注释: 分析是可选阶段：必须先拆书（产出 buildResult），再勾"使用模型"+选模型，
    // 才能分析。委托隐藏内置智能体，provider/model 由用户选择透传（与 app 默认解耦）。
    final workspacePort = _InMemoryProjectWorkspacePort();
    const currentProject = ProjectDescriptor(
      id: 'project-analyze',
      name: '拆书分析测试',
      rootPath: 'D:/Projects/deconstruction_analyze',
      projectType: 'book_deconstruction',
    );
    String? capturedProvider;
    String? capturedModel;
    final controller = BookDeconstructionController(
      readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
      readCurrentProject: () => currentProject,
      syncWorkbenchResources: () async {},
      onBackRequested: () {},
      readImportAssistantModelOptions: _modelOptions,
      extractKnowledgeHandler:
          (
            project, {
            required String providerId,
            required String modelId,
          }) async {
            capturedProvider = providerId;
            capturedModel = modelId;
            return const ProjectReferenceExtractionExecutionResult(
              ok: true,
              didMutateProject: false,
              statusMessage: '已暂存 3 条知识卡片',
              runId: 'analysis-run-1',
              packageId: 'analysis-package-1',
              packageVersionId: 'analysis-version-1',
            );
          },
    );

    await controller.initialize();
    controller.onBookDeconstructionSourceContentChanged(
      '第一章 港口风暴\n主角在港口被迫卷入一场追捕。',
    );
    await controller.onBookDeconstructionSplitRequested();
    // 拆书后才有 buildResult，分析才可用。
    expect(controller.viewData.canAnalyze, isTrue);

    controller.onBookDeconstructionAnalysisUseModelChanged(true);
    controller.onBookDeconstructionAnalysisModelSelected(_splitModelKey);
    await controller.onBookDeconstructionAnalysisRequested();

    expect(capturedProvider, 'provider-1');
    expect(capturedModel, 'test-model');
    expect(controller.viewData.analysisCompleted, isTrue);
    expect(controller.viewData.hasStagedAnalysis, isTrue);
    expect(controller.viewData.applyStagedAnalysisResults, isFalse);
    expect(controller.viewData.analysisStagingRunId, 'analysis-run-1');
    expect(controller.viewData.analysisStagingPackageId, 'analysis-package-1');
    expect(
      controller.viewData.analysisStagingPackageVersionId,
      'analysis-version-1',
    );
    expect(controller.viewData.status, contains('已暂存 3 条知识卡片'));
    expect(controller.viewData.status, contains('仅暂存、尚未应用到项目资产'));
    expect(controller.viewData.status, isNot(contains('写入项目资产')));
  });

  test('分析未选模型时不调用内置智能体并如实提示', () async {
    // 中文注释: spec：不选模型则不分析。未勾选/未选模型时点分析，如实提示，不触发回调。
    final workspacePort = _InMemoryProjectWorkspacePort();
    const currentProject = ProjectDescriptor(
      id: 'project-analyze-no-model',
      name: '拆书分析无模型测试',
      rootPath: 'D:/Projects/deconstruction_analyze_no_model',
      projectType: 'book_deconstruction',
    );
    var handlerCalls = 0;
    final controller = BookDeconstructionController(
      readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
      readCurrentProject: () => currentProject,
      syncWorkbenchResources: () async {},
      onBackRequested: () {},
      readImportAssistantModelOptions: _modelOptions,
      extractKnowledgeHandler:
          (
            project, {
            required String providerId,
            required String modelId,
          }) async {
            handlerCalls += 1;
            return const ProjectReferenceExtractionExecutionResult(
              ok: true,
              didMutateProject: false,
              statusMessage: '不应到达',
            );
          },
    );

    await controller.initialize();
    controller.onBookDeconstructionSourceContentChanged(
      '第一章 港口风暴\n主角在港口被迫卷入一场追捕。',
    );
    await controller.onBookDeconstructionSplitRequested();
    // 未勾"使用模型"、未选模型，直接点分析。
    await controller.onBookDeconstructionAnalysisRequested();
    expect(handlerCalls, 0);
    expect(controller.viewData.status, contains('选择一个模型'));
  });

  test('切换项目后会丢弃在途拆书结果，不能覆盖新项目快照', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const projectA = ProjectDescriptor(
      id: 'project-operation-a',
      name: '项目 A',
      rootPath: 'D:/Projects/deconstruction_operation_a',
      projectType: 'book_deconstruction',
    );
    const projectB = ProjectDescriptor(
      id: 'project-operation-b',
      name: '项目 B',
      rootPath: 'D:/Projects/deconstruction_operation_b',
      projectType: 'book_deconstruction',
    );
    ProjectDescriptor currentProject = projectA;
    final draftBuilder = _BlockingBookDeconstructionDraftBuilderService();
    final controller = BookDeconstructionController(
      readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
      readCurrentProject: () => currentProject,
      syncWorkbenchResources: () async {},
      onBackRequested: () {},
      readImportAssistantModelOptions: _modelOptions,
      draftBuilderService: draftBuilder,
    );

    await controller.initialize();
    controller.onBookDeconstructionSourceTitleChanged('项目 A 原文');
    controller.onBookDeconstructionSourceContentChanged('第一章 A 城\n项目 A 的正文。');
    final splitFuture = controller.onBookDeconstructionSplitRequested();
    await draftBuilder.started.future;

    currentProject = projectB;
    await controller.refresh();
    draftBuilder.complete();
    await splitFuture;

    expect(controller.viewData.projectTitle, projectB.name);
    expect(controller.viewData.sourceContent, isEmpty);
    expect(controller.viewData.planGroups, isEmpty);
    expect(
      workspacePort.readStoredTextFile(
        projectB.rootPath,
        'analysis/book_deconstruction_structured_source.md',
      ),
      isNull,
    );
    controller.dispose();
  });

  test('确认提交期间会冻结取消、返回和选择变更', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const currentProject = ProjectDescriptor(
      id: 'project-cancel-confirmation',
      name: '确认提交边界测试',
      rootPath: 'D:/Projects/deconstruction_cancel_confirmation',
      projectType: 'book_deconstruction',
    );
    var backRequested = false;
    final blockingConfirmation =
        _BlockingBookDeconstructionConfirmWorkflowService(workspacePort);
    final controller = BookDeconstructionController(
      readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
      readCurrentProject: () => currentProject,
      syncWorkbenchResources: () async {},
      onBackRequested: () {
        backRequested = true;
      },
      readImportAssistantModelOptions: _modelOptions,
      confirmWorkflowService: blockingConfirmation,
    );

    await controller.initialize();
    controller.onBookDeconstructionSourceContentChanged(
      '第一章 港口风暴\n主角在港口被迫卷入一场追捕。',
    );
    await controller.onBookDeconstructionSplitRequested();
    controller.onBookDeconstructionTargetWritingTypeSelected('novel');
    final selectedItemId = controller.viewData.planGroups.first.items.first.id;
    final selectedItemCountBeforeCommit = controller.viewData.selectedItemCount;

    final confirmation = controller.onBookDeconstructionConfirmRequested();
    await blockingConfirmation.started.future;
    controller.onBookDeconstructionCancelRequested();
    controller.onBookDeconstructionBackRequested();
    controller.onBookDeconstructionPlanItemSelectionChanged(
      itemId: selectedItemId,
      selected: false,
    );
    controller.onBookDeconstructionTargetWritingTypeSelected('long_novel');
    controller.onBookDeconstructionInheritAsLiveNarrativeChanged(true);

    expect(controller.viewData.isLoading, isTrue);
    expect(controller.viewData.operationKind, 'confirming_selection');
    expect(controller.viewData.status, '正在写入拆书预演纪要...');
    expect(
      controller.viewData.selectedItemCount,
      selectedItemCountBeforeCommit,
    );
    expect(controller.viewData.selectedTargetWritingTypeId, 'novel');
    expect(controller.viewData.inheritAsLiveNarrative, isFalse);
    expect(backRequested, isFalse);

    blockingConfirmation.complete();
    await confirmation;

    expect(controller.viewData.isLoading, isFalse);
    expect(
      controller.viewData.confirmedPreviewPath,
      'analysis/book_deconstruction_preview.md',
    );
    controller.dispose();
  });

  test('重开时沿用同一分章 extraction id，并忽略旧分章的确认 journal', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const currentProject = ProjectDescriptor(
      id: 'project-recovery-extraction-id',
      name: '提取 ID 恢复测试',
      rootPath: 'D:/Projects/deconstruction_recovery_extraction_id',
      projectType: 'novel',
    );
    BookDeconstructionController createController(
      _BlockingBookDeconstructionDraftBuilderService builder,
    ) {
      return BookDeconstructionController(
        readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
        writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
          projectWorkspacePort: workspacePort,
        ),
        narrativePersistenceService:
            BookDeconstructionNarrativePersistenceService(
              workspacePort: workspacePort,
            ),
        readCurrentProject: () => currentProject,
        syncWorkbenchResources: () async {},
        onBackRequested: () {},
        readImportAssistantModelOptions: _modelOptions,
        draftBuilderService: builder,
      );
    }

    final initialBuilder = _BlockingBookDeconstructionDraftBuilderService();
    final firstController = createController(initialBuilder);
    await firstController.initialize();
    firstController.onBookDeconstructionSourceContentChanged(
      '第一章 雾港\n用于验证重开恢复的分章身份。',
    );
    final split = firstController.onBookDeconstructionSplitRequested();
    await initialBuilder.started.future;
    initialBuilder.complete();
    await split;
    final splitExtractionId = initialBuilder.producedExtractionId;
    expect(splitExtractionId, isNotEmpty);

    const journalService = BookDeconstructionConfirmationJournalService();
    await workspacePort.writeTextFile(
      currentProject.rootPath,
      BookDeconstructionConfirmationJournalService.relativePath,
      journalService.completed(
        confirmationId: 'old-extraction-confirmation',
        extractionId: 'old-extraction-id',
        targetWritingProjectTypeId: 'novel',
        targetRuntimeBaselineId: '',
        selectedItemIds: const <String>{},
        inheritAsLiveNarrative: false,
        completedSteps: const <String>['preview'],
        changedPaths: const <String>['analysis/stale_preview.md'],
        chapterPaths: const <String>[],
        projectTypeTransitioned: false,
        previewPath: 'analysis/stale_preview.md',
      ),
    );
    firstController.dispose();

    final recoveryBuilder = _BlockingBookDeconstructionDraftBuilderService();
    final recoveredController = createController(recoveryBuilder);
    final recovery = recoveredController.initialize();
    await recoveryBuilder.started.future;
    expect(recoveryBuilder.requestedExtractionId, splitExtractionId);
    recoveryBuilder.complete();
    await recovery;

    expect(recoveredController.viewData.planGroups, isNotEmpty);
    expect(recoveredController.viewData.confirmedPreviewPath, isEmpty);
    recoveredController.dispose();
  });

  test('重新打开项目会恢复完整拆书上下文和确认状态', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const currentProject = ProjectDescriptor(
      id: 'project-recovery',
      name: '恢复测试',
      rootPath: 'D:/Projects/deconstruction_recovery',
      projectType: 'long_novel',
      runtimeBaselineId: 'continuous_autonomous',
    );
    var analysisCalls = 0;
    BookDeconstructionController createController() {
      return BookDeconstructionController(
        readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
        writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
          projectWorkspacePort: workspacePort,
        ),
        narrativePersistenceService:
            BookDeconstructionNarrativePersistenceService(
              workspacePort: workspacePort,
            ),
        readCurrentProject: () => currentProject,
        syncWorkbenchResources: () async {},
        onBackRequested: () {},
        readImportAssistantModelOptions: _modelOptions,
        extractKnowledgeHandler:
            (
              project, {
              required String providerId,
              required String modelId,
            }) async {
              analysisCalls += 1;
              return const ProjectReferenceExtractionExecutionResult(
                ok: true,
                didMutateProject: false,
                statusMessage: '恢复测试分析完成',
                runId: 'recovery-analysis-run',
                packageId: 'recovery-analysis-package',
                packageVersionId: 'recovery-analysis-version',
              );
            },
      );
    }

    final firstController = createController();
    await firstController.initialize();
    firstController.onBookDeconstructionSourceTitleChanged('可恢复的原文');
    firstController.onBookDeconstructionSourceContentChanged(
      '第一章 回航\n这是保存在恢复状态中的正文。',
    );
    await firstController.onBookDeconstructionSplitRequested();
    final selectedItemId = firstController.viewData.planGroups
        .expand((group) => group.items)
        .last
        .id;
    firstController.onBookDeconstructionClearSelectionRequested();
    firstController.onBookDeconstructionPlanItemSelectionChanged(
      itemId: selectedItemId,
      selected: true,
    );
    firstController.onBookDeconstructionFollowupOptionSelected(
      'continuation_novel',
    );
    firstController.onBookDeconstructionTargetWritingTypeSelected('long_novel');
    firstController.onBookDeconstructionTargetRuntimeBaselineSelected(
      'continuous_autonomous',
    );
    firstController.onBookDeconstructionInheritAsLiveNarrativeChanged(true);
    firstController.onBookDeconstructionAnalysisUseModelChanged(true);
    firstController.onBookDeconstructionAnalysisModelSelected(_splitModelKey);
    await firstController.onBookDeconstructionAnalysisRequested();
    await firstController.onBookDeconstructionConfirmRequested();
    firstController.dispose();

    final recoveredController = createController();
    await recoveredController.initialize();

    expect(recoveredController.viewData.sourceTitle, '可恢复的原文');
    expect(recoveredController.viewData.sourceContent, contains('第一章 回航'));
    expect(recoveredController.viewData.planGroups, isNotEmpty);
    expect(recoveredController.viewData.selectedItemCount, 1);
    expect(
      recoveredController.viewData.selectedFollowupOptionId,
      'continuation_novel',
    );
    expect(
      recoveredController.viewData.selectedTargetWritingTypeId,
      'long_novel',
    );
    expect(
      recoveredController.viewData.selectedTargetRuntimeBaselineId,
      'continuous_autonomous',
    );
    expect(recoveredController.viewData.inheritAsLiveNarrative, isTrue);
    expect(recoveredController.viewData.analysisCompleted, isTrue);
    expect(recoveredController.viewData.hasStagedAnalysis, isTrue);
    expect(recoveredController.viewData.applyStagedAnalysisResults, isFalse);
    expect(
      recoveredController.viewData.analysisStagingRunId,
      'recovery-analysis-run',
    );
    expect(
      recoveredController.viewData.analysisStagingPackageId,
      'recovery-analysis-package',
    );
    expect(
      recoveredController.viewData.analysisStagingPackageVersionId,
      'recovery-analysis-version',
    );
    expect(
      recoveredController.viewData.confirmedPreviewPath,
      'analysis/book_deconstruction_preview.md',
    );
    expect(recoveredController.viewData.activeStepId, 'confirm_selection');
    expect(recoveredController.viewData.canConfirmSelection, isTrue);
    expect(recoveredController.viewData.status, contains('已恢复已确认的拆书结果'));
    expect(analysisCalls, 1);
    recoveredController.dispose();
  });

  test('重开后可直接确认已恢复的分章结果，无需重新拆书', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const currentProject = ProjectDescriptor(
      id: 'project-recovery-confirm',
      name: '恢复后确认测试',
      rootPath: 'D:/Projects/deconstruction_recovery_confirm',
      projectType: 'novel',
    );
    BookDeconstructionController createController() {
      return BookDeconstructionController(
        readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
        writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
          projectWorkspacePort: workspacePort,
        ),
        narrativePersistenceService:
            BookDeconstructionNarrativePersistenceService(
              workspacePort: workspacePort,
            ),
        readCurrentProject: () => currentProject,
        syncWorkbenchResources: () async {},
        onBackRequested: () {},
        readImportAssistantModelOptions: _modelOptions,
        extractKnowledgeHandler:
            (
              project, {
              required String providerId,
              required String modelId,
            }) async {
              return const ProjectReferenceExtractionExecutionResult(
                ok: true,
                didMutateProject: false,
                statusMessage: '用于等待恢复状态落盘',
                runId: 'recovery-confirm-run',
                packageId: 'recovery-confirm-package',
                packageVersionId: 'recovery-confirm-version',
              );
            },
      );
    }

    final firstController = createController();
    await firstController.initialize();
    firstController.onBookDeconstructionSourceContentChanged(
      '第一章 灯塔\n拆书恢复后应直接可确认。',
    );
    await firstController.onBookDeconstructionSplitRequested();
    final selectedItemId =
        firstController.viewData.planGroups.first.items.first.id;
    firstController.onBookDeconstructionClearSelectionRequested();
    firstController.onBookDeconstructionPlanItemSelectionChanged(
      itemId: selectedItemId,
      selected: true,
    );
    firstController.onBookDeconstructionTargetWritingTypeSelected('novel');
    firstController.onBookDeconstructionAnalysisUseModelChanged(true);
    firstController.onBookDeconstructionAnalysisModelSelected(_splitModelKey);
    await firstController.onBookDeconstructionAnalysisRequested();
    firstController.dispose();

    final recoveredController = createController();
    await recoveredController.initialize();

    expect(recoveredController.viewData.planGroups, isNotEmpty);
    expect(recoveredController.viewData.canConfirmSelection, isTrue);
    expect(recoveredController.viewData.confirmedPreviewPath, isEmpty);
    await recoveredController.onBookDeconstructionConfirmRequested();
    expect(
      recoveredController.viewData.confirmedPreviewPath,
      'analysis/book_deconstruction_preview.md',
    );
    recoveredController.dispose();
  });

  test('粘贴源文只在启动拆书时归档，并写入 SQLite source_original 主事实源', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'book_deconstruction_pasted_source_sqlite_test_',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });
    final projectRoot = Directory(
      '${tempDirectory.path}${Platform.pathSeparator}project',
    );
    await projectRoot.create();
    final project = ProjectDescriptor(
      id: 'project-pasted-source-sqlite',
      name: '粘贴源文 SQLite 测试',
      rootPath: projectRoot.path,
      projectType: 'book_deconstruction',
      storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
    );
    final workspacePort = LocalProjectWorkspacePort();
    final controller = BookDeconstructionController(
      readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
      writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
        projectWorkspacePort: workspacePort,
      ),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
      readCurrentProject: () => project,
      syncWorkbenchResources: () async {},
      onBackRequested: () {},
      readImportAssistantModelOptions: _modelOptions,
    );
    const sourceContent = '\n第一章 港口风暴\n主角在港口被迫卷入一场追捕。\n';
    final archivePath = const BookDeconstructionTargetPathService()
        .sourceArchivePath(
          'pasted_book_deconstruction_source.md',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        );
    final archiveFile = File(
      '${project.rootPath}${Platform.pathSeparator}${archivePath.replaceAll('/', Platform.pathSeparator)}',
    );

    await controller.initialize();
    controller.onBookDeconstructionSourceTitleChanged('粘贴原文');
    controller.onBookDeconstructionSourceContentChanged(sourceContent);
    expect(await archiveFile.exists(), isFalse);

    await controller.onBookDeconstructionSplitRequested();

    expect(await archiveFile.readAsString(), sourceContent);
    expect(
      await ProjectStructuredContentBridgeService().readProjectedBodyText(
        project,
        archivePath,
      ),
      sourceContent,
    );
    controller.dispose();
  });

  test('复合写作项目默认保留当前类型作为确认目标', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    final projects = <ProjectDescriptor>[
      const ProjectDescriptor(
        id: 'project-composite-novel',
        name: '复合普通小说拆书项目',
        rootPath: 'D:/Projects/composite_novel_deconstruction',
        projectType: 'novel',
        additionalTraitIds: <String>['book_deconstruction'],
      ),
      const ProjectDescriptor(
        id: 'project-composite-long-novel',
        name: '复合长篇拆书项目',
        rootPath: 'D:/Projects/composite_long_novel_deconstruction',
        projectType: 'long_novel',
        runtimeBaselineId: 'continuous_autonomous',
        additionalTraitIds: <String>['book_deconstruction'],
      ),
    ];

    for (final project in projects) {
      final controller = BookDeconstructionController(
        readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
        writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
          projectWorkspacePort: workspacePort,
        ),
        narrativePersistenceService:
            BookDeconstructionNarrativePersistenceService(
              workspacePort: workspacePort,
            ),
        readCurrentProject: () => project,
        syncWorkbenchResources: () async {},
        onBackRequested: () {},
        readImportAssistantModelOptions: _modelOptions,
      );

      await controller.initialize();

      expect(
        controller.viewData.targetWritingTypeOptions.map((option) => option.id),
        contains(project.projectType),
      );
      expect(
        controller.viewData.selectedTargetWritingTypeId,
        project.projectType,
      );
      if (project.projectType == 'long_novel') {
        expect(
          controller.viewData.selectedTargetRuntimeBaselineId,
          'continuous_autonomous',
        );
        expect(controller.viewData.canSelectTargetRuntimeBaseline, isFalse);
        controller.onBookDeconstructionTargetRuntimeBaselineSelected(
          'chapter_collaboration_autorun',
        );
        expect(
          controller.viewData.selectedTargetRuntimeBaselineId,
          'continuous_autonomous',
        );
      }
      controller.dispose();
    }
  });

  test('SQLite 粘贴源文先写主事实源，再完成归档投影', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const project = ProjectDescriptor(
      id: 'project-pasted-source-cancel-boundary',
      name: '粘贴归档取消边界测试',
      rootPath: 'D:/Projects/pasted_source_cancel_boundary',
      projectType: 'book_deconstruction',
      storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
    );
    final archivePath = const BookDeconstructionTargetPathService()
        .sourceArchivePath(
          'pasted_book_deconstruction_source.md',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        );
    final events = <String>[];
    final writer = _BlockingArchiveWriteProjectTextFileUseCase(
      workspacePort: workspacePort,
      archivePath: archivePath,
      events: events,
    );
    final structuredContentBridge = _RecordingSourceArchiveBridgeService(
      events: events,
    );
    final controller = BookDeconstructionController(
      readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
      writeProjectTextFileUseCase: writer,
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
      readCurrentProject: () => project,
      syncWorkbenchResources: () async {},
      onBackRequested: () {},
      readImportAssistantModelOptions: _modelOptions,
      structuredContentBridgeService: structuredContentBridge,
    );
    const sourceContent = '第一章 港口风暴\n主角在港口被迫卷入一场追捕。';

    await controller.initialize();
    controller.onBookDeconstructionSourceContentChanged(sourceContent);
    final split = controller.onBookDeconstructionSplitRequested();
    await writer.archiveProjectionWritten.future;

    controller.onBookDeconstructionCancelRequested();
    writer.releaseArchiveCommit();
    await split;

    expect(
      workspacePort.readStoredTextFile(project.rootPath, archivePath),
      sourceContent,
    );
    expect(structuredContentBridge.persistedSourceArchiveCount, 1);
    expect(structuredContentBridge.lastSourceContent, sourceContent);
    expect(events, <String>['sqlite:$archivePath', 'projection:$archivePath']);
    expect(
      workspacePort.readStoredTextFile(
        project.rootPath,
        'analysis/book_deconstruction_structured_source.md',
      ),
      isNull,
    );
    controller.dispose();
  });
}

class _BlockingBookDeconstructionDraftBuilderService
    extends BookDeconstructionDraftBuilderService {
  final Completer<void> started = Completer<void>();
  final Completer<BookDeconstructionDraftBuildResult> _result =
      Completer<BookDeconstructionDraftBuildResult>();
  String _sourceTitle = '';
  String _sourceContent = '';
  String _sourceAbsolutePath = '';
  String _extractionId = '';
  String _producedExtractionId = '';
  ProjectStorageStrategy _storageStrategy =
      ProjectStorageStrategy.markdownProjectStore;
  BookDeconstructionContinuationDirection _preferredContinuationDirection =
      BookDeconstructionContinuationDirection.analysisFirst;
  bool _extractKnowledge = true;

  String get requestedExtractionId => _extractionId;
  String get producedExtractionId => _producedExtractionId;

  @override
  Future<BookDeconstructionDraftBuildResult> build({
    required String sourceTitle,
    required String sourceContent,
    required String sourceAbsolutePath,
    ProjectStorageStrategy storageStrategy =
        ProjectStorageStrategy.markdownProjectStore,
    String operatorNotes = '',
    String styleSummary = '',
    String worldRulesText = '',
    String characterLinesText = '',
    String organizationLinesText = '',
    String extractionId = '',
    BookDeconstructionContinuationDirection preferredContinuationDirection =
        BookDeconstructionContinuationDirection.analysisFirst,
    bool extractKnowledge = true,
  }) {
    _sourceTitle = sourceTitle;
    _sourceContent = sourceContent;
    _sourceAbsolutePath = sourceAbsolutePath;
    _storageStrategy = storageStrategy;
    _extractionId = extractionId;
    _preferredContinuationDirection = preferredContinuationDirection;
    _extractKnowledge = extractKnowledge;
    if (!started.isCompleted) {
      started.complete();
    }
    return _result.future;
  }

  void complete() {
    final result = BuildBookDeconstructionDraftUseCase().execute(
      sourceTitle: _sourceTitle,
      sourceContent: _sourceContent,
      sourceAbsolutePath: _sourceAbsolutePath,
      storageStrategy: _storageStrategy,
      extractionId: _extractionId,
      preferredContinuationDirection: _preferredContinuationDirection,
      extractKnowledge: _extractKnowledge,
    );
    _producedExtractionId = result.extractionResult.extractionId;
    _result.complete(result);
  }
}

class _BlockingBookDeconstructionConfirmWorkflowService
    extends BookDeconstructionConfirmWorkflowService {
  _BlockingBookDeconstructionConfirmWorkflowService(
    ProjectWorkspacePort workspacePort,
  ) : super(
        writeProjectTextFileUseCase: WriteProjectTextFileUseCase(
          projectWorkspacePort: workspacePort,
        ),
        narrativePersistenceService:
            BookDeconstructionNarrativePersistenceService(
              workspacePort: workspacePort,
            ),
      );

  final Completer<void> started = Completer<void>();
  final Completer<BookDeconstructionConfirmWorkflowResult> _result =
      Completer<BookDeconstructionConfirmWorkflowResult>();

  @override
  Future<BookDeconstructionConfirmWorkflowResult> execute({
    required ProjectDescriptor project,
    required BookDeconstructionDraftBuildResult buildResult,
    required Set<String> selectedItemIds,
    required String targetWritingProjectTypeId,
    String targetRuntimeBaselineId = '',
    required bool inheritAsLiveNarrative,
    bool applyStagedAnalysisResults = false,
    String stagedAnalysisRunId = '',
    String stagedAnalysisPackageId = '',
    String stagedAnalysisPackageVersionId = '',
  }) {
    if (!started.isCompleted) {
      started.complete();
    }
    return _result.future;
  }

  void complete() {
    _result.complete(
      const BookDeconstructionConfirmWorkflowResult(
        previewPath: 'analysis/book_deconstruction_preview.md',
        targetWritingProjectTypeId: 'novel',
        targetRuntimeBaselineId: '',
        projectTypeTransitioned: false,
        chapterPaths: <String>[],
        changedPaths: <String>['analysis/book_deconstruction_preview.md'],
      ),
    );
  }
}

class _BlockingArchiveWriteProjectTextFileUseCase
    extends WriteProjectTextFileUseCase {
  _BlockingArchiveWriteProjectTextFileUseCase({
    required ProjectWorkspacePort workspacePort,
    required this.archivePath,
    this.events,
  }) : super(projectWorkspacePort: workspacePort);

  final String archivePath;
  final List<String>? events;
  final Completer<void> archiveProjectionWritten = Completer<void>();
  final Completer<void> _archiveCommitReleased = Completer<void>();

  @override
  Future<void> execute({
    required ProjectDescriptor project,
    required String relativePath,
    required String content,
  }) async {
    await super.execute(
      project: project,
      relativePath: relativePath,
      content: content,
    );
    if (relativePath == archivePath && !archiveProjectionWritten.isCompleted) {
      events?.add('projection:$relativePath');
      archiveProjectionWritten.complete();
      await _archiveCommitReleased.future;
    }
  }

  void releaseArchiveCommit() {
    if (!_archiveCommitReleased.isCompleted) {
      _archiveCommitReleased.complete();
    }
  }
}

class _RecordingSourceArchiveBridgeService
    extends ProjectStructuredContentBridgeService {
  _RecordingSourceArchiveBridgeService({this.events});

  final List<String>? events;
  int persistedSourceArchiveCount = 0;
  String lastSourceContent = '';

  @override
  Future<void> persistSourceOriginalArchive({
    required ProjectDescriptor project,
    required String archivePath,
    required String archiveTitle,
    required String sourceContent,
    String statePath = '',
  }) async {
    persistedSourceArchiveCount += 1;
    lastSourceContent = sourceContent;
    events?.add('sqlite:$archivePath');
  }
}

class _FakeDesktopBookDeconstructionSourcePickerService
    extends DesktopBookDeconstructionSourcePickerService {
  _FakeDesktopBookDeconstructionSourcePickerService(this._sourceFilePath);

  final String _sourceFilePath;

  @override
  Future<String?> pickSourceFile() async {
    return _sourceFilePath;
  }
}

class _InMemoryProjectWorkspacePort implements ProjectWorkspacePort {
  final Map<String, String> _files = <String, String>{};
  int syncCount = 0;

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
