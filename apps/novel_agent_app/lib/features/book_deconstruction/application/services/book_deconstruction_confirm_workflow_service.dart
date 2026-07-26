import 'package:novel_agent_core/novel_agent_core.dart';

import 'book_deconstruction_application_plan_materialization_service.dart';
import 'book_deconstruction_confirmation_journal_service.dart';
import 'book_deconstruction_followup_persistence_service.dart';
import 'book_deconstruction_narrative_persistence_service.dart';
import 'book_deconstruction_preview_markdown_service.dart';
import 'book_deconstruction_staged_analysis_promotion_service.dart';
import 'book_deconstruction_structured_source_projection_service.dart';

class BookDeconstructionConfirmWorkflowService {
  BookDeconstructionConfirmWorkflowService({
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    required BookDeconstructionNarrativePersistenceService
    narrativePersistenceService,
    BookDeconstructionPreviewMarkdownService? previewMarkdownService,
    BookDeconstructionTargetPathService? targetPathService,
    BookDeconstructionFollowupPersistenceService? followupPersistenceService,
    BookDeconstructionApplicationPlanMaterializationService?
    applicationPlanMaterializationService,
    BookDeconstructionStructuredSourceProjectionService?
    structuredSourceProjectionService,
    BookDeconstructionNarrativeArtifactSelectionService?
    narrativeArtifactSelectionService,
    BookDeconstructionConfirmationJournalService? confirmationJournalService,
    BookDeconstructionStagedAnalysisPromotionService?
    stagedAnalysisPromotionService,
    ReadProjectFileUseCase? readProjectFileUseCase,
    ExecuteProjectTypeTransitionUseCase? projectTypeTransitionUseCase,
    ProjectTypeTransitionPreparationService?
    projectTypeTransitionPreparationService,
  }) : _writeProjectTextFileUseCase = writeProjectTextFileUseCase,
       _narrativePersistenceService = narrativePersistenceService,
       _previewMarkdownService =
           previewMarkdownService ??
           const BookDeconstructionPreviewMarkdownService(),
       _targetPathService =
           targetPathService ?? const BookDeconstructionTargetPathService(),
       _followupPersistenceService =
           followupPersistenceService ??
           BookDeconstructionFollowupPersistenceService(
             writeProjectTextFileUseCase: writeProjectTextFileUseCase,
             targetPathService:
                 targetPathService ??
                 const BookDeconstructionTargetPathService(),
           ),
       _structuredSourceProjectionService =
           structuredSourceProjectionService ??
           const BookDeconstructionStructuredSourceProjectionService(),
       _applicationPlanMaterializationService =
           applicationPlanMaterializationService ??
           BookDeconstructionApplicationPlanMaterializationService(
             writeProjectTextFileUseCase: writeProjectTextFileUseCase,
           ),
       _narrativeArtifactSelectionService =
           narrativeArtifactSelectionService ??
           const BookDeconstructionNarrativeArtifactSelectionService(),
       _confirmationJournalService =
           confirmationJournalService ??
           const BookDeconstructionConfirmationJournalService(),
       _stagedAnalysisPromotionService =
           stagedAnalysisPromotionService ??
           BookDeconstructionStagedAnalysisPromotionService(),
       _readProjectFileUseCase = readProjectFileUseCase,
       _projectTypeTransitionPreparationService =
           projectTypeTransitionPreparationService ??
           const ProjectTypeTransitionPreparationService(),
       _projectTypeTransitionUseCase = projectTypeTransitionUseCase;

  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final BookDeconstructionNarrativePersistenceService
  _narrativePersistenceService;
  final BookDeconstructionPreviewMarkdownService _previewMarkdownService;
  final BookDeconstructionTargetPathService _targetPathService;
  final BookDeconstructionFollowupPersistenceService
  _followupPersistenceService;
  final BookDeconstructionStructuredSourceProjectionService
  _structuredSourceProjectionService;
  final BookDeconstructionApplicationPlanMaterializationService
  _applicationPlanMaterializationService;
  final BookDeconstructionNarrativeArtifactSelectionService
  _narrativeArtifactSelectionService;
  final BookDeconstructionConfirmationJournalService
  _confirmationJournalService;
  final BookDeconstructionStagedAnalysisPromotionService
  _stagedAnalysisPromotionService;
  final ReadProjectFileUseCase? _readProjectFileUseCase;
  final ProjectTypeTransitionPreparationService
  _projectTypeTransitionPreparationService;
  final ExecuteProjectTypeTransitionUseCase? _projectTypeTransitionUseCase;

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
  }) async {
    // 中文注释: 先完成转换预校验，再开始所有不可逆写入。尤其 long_novel 必须已有
    // 运行基准，不能等 preview/正文已落盘后才由 transition 报错。
    final targetId = targetWritingProjectTypeId.trim();
    final requestedRuntimeBaselineId = targetRuntimeBaselineId.trim();
    final projectTypeTransitionUseCase = _projectTypeTransitionUseCase;
    if (targetId.isEmpty) {
      throw StateError('请先选择拆书后要复合成的写作项目类型。');
    }
    final requiresProjectTypeTransition =
        targetId != project.projectType.trim();
    if (requiresProjectTypeTransition && projectTypeTransitionUseCase == null) {
      throw StateError('当前环境未配置项目类型转换，不能确认写入拆书结果。');
    }
    // Confirming a composite long novel can create several durable artifacts
    // before the final type transition. Read the exact same authoritative
    // active-run source as that transition before any journal or content write.
    // The executor rechecks again at commit time for concurrent task starts.
    final hasActiveLongTaskRun = requiresProjectTypeTransition
        ? await projectTypeTransitionUseCase!.readHasActiveLongTaskRun(project)
        : false;
    // Always build the plan, including same-type confirmation. The plan is the
    // single source for long_novel baseline normalization/validation; only its
    // "same project type" blocker is irrelevant when confirmation does not
    // actually execute a transition.
    final transitionPlan = _projectTypeTransitionPreparationService.prepare(
      project: project,
      targetProjectTypeId: targetId,
      runtimeBaselineId: requestedRuntimeBaselineId,
      hasActiveLongTaskRun: hasActiveLongTaskRun,
    );
    final relevantBlockers = transitionPlan.blockers
        .where(
          (blocker) =>
              requiresProjectTypeTransition ||
              blocker.code != ProjectTypeTransitionBlockerCodes.sameProjectType,
        )
        .toList(growable: false);
    if (relevantBlockers.isNotEmpty) {
      throw StateError(relevantBlockers.map((item) => item.message).join('；'));
    }
    final resolvedRuntimeBaselineId = transitionPlan.targetRuntimeBaselineId;
    // A same-type long_novel confirmation only reuses the project's existing
    // runtime contract. Letting a caller record another baseline here without
    // updating manifest/runtime_profile.json would create a false confirmation.
    if (!requiresProjectTypeTransition && targetId == 'long_novel') {
      const baselineCatalog = ProjectRuntimeBaselineCatalogService();
      final currentRuntimeBaselineId = baselineCatalog.normalizeForProjectType(
        project.projectType,
        project.runtimeBaselineId,
      );
      if (resolvedRuntimeBaselineId != currentRuntimeBaselineId) {
        throw StateError('当前项目已是长篇类型，拆书确认不能变更运行基准。');
      }
    }
    final shouldApplyStagedAnalysis = applyStagedAnalysisResults;
    final cleanStagedAnalysisRunId = stagedAnalysisRunId.trim();
    final cleanStagedAnalysisPackageId = stagedAnalysisPackageId.trim();
    final cleanStagedAnalysisPackageVersionId = stagedAnalysisPackageVersionId
        .trim();
    // 第④步确认 = 写预演纪要 + 写结构化源文 + 只物化用户选中的应用条目 + 写叙事/信息资产
    // + 按续写开关写已选分章（续写→正文 chapters/，其他→资源 analysis/）+ 复合项目类型。
    // 每一步先写 pending 标记；若步骤内部发生异常，current_step 明确表示该步骤可能已部分落盘，
    // 而不是错误地宣称可自动回滚。
    final extractionId = buildResult.extractionResult.extractionId;
    final confirmationId = _confirmationJournalService.confirmationId(
      extractionId: extractionId,
      targetWritingProjectTypeId: targetId,
      targetRuntimeBaselineId: resolvedRuntimeBaselineId,
      selectedItemIds: selectedItemIds,
      inheritAsLiveNarrative: inheritAsLiveNarrative,
      applyStagedAnalysisResults: shouldApplyStagedAnalysis,
      stagedAnalysisRunId: cleanStagedAnalysisRunId,
      stagedAnalysisPackageId: cleanStagedAnalysisPackageId,
      stagedAnalysisPackageVersionId: cleanStagedAnalysisPackageVersionId,
    );
    final previousJournal = await _readJournal(project);
    if (previousJournal?.isCompleted == true &&
        previousJournal!.confirmationId == confirmationId &&
        previousJournal.previewPath.isNotEmpty) {
      return BookDeconstructionConfirmWorkflowResult(
        previewPath: previousJournal.previewPath,
        targetWritingProjectTypeId: targetId,
        targetRuntimeBaselineId: resolvedRuntimeBaselineId,
        projectTypeTransitioned: previousJournal.projectTypeTransitioned,
        chapterPaths: previousJournal.chapterPaths,
        changedPaths: previousJournal.changedPaths,
        stagedAnalysisApplied: previousJournal.stagedAnalysisApplied,
        stagedAnalysisMountStatus: previousJournal.stagedAnalysisMountStatus,
      );
    }

    if (shouldApplyStagedAnalysis) {
      // Validate before the confirmation journal and all durable result writes.
      // A package that disappeared after step ③ must not leave a new partial
      // confirmation merely because its explicit promotion was requested.
      await _stagedAnalysisPromotionService.validate(
        project: project,
        runId: cleanStagedAnalysisRunId,
        packageId: cleanStagedAnalysisPackageId,
        packageVersionId: cleanStagedAnalysisPackageVersionId,
      );
    }

    final changedPaths = <String>[];
    final chapterPaths = <String>[];
    final completedSteps = <String>[];
    var currentStep = 'write_preview';
    var transitioned = false;
    var stagedAnalysisApplied = false;
    var stagedAnalysisMountStatus = '';
    final previewPath = _targetPathService.previewPath(
      storageStrategy: project.storageStrategy,
    );

    Future<void> markPending(String step) async {
      currentStep = step;
      await _writeJournal(
        project: project,
        content: _confirmationJournalService.pending(
          confirmationId: confirmationId,
          extractionId: extractionId,
          targetWritingProjectTypeId: targetId,
          targetRuntimeBaselineId: resolvedRuntimeBaselineId,
          selectedItemIds: selectedItemIds,
          inheritAsLiveNarrative: inheritAsLiveNarrative,
          currentStep: currentStep,
          completedSteps: completedSteps,
          changedPaths: changedPaths,
          chapterPaths: chapterPaths,
          projectTypeTransitioned: transitioned,
          applyStagedAnalysisResults: shouldApplyStagedAnalysis,
          stagedAnalysisRunId: cleanStagedAnalysisRunId,
          stagedAnalysisPackageId: cleanStagedAnalysisPackageId,
          stagedAnalysisPackageVersionId: cleanStagedAnalysisPackageVersionId,
          stagedAnalysisApplied: stagedAnalysisApplied,
          stagedAnalysisMountStatus: stagedAnalysisMountStatus,
        ),
      );
    }

    void completeStep(String step, Iterable<String> paths) {
      completedSteps.add(step);
      changedPaths.addAll(paths);
    }

    try {
      await markPending('write_preview');
      final markdown = _previewMarkdownService.render(
        buildResult: buildResult,
        selectedItemIds: selectedItemIds,
      );
      await _writeProjectTextFileUseCase.execute(
        project: project,
        relativePath: previewPath,
        content: markdown,
      );
      completeStep('write_preview', <String>[previewPath]);

      await markPending('write_structured_source');
      final structuredSourcePath = _structuredSourceProjectionService
          .targetPath(storageStrategy: project.storageStrategy);
      await _writeProjectTextFileUseCase.execute(
        project: project,
        relativePath: structuredSourcePath,
        content: _structuredSourceProjectionService.render(
          buildResult: buildResult,
        ),
      );
      completeStep('write_structured_source', <String>[structuredSourcePath]);

      await markPending('materialize_selected_items');
      final materializedPaths = await _applicationPlanMaterializationService
          .materialize(
            project: project,
            buildResult: buildResult,
            selectedItemIds: selectedItemIds,
          );
      completeStep('materialize_selected_items', materializedPaths);

      await markPending('persist_selected_narrative_artifacts');
      final selectedNarrativeArtifacts = _narrativeArtifactSelectionService
          .select(buildResult: buildResult, selectedItemIds: selectedItemIds);
      final narrativeChangedPaths = await _narrativePersistenceService.persist(
        project: project,
        narrativeArtifacts: selectedNarrativeArtifacts,
      );
      completeStep(
        'persist_selected_narrative_artifacts',
        narrativeChangedPaths,
      );

      await markPending('persist_selected_chapters');
      final persistedChapterPaths = await _followupPersistenceService
          .persistChapters(
            project: project,
            buildResult: buildResult,
            asLiveNarrative: inheritAsLiveNarrative,
            selectedItemIds: selectedItemIds,
          );
      chapterPaths.addAll(persistedChapterPaths);
      completeStep('persist_selected_chapters', persistedChapterPaths);

      if (shouldApplyStagedAnalysis) {
        await markPending('apply_staged_analysis_results');
        final promotion = await _stagedAnalysisPromotionService.promote(
          project: project,
          runId: cleanStagedAnalysisRunId,
          packageId: cleanStagedAnalysisPackageId,
          packageVersionId: cleanStagedAnalysisPackageVersionId,
        );
        stagedAnalysisApplied = true;
        stagedAnalysisMountStatus = promotion.mountStatus;
        completeStep('apply_staged_analysis_results', promotion.changedPaths);
      }

      if (requiresProjectTypeTransition) {
        await markPending('transition_project_type');
        await projectTypeTransitionUseCase!.execute(
          project: project,
          targetProjectTypeId: targetId,
          runtimeBaselineId: resolvedRuntimeBaselineId,
          preserveAdditionalTraitIds: const <String>['book_deconstruction'],
        );
        transitioned = true;
        completeStep('transition_project_type', <String>[
          ProjectManifestCodecService.manifestRelativePath,
          ProjectSupportDocumentCatalog.projectOverviewRelativePath,
          ProjectRuntimeProfileDocumentService.profileRelativePath,
        ]);
      }

      currentStep = 'finalize_confirmation';
      await _writeJournal(
        project: project,
        content: _confirmationJournalService.completed(
          confirmationId: confirmationId,
          extractionId: extractionId,
          targetWritingProjectTypeId: targetId,
          targetRuntimeBaselineId: resolvedRuntimeBaselineId,
          selectedItemIds: selectedItemIds,
          inheritAsLiveNarrative: inheritAsLiveNarrative,
          completedSteps: completedSteps,
          changedPaths: changedPaths,
          chapterPaths: chapterPaths,
          projectTypeTransitioned: transitioned,
          previewPath: previewPath,
          applyStagedAnalysisResults: shouldApplyStagedAnalysis,
          stagedAnalysisRunId: cleanStagedAnalysisRunId,
          stagedAnalysisPackageId: cleanStagedAnalysisPackageId,
          stagedAnalysisPackageVersionId: cleanStagedAnalysisPackageVersionId,
          stagedAnalysisApplied: stagedAnalysisApplied,
          stagedAnalysisMountStatus: stagedAnalysisMountStatus,
        ),
      );
      return BookDeconstructionConfirmWorkflowResult(
        previewPath: previewPath,
        targetWritingProjectTypeId: targetId,
        targetRuntimeBaselineId: resolvedRuntimeBaselineId,
        projectTypeTransitioned: transitioned,
        chapterPaths: chapterPaths,
        changedPaths: changedPaths,
        stagedAnalysisApplied: stagedAnalysisApplied,
        stagedAnalysisMountStatus: stagedAnalysisMountStatus,
      );
    } catch (error) {
      try {
        await _writeJournal(
          project: project,
          content: _confirmationJournalService.failed(
            confirmationId: confirmationId,
            extractionId: extractionId,
            targetWritingProjectTypeId: targetId,
            targetRuntimeBaselineId: resolvedRuntimeBaselineId,
            selectedItemIds: selectedItemIds,
            inheritAsLiveNarrative: inheritAsLiveNarrative,
            currentStep: currentStep,
            completedSteps: completedSteps,
            changedPaths: changedPaths,
            chapterPaths: chapterPaths,
            projectTypeTransitioned: transitioned,
            error: error,
            applyStagedAnalysisResults: shouldApplyStagedAnalysis,
            stagedAnalysisRunId: cleanStagedAnalysisRunId,
            stagedAnalysisPackageId: cleanStagedAnalysisPackageId,
            stagedAnalysisPackageVersionId: cleanStagedAnalysisPackageVersionId,
            stagedAnalysisApplied: stagedAnalysisApplied,
            stagedAnalysisMountStatus: stagedAnalysisMountStatus,
          ),
        );
      } catch (_) {
        // Preserve the original failure if even the recovery marker cannot be written.
      }
      rethrow;
    }
  }

  Future<BookDeconstructionConfirmationJournal?> _readJournal(
    ProjectDescriptor project,
  ) async {
    final reader = _readProjectFileUseCase;
    if (reader == null) {
      return null;
    }
    try {
      final source = await reader.execute(
        project,
        BookDeconstructionConfirmationJournalService.relativePath,
      );
      return source == null
          ? null
          : _confirmationJournalService.tryParse(source);
    } catch (_) {
      // An unreadable old marker must not prevent a new confirmation attempt.
      return null;
    }
  }

  Future<void> _writeJournal({
    required ProjectDescriptor project,
    required String content,
  }) {
    return _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: BookDeconstructionConfirmationJournalService.relativePath,
      content: content,
    );
  }
}

class BookDeconstructionConfirmWorkflowResult {
  const BookDeconstructionConfirmWorkflowResult({
    required this.previewPath,
    required this.targetWritingProjectTypeId,
    required this.targetRuntimeBaselineId,
    required this.projectTypeTransitioned,
    required this.chapterPaths,
    required this.changedPaths,
    this.stagedAnalysisApplied = false,
    this.stagedAnalysisMountStatus = '',
  });

  final String previewPath;
  final String targetWritingProjectTypeId;
  final String targetRuntimeBaselineId;
  final bool projectTypeTransitioned;
  final List<String> chapterPaths;
  final List<String> changedPaths;
  final bool stagedAnalysisApplied;
  final String stagedAnalysisMountStatus;
}
