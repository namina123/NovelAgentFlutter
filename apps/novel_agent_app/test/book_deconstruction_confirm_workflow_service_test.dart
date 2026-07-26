import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_confirmation_journal_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_confirm_workflow_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_narrative_persistence_service.dart';
import 'package:novel_agent_app/features/book_deconstruction/application/services/book_deconstruction_staged_analysis_promotion_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('只勾选的分章才写进正文 chapters/，预演纪要与 narrative 资产落盘', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const project = ProjectDescriptor(
      id: 'project-1',
      name: '拆书测试项目',
      rootPath: 'D:/Projects/deconstruction_project',
      projectType: 'book_deconstruction',
    );
    final useCase = BuildBookDeconstructionDraftUseCase();
    final buildResult = useCase.execute(
      sourceTitle: '海上城邦',
      sourceContent: '第一章 港口风暴\n主角在港口被迫卷入一场追捕。\n\n第二章 议会阴影\n城邦议会开始浮出水面。',
      sourceAbsolutePath: 'D:/Books/source_book.md',
      operatorNotes: '注意城邦议会与航线规则的象征关系。',
      styleSummary: '叙事节奏快，善于用港口意象制造压迫感。',
      worldRulesText: '航线印记绑定了贸易权力与超常能力',
      characterLinesText: '林砚：被迫卷入城邦风暴的主角',
      organizationLinesText: '议会：海上城邦的最高权力结构',
    );
    final service = BookDeconstructionConfirmWorkflowService(
      writeProjectTextFileUseCase: _writeUseCase(workspacePort),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
      readProjectFileUseCase: ReadProjectFileUseCase(workspacePort),
      projectTypeTransitionUseCase: _transitionUseCase(workspacePort),
    );

    final selectedChapterItem = buildResult.applicationPlan.items.firstWhere(
      (item) =>
          item.sourceKind == BookDeconstructionArtifactKind.chapterOutline,
    );
    final result = await service.execute(
      project: project,
      buildResult: buildResult,
      selectedItemIds: <String>{selectedChapterItem.id},
      targetWritingProjectTypeId: 'novel',
      inheritAsLiveNarrative: true,
    );

    expect(result.previewPath, 'analysis/book_deconstruction_preview.md');
    expect(result.targetWritingProjectTypeId, 'novel');
    expect(result.projectTypeTransitioned, isTrue);
    // 续写开关开启 → 仅被勾选的第一章写进正文 chapters/。
    expect(result.chapterPaths, hasLength(1));
    expect(
      result.chapterPaths.every((path) => path.startsWith('chapters/')),
      isTrue,
    );
    expect(
      workspacePort.readStoredTextFile(project.rootPath, result.previewPath),
      contains('# 拆书结构化预演'),
    );
    expect(
      workspacePort.readStoredTextFile(
        project.rootPath,
        '.novel_agent/continuity/claims/claims.jsonl',
      ),
      contains('analysis.deconstruction.chapter_outline'),
    );
    expect(
      workspacePort.readStoredTextFile(
        project.rootPath,
        '.novel_agent/continuity/claims/claims.jsonl',
      ),
      isNot(contains('analysis.deconstruction.story_outline')),
    );
    expect(
      workspacePort.readStoredTextFile(
        project.rootPath,
        const BookDeconstructionTargetPathService().liveChapterPath(
          sequence: 2,
          title: '第二章 议会阴影',
        ),
      ),
      isNull,
    );
    final journal = workspacePort.readStoredTextFile(
      project.rootPath,
      '.novel_agent/state/book_deconstruction/confirmation.json',
    );
    expect(
      journal,
      allOf(
        contains('"status": "completed"'),
        contains(result.previewPath),
        contains(selectedChapterItem.id),
      ),
    );
    final claimsBeforeRetry = workspacePort.readStoredTextFile(
      project.rootPath,
      '.novel_agent/continuity/claims/claims.jsonl',
    );
    final retried = await service.execute(
      project: project,
      buildResult: buildResult,
      selectedItemIds: <String>{selectedChapterItem.id},
      targetWritingProjectTypeId: 'novel',
      inheritAsLiveNarrative: true,
    );
    expect(retried.previewPath, result.previewPath);
    expect(
      workspacePort.readStoredTextFile(
        project.rootPath,
        '.novel_agent/continuity/claims/claims.jsonl',
      ),
      claimsBeforeRetry,
    );
  });

  test('目标为 long_novel 但未选运行基准时不发生任何确认写入', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const project = ProjectDescriptor(
      id: 'project-guard',
      name: '拆书测试项目',
      rootPath: 'D:/Projects/deconstruction_project_guard',
      projectType: 'book_deconstruction',
    );
    final buildResult = BuildBookDeconstructionDraftUseCase().execute(
      sourceTitle: '海上城邦',
      sourceContent: '第一章 港口风暴\n主角在港口被迫卷入一场追捕。',
      sourceAbsolutePath: 'D:/Books/source_book.md',
      extractKnowledge: false,
    );
    final service = BookDeconstructionConfirmWorkflowService(
      writeProjectTextFileUseCase: _writeUseCase(workspacePort),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
    );

    await expectLater(
      () => service.execute(
        project: project,
        buildResult: buildResult,
        selectedItemIds: buildResult.applicationPlan.items
            .map((item) => item.id)
            .toSet(),
        targetWritingProjectTypeId: 'long_novel',
        inheritAsLiveNarrative: true,
      ),
      throwsA(isA<StateError>()),
    );

    expect(
      workspacePort.readStoredTextFile(
        project.rootPath,
        'analysis/book_deconstruction_preview.md',
      ),
      isNull,
    );
  });

  test('同类型 long_novel 未配置运行基准时也会在确认写入前被拒绝', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const project = ProjectDescriptor(
      id: 'project-same-type-long-novel-guard',
      name: '复合长篇拆书项目',
      rootPath: 'D:/Projects/deconstruction_same_type_long_novel_guard',
      projectType: 'long_novel',
      additionalTraitIds: <String>['book_deconstruction'],
    );
    final buildResult = BuildBookDeconstructionDraftUseCase().execute(
      sourceTitle: '海上城邦',
      sourceContent: '第一章 港口风暴\n主角在港口被迫卷入一场追捕。',
      sourceAbsolutePath: 'D:/Books/source_book.md',
      extractKnowledge: false,
    );
    final service = BookDeconstructionConfirmWorkflowService(
      writeProjectTextFileUseCase: _writeUseCase(workspacePort),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
    );

    await expectLater(
      () => service.execute(
        project: project,
        buildResult: buildResult,
        selectedItemIds: buildResult.applicationPlan.items
            .map((item) => item.id)
            .toSet(),
        targetWritingProjectTypeId: 'long_novel',
        inheritAsLiveNarrative: true,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          contains('运行基准'),
        ),
      ),
    );
    await expectLater(
      () => service.execute(
        project: project,
        buildResult: buildResult,
        selectedItemIds: buildResult.applicationPlan.items
            .map((item) => item.id)
            .toSet(),
        targetWritingProjectTypeId: 'long_novel',
        targetRuntimeBaselineId: 'continuous_autonomous',
        inheritAsLiveNarrative: true,
      ),
      throwsA(isA<StateError>()),
    );

    expect(
      workspacePort.readStoredTextFile(
        project.rootPath,
        'analysis/book_deconstruction_preview.md',
      ),
      isNull,
    );
    expect(
      workspacePort.readStoredTextFile(
        project.rootPath,
        BookDeconstructionConfirmationJournalService.relativePath,
      ),
      isNull,
    );
  });

  test('活跃长任务会在确认写入前阻断复合长篇回切', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const project = ProjectDescriptor(
      id: 'project-active-long-task-confirm-guard',
      name: '复合长篇拆书项目',
      rootPath: 'D:/Projects/deconstruction_active_long_task_guard',
      projectType: 'long_novel',
      runtimeBaselineId: 'continuous_autonomous',
      additionalTraitIds: <String>['book_deconstruction'],
    );
    final buildResult = BuildBookDeconstructionDraftUseCase().execute(
      sourceTitle: '海上城邦',
      sourceContent: '第一章 港口风暴\n主角在港口被迫卷入一场追捕。',
      sourceAbsolutePath: 'D:/Books/source_book.md',
      extractKnowledge: false,
    );
    final service = BookDeconstructionConfirmWorkflowService(
      writeProjectTextFileUseCase: _writeUseCase(workspacePort),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
      projectTypeTransitionUseCase: ExecuteProjectTypeTransitionUseCase(
        projectTypeTransitionPreparationService:
            const ProjectTypeTransitionPreparationService(),
        writeProjectTextFileUseCase: _writeUseCase(workspacePort),
        readHasActiveLongTaskRun: (_) async => true,
      ),
    );

    await expectLater(
      service.execute(
        project: project,
        buildResult: buildResult,
        selectedItemIds: buildResult.applicationPlan.items
            .map((item) => item.id)
            .toSet(),
        targetWritingProjectTypeId: 'novel',
        inheritAsLiveNarrative: true,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'message',
          contains('归档'),
        ),
      ),
    );

    expect(workspacePort.storedFileCount, 0);
  });

  test('同类型 long_novel 复用项目运行基准且不执行类型转换', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const project = ProjectDescriptor(
      id: 'project-same-type-long-novel',
      name: '复合长篇拆书项目',
      rootPath: 'D:/Projects/deconstruction_same_type_long_novel',
      projectType: 'long_novel',
      runtimeBaselineId: 'continuous_autonomous',
      additionalTraitIds: <String>['book_deconstruction'],
    );
    final buildResult = BuildBookDeconstructionDraftUseCase().execute(
      sourceTitle: '海上城邦',
      sourceContent: '第一章 港口风暴\n主角在港口被迫卷入一场追捕。',
      sourceAbsolutePath: 'D:/Books/source_book.md',
      extractKnowledge: false,
    );
    final service = BookDeconstructionConfirmWorkflowService(
      writeProjectTextFileUseCase: _writeUseCase(workspacePort),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
    );

    final result = await service.execute(
      project: project,
      buildResult: buildResult,
      selectedItemIds: buildResult.applicationPlan.items
          .map((item) => item.id)
          .toSet(),
      targetWritingProjectTypeId: 'long_novel',
      inheritAsLiveNarrative: true,
    );

    expect(result.targetRuntimeBaselineId, 'continuous_autonomous');
    expect(result.projectTypeTransitioned, isFalse);
  });

  test('同类型 long_novel 改选运行基准会在确认写入前被拒绝', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const project = ProjectDescriptor(
      id: 'project-same-type-long-novel-baseline-guard',
      name: '复合长篇拆书项目',
      rootPath:
          'D:/Projects/deconstruction_same_type_long_novel_baseline_guard',
      projectType: 'long_novel',
      runtimeBaselineId: 'continuous_autonomous',
      additionalTraitIds: <String>['book_deconstruction'],
    );
    final buildResult = BuildBookDeconstructionDraftUseCase().execute(
      sourceTitle: '海上城邦',
      sourceContent: '第一章 港口风暴\n主角在港口被迫卷入一场追捕。',
      sourceAbsolutePath: 'D:/Books/source_book.md',
      extractKnowledge: false,
    );
    final service = BookDeconstructionConfirmWorkflowService(
      writeProjectTextFileUseCase: _writeUseCase(workspacePort),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
    );

    await expectLater(
      service.execute(
        project: project,
        buildResult: buildResult,
        selectedItemIds: buildResult.applicationPlan.items
            .map((item) => item.id)
            .toSet(),
        targetWritingProjectTypeId: 'long_novel',
        targetRuntimeBaselineId: 'chapter_collaboration_autorun',
        inheritAsLiveNarrative: true,
      ),
      throwsA(isA<StateError>()),
    );

    expect(
      workspacePort.readStoredTextFile(
        project.rootPath,
        'analysis/book_deconstruction_preview.md',
      ),
      isNull,
    );
    expect(
      workspacePort.readStoredTextFile(
        project.rootPath,
        BookDeconstructionConfirmationJournalService.relativePath,
      ),
      isNull,
    );
  });

  test('续写开关关闭：分章写进资源 analysis/，不污染正文', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    const project = ProjectDescriptor(
      id: 'project-2',
      name: '拆书测试项目',
      rootPath: 'D:/Projects/deconstruction_project_resource',
      projectType: 'book_deconstruction',
    );
    final useCase = BuildBookDeconstructionDraftUseCase();
    final buildResult = useCase.execute(
      sourceTitle: '海上城邦',
      sourceContent: '第一章 港口风暴\n主角在港口被迫卷入一场追捕。\n\n第二章 议会阴影\n城邦议会开始浮出水面。',
      sourceAbsolutePath: 'D:/Books/source_book.md',
      operatorNotes: '非续写场景，分章作为参考资料。',
      styleSummary: '叙事节奏快。',
      worldRulesText: '航线印记绑定贸易权力',
      characterLinesText: '林砚：主角',
      organizationLinesText: '议会：权力结构',
    );
    final service = BookDeconstructionConfirmWorkflowService(
      writeProjectTextFileUseCase: _writeUseCase(workspacePort),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
      projectTypeTransitionUseCase: _transitionUseCase(workspacePort),
    );

    final result = await service.execute(
      project: project,
      buildResult: buildResult,
      selectedItemIds: buildResult.applicationPlan.items
          .map((item) => item.id)
          .toSet(),
      targetWritingProjectTypeId: 'novel',
      inheritAsLiveNarrative: false,
    );

    // 续写开关关闭 → 分章写进资源 analysis/，不进正文。
    expect(result.chapterPaths, isNotEmpty);
    expect(
      result.chapterPaths.every((path) => path.startsWith('analysis/')),
      isTrue,
    );
  });

  test('写入中断时 journal 记录可能部分完成的步骤，供重开后恢复', () async {
    final workspacePort = _InMemoryProjectWorkspacePort(
      failOnceForRelativePath:
          'analysis/book_deconstruction_structured_source.md',
    );
    const project = ProjectDescriptor(
      id: 'project-failed-confirmation',
      name: '拆书确认失败测试',
      rootPath: 'D:/Projects/deconstruction_failed_confirmation',
      projectType: 'book_deconstruction',
    );
    final buildResult = BuildBookDeconstructionDraftUseCase().execute(
      sourceTitle: '海上城邦',
      sourceContent: '第一章 港口风暴\n主角在港口被迫卷入一场追捕。',
      sourceAbsolutePath: 'D:/Books/source_book.md',
      extractKnowledge: false,
    );
    final service = BookDeconstructionConfirmWorkflowService(
      writeProjectTextFileUseCase: _writeUseCase(workspacePort),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
      projectTypeTransitionUseCase: _transitionUseCase(workspacePort),
    );

    await expectLater(
      service.execute(
        project: project,
        buildResult: buildResult,
        selectedItemIds: buildResult.applicationPlan.items
            .map((item) => item.id)
            .toSet(),
        targetWritingProjectTypeId: 'novel',
        inheritAsLiveNarrative: false,
      ),
      throwsA(isA<StateError>()),
    );

    final journal = workspacePort.readStoredTextFile(
      project.rootPath,
      '.novel_agent/state/book_deconstruction/confirmation.json',
    );
    expect(
      journal,
      allOf(
        contains('"status": "failed"'),
        contains('"current_step": "write_structured_source"'),
        contains('analysis/book_deconstruction_preview.md'),
      ),
    );
  });

  test('默认不应用步骤③暂存分析结果，也不会调用推广服务', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    final promotionService = _RecordingStagedAnalysisPromotionService();
    const project = ProjectDescriptor(
      id: 'project-staged-analysis-default',
      name: '默认不应用暂存分析',
      rootPath: 'D:/Projects/deconstruction_staged_analysis_default',
      projectType: 'novel',
    );
    final buildResult = _buildResult();
    final service = BookDeconstructionConfirmWorkflowService(
      writeProjectTextFileUseCase: _writeUseCase(workspacePort),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
      stagedAnalysisPromotionService: promotionService,
    );

    final result = await service.execute(
      project: project,
      buildResult: buildResult,
      selectedItemIds: buildResult.applicationPlan.items
          .map((item) => item.id)
          .toSet(),
      targetWritingProjectTypeId: 'novel',
      inheritAsLiveNarrative: false,
    );

    expect(promotionService.validationCount, 0);
    expect(promotionService.promotionCount, 0);
    expect(result.stagedAnalysisApplied, isFalse);
    final journal = workspacePort.readStoredTextFile(
      project.rootPath,
      BookDeconstructionConfirmationJournalService.relativePath,
    );
    expect(journal, contains('"apply_staged_analysis_results": false'));
  });

  test('显式选择后才推广精确的暂存分析包并记录确认 journal', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    final promotionService = _RecordingStagedAnalysisPromotionService();
    const project = ProjectDescriptor(
      id: 'project-staged-analysis-apply',
      name: '应用暂存分析',
      rootPath: 'D:/Projects/deconstruction_staged_analysis_apply',
      projectType: 'novel',
    );
    final buildResult = _buildResult();
    final service = BookDeconstructionConfirmWorkflowService(
      writeProjectTextFileUseCase: _writeUseCase(workspacePort),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
      stagedAnalysisPromotionService: promotionService,
    );

    final result = await service.execute(
      project: project,
      buildResult: buildResult,
      selectedItemIds: buildResult.applicationPlan.items
          .map((item) => item.id)
          .toSet(),
      targetWritingProjectTypeId: 'novel',
      inheritAsLiveNarrative: false,
      applyStagedAnalysisResults: true,
      stagedAnalysisRunId: 'staged-run-1',
      stagedAnalysisPackageId: 'staged-package-1',
      stagedAnalysisPackageVersionId: 'staged-version-1',
    );

    expect(promotionService.validationCount, 1);
    expect(promotionService.promotionCount, 1);
    expect(promotionService.lastRunId, 'staged-run-1');
    expect(promotionService.lastPackageId, 'staged-package-1');
    expect(promotionService.lastPackageVersionId, 'staged-version-1');
    expect(result.stagedAnalysisApplied, isTrue);
    expect(result.stagedAnalysisMountStatus, 'applied');
    expect(result.changedPaths, contains('knowledge/staged-analysis.md'));
    final journal = workspacePort.readStoredTextFile(
      project.rootPath,
      BookDeconstructionConfirmationJournalService.relativePath,
    );
    expect(
      journal,
      allOf(
        contains('"apply_staged_analysis_results": true'),
        contains('"staged_analysis_run_id": "staged-run-1"'),
        contains('"staged_analysis_package_id": "staged-package-1"'),
        contains('"staged_analysis_package_version_id": "staged-version-1"'),
        contains('"staged_analysis_applied": true'),
        contains('apply_staged_analysis_results'),
        contains('knowledge/staged-analysis.md'),
      ),
    );
  });

  test('暂存分析推广失败时 journal 标记该步骤且不继续类型转换', () async {
    final workspacePort = _InMemoryProjectWorkspacePort();
    final promotionService = _RecordingStagedAnalysisPromotionService(
      failPromotion: true,
    );
    const project = ProjectDescriptor(
      id: 'project-staged-analysis-failure',
      name: '暂存分析推广失败',
      rootPath: 'D:/Projects/deconstruction_staged_analysis_failure',
      projectType: 'book_deconstruction',
    );
    final buildResult = _buildResult();
    final service = BookDeconstructionConfirmWorkflowService(
      writeProjectTextFileUseCase: _writeUseCase(workspacePort),
      narrativePersistenceService:
          BookDeconstructionNarrativePersistenceService(
            workspacePort: workspacePort,
          ),
      stagedAnalysisPromotionService: promotionService,
      projectTypeTransitionUseCase: _transitionUseCase(workspacePort),
    );

    await expectLater(
      service.execute(
        project: project,
        buildResult: buildResult,
        selectedItemIds: buildResult.applicationPlan.items
            .map((item) => item.id)
            .toSet(),
        targetWritingProjectTypeId: 'novel',
        inheritAsLiveNarrative: false,
        applyStagedAnalysisResults: true,
        stagedAnalysisRunId: 'staged-run-failure',
        stagedAnalysisPackageId: 'staged-package-failure',
        stagedAnalysisPackageVersionId: 'staged-version-failure',
      ),
      throwsA(isA<StateError>()),
    );

    expect(promotionService.validationCount, 1);
    expect(promotionService.promotionCount, 1);
    final journal = workspacePort.readStoredTextFile(
      project.rootPath,
      BookDeconstructionConfirmationJournalService.relativePath,
    );
    expect(
      journal,
      allOf(
        contains('"status": "failed"'),
        contains('"current_step": "apply_staged_analysis_results"'),
        contains('"apply_staged_analysis_results": true'),
        contains('"staged_analysis_applied": false'),
        contains('staged-package-failure'),
      ),
    );
    expect(
      workspacePort.readStoredTextFile(
        project.rootPath,
        ProjectManifestCodecService.manifestRelativePath,
      ),
      isNull,
    );
  });
}

BookDeconstructionDraftBuildResult _buildResult() {
  return BuildBookDeconstructionDraftUseCase().execute(
    sourceTitle: '暂存分析测试原文',
    sourceContent: '第一章 启航\n主角从港口出发。',
    sourceAbsolutePath: 'D:/Books/staged_analysis_test.md',
    extractKnowledge: false,
  );
}

class _RecordingStagedAnalysisPromotionService
    extends BookDeconstructionStagedAnalysisPromotionService {
  _RecordingStagedAnalysisPromotionService({this.failPromotion = false});

  final bool failPromotion;
  var validationCount = 0;
  var promotionCount = 0;
  String lastRunId = '';
  String lastPackageId = '';
  String lastPackageVersionId = '';

  @override
  Future<void> validate({
    required ProjectDescriptor project,
    required String runId,
    required String packageId,
    required String packageVersionId,
  }) async {
    validationCount += 1;
    lastRunId = runId;
    lastPackageId = packageId;
    lastPackageVersionId = packageVersionId;
  }

  @override
  Future<BookDeconstructionStagedAnalysisPromotionResult> promote({
    required ProjectDescriptor project,
    required String runId,
    required String packageId,
    required String packageVersionId,
  }) async {
    promotionCount += 1;
    lastRunId = runId;
    lastPackageId = packageId;
    lastPackageVersionId = packageVersionId;
    if (failPromotion) {
      throw StateError('模拟暂存分析推广失败');
    }
    return BookDeconstructionStagedAnalysisPromotionResult(
      runId: runId,
      packageId: packageId,
      packageVersionId: packageVersionId,
      mountStatus: 'applied',
      changedPaths: const <String>['knowledge/staged-analysis.md'],
      warningCodes: const <String>[],
    );
  }
}

WriteProjectTextFileUseCase _writeUseCase(
  _InMemoryProjectWorkspacePort workspacePort,
) {
  return WriteProjectTextFileUseCase(projectWorkspacePort: workspacePort);
}

ExecuteProjectTypeTransitionUseCase _transitionUseCase(
  _InMemoryProjectWorkspacePort workspacePort,
) {
  final writeUseCase = _writeUseCase(workspacePort);
  return ExecuteProjectTypeTransitionUseCase(
    projectTypeTransitionPreparationService:
        const ProjectTypeTransitionPreparationService(),
    writeProjectTextFileUseCase: writeUseCase,
    readHasActiveLongTaskRun: (_) async => false,
  );
}

class _InMemoryProjectWorkspacePort implements ProjectWorkspacePort {
  _InMemoryProjectWorkspacePort({this.failOnceForRelativePath = ''});

  final Map<String, String> _files = <String, String>{};
  final String failOnceForRelativePath;
  var _hasFailed = false;

  int get storedFileCount => _files.length;

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
