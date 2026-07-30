import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';

import '../../../../shared/services/user_facing_error_humanizer.dart';
import '../../../project_assets/application/models/project_reference_extraction_execution_result.dart';
import '../../../workbench/application/services/import_assistant_model_options_service.dart';
import '../../../workbench/presentation/models/selector_option_view_data.dart';

import '../../presentation/contracts/book_deconstruction_action_handler.dart';
import '../../presentation/models/book_deconstruction_view_data.dart';
import '../models/book_deconstruction_operation_kind.dart';
import '../models/book_deconstruction_snapshot.dart';
import '../models/book_deconstruction_step_id.dart';
import '../models/book_deconstruction_workflow_recovery_state.dart';
import '../services/book_deconstruction_confirmation_journal_service.dart';
import '../services/book_deconstruction_confirm_workflow_service.dart';
import '../services/book_deconstruction_derived_project_creation_service.dart';
import '../services/book_deconstruction_draft_builder_service.dart';
import '../services/book_deconstruction_followup_option_selection_service.dart';
import '../services/book_deconstruction_narrative_persistence_service.dart';
import '../services/book_deconstruction_preview_markdown_service.dart';
import '../services/book_deconstruction_smart_import_agent_service.dart';
import '../services/book_deconstruction_smart_import_orchestration_service.dart';
import '../services/book_deconstruction_structured_source_projection_service.dart';
import '../services/book_deconstruction_view_data_service.dart';
import '../services/desktop_book_deconstruction_source_picker_service.dart';
import '../../../workbench/application/controllers/generate_draft_use_case_factory.dart';

/// 中文注释: 分析（可选阶段）的执行回调。由 app_shell 注入，委托给内置隐藏智能体的
/// LLM reference_extraction（读拆书产物、必须已配置模型）。provider/model 由拆书"分析"步
/// 用户选择透传（与 app 默认解耦、与"拆书"步模型独立不继承）。结果保留
/// run/package/version 身份，供步骤④显式选择后才挂载暂存包。
typedef BookDeconstructionExtractKnowledgeHandler =
    Future<ProjectReferenceExtractionExecutionResult> Function(
      ProjectDescriptor project, {
      required String providerId,
      required String modelId,
    });

class BookDeconstructionController extends ChangeNotifier
    implements BookDeconstructionActionHandler {
  BookDeconstructionController({
    required ReadProjectFileUseCase readProjectFileUseCase,
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    required BookDeconstructionNarrativePersistenceService
    narrativePersistenceService,
    required ProjectDescriptor? Function() readCurrentProject,
    required Future<void> Function() syncWorkbenchResources,
    required VoidCallback onBackRequested,
    required List<SelectorOptionViewData> Function()
    readImportAssistantModelOptions,
    DesktopBookDeconstructionSourcePickerService? sourcePickerService,
    BookDeconstructionDraftBuilderService? draftBuilderService,
    BookDeconstructionPreviewMarkdownService? previewMarkdownService,
    BookDeconstructionViewDataService? viewDataService,
    BookDeconstructionTargetPathService? targetPathService,
    ProjectStructuredContentBridgeService? structuredContentBridgeService,
    BookDeconstructionImportArchiveWorkflowService?
    importArchiveWorkflowService,
    BookDeconstructionConfirmWorkflowService? confirmWorkflowService,
    BookDeconstructionFollowupOptionSelectionService?
    followupOptionSelectionService,
    BookDeconstructionProjectSetupDocumentService? projectSetupDocumentService,
    BookDeconstructionDerivedProjectCreationService?
    derivedProjectCreationService,
    Future<void> Function(ProjectDescriptor project, String preferredOpenPath)?
    openDerivedProjectRequested,
    String projectsRootPath = '',
    AppSettings? Function()? readSettings,
    GenerateDraftUseCaseFactory? generateDraftUseCaseFactory,
    BookDeconstructionExtractKnowledgeHandler? extractKnowledgeHandler,
    BookDeconstructionStructuredSourceProjectionService?
    structuredSourceProjectionService,
    ExecuteProjectTypeTransitionUseCase? projectTypeTransitionUseCase,
    Future<void> Function()? onProjectTransitioned,
  }) : _readCurrentProject = readCurrentProject,
       _readProjectFileUseCase = readProjectFileUseCase,
       _writeProjectTextFileUseCase = writeProjectTextFileUseCase,
       _syncWorkbenchResources = syncWorkbenchResources,
       _onBackRequested = onBackRequested,
       _readImportAssistantModelOptions = readImportAssistantModelOptions,
       _sourcePickerService =
           sourcePickerService ??
           const DesktopBookDeconstructionSourcePickerService(),
       _draftBuilderService =
           draftBuilderService ?? BookDeconstructionDraftBuilderService(),
       _viewDataService =
           viewDataService ?? const BookDeconstructionViewDataService(),
       _targetPathService =
           targetPathService ?? const BookDeconstructionTargetPathService(),
       _structuredContentBridgeService =
           structuredContentBridgeService ??
           ProjectStructuredContentBridgeService(),
       _followupOptionSelectionService =
           followupOptionSelectionService ??
           const BookDeconstructionFollowupOptionSelectionService(),
       _projectSetupDocumentService =
           projectSetupDocumentService ??
           BookDeconstructionProjectSetupDocumentService(),
       _derivedProjectCreationService = derivedProjectCreationService,
       _openDerivedProjectRequested = openDerivedProjectRequested,
       _projectsRootPath = projectsRootPath,
       _importArchiveWorkflowService =
           importArchiveWorkflowService ??
           BookDeconstructionImportArchiveWorkflowService(
             writeProjectTextFileUseCase: writeProjectTextFileUseCase,
           ),
       _confirmWorkflowService =
           confirmWorkflowService ??
           BookDeconstructionConfirmWorkflowService(
             writeProjectTextFileUseCase: writeProjectTextFileUseCase,
             narrativePersistenceService: narrativePersistenceService,
             previewMarkdownService: previewMarkdownService,
             targetPathService: targetPathService,
             readProjectFileUseCase: readProjectFileUseCase,
             projectTypeTransitionUseCase: projectTypeTransitionUseCase,
           ),
       _structuredSourceProjectionService =
           structuredSourceProjectionService ??
           const BookDeconstructionStructuredSourceProjectionService(),
       _snapshot = BookDeconstructionSnapshot.initial(),
       _viewData = BookDeconstructionViewData.initial(),
       _readSettings = readSettings,
       _generateDraftUseCaseFactory = generateDraftUseCaseFactory,
       _extractKnowledgeHandler = extractKnowledgeHandler,
       _onProjectTransitioned = onProjectTransitioned;

  final ProjectDescriptor? Function() _readCurrentProject;
  final ReadProjectFileUseCase _readProjectFileUseCase;
  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final Future<void> Function() _syncWorkbenchResources;
  final VoidCallback _onBackRequested;
  final List<SelectorOptionViewData> Function()
  _readImportAssistantModelOptions;
  final DesktopBookDeconstructionSourcePickerService _sourcePickerService;
  final BookDeconstructionDraftBuilderService _draftBuilderService;
  final BookDeconstructionViewDataService _viewDataService;
  final BookDeconstructionTargetPathService _targetPathService;
  final ProjectStructuredContentBridgeService _structuredContentBridgeService;
  final AppSettings? Function()? _readSettings;
  final GenerateDraftUseCaseFactory? _generateDraftUseCaseFactory;
  final BookDeconstructionExtractKnowledgeHandler? _extractKnowledgeHandler;
  // 中文注释: 项目类型复合（transition）完成后，通知上层重新加载项目（刷新 descriptor 与导航）。
  final Future<void> Function()? _onProjectTransitioned;
  final BookDeconstructionFollowupOptionSelectionService
  _followupOptionSelectionService;
  final BookDeconstructionProjectSetupDocumentService
  _projectSetupDocumentService;
  final BookDeconstructionImportArchiveWorkflowService
  _importArchiveWorkflowService;
  final BookDeconstructionConfirmWorkflowService _confirmWorkflowService;
  final BookDeconstructionStructuredSourceProjectionService
  _structuredSourceProjectionService;
  final BookDeconstructionDerivedProjectCreationService?
  _derivedProjectCreationService;
  final Future<void> Function(
    ProjectDescriptor project,
    String preferredOpenPath,
  )?
  _openDerivedProjectRequested;
  final String _projectsRootPath;

  BookDeconstructionSnapshot _snapshot;
  BookDeconstructionViewData _viewData;
  String _statusMessage = '';
  bool _disposed = false;
  // 中文注释: 操作代际。每次"取消"自增；在途的长操作结束后若发现代际已变，说明用户已取消
  // 或发起了新操作，丢弃本次结果（软取消——LLM 调用无法真正中断，但不再写回/覆盖 UI）。
  int _operationGeneration = 0;
  Timer? _recoveryStatePersistTimer;
  Future<void> _recoveryStatePersistTail = Future<void>.value();
  int _recoveryStateRevision = 0;
  String _snapshotProjectId = '';
  String _splitSourceContent = '';
  String _splitExtractionId = '';
  String _splitContinuationDirectionId = '';

  /// 长 LLM 操作（拆书去噪 / 分析）的超时兜底，避免模型挂起时 UI 永久卡在"正在..."。
  static const Duration _longOperationTimeout = Duration(minutes: 8);

  static const ImportAssistantModelOptionsService _modelOptionsService =
      ImportAssistantModelOptionsService();
  static const String _pastedSourceArchiveIdentity =
      'pasted_book_deconstruction_source.md';

  BookDeconstructionViewData get viewData => _viewData;

  Future<void> initialize() async {
    await refresh();
  }

  Future<void> refresh({String? status}) async {
    final project = _readCurrentProject();
    if (project == null) {
      _invalidateInFlightOperations();
      _invalidateScheduledRecoveryPersistence();
      _snapshotProjectId = '';
      _clearSplitRecoveryState();
      _snapshot = BookDeconstructionSnapshot.initial();
      _statusMessage = status ?? '请先创建或打开拆书项目。';
      _rebuildView();
      return;
    }
    BookDeconstructionWorkflowRecoveryState? recoveryState;
    BookDeconstructionConfirmationJournal? confirmationJournal;
    var restoredBuildResult = false;
    var recoveryBuildFailed = false;
    var recoveryProjectionFailed = false;
    if (!_snapshotBelongsTo(project)) {
      _invalidateInFlightOperations();
      _invalidateScheduledRecoveryPersistence();
      final operation = _captureOperation(project);
      _snapshotProjectId = project.id;
      _clearSplitRecoveryState();
      _snapshot = BookDeconstructionSnapshot.initial().copyWith(
        projectRootPath: project.rootPath,
      );
      final projectSetup = await _loadProjectSetup(project);
      if (!_isCurrentOperation(operation)) {
        return;
      }
      recoveryState = await _loadRecoveryState(project);
      if (!_isCurrentOperation(operation)) {
        return;
      }
      final loadedConfirmationJournal = await _loadConfirmationJournal(project);
      if (!_isCurrentOperation(operation)) {
        return;
      }
      final restoredFollowupOptionId =
          recoveryState?.selectedFollowupOptionId.trim().isNotEmpty == true
          ? recoveryState!.selectedFollowupOptionId
          : projectSetup.preferredFollowupOptionId;
      final canRestoreSplit =
          recoveryState?.hasSourceContent == true &&
          recoveryState?.hasSplitSourceContent == true;
      final restoredSplitExtractionId = canRestoreSplit
          ? recoveryState!.splitExtractionId.trim()
          : '';
      // A journal belongs to one concrete split, not merely to this project.
      // Without this check, a completed confirmation from an earlier split can
      // make a newer reopened split look confirmed and restore stale choices.
      confirmationJournal = _journalForRestoredSplit(
        journal: loadedConfirmationJournal,
        splitExtractionId: restoredSplitExtractionId,
      );
      // A completed journal is only authoritative while its durable payload
      // still matches the recovered selection. Users can revise selection or
      // target settings after a completed confirmation; reopening must not
      // revive that older completion and let a derived project use it.
      if (!_completedJournalMatchesRecoveryState(
        journal: confirmationJournal,
        recoveryState: recoveryState,
        project: project,
      )) {
        confirmationJournal = null;
      }
      final restoredTargetWritingTypeId =
          recoveryState?.selectedTargetWritingTypeId.trim().isNotEmpty == true
          ? recoveryState!.selectedTargetWritingTypeId
          : confirmationJournal?.targetWritingProjectTypeId ?? '';
      final selectedTargetWritingTypeId = _resolveTargetWritingTypeId(
        project: project,
        preferredTargetWritingTypeId: restoredTargetWritingTypeId,
      );
      final restoredTargetRuntimeBaselineId =
          recoveryState?.selectedTargetRuntimeBaselineId.trim().isNotEmpty ==
              true
          ? recoveryState!.selectedTargetRuntimeBaselineId
          : confirmationJournal?.targetRuntimeBaselineId ?? '';
      final restoredSelectedItemIds =
          recoveryState?.selectedItemIds ?? const <String>[];
      final recoveredConfirmationMatchesProjectRuntimeBaseline =
          _confirmationRuntimeBaselineMatchesProject(
            project: project,
            targetWritingTypeId: selectedTargetWritingTypeId,
            targetRuntimeBaselineId: restoredTargetRuntimeBaselineId,
          );
      _splitSourceContent = canRestoreSplit
          ? recoveryState!.splitSourceContent
          : '';
      _splitExtractionId = restoredSplitExtractionId;
      _splitContinuationDirectionId = canRestoreSplit
          ? recoveryState!.splitContinuationDirectionId
          : '';
      final hasRestorableStagedAnalysis =
          canRestoreSplit &&
          recoveryState?.analysisCompleted == true &&
          recoveryState?.analysisStagingRunId.trim().isNotEmpty == true &&
          recoveryState?.analysisStagingPackageId.trim().isNotEmpty == true &&
          recoveryState?.analysisStagingPackageVersionId.trim().isNotEmpty ==
              true;
      _snapshot = BookDeconstructionSnapshot.initial().copyWith(
        projectRootPath: project.rootPath,
        activeStepId:
            confirmationJournal?.isCompleted == true ||
                confirmationJournal?.requiresRecovery == true
            ? BookDeconstructionStepId.confirmSelection
            : recoveryState?.restoredActiveStepId ??
                  BookDeconstructionStepId.importSource,
        sourceAbsolutePath: recoveryState?.sourceAbsolutePath ?? '',
        sourceTitle: recoveryState?.sourceTitle ?? '',
        sourceContent: recoveryState?.sourceContent ?? '',
        splitUseModel: recoveryState?.splitUseModel ?? false,
        splitModelOptionKey: recoveryState?.splitModelOptionKey ?? '',
        analysisUseModel: recoveryState?.analysisUseModel ?? false,
        analysisModelOptionKey: recoveryState?.analysisModelOptionKey ?? '',
        analysisCompleted: canRestoreSplit
            ? recoveryState!.analysisCompleted
            : false,
        analysisStatusMessage: canRestoreSplit
            ? recoveryState!.analysisStatusMessage
            : '',
        analysisStagingRunId: hasRestorableStagedAnalysis
            ? recoveryState?.analysisStagingRunId ?? ''
            : '',
        analysisStagingPackageId: hasRestorableStagedAnalysis
            ? recoveryState?.analysisStagingPackageId ?? ''
            : '',
        analysisStagingPackageVersionId: hasRestorableStagedAnalysis
            ? recoveryState?.analysisStagingPackageVersionId ?? ''
            : '',
        applyStagedAnalysisResults: hasRestorableStagedAnalysis
            ? recoveryState?.applyStagedAnalysisResults ?? false
            : false,
        selectedFollowupOptionId: restoredFollowupOptionId,
        selectedTargetWritingTypeId: selectedTargetWritingTypeId,
        selectedTargetRuntimeBaselineId: _resolveTargetRuntimeBaselineId(
          project: project,
          targetWritingTypeId: selectedTargetWritingTypeId,
          preferredRuntimeBaselineId: restoredTargetRuntimeBaselineId,
        ),
        inheritAsLiveNarrative: recoveryState?.inheritAsLiveNarrative ?? false,
        confirmedPreviewPath:
            confirmationJournal?.isCompleted == true &&
                confirmationJournal!.previewPath.trim().isNotEmpty
            ? confirmationJournal.previewPath
            : canRestoreSplit &&
                  recoveredConfirmationMatchesProjectRuntimeBaseline
            ? recoveryState!.confirmedPreviewPath
            : '',
      );
      if (canRestoreSplit) {
        try {
          final buildResult = await _draftBuilderService
              .build(
                sourceTitle: _snapshot.sourceTitle,
                sourceContent: _splitSourceContent,
                sourceAbsolutePath: _snapshot.sourceAbsolutePath,
                storageStrategy: project.storageStrategy,
                extractionId: _splitExtractionId,
                preferredContinuationDirection: _splitContinuationDirection(),
                extractKnowledge: false,
              )
              .timeout(_longOperationTimeout);
          if (!_isCurrentOperation(operation)) {
            return;
          }
          final availableItemIds = buildResult.applicationPlan.items
              .map((item) => item.id)
              .toSet();
          final selectedItemIds = restoredSelectedItemIds
              .where(availableItemIds.contains)
              .toSet();
          _snapshot = _snapshot.copyWith(
            buildResult: buildResult,
            selectedItemIds: selectedItemIds,
            selectedFollowupOptionId: _followupOptionSelectionService
                .resolveSelectedOptionId(
                  followupMenu: buildResult.followupMenu,
                  preferredOptionId: restoredFollowupOptionId,
                ),
          );
          try {
            await _persistStructuredSourceProjection(
              project,
              buildResult,
              operation,
            );
            if (!_isCurrentOperation(operation)) {
              return;
            }
            _snapshot = _snapshot.copyWith(
              structuredSourceProjectionReady: true,
            );
          } catch (_) {
            if (!_isCurrentOperation(operation)) {
              return;
            }
            recoveryProjectionFailed = true;
          }
          restoredBuildResult = true;
          await _persistRecoveryStateNow(project, operation);
          if (!_isCurrentOperation(operation)) {
            return;
          }
        } catch (_) {
          if (!_isCurrentOperation(operation)) {
            return;
          }
          _clearSplitRecoveryState();
          _snapshot = _snapshot.copyWith(
            activeStepId: BookDeconstructionStepId.splitChapters,
            buildResult: null,
            selectedItemIds: <String>{},
            analysisCompleted: false,
            analysisStatusMessage: '',
            analysisStagingRunId: '',
            analysisStagingPackageId: '',
            analysisStagingPackageVersionId: '',
            applyStagedAnalysisResults: false,
            confirmedPreviewPath: '',
          );
          recoveryBuildFailed = true;
        }
      }
    }
    _statusMessage =
        status ??
        _confirmationRecoveryStatusMessage(
          restoredBuildResult ? confirmationJournal : null,
        ) ??
        (restoredBuildResult
            ? recoveryProjectionFailed
                  ? '已恢复上次拆书结果，但结构化源文无法更新，暂不能执行模型分析；可直接确认或重新拆书。'
                  : '已恢复上次拆书结果，可继续确认。'
            : recoveryBuildFailed
            ? '已恢复源文，但拆书结果未能恢复，请重新执行拆书。'
            : recoveryState?.hasSourceContent == true
            ? '已恢复上次保存的源文，请重新执行拆书。'
            : project.projectType == BookDeconstructionConstants.projectTypeId
            ? '可以开始导入拆书材料。'
            : '当前项目不是拆书项目，但仍可先预演结构化拆书流程。');
    _rebuildView();
  }

  @override
  void onBookDeconstructionBackRequested() {
    if (_isCommitInProgress) {
      return;
    }
    _invalidateInFlightOperations();
    _onBackRequested();
  }

  @override
  void onBookDeconstructionRefreshRequested() {
    if (_isCommitInProgress) {
      return;
    }
    refresh();
  }

  @override
  void onBookDeconstructionCancelRequested() {
    // 中文注释: 软取消。LLM 调用本身无法真正中断，但自增代际让在途操作的结果被丢弃，
    // 并立即把界面恢复到 idle——用户不再被"正在..."卡住（与超时兜底配合，最坏情况有界）。
    if (_isCommitInProgress) {
      return;
    }
    if (!_ensureSnapshotForCurrentProject()) {
      return;
    }
    _invalidateInFlightOperations();
    _snapshot = _snapshot.copyWith(
      isLoading: false,
      operationKind: BookDeconstructionOperationKind.idle,
    );
    _statusMessage = '已取消当前操作。';
    _rebuildView();
  }

  @override
  void onBookDeconstructionStepSelected(String stepId) {
    if (_isCommitInProgress) {
      return;
    }
    if (!_ensureSnapshotForCurrentProject()) {
      return;
    }
    _snapshot = _snapshot.copyWith(activeStepId: stepId.trim());
    _persistRecoveryStateAfterDiscreteChange();
    _rebuildView();
  }

  @override
  Future<void> onBookDeconstructionImportFileRequested() async {
    if (_isCommitInProgress) {
      return;
    }
    final project = _readCurrentProject();
    if (project == null) {
      _statusMessage = '请先创建或打开拆书项目。';
      _rebuildView();
      return;
    }
    if (!_snapshotBelongsTo(project)) {
      await refresh();
      return;
    }
    final operation = _beginOperation(project);
    final selectedPath = await _sourcePickerService.pickSourceFile();
    if (!_isCurrentOperation(operation)) {
      return;
    }
    if (selectedPath == null || selectedPath.trim().isEmpty) {
      _statusMessage = '桌面端可选择文本文件；移动端请直接粘贴源文稿。';
      _rebuildView();
      return;
    }
    _snapshot = _snapshot.copyWith(
      isLoading: true,
      operationKind: BookDeconstructionOperationKind.importingSource,
    );
    _statusMessage = '正在读取拆书源文件...';
    _rebuildView();
    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (!_isCurrentOperation(operation)) {
      return;
    }
    try {
      final archiveResult = await _importArchiveWorkflowService.execute(
        project: project,
        sourceFilePath: selectedPath.trim(),
      );
      if (!_isCurrentOperation(operation)) {
        return;
      }
      _snapshot = _invalidatePreview(
        _snapshot.copyWith(
          isLoading: false,
          operationKind: BookDeconstructionOperationKind.idle,
          activeStepId: BookDeconstructionStepId.importSource,
          sourceAbsolutePath: archiveResult.sourceFilePath,
          sourceTitle: archiveResult.sourceTitle,
          sourceContent: archiveResult.sourceText,
        ),
      );
      _clearSplitRecoveryState();
      await _persistRecoveryStateNow(project, operation);
      if (!_isCurrentOperation(operation)) {
        return;
      }
      _statusMessage = '原文已导入，可进行拆书。';
      _rebuildView();
    } catch (error) {
      if (!_isCurrentOperation(operation)) {
        return;
      }
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        operationKind: BookDeconstructionOperationKind.idle,
      );
      _statusMessage = UserFacingErrorHumanizer.humanize(
        error,
        action: '读取源文件',
      );
      _rebuildView();
    }
  }

  @override
  void onBookDeconstructionSourceTitleChanged(String value) {
    if (_isCommitInProgress) {
      return;
    }
    if (!_ensureSnapshotForCurrentProject()) {
      return;
    }
    _cancelOperationForSourceMutation();
    _clearSplitRecoveryState();
    _snapshot = _invalidatePreview(_snapshot.copyWith(sourceTitle: value));
    _scheduleRecoveryStatePersistence();
    _rebuildView();
  }

  @override
  void onBookDeconstructionSourceContentChanged(String value) {
    if (_isCommitInProgress) {
      return;
    }
    if (!_ensureSnapshotForCurrentProject()) {
      return;
    }
    _cancelOperationForSourceMutation();
    _clearSplitRecoveryState();
    _snapshot = _invalidatePreview(
      _snapshot.copyWith(sourceAbsolutePath: '', sourceContent: value),
    );
    _scheduleRecoveryStatePersistence();
    _rebuildView();
  }

  // === 步骤②：拆书（纯净分章）=============================================

  @override
  void onBookDeconstructionSplitUseModelChanged(bool value) {
    if (_isCommitInProgress) {
      return;
    }
    if (!_ensureSnapshotForCurrentProject()) {
      return;
    }
    // 中文注释: 只有选了拆书模型才允许勾"使用模型"；取消勾选时清掉模型键更直观。
    final canUse = _readImportAssistantModelOptions().isNotEmpty;
    final next = value && canUse;
    _snapshot = _snapshot.copyWith(
      splitUseModel: next,
      splitModelOptionKey: next ? _snapshot.splitModelOptionKey : '',
    );
    _persistRecoveryStateAfterDiscreteChange();
    _rebuildView();
  }

  @override
  void onBookDeconstructionSplitModelSelected(String optionKey) {
    if (_isCommitInProgress) {
      return;
    }
    if (!_ensureSnapshotForCurrentProject()) {
      return;
    }
    _snapshot = _snapshot.copyWith(splitModelOptionKey: optionKey);
    _persistRecoveryStateAfterDiscreteChange();
    _rebuildView();
  }

  @override
  Future<void> onBookDeconstructionSplitRequested() async {
    if (_isCommitInProgress) {
      return;
    }
    final project = _readCurrentProject();
    if (project == null) {
      await refresh(status: '请先创建或打开拆书项目。');
      return;
    }
    if (!_snapshotBelongsTo(project)) {
      await refresh();
      return;
    }
    if (_snapshot.sourceContent.trim().isEmpty) {
      _statusMessage = '请先导入文件或粘贴源文稿。';
      _rebuildView();
      return;
    }
    final sourceTitle = _snapshot.sourceTitle;
    final sourceContent = _snapshot.sourceContent;
    final sourceAbsolutePath = _snapshot.sourceAbsolutePath;
    final splitModelOptionKey = _snapshot.splitModelOptionKey;
    final selectedFollowupOptionId = _snapshot.selectedFollowupOptionId;
    final preferredContinuationDirection = _preferredContinuationDirection();
    final useModel =
        _snapshot.splitUseModel && splitModelOptionKey.trim().isNotEmpty;
    final operation = _beginOperation(project);
    _snapshot = _snapshot.copyWith(
      isLoading: true,
      operationKind: BookDeconstructionOperationKind.splittingChapters,
    );
    _statusMessage = sourceAbsolutePath.trim().isEmpty
        ? '正在归档粘贴源文并拆书...'
        : useModel
        ? '正在用模型辅助拆书（分章 + 去噪）...'
        : '正在拆书（分章 + 去噪）...';
    _rebuildView();
    await _persistRecoveryStateNow(project, operation);
    if (!_isCurrentOperation(operation)) {
      return;
    }
    try {
      await _archivePastedSourceBeforeSplit(
        project: project,
        sourceTitle: sourceTitle,
        sourceContent: sourceContent,
        sourceAbsolutePath: sourceAbsolutePath,
        operation: operation,
      );
      if (!_isCurrentOperation(operation)) {
        return;
      }
      _statusMessage = useModel ? '正在用模型辅助拆书（分章 + 去噪）...' : '正在拆书（分章 + 去噪）...';
      _rebuildView();
      await Future<void>.delayed(const Duration(milliseconds: 16));
      if (!_isCurrentOperation(operation)) {
        return;
      }
      // 中文注释: 拆书永远只产出纯净分章（extractKnowledge:false）。勾了模型时，先用所选
      // 模型跑智能导入去噪（需源文件；粘贴内容无文件则跳过去噪、走规则分章，如实提示），
      // 再把（可能的）去噪正文喂给分章 use case。模型与分析步独立不继承。
      var splitSource = sourceContent;
      var modelNote = '';
      if (useModel) {
        final sourcePath = sourceAbsolutePath.trim();
        final readSettings = _readSettings;
        final factory = _generateDraftUseCaseFactory;
        final key = _modelOptionsService.splitKey(splitModelOptionKey);
        if (sourcePath.isEmpty) {
          modelNote = '（粘贴内容未走模型去噪：模型去噪需先选择文件；已按规则分章）';
        } else if (readSettings == null || factory == null) {
          modelNote = '（模型未接入，已按规则分章）';
        } else if (key.providerId.isEmpty || key.modelId.isEmpty) {
          modelNote = '（所选模型无效，已按规则分章）';
        } else {
          final orchestration =
              BookDeconstructionSmartImportOrchestrationService(
                agentService: BookDeconstructionSmartImportAgentService(
                  readSettings: readSettings,
                  generateDraftUseCaseFactory: factory,
                ),
              );
          final result = await orchestration
              .execute(
                project: project,
                sourcePaths: <String>[sourcePath],
                providerId: key.providerId,
                modelId: key.modelId,
              )
              .timeout(_longOperationTimeout);
          if (!_isCurrentOperation(operation)) {
            return;
          }
          if (result.applied && result.normalizedSourceText.trim().isNotEmpty) {
            splitSource = result.normalizedSourceText;
          } else {
            modelNote = result.note.trim().isEmpty
                ? '（模型未产出有效去噪正文，已按规则分章）'
                : '（${result.note}；已按规则分章）';
          }
        }
      }
      final buildResult = await _draftBuilderService
          .build(
            sourceTitle: sourceTitle,
            sourceContent: splitSource,
            sourceAbsolutePath: sourceAbsolutePath,
            storageStrategy: project.storageStrategy,
            extractionId: '',
            preferredContinuationDirection: preferredContinuationDirection,
            extractKnowledge: false,
          )
          .timeout(_longOperationTimeout);
      if (!_isCurrentOperation(operation)) {
        return;
      }
      final selectedIds = buildResult.applicationPlan.items
          .map((item) => item.id)
          .toSet();
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        operationKind: BookDeconstructionOperationKind.idle,
        activeStepId: BookDeconstructionStepId.splitChapters,
        buildResult: buildResult,
        selectedItemIds: selectedIds,
        selectedFollowupOptionId: _followupOptionSelectionService
            .resolveSelectedOptionId(
              followupMenu: buildResult.followupMenu,
              preferredOptionId: selectedFollowupOptionId,
            ),
        confirmedPreviewPath: '',
        analysisCompleted: false,
        analysisStatusMessage: '',
        analysisStagingRunId: '',
        analysisStagingPackageId: '',
        analysisStagingPackageVersionId: '',
        applyStagedAnalysisResults: false,
        structuredSourceProjectionReady: false,
      );
      _splitSourceContent = splitSource;
      _splitExtractionId = buildResult.extractionResult.extractionId;
      _splitContinuationDirectionId = preferredContinuationDirection.name;
      await _persistRecoveryStateNow(project, operation);
      if (!_isCurrentOperation(operation)) {
        return;
      }
      await _persistStructuredSourceProjection(project, buildResult, operation);
      if (!_isCurrentOperation(operation)) {
        return;
      }
      _snapshot = _snapshot.copyWith(structuredSourceProjectionReady: true);
      _statusMessage =
          '已完成拆书，共分出 ${buildResult.extractionResult.chapterOutlines.length} 章$modelNote。';
      _rebuildView();
    } catch (error) {
      if (!_isCurrentOperation(operation)) {
        return;
      }
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        operationKind: BookDeconstructionOperationKind.idle,
      );
      _statusMessage = UserFacingErrorHumanizer.humanize(
        error,
        action: sourceAbsolutePath.trim().isEmpty ? '归档粘贴源文' : '拆书',
      );
      _rebuildView();
    }
  }

  Future<void> _persistStructuredSourceProjection(
    ProjectDescriptor project,
    BookDeconstructionDraftBuildResult buildResult,
    _BookDeconstructionOperationContext operation,
  ) async {
    // 中文注释: 拆书一完成就落盘结构化源文投影，让步骤③"分析"立刻有产物可读，不再依赖步骤④确认。
    // 与 confirm_workflow_service 用同一份 render 逻辑，保证分析与确认读取/写入的产物一致。
    if (!_isCurrentOperation(operation)) {
      return;
    }
    final path = _structuredSourceProjectionService.targetPath(
      storageStrategy: project.storageStrategy,
    );
    await _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: path,
      content: _structuredSourceProjectionService.render(
        buildResult: buildResult,
      ),
    );
  }

  Future<void> _archivePastedSourceBeforeSplit({
    required ProjectDescriptor project,
    required String sourceTitle,
    required String sourceContent,
    required String sourceAbsolutePath,
    required _BookDeconstructionOperationContext operation,
  }) async {
    // 中文注释: 文件导入已经由 import workflow 归档；这里专门处理当前输入框内的文本快照。
    // 归档只在用户明确启动拆书时进行，避免每个输入字符都触发文件和 SQLite 写入。
    if (sourceAbsolutePath.trim().isNotEmpty ||
        sourceContent.trim().isEmpty ||
        !_isCurrentOperation(operation)) {
      return;
    }
    final archivePath = _targetPathService.sourceArchivePath(
      _pastedSourceArchiveIdentity,
      storageStrategy: project.storageStrategy,
    );
    final archiveTitle = sourceTitle.trim().isEmpty
        ? '拆书粘贴原文'
        : sourceTitle.trim();
    // SQLite 主事实源先于 Markdown 投影提交；后续软取消不能留下仅文件归档的半完成状态。
    await _structuredContentBridgeService.persistSourceOriginalArchive(
      project: project,
      archivePath: archivePath,
      archiveTitle: archiveTitle,
      sourceContent: sourceContent,
      statePath: BookDeconstructionWorkflowRecoveryState.relativePath,
    );
    await _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: archivePath,
      content: sourceContent,
    );
  }

  // === 步骤③：分析（可选·需选模型）=========================================

  @override
  void onBookDeconstructionAnalysisUseModelChanged(bool value) {
    if (_isCommitInProgress) {
      return;
    }
    if (!_ensureSnapshotForCurrentProject()) {
      return;
    }
    final canUse = _readImportAssistantModelOptions().isNotEmpty;
    final next = value && canUse;
    _snapshot = _snapshot.copyWith(
      analysisUseModel: next,
      analysisModelOptionKey: next ? _snapshot.analysisModelOptionKey : '',
    );
    _persistRecoveryStateAfterDiscreteChange();
    _rebuildView();
  }

  @override
  void onBookDeconstructionAnalysisModelSelected(String optionKey) {
    if (_isCommitInProgress) {
      return;
    }
    if (!_ensureSnapshotForCurrentProject()) {
      return;
    }
    _snapshot = _snapshot.copyWith(analysisModelOptionKey: optionKey);
    _persistRecoveryStateAfterDiscreteChange();
    _rebuildView();
  }

  @override
  Future<void> onBookDeconstructionAnalysisRequested() async {
    if (_isCommitInProgress) {
      return;
    }
    // 中文注释: 分析是可选阶段，且必须选了模型才能跑（本地/无模型分析质量过低，不提供）。
    // 模型与"拆书"步独立不继承。委托 app_shell 注入的隐藏内置智能体 reference_extraction。
    final project = _readCurrentProject();
    final handler = _extractKnowledgeHandler;
    if (project == null || handler == null) {
      _statusMessage = '分析尚未接入，可跳过此步直接确认进入创作。';
      _rebuildView();
      return;
    }
    if (!_snapshotBelongsTo(project)) {
      await refresh();
      return;
    }
    if (!_snapshot.structuredSourceProjectionReady) {
      _statusMessage = '拆书结构化源文尚未成功写入，不能执行模型分析；请重新拆书后再重试。';
      _rebuildView();
      return;
    }
    if (!_snapshot.analysisUseModel ||
        _snapshot.analysisModelOptionKey.trim().isEmpty) {
      _statusMessage = '请先勾选"使用模型"并选择一个模型，再进行分析；或跳过此步直接确认。';
      _rebuildView();
      return;
    }
    final key = _modelOptionsService.splitKey(_snapshot.analysisModelOptionKey);
    if (key.providerId.isEmpty || key.modelId.isEmpty) {
      _statusMessage = '所选分析模型无效，请重新选择。';
      _rebuildView();
      return;
    }
    final operation = _beginOperation(project);
    _snapshot = _snapshot.copyWith(
      isLoading: true,
      operationKind: BookDeconstructionOperationKind.analyzingAssets,
    );
    _statusMessage = '正在用内置智能体分析拆书产物（读取分章正文）...';
    _rebuildView();
    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (!_isCurrentOperation(operation)) {
      return;
    }
    try {
      final result = await handler(
        project,
        providerId: key.providerId,
        modelId: key.modelId,
      ).timeout(_longOperationTimeout);
      if (!_isCurrentOperation(operation)) {
        return;
      }
      final hasPromotableStagedAnalysis = result.ok && result.hasStagedPackage;
      _replaceConfirmationPayload(
        _snapshot.copyWith(
          isLoading: false,
          operationKind: BookDeconstructionOperationKind.idle,
          activeStepId: BookDeconstructionStepId.analyzeAssets,
          analysisCompleted: hasPromotableStagedAnalysis,
          analysisStatusMessage: hasPromotableStagedAnalysis
              ? '已用所选模型完成分析，结果仅暂存、尚未应用到项目资产：${result.statusMessage}'
              : result.ok
              ? '分析结果缺少可恢复的暂存标识，不能应用到项目资产；请重新执行分析。'
              : '分析未完成：${result.statusMessage}（可跳过此步直接确认进入创作）',
          analysisStagingRunId: hasPromotableStagedAnalysis ? result.runId : '',
          analysisStagingPackageId: hasPromotableStagedAnalysis
              ? result.packageId
              : '',
          analysisStagingPackageVersionId: hasPromotableStagedAnalysis
              ? result.packageVersionId
              : '',
          // A newly produced staging package is never implicitly applied.
          applyStagedAnalysisResults: false,
        ),
      );
      await _persistRecoveryStateNow(project, operation);
      if (!_isCurrentOperation(operation)) {
        return;
      }
      _statusMessage = _snapshot.analysisStatusMessage;
      _rebuildView();
    } catch (error) {
      if (!_isCurrentOperation(operation)) {
        return;
      }
      _replaceConfirmationPayload(
        _snapshot.copyWith(
          isLoading: false,
          operationKind: BookDeconstructionOperationKind.idle,
          analysisCompleted: false,
          analysisStatusMessage:
              '${UserFacingErrorHumanizer.humanize(error, action: '分析')}（可跳过此步直接确认进入创作）',
          analysisStagingRunId: '',
          analysisStagingPackageId: '',
          analysisStagingPackageVersionId: '',
          applyStagedAnalysisResults: false,
        ),
      );
      await _persistRecoveryStateNow(project, operation);
      if (!_isCurrentOperation(operation)) {
        return;
      }
      _statusMessage = _snapshot.analysisStatusMessage;
      _rebuildView();
    }
  }

  // === 步骤④：确认 ========================================================

  @override
  void onBookDeconstructionPlanItemSelectionChanged({
    required String itemId,
    required bool selected,
  }) {
    if (_isCommitInProgress) {
      return;
    }
    if (!_ensureSnapshotForCurrentProject()) {
      return;
    }
    final nextSelected = Set<String>.from(_snapshot.selectedItemIds);
    if (selected) {
      nextSelected.add(itemId.trim());
    } else {
      nextSelected.remove(itemId.trim());
    }
    _replaceConfirmationPayload(
      _snapshot.copyWith(selectedItemIds: nextSelected),
    );
    _persistRecoveryStateAfterDiscreteChange();
    _rebuildView();
  }

  @override
  void onBookDeconstructionSelectAllRequested() {
    if (_isCommitInProgress) {
      return;
    }
    if (!_ensureSnapshotForCurrentProject()) {
      return;
    }
    final buildResult = _snapshot.buildResult;
    if (buildResult == null) {
      return;
    }
    _replaceConfirmationPayload(
      _snapshot.copyWith(
        selectedItemIds: buildResult.applicationPlan.items
            .map((item) => item.id)
            .toSet(),
      ),
    );
    _persistRecoveryStateAfterDiscreteChange();
    _rebuildView();
  }

  @override
  void onBookDeconstructionClearSelectionRequested() {
    if (_isCommitInProgress) {
      return;
    }
    if (!_ensureSnapshotForCurrentProject()) {
      return;
    }
    _replaceConfirmationPayload(
      _snapshot.copyWith(selectedItemIds: <String>{}),
    );
    _persistRecoveryStateAfterDiscreteChange();
    _rebuildView();
  }

  @override
  void onBookDeconstructionFollowupOptionSelected(String optionId) {
    if (_isCommitInProgress) {
      return;
    }
    if (!_ensureSnapshotForCurrentProject()) {
      return;
    }
    final buildResult = _snapshot.buildResult;
    if (buildResult == null) {
      return;
    }
    final resolvedId = _followupOptionSelectionService.resolveSelectedOptionId(
      followupMenu: buildResult.followupMenu,
      preferredOptionId: optionId,
    );
    if (resolvedId.isEmpty) {
      return;
    }
    _snapshot = _snapshot.copyWith(selectedFollowupOptionId: resolvedId);
    _persistRecoveryStateAfterDiscreteChange();
    _rebuildView();
  }

  @override
  void onBookDeconstructionTargetWritingTypeSelected(
    String targetWritingTypeId,
  ) {
    if (_isCommitInProgress) {
      return;
    }
    if (!_ensureSnapshotForCurrentProject()) {
      return;
    }
    final cleanTargetWritingTypeId = targetWritingTypeId.trim();
    final project = _readCurrentProject();
    if (project == null) {
      return;
    }
    _replaceConfirmationPayload(
      _snapshot.copyWith(
        selectedTargetWritingTypeId: cleanTargetWritingTypeId,
        selectedTargetRuntimeBaselineId: _resolveTargetRuntimeBaselineId(
          project: project,
          targetWritingTypeId: cleanTargetWritingTypeId,
          preferredRuntimeBaselineId: _snapshot.selectedTargetRuntimeBaselineId,
        ),
      ),
    );
    _persistRecoveryStateAfterDiscreteChange();
    _rebuildView();
  }

  @override
  void onBookDeconstructionTargetRuntimeBaselineSelected(
    String runtimeBaselineId,
  ) {
    if (_isCommitInProgress) {
      return;
    }
    if (!_ensureSnapshotForCurrentProject()) {
      return;
    }
    const baselineCatalog = ProjectRuntimeBaselineCatalogService();
    final project = _readCurrentProject();
    if (project == null) {
      return;
    }
    if (_isSameLongNovelTarget(project)) {
      _replaceConfirmationPayload(
        _snapshot.copyWith(
          selectedTargetRuntimeBaselineId: baselineCatalog
              .normalizeForProjectType(
                project.projectType,
                project.runtimeBaselineId,
              ),
        ),
      );
      _statusMessage = '当前项目已是长篇类型，运行基准沿用已有项目配置。';
      _persistRecoveryStateAfterDiscreteChange();
      _rebuildView();
      return;
    }
    _replaceConfirmationPayload(
      _snapshot.copyWith(
        selectedTargetRuntimeBaselineId: baselineCatalog
            .normalizeForProjectType(
              _snapshot.selectedTargetWritingTypeId,
              runtimeBaselineId,
            ),
      ),
    );
    _persistRecoveryStateAfterDiscreteChange();
    _rebuildView();
  }

  @override
  void onBookDeconstructionInheritAsLiveNarrativeChanged(bool value) {
    if (_isCommitInProgress) {
      return;
    }
    if (!_ensureSnapshotForCurrentProject()) {
      return;
    }
    _replaceConfirmationPayload(
      _snapshot.copyWith(inheritAsLiveNarrative: value),
    );
    _persistRecoveryStateAfterDiscreteChange();
    _rebuildView();
  }

  @override
  void onBookDeconstructionApplyStagedAnalysisResultsChanged(bool value) {
    if (_isCommitInProgress) {
      return;
    }
    if (!_ensureSnapshotForCurrentProject()) {
      return;
    }
    final hasPromotableStagedAnalysis =
        _snapshot.analysisCompleted &&
        _snapshot.analysisStagingRunId.trim().isNotEmpty &&
        _snapshot.analysisStagingPackageId.trim().isNotEmpty &&
        _snapshot.analysisStagingPackageVersionId.trim().isNotEmpty;
    if (value && !hasPromotableStagedAnalysis) {
      _statusMessage = '当前没有可应用的步骤③暂存分析结果，请先完成分析。';
      _rebuildView();
      return;
    }
    _replaceConfirmationPayload(
      _snapshot.copyWith(applyStagedAnalysisResults: value),
    );
    _persistRecoveryStateAfterDiscreteChange();
    _rebuildView();
  }

  @override
  Future<void> onBookDeconstructionConfirmRequested() async {
    if (_isCommitInProgress) {
      return;
    }
    final validation = _validateConfirmationRequest();
    if (!validation.isValid) {
      return;
    }
    final operation = _beginOperation(validation.project!);
    _snapshot = _snapshot.copyWith(
      isLoading: true,
      operationKind: BookDeconstructionOperationKind.confirmingSelection,
    );
    _statusMessage = '正在写入拆书预演纪要...';
    _rebuildView();
    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (!_isCurrentOperation(operation)) {
      return;
    }
    try {
      final result = await _persistConfirmation(
        project: validation.project!,
        buildResult: validation.buildResult!,
        operation: operation,
      );
      if (result == null || !_isCurrentOperation(operation)) {
        return;
      }
      _statusMessage = _confirmationSuccessMessage(result);
      _rebuildView();
    } catch (error) {
      if (!_isCurrentOperation(operation)) {
        return;
      }
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        operationKind: BookDeconstructionOperationKind.idle,
      );
      _statusMessage = UserFacingErrorHumanizer.humanize(
        error,
        action: '写入拆书预演纪要',
      );
      _rebuildView();
    }
  }

  @override
  Future<void> onBookDeconstructionCreateDerivedProjectRequested() async {
    if (_isCommitInProgress) {
      return;
    }
    if (!_isDerivedProjectCreationAvailable()) {
      _statusMessage = '当前派生项目创建暂不可用。';
      _rebuildView();
      return;
    }
    final validation = _validateConfirmationRequest();
    if (!validation.isValid) {
      return;
    }
    final creationService = _derivedProjectCreationService!;
    final openDerivedProjectRequested = _openDerivedProjectRequested!;
    if (_projectsRootPath.trim().isEmpty) {
      _statusMessage = '未配置派生项目根目录，当前无法自动创建项目。';
      _rebuildView();
      return;
    }
    final operation = _beginOperation(validation.project!);
    final selectedItemIds = Set<String>.from(_snapshot.selectedItemIds);
    final selectedFollowupOptionId = _snapshot.selectedFollowupOptionId;
    final confirmedPreviewPath = _snapshot.confirmedPreviewPath;
    _snapshot = _snapshot.copyWith(
      isLoading: true,
      operationKind: BookDeconstructionOperationKind.creatingDerivedProject,
    );
    _statusMessage = '正在派生并创建后续项目...';
    _rebuildView();
    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (!_isCurrentOperation(operation)) {
      return;
    }
    try {
      if (confirmedPreviewPath.trim().isEmpty) {
        final confirmation = await _persistConfirmation(
          project: validation.project!,
          buildResult: validation.buildResult!,
          operation: operation,
        );
        if (confirmation == null || !_isCurrentOperation(operation)) {
          return;
        }
        _statusMessage = _confirmationSuccessMessage(confirmation);
        _snapshot = _snapshot.copyWith(
          isLoading: true,
          operationKind: BookDeconstructionOperationKind.creatingDerivedProject,
        );
        _rebuildView();
      }
      if (!_isCurrentOperation(operation)) {
        return;
      }
      final result = await creationService.execute(
        projectsRootPath: _projectsRootPath,
        sourceProject: validation.project!,
        buildResult: validation.buildResult!,
        selectedItemIds: selectedItemIds,
        selectedFollowupOptionId: selectedFollowupOptionId,
      );
      if (!_isCurrentOperation(operation)) {
        return;
      }
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        operationKind: BookDeconstructionOperationKind.idle,
      );
      _statusMessage = '已派生项目：${result.project.name}';
      _rebuildView();
      await openDerivedProjectRequested(
        result.project,
        result.preferredOpenPath,
      );
    } catch (error) {
      if (!_isCurrentOperation(operation)) {
        return;
      }
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        operationKind: BookDeconstructionOperationKind.idle,
      );
      _statusMessage = UserFacingErrorHumanizer.humanize(error, action: '派生项目');
      _rebuildView();
    }
  }

  @override
  void dispose() {
    _invalidateInFlightOperations();
    _invalidateScheduledRecoveryPersistence();
    _disposed = true;
    super.dispose();
  }

  BookDeconstructionSnapshot _invalidatePreview(
    BookDeconstructionSnapshot snapshot,
  ) {
    if (snapshot.buildResult == null &&
        snapshot.selectedItemIds.isEmpty &&
        snapshot.confirmedPreviewPath.trim().isEmpty &&
        !snapshot.analysisCompleted) {
      return snapshot;
    }
    // 中文注释: 源文稿一旦变化，旧的分章结果与分析结果都必须失效，避免误把旧结果当成新结果。
    return snapshot.copyWith(
      buildResult: null,
      selectedItemIds: <String>{},
      selectedFollowupOptionId: '',
      confirmedPreviewPath: '',
      activeStepId: BookDeconstructionStepId.importSource,
      analysisCompleted: false,
      analysisStatusMessage: '',
      analysisStagingRunId: '',
      analysisStagingPackageId: '',
      analysisStagingPackageVersionId: '',
      applyStagedAnalysisResults: false,
      structuredSourceProjectionReady: false,
    );
  }

  void _replaceConfirmationPayload(BookDeconstructionSnapshot next) {
    final confirmationPayloadChanged = !_hasSameConfirmationPayload(
      leftSelectedItemIds: _snapshot.selectedItemIds,
      leftTargetWritingTypeId: _snapshot.selectedTargetWritingTypeId,
      leftTargetRuntimeBaselineId: _snapshot.selectedTargetRuntimeBaselineId,
      leftInheritAsLiveNarrative: _snapshot.inheritAsLiveNarrative,
      leftApplyStagedAnalysisResults: _snapshot.applyStagedAnalysisResults,
      leftStagedAnalysisRunId: _snapshot.analysisStagingRunId,
      leftStagedAnalysisPackageId: _snapshot.analysisStagingPackageId,
      leftStagedAnalysisPackageVersionId:
          _snapshot.analysisStagingPackageVersionId,
      rightSelectedItemIds: next.selectedItemIds,
      rightTargetWritingTypeId: next.selectedTargetWritingTypeId,
      rightTargetRuntimeBaselineId: next.selectedTargetRuntimeBaselineId,
      rightInheritAsLiveNarrative: next.inheritAsLiveNarrative,
      rightApplyStagedAnalysisResults: next.applyStagedAnalysisResults,
      rightStagedAnalysisRunId: next.analysisStagingRunId,
      rightStagedAnalysisPackageId: next.analysisStagingPackageId,
      rightStagedAnalysisPackageVersionId: next.analysisStagingPackageVersionId,
    );
    final hadConfirmedPreview = _snapshot.confirmedPreviewPath
        .trim()
        .isNotEmpty;
    _snapshot = confirmationPayloadChanged && hadConfirmedPreview
        ? next.copyWith(confirmedPreviewPath: '')
        : next;
    if (confirmationPayloadChanged && hadConfirmedPreview) {
      _statusMessage = '确认条件已变更，请重新确认后再派生项目。';
    }
  }

  _BookDeconstructionConfirmationValidation _validateConfirmationRequest() {
    final project = _readCurrentProject();
    if (project == null) {
      refresh(status: '请先创建或打开拆书项目。');
      return const _BookDeconstructionConfirmationValidation.invalid();
    }
    if (!_snapshotBelongsTo(project)) {
      refresh();
      return const _BookDeconstructionConfirmationValidation.invalid();
    }
    final buildResult = _snapshot.buildResult;
    if (buildResult == null) {
      _statusMessage = '请先完成拆书。';
      _rebuildView();
      return const _BookDeconstructionConfirmationValidation.invalid();
    }
    if (_snapshot.selectedItemIds.isEmpty) {
      _statusMessage = '请至少勾选一个拟应用条目。';
      _rebuildView();
      return const _BookDeconstructionConfirmationValidation.invalid();
    }
    if (_snapshot.selectedTargetWritingTypeId.trim().isEmpty) {
      _statusMessage = '请先选择拆书后要复合成的写作项目类型。';
      _rebuildView();
      return const _BookDeconstructionConfirmationValidation.invalid();
    }
    if (_snapshot.selectedTargetWritingTypeId.trim() == 'long_novel' &&
        const ProjectRuntimeBaselineCatalogService()
            .normalizeForProjectType(
              'long_novel',
              _snapshot.selectedTargetRuntimeBaselineId,
            )
            .isEmpty) {
      _statusMessage = '请先为长篇长任务选择运行基准。';
      _rebuildView();
      return const _BookDeconstructionConfirmationValidation.invalid();
    }
    if (_snapshot.applyStagedAnalysisResults &&
        (_snapshot.analysisStagingRunId.trim().isEmpty ||
            _snapshot.analysisStagingPackageId.trim().isEmpty ||
            _snapshot.analysisStagingPackageVersionId.trim().isEmpty)) {
      _statusMessage = '已选择应用步骤③结果，但暂存分析标识不完整；请重新执行分析。';
      _rebuildView();
      return const _BookDeconstructionConfirmationValidation.invalid();
    }
    return _BookDeconstructionConfirmationValidation.valid(
      project: project,
      buildResult: buildResult,
    );
  }

  Future<BookDeconstructionProjectSetup> _loadProjectSetup(
    ProjectDescriptor project,
  ) async {
    try {
      final source = await _readProjectFileUseCase.execute(
        project,
        BookDeconstructionProjectSetupDocumentService.relativePath,
      );
      if (source == null || source.trim().isEmpty) {
        return _projectSetupDocumentService.create();
      }
      return _projectSetupDocumentService.parse(source);
    } catch (_) {
      return _projectSetupDocumentService.create();
    }
  }

  Future<BookDeconstructionWorkflowRecoveryState?> _loadRecoveryState(
    ProjectDescriptor project,
  ) async {
    try {
      final source = await _readProjectFileUseCase.execute(
        project,
        BookDeconstructionWorkflowRecoveryState.relativePath,
      );
      if (source == null) {
        return null;
      }
      return BookDeconstructionWorkflowRecoveryState.tryParse(source);
    } catch (_) {
      return null;
    }
  }

  Future<BookDeconstructionConfirmationJournal?> _loadConfirmationJournal(
    ProjectDescriptor project,
  ) async {
    try {
      final source = await _readProjectFileUseCase.execute(
        project,
        BookDeconstructionConfirmationJournalService.relativePath,
      );
      if (source == null) {
        return null;
      }
      return const BookDeconstructionConfirmationJournalService().tryParse(
        source,
      );
    } catch (_) {
      return null;
    }
  }

  BookDeconstructionConfirmationJournal? _journalForRestoredSplit({
    required BookDeconstructionConfirmationJournal? journal,
    required String splitExtractionId,
  }) {
    final cleanSplitExtractionId = splitExtractionId.trim();
    if (cleanSplitExtractionId.isEmpty ||
        journal?.extractionId.trim() != cleanSplitExtractionId) {
      return null;
    }
    return journal;
  }

  bool _completedJournalMatchesRecoveryState({
    required BookDeconstructionConfirmationJournal? journal,
    required BookDeconstructionWorkflowRecoveryState? recoveryState,
    required ProjectDescriptor project,
  }) {
    // Pending and failed journals describe a possibly partial commit. Keep
    // them recoverable even when the user has since revised the form.
    if (journal == null || !journal.isCompleted || recoveryState == null) {
      return true;
    }
    return _hasSameConfirmationPayload(
          leftSelectedItemIds: journal.selectedItemIds,
          leftTargetWritingTypeId: journal.targetWritingProjectTypeId,
          leftTargetRuntimeBaselineId: journal.targetRuntimeBaselineId,
          leftInheritAsLiveNarrative: journal.inheritAsLiveNarrative,
          leftApplyStagedAnalysisResults: journal.applyStagedAnalysisResults,
          leftStagedAnalysisRunId: journal.stagedAnalysisRunId,
          leftStagedAnalysisPackageId: journal.stagedAnalysisPackageId,
          leftStagedAnalysisPackageVersionId:
              journal.stagedAnalysisPackageVersionId,
          rightSelectedItemIds: recoveryState.selectedItemIds,
          rightTargetWritingTypeId: recoveryState.selectedTargetWritingTypeId,
          rightTargetRuntimeBaselineId:
              recoveryState.selectedTargetRuntimeBaselineId,
          rightInheritAsLiveNarrative: recoveryState.inheritAsLiveNarrative,
          rightApplyStagedAnalysisResults:
              recoveryState.applyStagedAnalysisResults,
          rightStagedAnalysisRunId: recoveryState.analysisStagingRunId,
          rightStagedAnalysisPackageId: recoveryState.analysisStagingPackageId,
          rightStagedAnalysisPackageVersionId:
              recoveryState.analysisStagingPackageVersionId,
        ) &&
        _confirmationRuntimeBaselineMatchesProject(
          project: project,
          targetWritingTypeId: journal.targetWritingProjectTypeId,
          targetRuntimeBaselineId: journal.targetRuntimeBaselineId,
        );
  }

  bool _hasSameConfirmationPayload({
    required Iterable<String> leftSelectedItemIds,
    required String leftTargetWritingTypeId,
    required String leftTargetRuntimeBaselineId,
    required bool leftInheritAsLiveNarrative,
    required bool leftApplyStagedAnalysisResults,
    required String leftStagedAnalysisRunId,
    required String leftStagedAnalysisPackageId,
    required String leftStagedAnalysisPackageVersionId,
    required Iterable<String> rightSelectedItemIds,
    required String rightTargetWritingTypeId,
    required String rightTargetRuntimeBaselineId,
    required bool rightInheritAsLiveNarrative,
    required bool rightApplyStagedAnalysisResults,
    required String rightStagedAnalysisRunId,
    required String rightStagedAnalysisPackageId,
    required String rightStagedAnalysisPackageVersionId,
  }) {
    if (!_sameNormalizedIdSet(leftSelectedItemIds, rightSelectedItemIds) ||
        leftTargetWritingTypeId.trim() != rightTargetWritingTypeId.trim() ||
        leftTargetRuntimeBaselineId.trim() !=
            rightTargetRuntimeBaselineId.trim() ||
        leftInheritAsLiveNarrative != rightInheritAsLiveNarrative ||
        leftApplyStagedAnalysisResults != rightApplyStagedAnalysisResults) {
      return false;
    }
    // Staged-analysis identities affect a confirmation only when the user
    // explicitly asked to mount that staged package.
    if (!leftApplyStagedAnalysisResults) {
      return true;
    }
    return leftStagedAnalysisRunId.trim() == rightStagedAnalysisRunId.trim() &&
        leftStagedAnalysisPackageId.trim() ==
            rightStagedAnalysisPackageId.trim() &&
        leftStagedAnalysisPackageVersionId.trim() ==
            rightStagedAnalysisPackageVersionId.trim();
  }

  bool _sameNormalizedIdSet(Iterable<String> left, Iterable<String> right) {
    final normalizedLeft = left
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    final normalizedRight = right
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    return normalizedLeft.length == normalizedRight.length &&
        normalizedLeft.containsAll(normalizedRight);
  }

  String? _confirmationRecoveryStatusMessage(
    BookDeconstructionConfirmationJournal? journal,
  ) {
    if (journal == null) {
      return null;
    }
    if (journal.isCompleted) {
      return '已恢复已确认的拆书结果，可继续查看或派生后续项目。';
    }
    if (!journal.requiresRecovery) {
      return null;
    }
    final stepHint = journal.currentStep.trim().isEmpty
        ? ''
        : '（进行到 ${journal.currentStep}）';
    if (journal.status == BookDeconstructionConfirmationStatus.failed) {
      final errorHint = journal.error.trim().isEmpty
          ? ''
          : '：${journal.error.trim()}';
      // 中文注释: 如实告知"重新确认会重写各步文件"——章节路径由序号决定、可覆盖，
      // 避免用户以为要先手动清理半成品而不敢重试。
      return '检测到上次确认失败$stepHint$errorHint，已恢复拆书结果。'
          '重新确认会重写各步文件（章节按序号覆盖，通常可安全重试）。';
    }
    return '检测到上次确认未完成$stepHint，已恢复拆书结果，请重新确认以完成写入。';
  }

  BookDeconstructionContinuationDirection _preferredContinuationDirection() {
    final selectedOptionId = _snapshot.selectedFollowupOptionId.trim();
    if (selectedOptionId.startsWith('fanfic_')) {
      return BookDeconstructionContinuationDirection.longTaskPreferred;
    }
    if (selectedOptionId.startsWith('continuation_')) {
      return BookDeconstructionContinuationDirection.generalNovelPreferred;
    }
    return BookDeconstructionContinuationDirection.analysisFirst;
  }

  BookDeconstructionContinuationDirection _splitContinuationDirection() {
    final savedDirectionId = _splitContinuationDirectionId.trim();
    for (final direction in BookDeconstructionContinuationDirection.values) {
      if (direction.name == savedDirectionId) {
        return direction;
      }
    }
    return _preferredContinuationDirection();
  }

  Future<BookDeconstructionConfirmWorkflowResult?> _persistConfirmation({
    required ProjectDescriptor project,
    required BookDeconstructionDraftBuildResult buildResult,
    required _BookDeconstructionOperationContext operation,
  }) async {
    if (!_isCurrentOperation(operation)) {
      return null;
    }
    final result = await _confirmWorkflowService.execute(
      project: project,
      buildResult: buildResult,
      selectedItemIds: _snapshot.selectedItemIds,
      targetWritingProjectTypeId: _snapshot.selectedTargetWritingTypeId,
      targetRuntimeBaselineId: _snapshot.selectedTargetRuntimeBaselineId,
      inheritAsLiveNarrative: _snapshot.inheritAsLiveNarrative,
      applyStagedAnalysisResults: _snapshot.applyStagedAnalysisResults,
      stagedAnalysisRunId: _snapshot.analysisStagingRunId,
      stagedAnalysisPackageId: _snapshot.analysisStagingPackageId,
      stagedAnalysisPackageVersionId: _snapshot.analysisStagingPackageVersionId,
    );
    if (!_isCurrentOperation(operation)) {
      return null;
    }
    await _syncWorkbenchResources();
    if (!_isCurrentOperation(operation)) {
      return null;
    }
    if (result.projectTypeTransitioned) {
      final hook = _onProjectTransitioned;
      if (hook != null) {
        await hook();
        if (!_isCurrentOperation(operation)) {
          return null;
        }
      }
    }
    _snapshot = _snapshot.copyWith(
      isLoading: false,
      operationKind: BookDeconstructionOperationKind.idle,
      activeStepId: BookDeconstructionStepId.confirmSelection,
      confirmedPreviewPath: result.previewPath,
    );
    await _persistRecoveryStateNow(project, operation);
    if (!_isCurrentOperation(operation)) {
      return null;
    }
    return result;
  }

  void _scheduleRecoveryStatePersistence() {
    final project = _readCurrentProject();
    if (project == null || !_snapshotBelongsTo(project)) {
      return;
    }
    final revision = ++_recoveryStateRevision;
    _recoveryStatePersistTimer?.cancel();
    _recoveryStatePersistTimer = Timer(const Duration(milliseconds: 300), () {
      if (_disposed || revision != _recoveryStateRevision) {
        return;
      }
      _enqueueRecoveryStatePersistence(
        project: project,
        state: _recoveryStateFromSnapshot(),
        revision: revision,
      );
    });
  }

  void _persistRecoveryStateAfterDiscreteChange() {
    final project = _readCurrentProject();
    if (project == null || !_snapshotBelongsTo(project)) {
      return;
    }
    unawaited(_persistRecoveryStateNow(project, _captureOperation(project)));
  }

  Future<void> _persistRecoveryStateNow(
    ProjectDescriptor project,
    _BookDeconstructionOperationContext operation,
  ) {
    final revision = ++_recoveryStateRevision;
    _recoveryStatePersistTimer?.cancel();
    return _enqueueRecoveryStatePersistence(
      project: project,
      state: _recoveryStateFromSnapshot(),
      revision: revision,
      operation: operation,
    );
  }

  Future<void> _enqueueRecoveryStatePersistence({
    required ProjectDescriptor project,
    required BookDeconstructionWorkflowRecoveryState state,
    required int revision,
    _BookDeconstructionOperationContext? operation,
  }) {
    final pending = _recoveryStatePersistTail.then((_) async {
      if (_disposed || revision != _recoveryStateRevision) {
        return;
      }
      if (operation != null) {
        if (!_isCurrentOperation(operation)) {
          return;
        }
      } else if (!_snapshotBelongsTo(project) || !_isCurrentProject(project)) {
        return;
      }
      try {
        await _writeProjectTextFileUseCase.execute(
          project: project,
          relativePath: BookDeconstructionWorkflowRecoveryState.relativePath,
          content: state.encode(),
        );
      } catch (_) {
        // Recovery state is best effort and must not block the main workflow.
      }
    });
    _recoveryStatePersistTail = pending;
    return pending;
  }

  BookDeconstructionWorkflowRecoveryState _recoveryStateFromSnapshot() {
    return BookDeconstructionWorkflowRecoveryState(
      sourceAbsolutePath: _snapshot.sourceAbsolutePath,
      sourceTitle: _snapshot.sourceTitle,
      sourceContent: _snapshot.sourceContent,
      splitSourceContent: _splitSourceContent,
      splitExtractionId: _splitExtractionId,
      splitContinuationDirectionId: _splitContinuationDirectionId,
      splitUseModel: _snapshot.splitUseModel,
      splitModelOptionKey: _snapshot.splitModelOptionKey,
      analysisUseModel: _snapshot.analysisUseModel,
      analysisModelOptionKey: _snapshot.analysisModelOptionKey,
      analysisCompleted: _snapshot.analysisCompleted,
      analysisStatusMessage: _snapshot.analysisStatusMessage,
      analysisStagingRunId: _snapshot.analysisStagingRunId,
      analysisStagingPackageId: _snapshot.analysisStagingPackageId,
      analysisStagingPackageVersionId:
          _snapshot.analysisStagingPackageVersionId,
      applyStagedAnalysisResults: _snapshot.applyStagedAnalysisResults,
      selectedItemIds: _snapshot.selectedItemIds.toList(growable: false),
      selectedFollowupOptionId: _snapshot.selectedFollowupOptionId,
      selectedTargetWritingTypeId: _snapshot.selectedTargetWritingTypeId,
      selectedTargetRuntimeBaselineId:
          _snapshot.selectedTargetRuntimeBaselineId,
      inheritAsLiveNarrative: _snapshot.inheritAsLiveNarrative,
      confirmedPreviewPath: _snapshot.confirmedPreviewPath,
      activeStepId: _snapshot.activeStepId,
    );
  }

  void _invalidateScheduledRecoveryPersistence() {
    _recoveryStateRevision += 1;
    _recoveryStatePersistTimer?.cancel();
    _recoveryStatePersistTimer = null;
  }

  void _cancelOperationForSourceMutation() {
    _invalidateInFlightOperations();
    if (!_snapshot.isLoading) {
      return;
    }
    _snapshot = _snapshot.copyWith(
      isLoading: false,
      operationKind: BookDeconstructionOperationKind.idle,
    );
    _statusMessage = '源文已更新，已取消当前操作。';
  }

  void _clearSplitRecoveryState() {
    _splitSourceContent = '';
    _splitExtractionId = '';
    _splitContinuationDirectionId = '';
  }

  _BookDeconstructionOperationContext _beginOperation(
    ProjectDescriptor project,
  ) {
    _invalidateInFlightOperations();
    return _captureOperation(project);
  }

  _BookDeconstructionOperationContext _captureOperation(
    ProjectDescriptor project,
  ) {
    return _BookDeconstructionOperationContext(
      generation: _operationGeneration,
      projectId: project.id,
      projectRootPath: project.rootPath,
    );
  }

  void _invalidateInFlightOperations() {
    _operationGeneration += 1;
  }

  bool _isCurrentOperation(_BookDeconstructionOperationContext operation) {
    if (_disposed || operation.generation != _operationGeneration) {
      return false;
    }
    final project = _readCurrentProject();
    return project != null &&
        _isCurrentProject(project, operation) &&
        _snapshotBelongsTo(project);
  }

  bool get _isCommitInProgress =>
      _snapshot.operationKind ==
          BookDeconstructionOperationKind.confirmingSelection ||
      _snapshot.operationKind ==
          BookDeconstructionOperationKind.creatingDerivedProject;

  bool _snapshotBelongsToCurrentProject() {
    final project = _readCurrentProject();
    return project != null && _snapshotBelongsTo(project);
  }

  bool _snapshotBelongsTo(ProjectDescriptor project) {
    return _snapshotProjectId == project.id &&
        _sameProjectRootPath(_snapshot.projectRootPath, project.rootPath);
  }

  bool _ensureSnapshotForCurrentProject() {
    if (_snapshotBelongsToCurrentProject()) {
      return true;
    }
    unawaited(refresh());
    return false;
  }

  bool _isCurrentProject(
    ProjectDescriptor project, [
    _BookDeconstructionOperationContext? operation,
  ]) {
    final current = _readCurrentProject();
    if (current == null ||
        !_sameProjectRootPath(current.rootPath, project.rootPath)) {
      return false;
    }
    if (operation == null) {
      return current.id == project.id;
    }
    return current.id == operation.projectId &&
        _sameProjectRootPath(current.rootPath, operation.projectRootPath);
  }

  bool _sameProjectRootPath(String left, String right) {
    return _normalizeProjectRootPath(left) == _normalizeProjectRootPath(right);
  }

  String _normalizeProjectRootPath(String value) {
    return value.trim().replaceAll('\\', '/').replaceFirst(RegExp(r'/+$'), '');
  }

  String _confirmationSuccessMessage(
    BookDeconstructionConfirmWorkflowResult result,
  ) {
    final chapterHint = result.chapterPaths.isEmpty
        ? ''
        : '，分章已写入 ${result.chapterPaths.length} 份';
    final transitionHint = result.projectTypeTransitioned
        ? '，项目类型已切换为${result.targetWritingProjectTypeId}'
        : '';
    return '已保存拆书结果（${_snapshot.selectedItemIds.length} 项）$chapterHint$transitionHint。';
  }

  void _rebuildView() {
    final modelOptions = _readImportAssistantModelOptions();
    _viewData = _viewDataService.build(
      projectTitle: _readCurrentProject()?.name ?? '',
      snapshot: _snapshot,
      status: _statusMessage,
      canCreateDerivedProject: _isDerivedProjectCreationAvailable(),
      splitModelOptions: modelOptions,
      analysisModelOptions: modelOptions,
      targetWritingTypeOptions: _readTargetWritingTypeOptions(),
      targetRuntimeBaselineOptions: _readTargetRuntimeBaselineOptions(),
      canSelectTargetRuntimeBaseline: _canSelectTargetRuntimeBaseline(),
    );
    if (!_disposed) {
      notifyListeners();
    }
  }

  bool _isDerivedProjectCreationAvailable() {
    return _derivedProjectCreationService != null &&
        _openDerivedProjectRequested != null &&
        _projectsRootPath.trim().isNotEmpty;
  }

  List<SelectorOptionViewData> _readTargetWritingTypeOptions() {
    // 中文注释: 复合项目类型可选目标 = 当前项目类型可转换到的写作类型；已带拆书 trait 的
    // 写作项目还必须保留当前类型，确认时不应被迫做一次无意义的反向转换。
    const catalog = ProjectTypeCatalogService();
    return _targetWritingTypeIdsForProject(_readCurrentProject())
        .map((id) => catalog.definitionOf(id))
        .map((d) => SelectorOptionViewData(id: d.id, label: d.name))
        .toList(growable: false);
  }

  List<String> _targetWritingTypeIdsForProject(ProjectDescriptor? project) {
    const policy = ProjectTypeTransitionPolicy();
    final sourceId = project == null
        ? BookDeconstructionConstants.projectTypeId
        : project.projectType;
    final targetIds = <String>[];
    if (project != null && _isWritingProjectType(project)) {
      targetIds.add(project.projectType);
    }
    for (final targetId in policy.availableTargetProjectTypeIds(sourceId)) {
      if (!targetIds.contains(targetId)) {
        targetIds.add(targetId);
      }
    }
    return List<String>.unmodifiable(targetIds);
  }

  bool _isCompositeBookDeconstructionWritingProject(ProjectDescriptor project) {
    if (!_isWritingProjectType(project)) {
      return false;
    }
    return const ProjectCapabilityService().hasBookDeconstruction(
      projectTypeId: project.projectType,
      additionalTraitIds: project.additionalTraitIds,
      runtimeBaselineId: project.runtimeBaselineId,
    );
  }

  bool _isWritingProjectType(ProjectDescriptor project) {
    final projectTypeId = project.projectType.trim();
    return projectTypeId == 'novel' || projectTypeId == 'long_novel';
  }

  String _resolveTargetWritingTypeId({
    required ProjectDescriptor project,
    required String preferredTargetWritingTypeId,
  }) {
    final availableTargetIds = _targetWritingTypeIdsForProject(project);
    final cleanPreferredTargetId = preferredTargetWritingTypeId.trim();
    if (availableTargetIds.contains(cleanPreferredTargetId)) {
      return cleanPreferredTargetId;
    }
    if (_isCompositeBookDeconstructionWritingProject(project) &&
        availableTargetIds.contains(project.projectType)) {
      return project.projectType;
    }
    return '';
  }

  String _resolveTargetRuntimeBaselineId({
    required ProjectDescriptor project,
    required String targetWritingTypeId,
    required String preferredRuntimeBaselineId,
  }) {
    const catalog = ProjectRuntimeBaselineCatalogService();
    final projectRuntimeBaselineId = catalog.normalizeForProjectType(
      project.projectType,
      project.runtimeBaselineId,
    );
    if (_isSameLongNovelTarget(project, targetWritingTypeId) &&
        projectRuntimeBaselineId.isNotEmpty) {
      return projectRuntimeBaselineId;
    }
    final normalizedPreferred = catalog.normalizeForProjectType(
      targetWritingTypeId,
      preferredRuntimeBaselineId,
    );
    if (normalizedPreferred.isNotEmpty) {
      return normalizedPreferred;
    }
    return catalog.normalizeForProjectType(
      targetWritingTypeId,
      project.runtimeBaselineId,
    );
  }

  bool _confirmationRuntimeBaselineMatchesProject({
    required ProjectDescriptor project,
    required String targetWritingTypeId,
    required String targetRuntimeBaselineId,
  }) {
    if (!_isSameLongNovelTarget(project, targetWritingTypeId)) {
      return true;
    }
    const catalog = ProjectRuntimeBaselineCatalogService();
    final projectRuntimeBaselineId = catalog.normalizeForProjectType(
      project.projectType,
      project.runtimeBaselineId,
    );
    // Old long_novel projects without a durable baseline remain recoverable,
    // but cannot pass confirmation preflight until their runtime configuration
    // is repaired. A configured project is authoritative over old UI caches.
    if (projectRuntimeBaselineId.isEmpty) {
      return true;
    }
    return catalog.normalizeForProjectType(
          targetWritingTypeId,
          targetRuntimeBaselineId,
        ) ==
        projectRuntimeBaselineId;
  }

  List<SelectorOptionViewData> _readTargetRuntimeBaselineOptions() {
    const catalog = ProjectRuntimeBaselineCatalogService();
    return catalog
        .definitionsForProjectType(_snapshot.selectedTargetWritingTypeId)
        .where((definition) => definition.enabled)
        .map(
          (definition) => SelectorOptionViewData(
            id: definition.id,
            label: definition.title,
            note: definition.description,
          ),
        )
        .toList(growable: false);
  }

  bool _canSelectTargetRuntimeBaseline() {
    final project = _readCurrentProject();
    return project == null || !_isSameLongNovelTarget(project);
  }

  bool _isSameLongNovelTarget(
    ProjectDescriptor project, [
    String? targetWritingTypeId,
  ]) {
    return project.projectType.trim() == 'long_novel' &&
        (targetWritingTypeId ?? _snapshot.selectedTargetWritingTypeId).trim() ==
            'long_novel';
  }
}

class _BookDeconstructionConfirmationValidation {
  const _BookDeconstructionConfirmationValidation.invalid()
    : isValid = false,
      project = null,
      buildResult = null;

  const _BookDeconstructionConfirmationValidation.valid({
    required this.project,
    required this.buildResult,
  }) : isValid = true;

  final bool isValid;
  final ProjectDescriptor? project;
  final BookDeconstructionDraftBuildResult? buildResult;
}

class _BookDeconstructionOperationContext {
  const _BookDeconstructionOperationContext({
    required this.generation,
    required this.projectId,
    required this.projectRootPath,
  });

  final int generation;
  final String projectId;
  final String projectRootPath;
}
