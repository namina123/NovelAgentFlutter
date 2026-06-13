import 'package:flutter/material.dart';

import '../../../../../app/layout/app_layout_metrics.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/workbench_workspace_shell_view_data.dart';
import 'workbench_visual_style.dart';

class WorkbenchIdeShell extends StatelessWidget {
  const WorkbenchIdeShell({
    super.key,
    required this.metrics,
    required this.viewData,
    required this.child,
  });

  final AppLayoutMetrics metrics;
  final WorkbenchWorkspaceShellViewData viewData;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final showStatusBar =
        viewData.resourceCount > 0 ||
        viewData.activeDocumentDirty ||
        viewData.isGenerating ||
        viewData.generationStatus.trim().isNotEmpty;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.canvasBackground.withValues(alpha: 0.99),
            colors.panelBackground.withValues(alpha: 0.94),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WorkbenchTopBar(metrics: metrics, viewData: viewData),
          const SizedBox(height: 1),
          Expanded(child: child),
          if (showStatusBar) _WorkbenchStatusBar(viewData: viewData),
        ],
      ),
    );
  }
}

class _WorkbenchTopBar extends StatelessWidget {
  const _WorkbenchTopBar({required this.metrics, required this.viewData});

  final AppLayoutMetrics metrics;
  final WorkbenchWorkspaceShellViewData viewData;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final visual = WorkbenchVisualStyle.of(context);
    final isCompact = metrics.isCompact;
    final capsuleChildren = <Widget>[
      if (viewData.modelLabel.trim().isNotEmpty)
        _InfoCapsule(
          icon: Icons.auto_awesome_outlined,
          label: viewData.modelLabel,
        ),
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(
        isCompact ? visual.sectionGap + 1 : visual.panelPadding.left,
        isCompact ? visual.compactGap : visual.microGap + 1,
        isCompact ? visual.sectionGap + 1 : visual.panelPadding.right,
        isCompact ? visual.compactGap : visual.microGap + 1,
      ),
      decoration: BoxDecoration(
        color: colors.panelBackground.withValues(alpha: 0.38),
        border: Border(
          bottom: BorderSide(color: colors.lineColor.withValues(alpha: 0.1)),
        ),
      ),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WorkspaceIdentity(viewData: viewData, compact: true),
                if (capsuleChildren.isNotEmpty) ...[
                  SizedBox(height: visual.compactGap),
                  Wrap(
                    spacing: visual.compactGap,
                    runSpacing: visual.compactGap,
                    children: capsuleChildren,
                  ),
                ],
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 7,
                  child: _WorkspaceIdentity(viewData: viewData),
                ),
                if (capsuleChildren.isNotEmpty) ...[
                  SizedBox(width: visual.headerGap),
                  Flexible(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: visual.compactGap,
                        runSpacing: visual.compactGap,
                        children: capsuleChildren,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _WorkspaceIdentity extends StatelessWidget {
  const _WorkspaceIdentity({required this.viewData, this.compact = false});

  final WorkbenchWorkspaceShellViewData viewData;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final visual = WorkbenchVisualStyle.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: colors.accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: visual.compactGap),
            Text(
              'NovelAgent',
              style: TextStyle(
                fontSize: visual.captionFontSize - 0.2,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.06,
                color: colors.textColor,
              ),
            ),
            if (compact && viewData.modelLabel.trim().isNotEmpty) ...[
              SizedBox(width: visual.compactGap),
              Flexible(
                child: Text(
                  viewData.modelLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: visual.captionFontSize,
                    fontWeight: FontWeight.w700,
                    color: colors.mutedTextColor,
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: visual.microGap),
        Text(
          viewData.projectName.trim().isEmpty ? '未打开项目' : viewData.projectName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact
                ? visual.titleFontSize + 0.15
                : visual.titleFontSize + 0.7,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.08,
            color: colors.textColor,
          ),
        ),
        if (viewData.projectSubtitle.trim().isNotEmpty) ...[
          SizedBox(height: visual.microGap),
          Text(
            viewData.projectSubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: visual.metaFontSize,
              height: visual.bodyLineHeight,
              color: colors.mutedTextColor,
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoCapsule extends StatelessWidget {
  const _InfoCapsule({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final visual = WorkbenchVisualStyle.of(context);
    final foreground = colors.mutedTextColor;
    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: colors.sidebarBackground.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(visual.sectionRadius),
          border: Border.all(color: colors.lineColor.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            SizedBox(width: visual.compactGap),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                label.trim().isEmpty ? '未设置' : label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: visual.compactLabelFontSize - 0.5,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkbenchStatusBar extends StatelessWidget {
  const _WorkbenchStatusBar({required this.viewData});

  final WorkbenchWorkspaceShellViewData viewData;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final leftItems = <_StatusItem>[
      _StatusItem(
        icon: viewData.activeDocumentDirty
            ? Icons.edit_note_rounded
            : Icons.check_circle_outline_rounded,
        label: viewData.activeDocumentDirty ? '未保存修改' : '已保存',
      ),
      if (viewData.resourceCount > 0)
        _StatusItem(
          icon: Icons.folder_open_outlined,
          label: '${viewData.resourceCount} 项',
        ),
    ];
    final rightItems = <_StatusItem>[
      _StatusItem(
        icon: viewData.isGenerating ? Icons.sync_rounded : Icons.bolt_outlined,
        label: viewData.generationStatus.trim().isEmpty
            ? '就绪'
            : viewData.generationStatus,
      ),
      if (viewData.toolCoreStatus.trim().isNotEmpty &&
          viewData.toolCoreStatus.trim() != '紧凑' &&
          viewData.toolCoreStatus.trim() != '就绪')
        _StatusItem(
          icon: Icons.build_circle_outlined,
          label: viewData.toolCoreStatus,
        ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
      decoration: BoxDecoration(
        color: colors.sidebarBackground.withValues(alpha: 0.34),
        border: Border(
          top: BorderSide(color: colors.lineColor.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var index = 0; index < leftItems.length; index++) ...[
                    if (index > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          width: 1,
                          height: 12,
                          color: colors.lineColor.withValues(alpha: 0.28),
                        ),
                      ),
                    _StatusTag(item: leftItems[index]),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < rightItems.length; index++) ...[
                      if (index > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Container(
                            width: 1,
                            height: 12,
                            color: colors.lineColor.withValues(alpha: 0.28),
                          ),
                        ),
                      _StatusTag(item: rightItems[index], emphasized: true),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.item, this.emphasized = false});

  final _StatusItem item;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final visual = WorkbenchVisualStyle.of(context);
    return Tooltip(
      message: item.label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.icon,
            size: 12,
            color: emphasized ? colors.lineStrongColor : colors.mutedTextColor,
          ),
          SizedBox(width: visual.microGap),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Text(
              item.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: visual.captionFontSize - 0.5,
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
                color: emphasized ? colors.textColor : colors.mutedTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusItem {
  const _StatusItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
