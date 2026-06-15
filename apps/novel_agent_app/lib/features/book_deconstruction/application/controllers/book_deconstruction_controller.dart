import 'package:flutter/foundation.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';

import '../../presentation/contracts/book_deconstruction_action_handler.dart';
import '../../presentation/models/book_deconstruction_view_data.dart';
import '../models/book_deconstruction_snapshot.dart';
import '../models/book_deconstruction_step_id.dart';
import '../services/book_deconstruction_draft_builder_service.dart';
import '../services/book_deconstruction_narrative_persistence_service.dart';
import '../services/book_deconstruction_preview_markdown_service.dart';
import '../services/book_deconstruction_view_data_service.dart';
import '../services/desktop_book_deconstruction_source_picker_service.dart';

class BookDeconstructionController extends ChangeNotifier
    implements BookDeconstructionActionHandler {
  BookDeconstructionController({
    required ProjectToolHostPort projectToolHostPort,
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
    ReferenceSourceDocumentFileReaderService? sourceDocumentReaderService,
    BookDeconstructionTargetPathService? targetPathService,
  }) : _projectToolHostPort = projectToolHostPort,
       _writeProjectTextFileUseCase = writeProjectTextFileUseCase,
       _narrativePersistenceService = narrativePersistenceService,
       _readCurrentProject = readCurrentProject,
       _syncWorkbenchResources = syncWorkbenchResources,
       _onBackRequested = onBackRequested,
       _sourcePickerService =
           sourcePickerService ??
           const DesktopBookDeconstructionSourcePickerService(),
       _draftBuilderService =
           draftBuilderService ?? BookDeconstructionDraftBuilderService(),
       _previewMarkdownService =
           previewMarkdownService ??
           const BookDeconstructionPreviewMarkdownService(),
       _viewDataService =
           viewDataService ?? const BookDeconstructionViewDataService(),
       _sourceDocumentReaderService =
           sourceDocumentReaderService ??
           const ReferenceSourceDocumentFileReaderService(),
       _targetPathService =
           targetPathService ?? const BookDeconstructionTargetPathService(),
       _snapshot = BookDeconstructionSnapshot.initial(),
       _viewData = BookDeconstructionViewData.initial();

  final ProjectToolHostPort _projectToolHostPort;
  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final BookDeconstructionNarrativePersistenceService
  _narrativePersistenceService;
  final ProjectDescriptor? Function() _readCurrentProject;
  final Future<void> Function() _syncWorkbenchResources;
  final VoidCallback _onBackRequested;
  final DesktopBookDeconstructionSourcePickerService _sourcePickerService;
  final BookDeconstructionDraftBuilderService _draftBuilderService;
  final BookDeconstructionPreviewMarkdownService _previewMarkdownService;
  final BookDeconstructionViewDataService _viewDataService;
  final ReferenceSourceDocumentFileReaderService _sourceDocumentReaderService;
  final BookDeconstructionTargetPathService _targetPathService;

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
      final sourceDocument = await _sourceDocumentReaderService.read(
        sourceFilePath: selectedPath.trim(),
      );
      final archivePath = _targetPathService.sourceArchivePath(
        sourceDocument.sourceFilePath,
      );
      await _writeProjectTextFileUseCase.execute(
        project: project,
        relativePath: archivePath,
        content: sourceDocument.sourceText.trim(),
      );
      _snapshot = _invalidatePreview(
        _snapshot.copyWith(
          isLoading: false,
          activeStepId: BookDeconstructionStepId.importSource,
          sourceAbsolutePath: sourceDocument.sourceFilePath,
          sourceTitle: sourceDocument.sourceTitle,
          sourceContent: sourceDocument.sourceText.trim(),
        ),
      );
      _statusMessage = '原文已归档到 $archivePath，可继续补充结构说明后生成预览。';
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
  Future<void> onBookDeconstructionConfirmRequested() async {
    final project = _readCurrentProject();
    final buildResult = _snapshot.buildResult;
    if (project == null) {
      await refresh(status: '请先创建或打开拆书项目。');
      return;
    }
    if (buildResult == null) {
      _statusMessage = '请先生成结构化预览。';
      _rebuildView();
      return;
    }
    if (_snapshot.selectedItemIds.isEmpty) {
      _statusMessage = '请至少勾选一个拟应用条目。';
      _rebuildView();
      return;
    }
    _snapshot = _snapshot.copyWith(isLoading: true);
    _statusMessage = '正在写入拆书预演纪要...';
    _rebuildView();
    final previewPath = _targetPathService.previewPath();
    try {
      final markdown = _previewMarkdownService.render(
        buildResult: buildResult,
        selectedItemIds: _snapshot.selectedItemIds,
      );
      await _writeProjectTextFileUseCase.execute(
        project: project,
        relativePath: previewPath,
        content: markdown,
      );
      await _narrativePersistenceService.persist(
        project: project,
        narrativeArtifacts: buildResult.narrativeArtifacts,
      );
      await _syncWorkbenchResources();
      _snapshot = _snapshot.copyWith(
        isLoading: false,
        activeStepId: BookDeconstructionStepId.confirmSelection,
        confirmedPreviewPath: previewPath,
      );
      _statusMessage =
          '已确认 ${_snapshot.selectedItemIds.length} 项，预演纪要已写入 $previewPath。';
      _rebuildView();
    } catch (error) {
      _snapshot = _snapshot.copyWith(isLoading: false);
      _statusMessage = '写入拆书预演纪要失败：$error';
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
      confirmedPreviewPath: '',
      activeStepId: BookDeconstructionStepId.importSource,
    );
  }

  void _rebuildView() {
    _viewData = _viewDataService.build(
      projectTitle: _readCurrentProject()?.name ?? '',
      snapshot: _snapshot,
      status: _statusMessage,
    );
    if (!_disposed) {
      notifyListeners();
    }
  }
}
