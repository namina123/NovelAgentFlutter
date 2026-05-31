import 'package:flutter/material.dart';

import '../models/workbench_compact_primary_view.dart';
import '../services/workbench_compact_primary_view_resolver.dart';
import 'workbench_compact_view_switcher.dart';
import 'workbench_pane_shell.dart';

class WorkbenchCompactWorkspaceShell extends StatefulWidget {
  const WorkbenchCompactWorkspaceShell({
    super.key,
    required this.workspacePane,
    required this.documentPane,
    required this.conversationPane,
    required this.isDocumentsWorkspaceVisible,
    required this.onDocumentViewRequested,
    required this.onNonDocumentViewRequested,
  });

  final Widget workspacePane;
  final Widget documentPane;
  final Widget conversationPane;
  final bool isDocumentsWorkspaceVisible;
  final VoidCallback onDocumentViewRequested;
  final VoidCallback onNonDocumentViewRequested;

  @override
  State<WorkbenchCompactWorkspaceShell> createState() =>
      _WorkbenchCompactWorkspaceShellState();
}

class _WorkbenchCompactWorkspaceShellState
    extends State<WorkbenchCompactWorkspaceShell> {
  static const WorkbenchCompactPrimaryViewResolver _viewResolver =
      WorkbenchCompactPrimaryViewResolver();

  late WorkbenchCompactPrimaryView _activeView;

  @override
  void initState() {
    super.initState();
    _activeView = _viewResolver.resolveInitial(
      isDocumentsWorkspaceVisible: widget.isDocumentsWorkspaceVisible,
    );
  }

  @override
  void didUpdateWidget(covariant WorkbenchCompactWorkspaceShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextView = _viewResolver.synchronize(
      currentView: _activeView,
      isDocumentsWorkspaceVisible: widget.isDocumentsWorkspaceVisible,
    );
    if (nextView != _activeView) {
      _activeView = nextView;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WorkbenchCompactViewSwitcher(
          activeView: _activeView,
          onViewSelected: _handleViewSelected,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeOut,
            child: KeyedSubtree(
              key: ValueKey(_activeView),
              child: WorkbenchPaneShell(
                sectionId: _activeView.sectionId,
                showLeftOuterBorder: true,
                showRightOuterBorder: true,
                child: switch (_activeView) {
                  WorkbenchCompactPrimaryView.workspace =>
                    widget.workspacePane,
                  WorkbenchCompactPrimaryView.document => widget.documentPane,
                  WorkbenchCompactPrimaryView.conversation =>
                    widget.conversationPane,
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleViewSelected(WorkbenchCompactPrimaryView view) {
    if (_activeView == view) {
      return;
    }
    setState(() {
      _activeView = view;
    });
    if (view == WorkbenchCompactPrimaryView.document) {
      widget.onDocumentViewRequested();
      return;
    }
    widget.onNonDocumentViewRequested();
  }
}
