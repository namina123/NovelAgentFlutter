import 'package:flutter/foundation.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';

import '../../../../shared/services/user_facing_error_humanizer.dart';
import '../../../workbench/application/services/import_assistant_model_options_service.dart';
import '../../../workbench/presentation/models/selector_option_view_data.dart';

import '../../presentation/contracts/book_deconstruction_action_handler.dart';
import '../../presentation/models/book_deconstruction_view_data.dart';
import '../models/book_deconstruction_operation_kind.dart';
import '../models/book_deconstruction_snapshot.dart';
import '../models/book_deconstruction_step_id.dart';
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
/// 用户选择透传（与 app 默认解耦、与"拆书"步模型独立不继承）。返回 (ok, message) 给 UI。
typedef BookDeconstructionExtractKnowledgeHandler =
    Future<({bool ok, String message})> Function(
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
    required List<SelectorOptionViewData> Function() readImportAssistantModelOptions,
    DesktopBookDeconstructionSourcePickerService? sourcePickerService,
    BookDeconstructionDraftBuilderService? draftBuilderService,
    BookDeconstructionPreviewMarkdownService? previewMarkdownService,
    BookDeconstructionViewDataService? viewDataService,
    BookDeconstructionTargetPathService? targetPathService,
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
           ),
       _structuredSourceProjectionService =
           structuredSourceProjectionService ??
           const BookDeconstructionStructuredSourceProjectionService(),
       _snapshot = BookDeconstructionSnapshot.initial(),
       _viewData = BookDeconstructionViewData.initial(),
       _readSettings = readSettings,
       _generateDraftUseCaseFactory = generateDraftUseCaseFactory,
       _extractKnowledgeHandler = extractKnowledgeHandler;

  final ProjectDescriptor? Function() _readCurrentProject;
  final ReadProjectFileUseCase _readProjectFileUseCase;
  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final Future<void> Function() _syncWorkbenchResources;
  final VoidCallback _onBackRequested;
  final List<SelectorOptionViewData> Function() _readImportAssistantModelOptions;
  final DesktopBookDeconstructionSourcePickerService _sourcePickerService;
  final BookDeconstructionDraftBuilderService _draftBuilderService;
  final BookDeconstructionViewDataService _viewDataService;
  final AppSettings? Function()? _readSettings;
  final GenerateDraftUseCaseFactory? _generateDraftUseCaseFactory;
  final BookDeconstructionExtractKnowledgeHandler? _extractKnowledgeHandler;
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

  /// 长 LLM 操作（拆书去噪 / 分析）的超时兜底，避免模型挂起时 UI 永久卡在"正在…"。
  static const Duration _longOperationTimeout = Duration(minutes: 8);

  static const ImportAssistantModelOptionsService _modelOptionsService =
      ImportAssistantModelOptionsService();

  BookDeconstructionViewData get viewData => _viewData;

  Future<void> initialize() async {
    await refresh();
  }

  Future<void> refresh({String? status}) async {
    final project = _readCurrentProject();
    if (project == null) {
      _snapshot = BookDeconstructionSnapshot.initial();
      _statusMessage = status ?? '请先创建或打开拆书项目。';
      _rebuildView();
      return;
    }
    if (_snapshot.projectRootPath != project.rootPath) {
      final projectSetup = await _loadProjectSetup(project);
      _snapshot = BookDeconstructionSnapshot.initial().copyWith(
        projectRootPath: project.rootPath,
        selectedFollowupOptionId: projectSetup.preferredFollowupOptionId,
      );
    }
    _statusMessage =
        status ??
        (project.projectType == BookDeconstructionConstants.projectTypeId
            ? '可以开始导入拆书材料。'
            : '当前项目不是拆书项目，但仍可先预演结构化拆书流程。');
    _rebuildView();
  }

  @override
  void onBookDeconstructionBackRequested() => _onBackRequested();

  @override
  void onBookDeconstructionRefreshRequested() {
    refresh();
  }

  @override
  void onBookDeconstructionCancelRequested() {
    // 中文注释: 软取消。LLM 调用本身无法真正中断，但自增代际让在途操作的结果被丢弃，
    // 并立即把界面恢复到 idle——用户不再被"正在…"卡住（与超时兜底配合，最坏情况有界）。
    _operationGeneration += 1;
    _snapshot = _snapshot.copyWith(
      isLoading: false,
      operationKind: BookDeconstructionOperationKind.idle,
    );
    _statusMessage = '已取消当前操作。';
    _rebuildView();
  }

  @override
  void onBookDeconstructionStepSelected(String stepId) {
    _snapshot = _snapshot.copyWith(activeStepId: stepId.trim());
    _rebuildView();
  }

  @override
  Future<void> onBookDeconstructionImportFileRequested() async {
    final project = _readCurrentProject();
    if (project == null) {
      _statusMessage = '请先创建或打开拆书项目。';
      _rebuildView();
      return;
    }
    final selectedPath = await _sourcePickerService.pickSourceFile();
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
    try {
      final archiveResult = await _importArchiveWorkflowService.execute(
        project: project,
        sourceFilePath: selectedPath.trim(),
      );
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
      _statusMessage = '原文已导入，可进行拆书。';
      _rebuildView();
    } catch (error) {
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        operationKind: BookDeconstructionOperationKind.idle,
      );
      _statusMessage = UserFacingErrorHumanizer.humanize(error, action: '读取源文件');
      _rebuildView();
    }
  }

  @override
  void onBookDeconstructionSourceTitleChanged(String value) {
    _snapshot = _invalidatePreview(_snapshot.copyWith(sourceTitle: value));
    _rebuildView();
  }

  @override
  void onBookDeconstructionSourceContentChanged(String value) {
    _snapshot = _invalidatePreview(_snapshot.copyWith(sourceContent: value));
    _rebuildView();
  }

  // === 步骤②：拆书（纯净分章）=============================================

  @override
  void onBookDeconstructionSplitUseModelChanged(bool value) {
    // 中文注释: 只有选了拆书模型才允许勾"使用模型"；取消勾选时清掉模型键更直观。
    final canUse = _readImportAssistantModelOptions().isNotEmpty;
    final next = value && canUse;
    _snapshot = _snapshot.copyWith(
      splitUseModel: next,
      splitModelOptionKey: next ? _snapshot.splitModelOptionKey : '',
    );
    _rebuildView();
  }

  @override
  void onBookDeconstructionSplitModelSelected(String optionKey) {
    _snapshot = _snapshot.copyWith(splitModelOptionKey: optionKey);
    _rebuildView();
  }

  @override
  Future<void> onBookDeconstructionSplitRequested() async {
    final project = _readCurrentProject();
    if (project == null) {
      await refresh(status: '请先创建或打开拆书项目。');
      return;
    }
    if (_snapshot.sourceContent.trim().isEmpty) {
      _statusMessage = '请先导入文件或粘贴源文稿。';
      _rebuildView();
      return;
    }
    final useModel = _snapshot.splitUseModel &&
        _snapshot.splitModelOptionKey.trim().isNotEmpty;
    final generation = _operationGeneration;
    _snapshot = _snapshot.copyWith(
      isLoading: true,
      operationKind: BookDeconstructionOperationKind.splittingChapters,
    );
    _statusMessage = useModel ? '正在用模型辅助拆书（分章 + 去噪）…' : '正在拆书（分章 + 去噪）…';
    _rebuildView();
    await Future<void>.delayed(const Duration(milliseconds: 16));
    try {
      // 中文注释: 拆书永远只产出纯净分章（extractKnowledge:false）。勾了模型时，先用所选
      // 模型跑智能导入去噪（需源文件；粘贴内容无文件则跳过去噪、走规则分章，如实提示），
      // 再把（可能的）去噪正文喂给分章 use case。模型与分析步独立不继承。
      var splitSource = _snapshot.sourceContent;
      var modelNote = '';
      if (useModel) {
        final sourcePath = _snapshot.sourceAbsolutePath.trim();
        final readSettings = _readSettings;
        final factory = _generateDraftUseCaseFactory;
        final key = _modelOptionsService.splitKey(_snapshot.splitModelOptionKey);
        if (sourcePath.isEmpty) {
          modelNote = '（粘贴内容未走模型去噪：模型去噪需先选择文件；已按规则分章）';
        } else if (readSettings == null || factory == null) {
          modelNote = '（模型未接入，已按规则分章）';
        } else if (key.providerId.isEmpty || key.modelId.isEmpty) {
          modelNote = '（所选模型无效，已按规则分章）';
        } else {
          final orchestration = BookDeconstructionSmartImportOrchestrationService(
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
          if (generation != _operationGeneration) {
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
            sourceTitle: _snapshot.sourceTitle,
            sourceContent: splitSource,
            sourceAbsolutePath: _snapshot.sourceAbsolutePath,
            preferredContinuationDirection: _preferredContinuationDirection(),
            extractKnowledge: false,
          )
          .timeout(_longOperationTimeout);
      if (generation != _operationGeneration) {
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
              preferredOptionId: _snapshot.selectedFollowupOptionId,
            ),
        confirmedPreviewPath: '',
        analysisCompleted: false,
        analysisStatusMessage: '',
      );
      await _persistStructuredSourceProjection(project, buildResult);
      _statusMessage =
          '已完成拆书，共分出 ${buildResult.extractionResult.chapterOutlines.length} 章$modelNote。';
      _rebuildView();
    } catch (error) {
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        operationKind: BookDeconstructionOperationKind.idle,
      );
      _statusMessage = UserFacingErrorHumanizer.humanize(error, action: '拆书');
      _rebuildView();
    }
  }

  Future<void> _persistStructuredSourceProjection(
    ProjectDescriptor project,
    BookDeconstructionDraftBuildResult buildResult,
  ) async {
    // 中文注释: 拆书一完成就落盘结构化源文投影，让步骤③"分析"立刻有产物可读，不再依赖步骤④确认。
    // 与 confirm_workflow_service 用同一份 render 逻辑，保证分析与确认读取/写入的产物一致。
    try {
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
    } catch (_) {
      // 中文注释: 投影落盘失败不阻断拆书主流程（结构化源文仅在分析步需要，分析会再次提示）。
    }
  }

  // === 步骤③：分析（可选·需选模型）=========================================

  @override
  void onBookDeconstructionAnalysisUseModelChanged(bool value) {
    final canUse = _readImportAssistantModelOptions().isNotEmpty;
    final next = value && canUse;
    _snapshot = _snapshot.copyWith(
      analysisUseModel: next,
      analysisModelOptionKey: next ? _snapshot.analysisModelOptionKey : '',
    );
    _rebuildView();
  }

  @override
  void onBookDeconstructionAnalysisModelSelected(String optionKey) {
    _snapshot = _snapshot.copyWith(analysisModelOptionKey: optionKey);
    _rebuildView();
  }

  @override
  Future<void> onBookDeconstructionAnalysisRequested() async {
    // 中文注释: 分析是可选阶段，且必须选了模型才能跑（本地/无模型分析质量过低，不提供）。
    // 模型与"拆书"步独立不继承。委托 app_shell 注入的隐藏内置智能体 reference_extraction。
    final project = _readCurrentProject();
    final handler = _extractKnowledgeHandler;
    if (project == null || handler == null) {
      _statusMessage = '分析尚未接入，可跳过此步直接确认进入创作。';
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
    final generation = _operationGeneration;
    _snapshot = _snapshot.copyWith(
      isLoading: true,
      operationKind: BookDeconstructionOperationKind.analyzingAssets,
    );
    _statusMessage = '正在用内置智能体分析拆书产物（读取分章正文）…';
    _rebuildView();
    await Future<void>.delayed(const Duration(milliseconds: 16));
    try {
      final result = await handler(
        project,
        providerId: key.providerId,
        modelId: key.modelId,
      ).timeout(_longOperationTimeout);
      if (generation != _operationGeneration) {
        return;
      }
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        operationKind: BookDeconstructionOperationKind.idle,
        activeStepId: BookDeconstructionStepId.analyzeAssets,
        analysisCompleted: result.ok,
        analysisStatusMessage: result.ok
            ? '已用所选模型分析并写入项目资产：${result.message}'
            : '分析未完成：${result.message}（可跳过此步直接确认进入创作）',
      );
      _statusMessage = _snapshot.analysisStatusMessage;
      _rebuildView();
    } catch (error) {
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        operationKind: BookDeconstructionOperationKind.idle,
        analysisCompleted: false,
        analysisStatusMessage:
            '${UserFacingErrorHumanizer.humanize(error, action: '分析')}（可跳过此步直接确认进入创作）',
      );
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
    final nextSelected = Set<String>.from(_snapshot.selectedItemIds);
    if (selected) {
      nextSelected.add(itemId.trim());
    } else {
      nextSelected.remove(itemId.trim());
    }
    _snapshot = _snapshot.copyWith(selectedItemIds: nextSelected);
    _rebuildView();
  }

  @override
  void onBookDeconstructionSelectAllRequested() {
    final buildResult = _snapshot.buildResult;
    if (buildResult == null) {
      return;
    }
    _snapshot = _snapshot.copyWith(
      selectedItemIds: buildResult.applicationPlan.items
          .map((item) => item.id)
          .toSet(),
    );
    _rebuildView();
  }

  @override
  void onBookDeconstructionClearSelectionRequested() {
    _snapshot = _snapshot.copyWith(selectedItemIds: <String>{});
    _rebuildView();
  }

  @override
  void onBookDeconstructionFollowupOptionSelected(String optionId) {
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
    _rebuildView();
  }

  @override
  Future<void> onBookDeconstructionConfirmRequested() async {
    final validation = _validateConfirmationRequest();
    if (!validation.isValid) {
      return;
    }
    _snapshot = _snapshot.copyWith(
      isLoading: true,
      operationKind: BookDeconstructionOperationKind.confirmingSelection,
    );
    _statusMessage = '正在写入拆书预演纪要...';
    _rebuildView();
    await Future<void>.delayed(const Duration(milliseconds: 16));
    try {
      final result = await _persistConfirmation(
        project: validation.project!,
        buildResult: validation.buildResult!,
      );
      _statusMessage = _confirmationSuccessMessage(result);
      _rebuildView();
    } catch (error) {
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        operationKind: BookDeconstructionOperationKind.idle,
      );
      _statusMessage = UserFacingErrorHumanizer.humanize(error, action: '写入拆书预演纪要');
      _rebuildView();
    }
  }

  @override
  Future<void> onBookDeconstructionCreateDerivedProjectRequested() async {
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
    _snapshot = _snapshot.copyWith(
      isLoading: true,
      operationKind: BookDeconstructionOperationKind.creatingDerivedProject,
    );
    _statusMessage = '正在派生并创建后续项目...';
    _rebuildView();
    await Future<void>.delayed(const Duration(milliseconds: 16));
    try {
      if (_snapshot.confirmedPreviewPath.trim().isEmpty) {
        final confirmation = await _persistConfirmation(
          project: validation.project!,
          buildResult: validation.buildResult!,
        );
        _statusMessage = _confirmationSuccessMessage(confirmation);
        _snapshot = _snapshot.copyWith(
          isLoading: true,
          operationKind: BookDeconstructionOperationKind.creatingDerivedProject,
        );
        _rebuildView();
      }
      final result = await creationService.execute(
        projectsRootPath: _projectsRootPath,
        sourceProject: validation.project!,
        buildResult: validation.buildResult!,
        selectedItemIds: _snapshot.selectedItemIds,
        selectedFollowupOptionId: _snapshot.selectedFollowupOptionId,
      );
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
    );
  }

  _BookDeconstructionConfirmationValidation _validateConfirmationRequest() {
    final project = _readCurrentProject();
    if (project == null) {
      refresh(status: '请先创建或打开拆书项目。');
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
    if (_snapshot.selectedFollowupOptionId.trim().isEmpty) {
      _statusMessage = '请先选择拆书后的续写或同人路线。';
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
    final source = await _readProjectFileUseCase.execute(
      project,
      BookDeconstructionProjectSetupDocumentService.relativePath,
    );
    if (source == null || source.trim().isEmpty) {
      return _projectSetupDocumentService.create();
    }
    return _projectSetupDocumentService.parse(source);
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

  Future<BookDeconstructionConfirmWorkflowResult> _persistConfirmation({
    required ProjectDescriptor project,
    required BookDeconstructionDraftBuildResult buildResult,
  }) async {
    final result = await _confirmWorkflowService.execute(
      project: project,
      buildResult: buildResult,
      selectedItemIds: _snapshot.selectedItemIds,
      selectedFollowupOptionId: _snapshot.selectedFollowupOptionId,
    );
    await _syncWorkbenchResources();
    _snapshot = _snapshot.copyWith(
      isLoading: false,
      operationKind: BookDeconstructionOperationKind.idle,
      activeStepId: BookDeconstructionStepId.confirmSelection,
      confirmedPreviewPath: result.previewPath,
    );
    return result;
  }

  String _confirmationSuccessMessage(
    BookDeconstructionConfirmWorkflowResult result,
  ) {
    final inheritedHint = result.inheritedChapterPaths.isEmpty
        ? ''
        : '，并已接入 ${result.inheritedChapterPaths.length} 份原作正文';
    return '已确认 ${_snapshot.selectedItemIds.length} 项，${result.selectedFollowupOptionTitle} 路线说明已写入 ${result.guidePath}$inheritedHint。';
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
