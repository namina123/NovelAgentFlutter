import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/services/document_workspace_display_mode_policy_service.dart';
import '../contracts/document_workspace_action_handler.dart';
import '../models/workbench_canvas_view_data.dart';
import '../services/document_resource_render_request_factory_service.dart';
import 'document_resource_canvas_host.dart';
import 'document_workspace_display_mode.dart';
import 'document_workspace_header_panel.dart';
import 'workbench_desktop_style.dart';

class WorkbenchPrimaryCanvasHost extends StatefulWidget {
  const WorkbenchPrimaryCanvasHost({
    super.key,
    required this.viewData,
    required this.actionHandler,
    this.onCreateFileRequested,
  });

  final WorkbenchCanvasViewData viewData;
  final DocumentWorkspaceActionHandler actionHandler;

  /// 空态「新建文档」入口；透传到空画布。为空时（如非主壳路径）不显示该按钮。
  final VoidCallback? onCreateFileRequested;

  @override
  State<WorkbenchPrimaryCanvasHost> createState() =>
      _WorkbenchPrimaryCanvasHostState();
}

class _WorkbenchPrimaryCanvasHostState
    extends State<WorkbenchPrimaryCanvasHost> {
  static const DocumentResourceRenderRequestFactoryService _requestFactory =
      DocumentResourceRenderRequestFactoryService();
  static const DocumentWorkspaceDisplayModePolicyService _modePolicyService =
      DocumentWorkspaceDisplayModePolicyService();

  String _trackedDocumentId = '';
  // 中文注释: 结构(信息)模式偏好按文档记住——切到另一文档再切回，仍保留之前的选择，
  // 与 isRendered(每文档持久)一致；此前用单个 bool 会在每次切文档时重置。
  final Map<String, bool> _structureModeByDocument = <String, bool>{};

  bool get _prefersStructureMode =>
      _structureModeByDocument[_trackedDocumentId] ?? false;

  @override
  void initState() {
    super.initState();
    _trackedDocumentId = _activeDocumentId(widget.viewData);
  }

  @override
  void didUpdateWidget(covariant WorkbenchPrimaryCanvasHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextDocumentId = _activeDocumentId(widget.viewData);
    if (nextDocumentId != _trackedDocumentId) {
      _trackedDocumentId = nextDocumentId;
      // 中文注释: 不重置偏好——per-doc map 保留每个文档的选择。
    }
    if (widget.viewData.documents.isEmpty && _structureModeByDocument.isNotEmpty) {
      _structureModeByDocument.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = WorkbenchDesktopStyle.of(context);
    final modePolicy = _modePolicyService.resolve(
      viewData: widget.viewData,
      prefersStructureMode: _prefersStructureMode,
    );
    final selectedMode = modePolicy.selectedMode;
    final request = _requestFactory.build(
      viewData: widget.viewData,
      selectedMode: selectedMode,
      onChanged: selectedMode != DocumentWorkspaceDisplayMode.structure
          ? widget.actionHandler.onDocumentBodyChanged
          : null,
      onCreateFileRequested: widget.onCreateFileRequested,
    );
    return CallbackShortcuts(
      // 中文注释: 写作面的基本快捷键：Ctrl+S 保存当前文档（文档工具栏的保存等价物）。
      // 焦点在正文编辑区时生效；无文档时保存动作会自行给出"当前没有可保存内容"提示。
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          widget.actionHandler.onDocumentActionRequested(
            DocumentToolbarAction.save,
          );
        },
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DocumentWorkspaceHeaderPanel(
            documents: widget.viewData.documents,
            onSelected: widget.actionHandler.onDocumentSelected,
            onClosed: widget.actionHandler.onDocumentClosed,
            onActionRequested: widget.actionHandler.onDocumentActionRequested,
            onDisplayModeSelected: _handleDisplayModeSelected,
            selectedMode: selectedMode,
            canRender: modePolicy.canRender,
            hasDocument: modePolicy.hasDocument,
          ),
          SizedBox(height: style.headerGap - 5.8),
          Expanded(child: DocumentResourceCanvasHost(request: request)),
        ],
      ),
    );
  }

  void _handleDisplayModeSelected(DocumentWorkspaceDisplayMode mode) {
    final nextPrefersStructure = _modePolicyService
        .prefersStructureModeAfterSelection(mode);
    if (_prefersStructureMode != nextPrefersStructure) {
      setState(() {
        if (_trackedDocumentId.isEmpty) {
          return;
        }
        _structureModeByDocument[_trackedDocumentId] = nextPrefersStructure;
      });
    }
    if (_modePolicyService.shouldRequestRenderToggle(
      requestedMode: mode,
      isActiveDocumentRendered: widget.viewData.isActiveDocumentRendered,
    )) {
      widget.actionHandler.onDocumentActionRequested(
        DocumentToolbarAction.render,
      );
    }
  }

  String _activeDocumentId(WorkbenchCanvasViewData viewData) {
    for (final document in viewData.documents) {
      if (document.isActive) {
        return document.id;
      }
    }
    return '';
  }
}
