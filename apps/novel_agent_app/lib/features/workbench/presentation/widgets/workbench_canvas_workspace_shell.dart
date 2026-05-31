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
import 'workbench_desktop_style.dart';
import 'workbench_primary_canvas_host.dart';

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
    final style = WorkbenchDesktopStyle.of(context);
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
        final selectedAuxiliaryPanel = centerPaneViewData.descriptorFor(
          _selectedPanelId,
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
                if (centerPaneViewData.canRevealAuxiliary)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: style.sectionGap * 0.55),
                        _AuxiliaryPeekBar(
                          title: centerPaneViewData.auxiliaryTitle,
                          selectedLabel: selectedAuxiliaryPanel.label,
                          selectedDescription:
                              selectedAuxiliaryPanel.description,
                          isExpanded: _isAuxiliaryVisible,
                          onPressed: _isAuxiliaryVisible
                              ? _hideAuxiliary
                              : _showAuxiliary,
                        ),
                        if (_isAuxiliaryVisible)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
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

  void _showAuxiliary() {
    if (_isAuxiliaryVisible) {
      return;
    }
    setState(() {
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

class _AuxiliaryPeekBar extends StatelessWidget {
  const _AuxiliaryPeekBar({
    required this.title,
    required this.selectedLabel,
    required this.selectedDescription,
    required this.isExpanded,
    required this.onPressed,
  });

  final String title;
  final String selectedLabel;
  final String selectedDescription;
  final bool isExpanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$title · $selectedLabel',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedDescription,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onPressed,
              icon: Icon(
                isExpanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 16,
              ),
              label: Text(isExpanded ? '收起' : '展开'),
            ),
          ],
        ),
      ),
    );
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
