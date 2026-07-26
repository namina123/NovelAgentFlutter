import 'package:flutter/foundation.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/contracts/project_assets_action_handler.dart';
import '../../presentation/models/project_assets_view_data.dart';
import '../models/project_rag_extraction_execution_result.dart';
import '../models/project_reference_extraction_execution_result.dart';
import '../models/project_assets_snapshot.dart';
import '../models/project_assets_tab_id.dart';
import '../services/project_assets_catalog_refresh_service.dart';
import '../services/project_assets_loader_service.dart';
import '../services/project_assets_rag_refresh_service.dart';
import '../services/project_assets_refresh_coordinator.dart';
import '../services/project_assets_refresh_status_projection_service.dart';
import '../services/project_assets_selection_reconciler.dart';
import '../services/project_expression_constraint_binding_action_service.dart';
import '../services/project_expression_constraint_workspace_service.dart';
import '../services/project_assets_view_data_service.dart';
import '../services/project_rag_extraction_execution_service.dart';
import '../services/project_reference_extraction_execution_service.dart';
import '../services/project_reference_extraction_strategy_picker_view_data_service.dart';

typedef ReadAvailableProjectAgents = List<JsonMap> Function();

class ProjectAssetsController extends ChangeNotifier
    implements ProjectAssetsActionHandler {
  ProjectAssetsController({
    required ProjectAssetLibraryService projectAssetLibraryService,
    required ProjectExpressionConstraintWorkspaceService
    expressionConstraintWorkspaceService,
    required ProjectAssetsLoaderService loaderService,
    required ProjectDescriptor? Function() readCurrentProject,
    required ReadAvailableProjectAgents readAvailableProjectAgents,
    required Future<void> Function() syncWorkbenchResources,
    required VoidCallback onBackRequested,
    ProjectRagExtractionExecutionService? ragExtractionExecutionService,
    ProjectAssetsRefreshCoordinator? refreshCoordinator,
    required ProjectReferenceExtractionExecutionService
    referenceExtractionExecutionService,
    ProjectAssetsViewDataService? viewDataService,
    ProjectReferenceExtractionStrategyPickerViewDataService?
    referenceExtractionStrategyPickerViewDataService,
    ProjectExpressionConstraintBindingActionService?
    expressionConstraintBindingActionService,
    ForeshadowRecordNormalizerService? foreshadowNormalizerService,
  }) : _projectAssetLibraryService = projectAssetLibraryService,
       _expressionConstraintWorkspaceService =
           expressionConstraintWorkspaceService,
       _readCurrentProject = readCurrentProject,
       _syncWorkbenchResources = syncWorkbenchResources,
       _onBackRequested = onBackRequested,
       _ragExtractionExecutionService =
           ragExtractionExecutionService ??
           ProjectRagExtractionExecutionService(),
       _referenceExtractionExecutionService =
           referenceExtractionExecutionService,
       _viewDataService =
           viewDataService ?? const ProjectAssetsViewDataService(),
       _referenceExtractionStrategyPickerViewDataService =
           referenceExtractionStrategyPickerViewDataService ??
           const ProjectReferenceExtractionStrategyPickerViewDataService(),
       _refreshCoordinator =
           refreshCoordinator ??
           ProjectAssetsRefreshCoordinator(
             catalogRefreshService: ProjectAssetsCatalogRefreshService(
               loaderService: loaderService,
               viewDataService:
                   viewDataService ?? const ProjectAssetsViewDataService(),
               readAvailableProjectAgents: readAvailableProjectAgents,
             ),
             ragRefreshService: ProjectAssetsRagRefreshService(
               ragExtractionExecutionService:
                   ragExtractionExecutionService ??
                   ProjectRagExtractionExecutionService(),
             ),
             selectionReconciler: const ProjectAssetsSelectionReconciler(),
             statusProjectionService:
                 const ProjectAssetsRefreshStatusProjectionService(),
           ),
       _expressionConstraintBindingActionService =
           expressionConstraintBindingActionService ??
           const ProjectExpressionConstraintBindingActionService(),
       _foreshadowNormalizerService =
           foreshadowNormalizerService ??
           const ForeshadowRecordNormalizerService(),
       _snapshot = ProjectAssetsSnapshot.initial(),
       _viewData = ProjectAssetsViewData.initial();

  final ProjectAssetLibraryService _projectAssetLibraryService;
  final ProjectExpressionConstraintWorkspaceService
  _expressionConstraintWorkspaceService;
  final ProjectDescriptor? Function() _readCurrentProject;
  final Future<void> Function() _syncWorkbenchResources;
  final VoidCallback _onBackRequested;
  final ProjectRagExtractionExecutionService _ragExtractionExecutionService;
  final ProjectReferenceExtractionExecutionService
  _referenceExtractionExecutionService;
  final ProjectAssetsViewDataService _viewDataService;
  final ProjectAssetsRefreshCoordinator _refreshCoordinator;
  final ProjectReferenceExtractionStrategyPickerViewDataService
  _referenceExtractionStrategyPickerViewDataService;
  final ProjectExpressionConstraintBindingActionService
  _expressionConstraintBindingActionService;
  final ForeshadowRecordNormalizerService _foreshadowNormalizerService;
  final ProjectCapabilityService _projectCapabilityService =
      ProjectCapabilityService();

  ProjectAssetsSnapshot _snapshot;
  ProjectAssetsViewData _viewData;
  String _statusMessage = '';
  bool _disposed = false;

  ProjectAssetsViewData get viewData => _viewData;

  Future<void> refresh({String? status}) async {
    final project = _readCurrentProject();
    if (project == null) {
      _snapshot = ProjectAssetsSnapshot.initial();
      _statusMessage = status ?? '请先创建或打开项目。';
      _rebuildView();
      return;
    }
    final initialSnapshot = _snapshot;
    _snapshot = _snapshot.copyWith(isLoading: true);
    _statusMessage = '正在加载项目资产...';
    _rebuildView();
    try {
      final outcome = await _refreshCoordinator.refreshAll(
        currentProject: project,
        previousSnapshot: initialSnapshot,
        status: status,
      );
      _snapshot = outcome.snapshot.copyWith(isLoading: false);
      _statusMessage = outcome.statusMessage;
      _rebuildView();
    } catch (error) {
      _snapshot = _snapshot.copyWith(isLoading: false);
      _statusMessage = '加载项目资产失败：$error';
      _rebuildView();
    }
  }

  Future<void> _refreshCatalog({String? status}) async {
    final project = _readCurrentProject();
    if (project == null) {
      _snapshot = ProjectAssetsSnapshot.initial();
      _statusMessage = status ?? '请先创建或打开项目。';
      _rebuildView();
      return;
    }
    final initialSnapshot = _snapshot;
    _snapshot = _snapshot.copyWith(isLoading: true);
    _statusMessage = status ?? '正在加载项目资产目录...';
    _rebuildView();
    try {
      final outcome = await _refreshCoordinator.refreshCatalog(
        currentProject: project,
        previousSnapshot: initialSnapshot,
        status: status,
      );
      _snapshot = outcome.snapshot.copyWith(isLoading: false);
      _statusMessage = outcome.statusMessage;
      _rebuildView();
    } catch (error) {
      _snapshot = _snapshot.copyWith(isLoading: false);
      _statusMessage = '加载项目资产目录失败：$error';
      _rebuildView();
    }
  }

  Future<void> _refreshRag({String? status}) async {
    final project = _readCurrentProject();
    if (project == null) {
      _snapshot = ProjectAssetsSnapshot.initial();
      _statusMessage = status ?? '请先创建或打开项目。';
      _rebuildView();
      return;
    }
    final initialSnapshot = _snapshot;
    _snapshot = _snapshot.copyWith(isLoading: true);
    _statusMessage = status ?? '正在加载语料状态...';
    _rebuildView();
    try {
      final outcome = await _refreshCoordinator.refreshRag(
        currentProject: project,
        previousSnapshot: initialSnapshot,
        status: status,
      );
      _snapshot = outcome.snapshot.copyWith(isLoading: false);
      _statusMessage = outcome.statusMessage;
      _rebuildView();
    } catch (error) {
      _snapshot = _snapshot.copyWith(isLoading: false);
      _statusMessage = '加载语料状态失败：$error';
      _rebuildView();
    }
  }

  @override
  void onProjectAssetsBackRequested() => _onBackRequested();

  @override
  void onProjectAssetsRefreshRequested() {
    refresh();
  }

  @override
  Future<void> onProjectAssetsExtractReferenceRequested({
    String strategyProfileId = '',
  }) async {
    final project = _readCurrentProject();
    if (project == null) {
      await _refreshCatalog(status: '请先创建或打开项目。');
      return;
    }
    final normalizedStrategyProfileId =
        _referenceExtractionStrategyPickerViewDataService
            .normalizeSelectedProfileId(
              strategyProfileId.trim().isEmpty
                  ? _snapshot.selectedReferenceExtractionStrategyId
                  : strategyProfileId.trim(),
            );
    _snapshot = _snapshot.copyWith(
      selectedReferenceExtractionStrategyId: normalizedStrategyProfileId,
      activeTabId: ProjectAssetsTabId.referenceExtraction,
    );
    _snapshot = _snapshot.copyWith(isLoading: true);
    final strategyName = _referenceExtractionStrategyLabel(
      normalizedStrategyProfileId,
    );
    final sourceHint = _hasBookDeconstructionCapability(project)
        ? '正在使用拆书产物执行知识提取... 当前策略：$strategyName'
        : '正在执行知识提取... 当前策略：$strategyName';
    _statusMessage = sourceHint;
    _rebuildView();
    final result = await _referenceExtractionExecutionService.pickAndExecute(
      project: project,
      strategyProfileId: normalizedStrategyProfileId,
    );
    await _handleReferenceExtractionResult(result);
  }

  @override
  Future<void> onProjectAssetsExtractRagRequested({String modeId = ''}) async {
    final project = _readCurrentProject();
    if (project == null) {
      await _refreshRag(status: '请先创建或打开项目。');
      return;
    }
    final selectedModeId = modeId.trim().isEmpty
        ? _snapshot.ragExtraction.activeModeId
        : modeId.trim();
    _snapshot = _snapshot.copyWith(
      activeTabId: ProjectAssetsTabId.ragExtraction,
      ragExtraction: _snapshot.ragExtraction.copyWith(
        activeModeId: selectedModeId,
        isLoading: true,
        statusMessage: '正在构建语料...',
      ),
    );
    _rebuildView();
    final result = await _ragExtractionExecutionService.pickAndExecute(
      project: project,
      modeId: selectedModeId,
      onProgress: _handleRagExtractionProgress,
    );
    await _handleRagExtractionResult(result);
  }

  @override
  Future<void> onProjectAssetsMountRagCorpusRequested() async {
    final project = _readCurrentProject();
    if (project == null) {
      await _refreshRag(status: '请先创建或打开项目。');
      return;
    }
    final corpus = _snapshot.ragExtraction.selectedCorpus;
    if (corpus == null) {
      _snapshot = _snapshot.copyWith(
        ragExtraction: _snapshot.ragExtraction.copyWith(
          statusMessage: '当前没有可挂载的语料。',
        ),
      );
      _rebuildView();
      return;
    }
    _snapshot = _snapshot.copyWith(
      activeTabId: ProjectAssetsTabId.ragExtraction,
      ragExtraction: _snapshot.ragExtraction.copyWith(
        isLoading: true,
        statusMessage: '正在挂载语料...',
      ),
    );
    _rebuildView();
    final result = await _ragExtractionExecutionService.mountSelectedCorpus(
      project: project,
      corpusPackage: corpus,
    );
    await _handleRagExtractionResult(result);
  }

  @override
  void onProjectAssetsTabSelected(String tabId) {
    _snapshot = _snapshot.copyWith(activeTabId: tabId.trim());
    _rebuildView();
  }

  Future<void> _handleReferenceExtractionResult(
    ProjectReferenceExtractionExecutionResult result,
  ) async {
    if (result.didMutateProject) {
      await _syncWorkbenchResources();
      await _refreshCatalog(status: result.statusMessage);
      return;
    }
    _snapshot = _snapshot.copyWith(isLoading: false);
    _statusMessage = result.statusMessage;
    _rebuildView();
  }

  void openExpressionConstraintsForAgent(String agentId) {
    // 中文注释: 工作台从当前智能体进入时，只冻结页签与上下文，不在这里猜测要替用户选哪条 preset。
    _snapshot = _snapshot.copyWith(
      activeTabId: ProjectAssetsTabId.expressionConstraints,
      entryAgentContextId: agentId.trim(),
    );
    _rebuildView();
  }

  void openRagExtractionWorkspace() {
    _snapshot = _snapshot.copyWith(
      activeTabId: ProjectAssetsTabId.ragExtraction,
      entryAgentContextId: '',
    );
    _rebuildView();
  }

  void openReferenceExtractionWorkspace() {
    _snapshot = _snapshot.copyWith(
      activeTabId: ProjectAssetsTabId.referenceExtraction,
      entryAgentContextId: '',
    );
    _rebuildView();
  }

  @override
  void onProjectAssetsEntrySelected(String entryId) {
    switch (_snapshot.activeTabId) {
      case ProjectAssetsTabId.expressionConstraints:
        _snapshot = _snapshot.copyWith(
          selectedExpressionConstraintId: entryId.trim(),
        );
        break;
      case ProjectAssetsTabId.ragExtraction:
        _snapshot = _snapshot.copyWith(
          ragExtraction: _snapshot.ragExtraction.copyWith(
            activeModeId: entryId.trim(),
          ),
        );
        break;
      case ProjectAssetsTabId.foreshadows:
        _snapshot = _snapshot.copyWith(selectedForeshadowId: entryId.trim());
        break;
      case ProjectAssetsTabId.timelines:
        _snapshot = _snapshot.copyWith(selectedTimelineId: entryId.trim());
        break;
      case ProjectAssetsTabId.relationships:
        _snapshot = _snapshot.copyWith(selectedRelationshipId: entryId.trim());
        break;
      case ProjectAssetsTabId.graph:
        _snapshot = _snapshot.copyWith(
          selectedGraphReferenceKey: entryId.trim(),
        );
        break;
      case ProjectAssetsTabId.styles:
      default:
        _snapshot = _snapshot.copyWith(selectedStyleId: entryId.trim());
        break;
    }
    _rebuildView();
  }

  Future<void> _handleRagExtractionResult(
    ProjectRagExtractionExecutionResult result,
  ) async {
    final updatedCorpus = result.corpusPackage;
    final updatedMountSummary = result.mountSummary;
    if (result.didMutateProject) {
      await _syncWorkbenchResources();
    }
    _snapshot = _snapshot.copyWith(
      ragExtraction: _snapshot.ragExtraction.copyWith(
        selectedCorpusId:
            updatedCorpus?.corpusId ?? _snapshot.ragExtraction.selectedCorpusId,
        selectedCorpus: updatedCorpus ?? _snapshot.ragExtraction.selectedCorpus,
        mountSummary:
            updatedMountSummary ?? _snapshot.ragExtraction.mountSummary,
        analysisSummary:
            result.analysisSummary ?? _snapshot.ragExtraction.analysisSummary,
        normalizationNote: result.normalizationNote.trim().isNotEmpty
            ? result.normalizationNote
            : _snapshot.ragExtraction.normalizationNote,
        isLoading: false,
        statusMessage: result.statusMessage,
        recentSourcePath:
            updatedCorpus?.metadata['source_file_path']?.toString() ??
            _snapshot.ragExtraction.recentSourcePath,
      ),
    );
    if (result.didMutateProject) {
      await _refreshRag(status: result.statusMessage);
      return;
    }
    _rebuildView();
  }

  Future<void> _handleRagExtractionProgress(String statusMessage) async {
    _snapshot = _snapshot.copyWith(
      ragExtraction: _snapshot.ragExtraction.copyWith(
        isLoading: true,
        statusMessage: statusMessage,
      ),
    );
    _rebuildView();
    await Future<void>.delayed(Duration.zero);
  }

  @override
  void onProjectAssetsReferenceSelected(String referenceKey) {
    final reference = _snapshot.catalog.referenceIndex.referenceByKey(
      referenceKey,
    );
    if (reference == null) {
      return;
    }
    switch (reference.assetKind) {
      case 'foreshadow':
        _snapshot = _snapshot.copyWith(
          activeTabId: ProjectAssetsTabId.foreshadows,
          selectedForeshadowId: reference.assetId,
          selectedGraphReferenceKey: reference.referenceKey,
        );
        break;
      case 'timeline':
        _snapshot = _snapshot.copyWith(
          activeTabId: ProjectAssetsTabId.timelines,
          selectedTimelineId: reference.assetId,
          selectedGraphReferenceKey: reference.referenceKey,
        );
        break;
      case 'relationship':
        _snapshot = _snapshot.copyWith(
          activeTabId: ProjectAssetsTabId.relationships,
          selectedRelationshipId: reference.assetId,
          selectedGraphReferenceKey: reference.referenceKey,
        );
        break;
      default:
        _snapshot = _snapshot.copyWith(
          selectedGraphReferenceKey: reference.referenceKey,
        );
        break;
    }
    _rebuildView();
  }

  @override
  void onProjectAssetsNewRequested() {
    if (!ProjectAssetsTabId.supportsCreation(_snapshot.activeTabId)) {
      _statusMessage = '当前页签先只提供浏览，暂不支持直接新建。';
      _rebuildView();
      return;
    }
    if (_snapshot.activeTabId == ProjectAssetsTabId.foreshadows) {
      _snapshot = _snapshot.copyWith(selectedForeshadowId: '');
      _statusMessage = '正在创建新的伏笔资产。';
    } else {
      _snapshot = _snapshot.copyWith(selectedStyleId: '');
      _statusMessage = '正在创建新的风格资产。';
    }
    _rebuildView();
  }

  @override
  void onProjectAssetsSaveStyleRequested(
    StyleProfileEditorRequestViewData request,
  ) async {
    final project = _readCurrentProject();
    if (project == null) {
      await _refreshCatalog(status: '请先创建或打开项目。');
      return;
    }
    final result = await _projectAssetLibraryService
        .saveStyle(project, <String, Object?>{
          'id': request.id.trim(),
          'display_name': request.displayName.trim(),
          'summary': request.summary,
          'genre': request.genre.trim(),
          'tone': request.tone.trim(),
          'audience': request.audience.trim(),
          'tags': _csvList(request.tagsText),
          'guardrails': _csvList(request.guardrailsText),
          'example_paths': _csvList(request.examplePathsText),
          'inherited_from_ids': _csvList(request.inheritedIdsText),
          'default_for_project': request.defaultForProject,
        });
    await _syncWorkbenchResources();
    if (ValueReaders.boolValue(result['ok'])) {
      _snapshot = _snapshot.copyWith(
        activeTabId: ProjectAssetsTabId.styles,
        selectedStyleId: ValueReaders.stringValue(
          ValueReaders.mapValue(result['asset'])['id'],
        ),
      );
    }
    await _refreshCatalog(status: _resultMessage(result, success: '风格资产已保存。'));
  }

  @override
  void onProjectAssetsSaveExpressionConstraintBindingRequested(
    ExpressionConstraintBindingEditorRequestViewData request,
  ) async {
    final project = _readCurrentProject();
    if (project == null) {
      await _refreshCatalog(status: '请先创建或打开项目。');
      return;
    }
    final selectedProfiles = _snapshot.catalog.expressionConstraints.where(
      (item) => item.id == request.profileId.trim(),
    );
    if (selectedProfiles.isEmpty) {
      await _refreshCatalog(status: '当前表达限制方案不存在或已被移除。');
      return;
    }
    final nextBindings = _expressionConstraintBindingActionService
        .upsertBinding(
          currentBindings: _snapshot.catalog.expressionConstraintBindings,
          profile: selectedProfiles.first,
          request: request,
        );
    await _expressionConstraintWorkspaceService.saveBindings(
      project,
      nextBindings,
    );
    await _refreshCatalog(status: '表达限制绑定已保存。');
  }

  @override
  void onProjectAssetsRemoveExpressionConstraintBindingRequested(
    String profileId,
  ) async {
    final project = _readCurrentProject();
    if (project == null) {
      await _refreshCatalog(status: '请先创建或打开项目。');
      return;
    }
    final cleanProfileId = profileId.trim();
    if (cleanProfileId.isEmpty) {
      await _refreshCatalog(status: '请先选择一个表达限制方案。');
      return;
    }
    final nextBindings = _expressionConstraintBindingActionService
        .removeBinding(
          currentBindings: _snapshot.catalog.expressionConstraintBindings,
          profileId: cleanProfileId,
        );
    await _expressionConstraintWorkspaceService.saveBindings(
      project,
      nextBindings,
    );
    await _refreshCatalog(status: '表达限制绑定已移除。');
  }

  @override
  void onProjectAssetsSaveForeshadowRequested(
    ForeshadowRecordEditorRequestViewData request,
  ) async {
    final project = _readCurrentProject();
    if (project == null) {
      await _refreshCatalog(status: '请先创建或打开项目。');
      return;
    }
    final result = await _projectAssetLibraryService
        .saveForeshadow(project, <String, Object?>{
          'id': request.id.trim(),
          'title': request.title.trim(),
          'status': request.status.trim(),
          'summary': request.summary,
          'planted_chapter_path': request.plantedChapterPath.trim(),
          'target_payoff_path': request.targetPayoffPath.trim(),
          'related_entity_ids': _csvList(request.relatedEntityIdsText),
          'related_paths': _csvList(request.relatedPathsText),
          'trigger_conditions': _csvList(request.triggerConditionsText),
          'payoff_expectations': _csvList(request.payoffExpectationsText),
          'tags': _csvList(request.tagsText),
          'notes': request.notes,
        });
    await _syncWorkbenchResources();
    if (ValueReaders.boolValue(result['ok'])) {
      _snapshot = _snapshot.copyWith(
        activeTabId: ProjectAssetsTabId.foreshadows,
        selectedForeshadowId: ValueReaders.stringValue(
          ValueReaders.mapValue(result['asset'])['id'],
        ),
      );
    }
    await _refreshCatalog(status: _resultMessage(result, success: '伏笔资产已保存。'));
  }

  @override
  void onProjectAssetsDeleteRequested({
    required String kind,
    required String id,
  }) async {
    final project = _readCurrentProject();
    if (project == null) {
      await _refreshCatalog(status: '请先创建或打开项目。');
      return;
    }
    if (id.trim().isEmpty) {
      await _refreshCatalog(status: '请先选择一个资产。');
      return;
    }
    final result = kind == 'foreshadow'
        ? await _projectAssetLibraryService.deleteForeshadow(project, id.trim())
        : await _projectAssetLibraryService.deleteStyle(project, id.trim());
    await _syncWorkbenchResources();
    if (ValueReaders.boolValue(result['ok'])) {
      if (kind == 'foreshadow') {
        _snapshot = _snapshot.copyWith(selectedForeshadowId: '');
      } else {
        _snapshot = _snapshot.copyWith(selectedStyleId: '');
      }
    }
    await _refreshCatalog(status: _resultMessage(result, success: '资产已删除。'));
  }

  @override
  void onProjectAssetsImportBundleRequested(
    ProjectAssetBundleImportRequestViewData request,
  ) async {
    final project = _readCurrentProject();
    if (project == null) {
      await _refreshCatalog(status: '请先创建或打开项目。');
      return;
    }
    if (request.absolutePath.trim().isEmpty) {
      await _refreshCatalog(status: '请提供资产包绝对路径。');
      return;
    }
    final bundleContent = await _projectAssetLibraryService.readExternalBundle(
      request.absolutePath.trim(),
    );
    if ((bundleContent ?? '').trim().isEmpty) {
      await _refreshCatalog(status: '资产包文件不存在或不可读。');
      return;
    }
    final preview = _projectAssetLibraryService.previewImportBundle(
      project,
      bundleContent: bundleContent!,
      currentStyles: _snapshot.catalog.styles,
      currentForeshadows: _snapshot.catalog.foreshadows
          .map(_foreshadowNormalizerService.toDocument)
          .toList(growable: false),
      overwrite: request.overwrite,
    );
    if (!ValueReaders.boolValue(preview['ok'])) {
      await _refreshCatalog(status: '资产包预检失败。');
      return;
    }
    final result = await _projectAssetLibraryService.importBundle(
      project,
      bundleContent: bundleContent,
      overwrite: request.overwrite,
    );
    await _syncWorkbenchResources();
    await _refreshCatalog(
      status:
          '${_resultMessage(result, success: '资产包已导入。')} 预检条目 ${ValueReaders.objectList(preview['items']).length} 个。',
    );
  }

  @override
  void onProjectAssetsExportBundleRequested(
    ProjectAssetBundleExportRequestViewData request,
  ) async {
    final project = _readCurrentProject();
    if (project == null) {
      await _refreshCatalog(status: '请先创建或打开项目。');
      return;
    }
    final result = await _projectAssetLibraryService.exportBundle(
      project,
      title: request.title.trim(),
      description: request.description.trim(),
    );
    await _syncWorkbenchResources();
    await _refreshCatalog(status: _resultMessage(result, success: '资产包已导出。'));
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _rebuildView() {
    _viewData = _viewDataService.build(
      snapshot: _snapshot,
      status: _statusMessage,
      project: _readCurrentProject(),
    );
    if (!_disposed) {
      notifyListeners();
    }
  }

  List<String> _csvList(String rawText) {
    return rawText
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String _resultMessage(JsonMap result, {required String success}) {
    if (ValueReaders.boolValue(result['ok'])) {
      return success;
    }
    final errorText = ValueReaders.stringValue(result['error']);
    if (errorText.isNotEmpty) {
      return errorText;
    }
    return '操作失败。';
  }

  String _referenceExtractionStrategyLabel(String profileId) {
    final picker = _viewData.referenceExtractionStrategyPicker.options;
    for (final option in picker) {
      if (option.profileId == profileId.trim()) {
        return option.displayName;
      }
    }
    final fallback = _referenceExtractionStrategyPickerViewDataService.build(
      selectedProfileId: profileId,
    );
    if (fallback.options.isEmpty) {
      return profileId.trim();
    }
    for (final option in fallback.options) {
      if (option.profileId == fallback.selectedProfileId) {
        return option.displayName;
      }
    }
    return profileId.trim();
  }

  bool _hasBookDeconstructionCapability(ProjectDescriptor project) {
    return _projectCapabilityService.hasBookDeconstruction(
      projectTypeId: project.projectType,
      additionalTraitIds: project.additionalTraitIds,
      runtimeBaselineId: project.runtimeBaselineId,
    );
  }
}
