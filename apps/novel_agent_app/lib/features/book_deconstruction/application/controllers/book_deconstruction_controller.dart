import 'package:flutter/foundation.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';

import '../../presentation/contracts/book_deconstruction_action_handler.dart';
import '../../presentation/models/book_deconstruction_view_data.dart';
import '../models/book_deconstruction_snapshot.dart';
import '../models/book_deconstruction_step_id.dart';
import '../services/book_deconstruction_confirm_workflow_service.dart';
import '../services/book_deconstruction_derived_project_creation_service.dart';
import '../services/book_deconstruction_draft_builder_service.dart';
import '../services/book_deconstruction_followup_option_selection_service.dart';
import '../services/book_deconstruction_narrative_persistence_service.dart';
import '../services/book_deconstruction_preview_markdown_service.dart';
import '../services/book_deconstruction_view_data_service.dart';
import '../services/desktop_book_deconstruction_source_picker_service.dart';

class BookDeconstructionController extends ChangeNotifier
    implements BookDeconstructionActionHandler {
  BookDeconstructionController({
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
    BookDeconstructionDerivedProjectCreationService?
    derivedProjectCreationService,
    Future<void> Function(ProjectDescriptor project, String preferredOpenPath)?
    openDerivedProjectRequested,
    String projectsRootPath = '',
  }) : _readCurrentProject = readCurrentProject,
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
       _viewData = BookDeconstructionViewData.initial();

  final ProjectDescriptor? Function() _readCurrentProject;
  final Future<void> Function() _syncWorkbenchResources;
  final VoidCallback _onBackRequested;
  final DesktopBookDeconstructionSourcePickerService _sourcePickerService;
  final BookDeconstructionDraftBuilderService _draftBuilderService;
  final BookDeconstructionViewDataService _viewDataService;
  final BookDeconstructionFollowupOptionSelectionService
  _followupOptionSelectionService;
  final BookDeconstructionImportArchiveWorkflowService
  _importArchiveWorkflowService;
  final BookDeconstructionConfirmWorkflowService _confirmWorkflowService;
  final BookDeconstructionDerivedProjectCreationService?
  _derivedProjectCreationService;
  final Future<void> Function(ProjectDescriptor project, String preferredOpenPath)?
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
      _snapshot = BookDeconstructionSnapshot.initial().copyWith(
        projectRootPath: project.rootPath,
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
    _snapshot = _snapshot.copyWith(isLoading: true);
    _statusMessage = '正在读取拆书源文件...';
    _rebuildView();
    try {
      final archiveResult = await _importArchiveWorkflowService.execute(
        project: project,
        sourceFilePath: selectedPath.trim(),
      );
      _snapshot = _invalidatePreview(
        _snapshot.copyWith(
          isLoading: false,
          activeStepId: BookDeconstructionStepId.importSource,
          sourceAbsolutePath: archiveResult.sourceFilePath,
          sourceTitle: archiveResult.sourceTitle,
          sourceContent: archiveResult.sourceText,
        ),
      );
      _statusMessage = '原文已归档到 ${archiveResult.archivePath}，可继续补充结构说明后生成预览。';
      _rebuildView();
    } catch (error) {
      _snapshot = _snapshot.copyWith(isLoading: false);
      _statusMessage = '读取源文件失败：$error';
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
    _snapshot = _snapshot.copyWith(isLoading: true);
    _statusMessage = '正在生成结构化预览...';
    _rebuildView();
    try {
      final buildResult = _draftBuilderService.build(
        sourceTitle: _snapshot.sourceTitle,
        sourceContent: _snapshot.sourceContent,
        sourceAbsolutePath: _snapshot.sourceAbsolutePath,
        operatorNotes: _snapshot.operatorNotes,
        styleSummary: _snapshot.styleSummary,
        worldRulesText: _snapshot.worldRulesText,
        characterLinesText: _snapshot.characterLinesText,
        organizationLinesText: _snapshot.organizationLinesText,
      );
      final selectedIds = buildResult.applicationPlan.items
          .map((item) => item.id)
          .toSet();
      _snapshot = _snapshot.copyWith(
        isLoading: false,
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
          '已生成结构化预览，共 ${buildResult.applicationPlan.items.length} 项可应用。';
      _rebuildView();
    } catch (error) {
      _snapshot = _snapshot.copyWith(isLoading: false);
      _statusMessage = '生成结构化预览失败：$error';
      _rebuildView();
    }
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
    _snapshot = _snapshot.copyWith(isLoading: true);
    _statusMessage = '正在写入拆书预演纪要...';
    _rebuildView();
    try {
      final result = await _persistConfirmation(
        project: validation.project!,
        buildResult: validation.buildResult!,
      );
      _statusMessage = _confirmationSuccessMessage(result);
      _rebuildView();
    } catch (error) {
      _snapshot = _snapshot.copyWith(isLoading: false);
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
    _snapshot = _snapshot.copyWith(isLoading: true);
    _statusMessage = '正在派生并创建后续项目...';
    _rebuildView();
    try {
      if (_snapshot.confirmedPreviewPath.trim().isEmpty) {
        final confirmation = await _persistConfirmation(
          project: validation.project!,
          buildResult: validation.buildResult!,
        );
        _statusMessage = _confirmationSuccessMessage(confirmation);
        _rebuildView();
      }
      final result = await creationService.execute(
        projectsRootPath: _projectsRootPath,
        sourceProject: validation.project!,
        buildResult: validation.buildResult!,
        selectedItemIds: _snapshot.selectedItemIds,
        selectedFollowupOptionId: _snapshot.selectedFollowupOptionId,
      );
      _snapshot = _snapshot.copyWith(isLoading: false);
      _statusMessage = '已派生项目：${result.project.name}';
      _rebuildView();
      await openDerivedProjectRequested(
        result.project,
        result.preferredOpenPath,
      );
    } catch (error) {
      _snapshot = _snapshot.copyWith(isLoading: false);
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
