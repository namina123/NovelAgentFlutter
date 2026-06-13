import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/workbench_workspace_shell_view_data.dart';
import '../models/workbench_compact_primary_view.dart';
import '../services/workbench_compact_primary_view_resolver.dart';
import 'workbench_compact_view_switcher.dart';
import 'workbench_visual_style.dart';

class WorkbenchCompactWorkspaceShell extends StatefulWidget {
  const WorkbenchCompactWorkspaceShell({
    super.key,
    required this.viewData,
    required this.workspacePane,
    required this.documentPane,
    required this.conversationPane,
    required this.isDocumentsWorkspaceVisible,
    required this.onDocumentViewRequested,
    required this.onNonDocumentViewRequested,
  });

  final WorkbenchWorkspaceShellViewData viewData;
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
        _WorkbenchCompactChromeBar(
          viewData: widget.viewData,
          activeView: _activeView,
        ),
        WorkbenchCompactViewSwitcher(
          activeView: _activeView,
          onViewSelected: _handleViewSelected,
          showOverview: false,
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeOut,
            child: KeyedSubtree(
              key: ValueKey(_activeView),
              child: switch (_activeView) {
                WorkbenchCompactPrimaryView.workspace => widget.workspacePane,
                WorkbenchCompactPrimaryView.document => widget.documentPane,
                WorkbenchCompactPrimaryView.conversation =>
                  widget.conversationPane,
              },
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

class _WorkbenchCompactChromeBar extends StatelessWidget {
  const _WorkbenchCompactChromeBar({
    required this.viewData,
    required this.activeView,
  });

  final WorkbenchWorkspaceShellViewData viewData;
  final WorkbenchCompactPrimaryView activeView;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final visual = WorkbenchVisualStyle.of(context);
    final projectName = viewData.projectName.trim().isEmpty
        ? '未命名项目'
        : viewData.projectName.trim();
    final activeTitle = switch (activeView) {
      WorkbenchCompactPrimaryView.workspace => '目录',
      WorkbenchCompactPrimaryView.document => '文档',
      WorkbenchCompactPrimaryView.conversation => '会话',
    };
    return Container(
      padding: EdgeInsets.fromLTRB(
        visual.panelPadding.left,
        visual.microGap,
        visual.panelPadding.right,
        visual.microGap,
      ),
      decoration: BoxDecoration(
        color: colors.panelBackground.withValues(alpha: 0.42),
        border: Border(
          bottom: BorderSide(color: colors.lineColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              projectName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: visual.titleFontSize - 0.6,
                fontWeight: FontWeight.w800,
                color: colors.textColor,
              ),
            ),
          ),
          Text(
            activeTitle,
            style: TextStyle(
              fontSize: visual.metaFontSize - 0.1,
              fontWeight: FontWeight.w700,
              color: colors.mutedTextColor,
            ),
          ),
          SizedBox(width: visual.microGap + 1),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colors.accentColor.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}
