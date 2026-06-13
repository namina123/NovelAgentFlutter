import 'package:flutter/material.dart';

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
  });

  final WorkbenchCanvasViewData viewData;
  final DocumentWorkspaceActionHandler actionHandler;

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
  bool _prefersStructureMode = false;

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
      _prefersStructureMode = false;
    }
    if (widget.viewData.documents.isEmpty && _prefersStructureMode) {
      _prefersStructureMode = false;
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
      onChanged: selectedMode == DocumentWorkspaceDisplayMode.source
          ? widget.actionHandler.onDocumentBodyChanged
          : null,
    );
    return Column(
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
    );
  }

  void _handleDisplayModeSelected(DocumentWorkspaceDisplayMode mode) {
    final nextPrefersStructure = _modePolicyService
        .prefersStructureModeAfterSelection(mode);
    if (_prefersStructureMode != nextPrefersStructure) {
      setState(() => _prefersStructureMode = nextPrefersStructure);
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
