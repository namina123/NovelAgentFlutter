import 'package:flutter/foundation.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';

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
import '../services/book_deconstruction_smart_import_result.dart';
import '../services/book_deconstruction_view_data_service.dart';
import '../services/desktop_book_deconstruction_source_picker_service.dart';
import '../../../workbench/application/controllers/generate_draft_use_case_factory.dart';

/// 中文注释: 提取知识（可选阶段）的执行回调。由 app_shell 注入，委托给内置隐藏智能体的
/// LLM 参考资料 extraction（读拆书产物、必须已配置模型）。返回 (ok, message) 给 UI 如实呈现。
typedef BookDeconstructionExtractKnowledgeHandler =
    Future<({bool ok, String message})> Function(ProjectDescriptor project);

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
  }) : _readCurrentProject = readCurrentProject,
       _readProjectFileUseCase = readProjectFileUseCase,
       _syncWorkbenchResources = syncWorkbenchResources,
       _onBackRequested = onBackRequested,
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
       _snapshot = BookDeconstructionSnapshot.initial(),
       _viewData = BookDeconstructionViewData.initial(),
       _readSettings = readSettings,
       _generateDraftUseCaseFactory = generateDraftUseCaseFactory,
       _extractKnowledgeHandler = extractKnowledgeHandler;

  final ProjectDescriptor? Function() _readCurrentProject;
  final ReadProjectFileUseCase _readProjectFileUseCase;
  final Future<void> Function() _syncWorkbenchResources;
  final VoidCallback _onBackRequested;
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
      _statusMessage = '原文已归档到 ${archiveResult.archivePath}，可继续补充结构说明后生成预览。';
      _rebuildView();
    } catch (error) {
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        operationKind: BookDeconstructionOperationKind.idle,
      );
      _statusMessage = '读取源文件失败：$error';
      _rebuildView();
    }
  }

  @override
  Future<void> onBookDeconstructionSmartImportRequested() async {
    // 中文注释: 智能拆书 = 模型辅助正文标准化（识别正文 / 分章 / 去噪），复用 RAG 也用的同一套
    // BookDeconstructionSmartImportOrchestrationService。先按普通导入把原文归档到来源层，
    // 再跑智能拆书，把清洗后的正文填回 sourceContent；模型不可用时如实提示，不静默失败。
    final project = _readCurrentProject();
    if (project == null) {
      _statusMessage = '请先创建或打开拆书项目。';
      _rebuildView();
      return;
    }
    final readSettings = _readSettings;
    final generateDraftUseCaseFactory = _generateDraftUseCaseFactory;
    if (readSettings == null || generateDraftUseCaseFactory == null) {
      _statusMessage = '尚未接入模型设置，无法使用智能拆书。';
      _rebuildView();
      return;
    }
    final settings = readSettings();
    if (settings == null || settings.providers.isEmpty) {
      _statusMessage = '尚未配置模型提供商，无法使用智能拆书。';
      _rebuildView();
      return;
    }
    final provider = _resolveProvider(settings);
    if (provider == null) {
      _statusMessage = '未解析到可用模型提供商，无法使用智能拆书。';
      _rebuildView();
      return;
    }
    final modelId = _resolveModelId(settings, provider);
    if (modelId.isEmpty) {
      _statusMessage = '未解析到可用模型，无法使用智能拆书。';
      _rebuildView();
      return;
    }
    final selectedPath = await _sourcePickerService.pickSourceFile();
    if (selectedPath == null || selectedPath.trim().isEmpty) {
      _statusMessage = '已取消智能拆书。';
      _rebuildView();
      return;
    }
    _snapshot = _snapshot.copyWith(
      isLoading: true,
      operationKind: BookDeconstructionOperationKind.smartImportingSource,
    );
    _statusMessage = '正在用模型辅助智能拆书…';
    _rebuildView();
    await Future<void>.delayed(const Duration(milliseconds: 16));
    try {
      final archiveResult = await _importArchiveWorkflowService.execute(
        project: project,
        sourceFilePath: selectedPath.trim(),
      );
      final orchestration = BookDeconstructionSmartImportOrchestrationService(
        agentService: BookDeconstructionSmartImportAgentService(
          readSettings: readSettings,
          generateDraftUseCaseFactory: generateDraftUseCaseFactory,
        ),
      );
      final result = await orchestration.execute(
        project: project,
        sourcePaths: <String>[selectedPath.trim()],
        providerId: provider.id,
        modelId: modelId,
      );
      final normalized = result.normalizedSourceText.trim().isNotEmpty
          ? result.normalizedSourceText
          : archiveResult.sourceText;
      _snapshot = _invalidatePreview(
        _snapshot.copyWith(
          isLoading: false,
          operationKind: BookDeconstructionOperationKind.idle,
          activeStepId: BookDeconstructionStepId.importSource,
          sourceAbsolutePath: archiveResult.sourceFilePath,
          sourceTitle: archiveResult.sourceTitle,
          sourceContent: normalized,
        ),
      );
      _statusMessage = result.applied
          ? '智能拆书已完成模型辅助标准化${result.note.trim().isEmpty ? '' : '：${result.note}'}，可继续补充结构说明后生成预览。'
          : '智能拆书未产出有效正文，已保留原文${result.note.trim().isEmpty ? '' : '（${result.note}）'}。';
      _rebuildView();
    } catch (error) {
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        operationKind: BookDeconstructionOperationKind.idle,
      );
      _statusMessage = '智能拆书失败：$error';
      _rebuildView();
    }
  }

  ProviderEndpointSettings? _resolveProvider(AppSettings settings) {
    final defaultProviderId = settings.defaultProviderId.trim();
    if (defaultProviderId.isNotEmpty) {
      for (final provider in settings.providers) {
        if (provider.id == defaultProviderId) {
          return provider;
        }
      }
    }
    return settings.providers.isEmpty ? null : settings.providers.first;
  }

  String _resolveModelId(
    AppSettings settings,
    ProviderEndpointSettings provider,
  ) {
    final defaultModelId = settings.defaultModelId.trim();
    if (defaultModelId.isNotEmpty) {
      return defaultModelId;
    }
    return provider.modelId.trim();
  }

  bool _isSmartImportAvailable() {
    final readSettings = _readSettings;
    final generateDraftUseCaseFactory = _generateDraftUseCaseFactory;
    if (readSettings == null || generateDraftUseCaseFactory == null) {
      return false;
    }
    final settings = readSettings();
    if (settings == null || settings.providers.isEmpty) {
      return false;
    }
    final provider = _resolveProvider(settings);
    if (provider == null) {
      return false;
    }
    return _resolveModelId(settings, provider).isNotEmpty;
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

  @override
  void onBookDeconstructionOperatorNotesChanged(String value) {
    _snapshot = _invalidatePreview(_snapshot.copyWith(operatorNotes: value));
    _rebuildView();
  }

  @override
  void onBookDeconstructionStyleSummaryChanged(String value) {
    _snapshot = _invalidatePreview(_snapshot.copyWith(styleSummary: value));
    _rebuildView();
  }

  @override
  void onBookDeconstructionWorldRulesChanged(String value) {
    _snapshot = _invalidatePreview(_snapshot.copyWith(worldRulesText: value));
    _rebuildView();
  }

  @override
  void onBookDeconstructionCharacterLinesChanged(String value) {
    _snapshot = _invalidatePreview(
      _snapshot.copyWith(characterLinesText: value),
    );
    _rebuildView();
  }

  @override
  void onBookDeconstructionOrganizationLinesChanged(String value) {
    _snapshot = _invalidatePreview(
      _snapshot.copyWith(organizationLinesText: value),
    );
    _rebuildView();
  }

  @override
  Future<void> onBookDeconstructionBuildPreviewRequested() async {
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
    _snapshot = _snapshot.copyWith(
      isLoading: true,
      operationKind: BookDeconstructionOperationKind.buildingPreview,
    );
    _statusMessage = '正在拆书（分章 + 清洗）...';
    _rebuildView();
    await Future<void>.delayed(const Duration(milliseconds: 16));
    try {
      // 中文注释: 拆书按钮 = 纯拆书（extractKnowledge:false）：只分章 + 章节骨架，不做知识抽取。
      // 知识抽取是可选的"提取知识"阶段，用户可跳过直接进入确认/创作。
      final buildResult = await _draftBuilderService.build(
        sourceTitle: _snapshot.sourceTitle,
        sourceContent: _snapshot.sourceContent,
        sourceAbsolutePath: _snapshot.sourceAbsolutePath,
        operatorNotes: _snapshot.operatorNotes,
        styleSummary: _snapshot.styleSummary,
        worldRulesText: _snapshot.worldRulesText,
        characterLinesText: _snapshot.characterLinesText,
        organizationLinesText: _snapshot.organizationLinesText,
        preferredContinuationDirection: _preferredContinuationDirection(),
        extractKnowledge: false,
      );
      final selectedIds = buildResult.applicationPlan.items
          .map((item) => item.id)
          .toSet();
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        operationKind: BookDeconstructionOperationKind.idle,
        activeStepId: BookDeconstructionStepId.previewStructure,
        buildResult: buildResult,
        selectedItemIds: selectedIds,
        selectedFollowupOptionId: _followupOptionSelectionService
            .resolveSelectedOptionId(
              followupMenu: buildResult.followupMenu,
              preferredOptionId: _snapshot.selectedFollowupOptionId,
            ),
        confirmedPreviewPath: '',
      );
      _statusMessage =
          '已完成拆书，共分出 ${buildResult.extractionResult.chapterOutlines.length} 章；可继续提取知识（可选）或直接确认进入创作。';
      _rebuildView();
    } catch (error) {
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        operationKind: BookDeconstructionOperationKind.idle,
      );
      _statusMessage = '生成结构化预览失败：$error';
      _rebuildView();
    }
  }

  @override
  Future<void> onBookDeconstructionExtractKnowledgeRequested() async {
    // 中文注释: 提取知识是可选阶段：委托 app_shell 注入的隐藏内置智能体 LLM extraction，
    // 读拆书产物分析知识。必须已配置模型（否则 service 如实拒绝）。可跳过——不点就不提取。
    final project = _readCurrentProject();
    final handler = _extractKnowledgeHandler;
    if (project == null || handler == null) {
      _statusMessage = '提取知识尚未接入，可跳过此步直接确认进入创作。';
      _rebuildView();
      return;
    }
    if (!_isModelConfigured()) {
      _statusMessage = '提取知识需要先在设置里配置模型；也可跳过此步直接确认进入创作。';
      _rebuildView();
      return;
    }
    _snapshot = _snapshot.copyWith(
      isLoading: true,
      operationKind: BookDeconstructionOperationKind.extractingKnowledge,
    );
    _statusMessage = '正在用内置智能体提取知识（读取拆书产物）…';
    _rebuildView();
    await Future<void>.delayed(const Duration(milliseconds: 16));
    try {
      final result = await handler(project);
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        operationKind: BookDeconstructionOperationKind.idle,
      );
      _statusMessage = result.ok
          ? '已提取知识并写入项目资产：${result.message}'
          : '提取知识未完成：${result.message}（可跳过此步直接确认进入创作）';
      _rebuildView();
    } catch (error) {
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        operationKind: BookDeconstructionOperationKind.idle,
      );
      _statusMessage = '提取知识失败：$error（可跳过此步直接确认进入创作）';
      _rebuildView();
    }
  }

  bool _isModelConfigured() {
    final settings = _readSettings?.call();
    if (settings == null || settings.providers.isEmpty) {
      return false;
    }
    final provider = _resolveProvider(settings);
    if (provider == null) {
      return false;
    }
    return _resolveModelId(settings, provider).isNotEmpty;
  }

  bool _isExtractKnowledgeAvailable() {
    return _extractKnowledgeHandler != null && _isModelConfigured();
  }

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
      _statusMessage = '写入拆书预演纪要失败：$error';
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
      _statusMessage = '派生项目失败：$error';
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
        snapshot.confirmedPreviewPath.trim().isEmpty) {
      return snapshot;
    }
    // 中文注释: 一旦源文稿或结构补充发生变化，旧的结构化预览必须失效，避免用户误把旧计划当成新结果。
    return snapshot.copyWith(
      buildResult: null,
      selectedItemIds: <String>{},
      selectedFollowupOptionId: '',
      confirmedPreviewPath: '',
      activeStepId: BookDeconstructionStepId.importSource,
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
      _statusMessage = '请先生成结构化预览。';
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
    _viewData = _viewDataService.build(
      projectTitle: _readCurrentProject()?.name ?? '',
      snapshot: _snapshot,
      status: _statusMessage,
      canCreateDerivedProject: _isDerivedProjectCreationAvailable(),
      canSmartImport: _isSmartImportAvailable(),
      canExtractKnowledge: _isExtractKnowledgeAvailable(),
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
