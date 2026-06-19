import 'package:flutter/foundation.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/contracts/project_assets_action_handler.dart';
import '../../presentation/models/project_assets_view_data.dart';
import '../models/project_assets_catalog.dart';
import '../models/project_rag_extraction_execution_result.dart';
import '../models/project_reference_extraction_execution_result.dart';
import '../models/project_assets_snapshot.dart';
import '../models/project_assets_tab_id.dart';
import '../services/project_assets_loader_service.dart';
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
       _loaderService = loaderService,
       _readCurrentProject = readCurrentProject,
       _readAvailableProjectAgents = readAvailableProjectAgents,
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
  final ProjectAssetsLoaderService _loaderService;
  final ProjectDescriptor? Function() _readCurrentProject;
  final ReadAvailableProjectAgents _readAvailableProjectAgents;
  final Future<void> Function() _syncWorkbenchResources;
  final VoidCallback _onBackRequested;
  final ProjectRagExtractionExecutionService
  _ragExtractionExecutionService;
  final ProjectReferenceExtractionExecutionService
  _referenceExtractionExecutionService;
  final ProjectAssetsViewDataService _viewDataService;
  final ProjectReferenceExtractionStrategyPickerViewDataService
  _referenceExtractionStrategyPickerViewDataService;
  final ProjectExpressionConstraintBindingActionService
  _expressionConstraintBindingActionService;
  final ForeshadowRecordNormalizerService _foreshadowNormalizerService;

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
    if (_shouldPreferRagTab(project, _snapshot.activeTabId)) {
      _snapshot = _snapshot.copyWith(activeTabId: ProjectAssetsTabId.ragExtraction);
    }
    _snapshot = _snapshot.copyWith(isLoading: true);
    _statusMessage = status ?? '正在加载项目资产...';
    _rebuildView();
    try {
      final catalog = await _loaderService.load(project);
      final availableAgentOptions = _viewDataService
          .buildExpressionConstraintAgentOptions(_readAvailableProjectAgents());
      final availableModeOptions = _viewDataService
          .buildExpressionConstraintModeOptions();
      final availableStageOptions = _viewDataService
          .buildExpressionConstraintStageOptions();
      final ragSnapshot = await _ragExtractionExecutionService.loadSnapshot(
        project: project,
        selectedCorpusId: _snapshot.ragExtraction.selectedCorpusId,
      );
      _snapshot = _snapshot.copyWith(
        catalog: catalog,
        availableAgentOptions: availableAgentOptions,
        availableModeOptions: availableModeOptions,
        availableStageOptions: availableStageOptions,
        ragExtraction: _snapshot.ragExtraction.copyWith(
          selectedCorpusId:
              ragSnapshot.corpusPackage?.corpusId ?? _snapshot.ragExtraction.selectedCorpusId,
          selectedCorpus: ragSnapshot.corpusPackage ?? _snapshot.ragExtraction.selectedCorpus,
          mountSummary: ragSnapshot.mountSummary ??
              _snapshot.ragExtraction.mountSummary,
          statusMessage: ragSnapshot.statusMessage,
          recentSourcePath:
              ragSnapshot.corpusPackage?.metadata['source_file_path']?.toString() ??
              _snapshot.ragExtraction.recentSourcePath,
        ),
        selectedStyleId: _selectedStyleId(catalog, _snapshot.selectedStyleId),
        selectedExpressionConstraintId: _selectedExpressionConstraintId(
          catalog,
          _snapshot.selectedExpressionConstraintId,
        ),
        selectedForeshadowId: _selectedForeshadowId(
          catalog,
          _snapshot.selectedForeshadowId,
        ),
        selectedTimelineId: _selectedTimelineId(
          catalog,
          _snapshot.selectedTimelineId,
        ),
        selectedRelationshipId: _selectedRelationshipId(
          catalog,
          _snapshot.selectedRelationshipId,
        ),
        selectedGraphReferenceKey: _selectedGraphReferenceKey(
          catalog,
          _snapshot.selectedGraphReferenceKey,
        ),
        isLoading: false,
      );
      _statusMessage =
          status ??
          '已加载 ${catalog.styles.length} 个风格、${catalog.expressionConstraints.length} 个表达限制方案、${catalog.foreshadows.length} 个伏笔、${catalog.timelines.length} 条时间线、${catalog.relationships.length} 条关系。';
      _rebuildView();
    } catch (error) {
      _snapshot = _snapshot.copyWith(isLoading: false);
      _statusMessage = '加载项目资产失败：$error';
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
      await refresh(status: '请先创建或打开项目。');
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
    );
    _snapshot = _snapshot.copyWith(isLoading: true);
    final strategyName = _referenceExtractionStrategyLabel(
      normalizedStrategyProfileId,
    );
    _statusMessage = '正在提取参考资料... 当前策略：$strategyName';
    _rebuildView();
    final result = await _referenceExtractionExecutionService.pickAndExecute(
      project: project,
      strategyProfileId: normalizedStrategyProfileId,
    );
    await _handleReferenceExtractionResult(result);
  }

  @override
  Future<void> onProjectAssetsExtractRagRequested({
    String modeId = '',
  }) async {
    final project = _readCurrentProject();
    if (project == null) {
      await refresh(status: '请先创建或打开项目。');
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
      await refresh(status: '请先创建或打开项目。');
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
      await refresh(status: result.statusMessage);
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
        selectedCorpusId: updatedCorpus?.corpusId ??
            _snapshot.ragExtraction.selectedCorpusId,
        selectedCorpus: updatedCorpus ?? _snapshot.ragExtraction.selectedCorpus,
        mountSummary: updatedMountSummary ??
            _snapshot.ragExtraction.mountSummary,
        isLoading: false,
        statusMessage: result.statusMessage,
        recentSourcePath: updatedCorpus?.metadata['source_file_path']
                ?.toString() ??
            _snapshot.ragExtraction.recentSourcePath,
      ),
    );
    if (result.didMutateProject) {
      await refresh(status: result.statusMessage);
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
      await refresh(status: '请先创建或打开项目。');
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
    await refresh(status: _resultMessage(result, success: '风格资产已保存。'));
  }

  @override
  void onProjectAssetsSaveExpressionConstraintBindingRequested(
    ExpressionConstraintBindingEditorRequestViewData request,
  ) async {
    final project = _readCurrentProject();
    if (project == null) {
      await refresh(status: '请先创建或打开项目。');
      return;
    }
    final selectedProfiles = _snapshot.catalog.expressionConstraints.where(
      (item) => item.id == request.profileId.trim(),
    );
    if (selectedProfiles.isEmpty) {
      await refresh(status: '当前表达限制方案不存在或已被移除。');
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
    await refresh(status: '表达限制绑定已保存。');
  }

  @override
  void onProjectAssetsRemoveExpressionConstraintBindingRequested(
    String profileId,
  ) async {
    final project = _readCurrentProject();
    if (project == null) {
      await refresh(status: '请先创建或打开项目。');
      return;
    }
    final cleanProfileId = profileId.trim();
    if (cleanProfileId.isEmpty) {
      await refresh(status: '请先选择一个表达限制方案。');
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
    await refresh(status: '表达限制绑定已移除。');
  }

  @override
  void onProjectAssetsSaveForeshadowRequested(
    ForeshadowRecordEditorRequestViewData request,
  ) async {
    final project = _readCurrentProject();
    if (project == null) {
      await refresh(status: '请先创建或打开项目。');
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
    await refresh(status: _resultMessage(result, success: '伏笔资产已保存。'));
  }

  @override
  void onProjectAssetsDeleteRequested({
    required String kind,
    required String id,
  }) async {
    final project = _readCurrentProject();
    if (project == null) {
      await refresh(status: '请先创建或打开项目。');
      return;
    }
    if (id.trim().isEmpty) {
      await refresh(status: '请先选择一个资产。');
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
    await refresh(status: _resultMessage(result, success: '资产已删除。'));
  }

  @override
  void onProjectAssetsImportBundleRequested(
    ProjectAssetBundleImportRequestViewData request,
  ) async {
    final project = _readCurrentProject();
    if (project == null) {
      await refresh(status: '请先创建或打开项目。');
      return;
    }
    if (request.absolutePath.trim().isEmpty) {
      await refresh(status: '请提供资产包绝对路径。');
      return;
    }
    final bundleContent = await _projectAssetLibraryService.readExternalBundle(
      request.absolutePath.trim(),
    );
    if ((bundleContent ?? '').trim().isEmpty) {
      await refresh(status: '资产包文件不存在或不可读。');
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
      await refresh(status: '资产包预检失败。');
      return;
    }
    final result = await _projectAssetLibraryService.importBundle(
      project,
      bundleContent: bundleContent,
      overwrite: request.overwrite,
    );
    await _syncWorkbenchResources();
    await refresh(
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
      await refresh(status: '请先创建或打开项目。');
      return;
    }
    final result = await _projectAssetLibraryService.exportBundle(
      project,
      title: request.title.trim(),
      description: request.description.trim(),
    );
    await _syncWorkbenchResources();
    await refresh(status: _resultMessage(result, success: '资产包已导出。'));
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
    );
    if (!_disposed) {
      notifyListeners();
    }
  }

  bool _shouldPreferRagTab(ProjectDescriptor project, String activeTabId) {
    if (project.projectType.trim() != 'knowledge_base') {
      return false;
    }
    if (!const KnowledgeBaseBranchCatalogService().isRagBranch(
      project.projectBranchId,
    )) {
      return false;
    }
    final cleanActiveTabId = activeTabId.trim();
    return cleanActiveTabId.isEmpty || cleanActiveTabId == ProjectAssetsTabId.styles;
  }

  String _selectedStyleId(ProjectAssetsCatalog catalog, String currentId) {
    if (currentId.trim().isNotEmpty &&
        catalog.styles.any(
          (item) => ValueReaders.stringValue(item['id']) == currentId,
        )) {
      return currentId.trim();
    }
    if (catalog.styles.isEmpty) {
      return '';
    }
    return ValueReaders.stringValue(catalog.styles.first['id']);
  }

  String _selectedExpressionConstraintId(
    ProjectAssetsCatalog catalog,
    String currentId,
  ) {
    if (currentId.trim().isNotEmpty &&
        catalog.expressionConstraints.any(
          (item) => item.id == currentId.trim(),
        )) {
      return currentId.trim();
    }
    if (catalog.expressionConstraints.isEmpty) {
      return '';
    }
    return catalog.expressionConstraints.first.id;
  }

  String _selectedForeshadowId(ProjectAssetsCatalog catalog, String currentId) {
    if (currentId.trim().isNotEmpty &&
        catalog.foreshadows.any((item) => item.id == currentId.trim())) {
      return currentId.trim();
    }
    if (catalog.foreshadows.isEmpty) {
      return '';
    }
    return catalog.foreshadows.first.id;
  }

  String _selectedTimelineId(ProjectAssetsCatalog catalog, String currentId) {
    if (currentId.trim().isNotEmpty &&
        catalog.timelines.any((item) => item.id == currentId.trim())) {
      return currentId.trim();
    }
    if (catalog.timelines.isEmpty) {
      return '';
    }
    return catalog.timelines.first.id;
  }

  String _selectedRelationshipId(
    ProjectAssetsCatalog catalog,
    String currentId,
  ) {
    if (currentId.trim().isNotEmpty &&
        catalog.relationships.any((item) => item.id == currentId.trim())) {
      return currentId.trim();
    }
    if (catalog.relationships.isEmpty) {
      return '';
    }
    return catalog.relationships.first.id;
  }

  String _selectedGraphReferenceKey(
    ProjectAssetsCatalog catalog,
    String currentKey,
  ) {
    if (currentKey.trim().isNotEmpty &&
        catalog.referenceIndex.references.any(
          (item) => item.referenceKey == currentKey.trim(),
        )) {
      return currentKey.trim();
    }
    if (catalog.referenceIndex.references.isEmpty) {
      return '';
    }
    return catalog.referenceIndex.references.first.referenceKey;
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
}
