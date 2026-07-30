import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../application/services/workbench_center_pane_policy_service.dart';
import '../../application/services/workbench_workspace_shell_view_data_service.dart';
import '../contracts/conversation_action_handler.dart';
import '../contracts/document_workspace_action_handler.dart';
import '../contracts/resource_manager_action_handler.dart';
import '../models/workbench_auxiliary_panel_id.dart';
import '../models/workbench_canvas_view_data.dart';
import '../models/workbench_conversation_view_data.dart';
import '../models/workbench_resource_view_data.dart';
import 'workbench_auxiliary_panel_host.dart';
import 'workbench_primary_canvas_host.dart';
import 'workbench_visual_style.dart';

class WorkbenchCanvasWorkspaceShell extends StatefulWidget {
  const WorkbenchCanvasWorkspaceShell({
    super.key,
    required this.canvasViewData,
    required this.resourceListenable,
    required this.conversationListenable,
    required this.documentHandler,
    required this.resourceHandler,
    required this.conversationHandler,
  });

  final WorkbenchCanvasViewData canvasViewData;
  final ValueListenable<WorkbenchResourceViewData> resourceListenable;
  final ValueListenable<WorkbenchConversationViewData> conversationListenable;
  final DocumentWorkspaceActionHandler documentHandler;
  final ResourceManagerActionHandler resourceHandler;
  final ConversationActionHandler conversationHandler;

  @override
  State<WorkbenchCanvasWorkspaceShell> createState() =>
      _WorkbenchCanvasWorkspaceShellState();
}

class _WorkbenchCanvasWorkspaceShellState
    extends State<WorkbenchCanvasWorkspaceShell> {
  static const WorkbenchWorkspaceShellViewDataService _shellViewDataService =
      WorkbenchWorkspaceShellViewDataService();
  static const WorkbenchCenterPanePolicyService _centerPanePolicyService =
      WorkbenchCenterPanePolicyService();

  WorkbenchAuxiliaryPanelId _selectedPanelId =
      WorkbenchAuxiliaryPanelId.promptPreview;
  bool _isAuxiliaryVisible = false;

  @override
  Widget build(BuildContext context) {
    final visual = WorkbenchVisualStyle.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.resourceListenable,
        widget.conversationListenable,
      ]),
      builder: (context, _) {
        final shellViewData = _shellViewDataService.build(
          resource: widget.resourceListenable.value,
          canvas: widget.canvasViewData,
          conversation: widget.conversationListenable.value,
        );
        final centerPaneViewData = _centerPanePolicyService.build(
          shellViewData,
        );
        return LayoutBuilder(
          builder: (context, constraints) {
            final auxiliaryHeight = constraints.maxHeight >= 860
                ? 188.0
                : 152.0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: WorkbenchPrimaryCanvasHost(
                    viewData: widget.canvasViewData,
                    // 中文注释: 空画布的「新建文档」复用资料库的 onCreateFileRequested，
                    // 不经 DocumentWorkspaceActionHandler，避免改契约/波及测试桩。
                    onCreateFileRequested: widget.resourceHandler.onCreateFileRequested,
                    actionHandler: _DocumentWorkspaceAuxiliaryProxy(
                      delegate: widget.documentHandler,
                      onReviewRequested: () {
                        _openAuxiliary(
                          WorkbenchAuxiliaryPanelId.reviewAnalysis,
                        );
                      },
                      onOutlineRequested: () {
                        _openAuxiliary(
                          WorkbenchAuxiliaryPanelId.contextSelection,
                        );
                      },
                    ),
                  ),
                ),
                if (centerPaneViewData.canRevealAuxiliary && _isAuxiliaryVisible)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      visual.panelPadding.left - 2,
                      1,
                      visual.panelPadding.right - 2,
                      visual.compactGap + 1,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            top: visual.compactGap + 1,
                          ),
                          child: SizedBox(
                            height: auxiliaryHeight,
                            child: WorkbenchAuxiliaryPanelHost(
                              selectedPanelId: _selectedPanelId,
                              centerPaneViewData: centerPaneViewData,
                              viewData: shellViewData,
                              onPanelSelected: _selectAuxiliary,
                              onDismissRequested: _hideAuxiliary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _selectAuxiliary(WorkbenchAuxiliaryPanelId panelId) {
    if (_selectedPanelId == panelId && _isAuxiliaryVisible) {
      return;
    }
    setState(() {
      _selectedPanelId = panelId;
    });
  }

  void _openAuxiliary(WorkbenchAuxiliaryPanelId panelId) {
    setState(() {
      _selectedPanelId = panelId;
      _isAuxiliaryVisible = true;
    });
  }

  void _hideAuxiliary() {
    if (!_isAuxiliaryVisible) {
      return;
    }
    setState(() {
      _isAuxiliaryVisible = false;
    });
  }
}

class _DocumentWorkspaceAuxiliaryProxy
    implements DocumentWorkspaceActionHandler {
  const _DocumentWorkspaceAuxiliaryProxy({
    required this.delegate,
    required this.onReviewRequested,
    required this.onOutlineRequested,
  });

  final DocumentWorkspaceActionHandler delegate;
  final VoidCallback onReviewRequested;
  final VoidCallback onOutlineRequested;

  @override
  void onDocumentActionRequested(DocumentToolbarAction action) {
    switch (action) {
      case DocumentToolbarAction.review:
        onReviewRequested();
        break;
      case DocumentToolbarAction.outline:
        onOutlineRequested();
        break;
      case DocumentToolbarAction.render:
      case DocumentToolbarAction.save:
        break;
    }
    delegate.onDocumentActionRequested(action);
  }

  @override
  void onDocumentBodyChanged(String value) {
    delegate.onDocumentBodyChanged(value);
  }

  @override
  void onDocumentClosed(String documentId) {
    delegate.onDocumentClosed(documentId);
  }

  @override
  void onDocumentSelected(String documentId) {
    delegate.onDocumentSelected(documentId);
  }
}
