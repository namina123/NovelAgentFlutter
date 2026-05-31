import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/workbench_auxiliary_panel_id.dart';
import '../models/workbench_center_auxiliary_panel_view_data.dart';
import '../models/workbench_center_pane_view_data.dart';
import '../models/workbench_workspace_shell_view_data.dart';
import 'workbench_desktop_style.dart';
import 'workbench_visual_style.dart';

class WorkbenchAuxiliaryPanelHost extends StatelessWidget {
  const WorkbenchAuxiliaryPanelHost({
    super.key,
    required this.selectedPanelId,
    required this.centerPaneViewData,
    required this.viewData,
    required this.onPanelSelected,
    required this.onDismissRequested,
  });

  final WorkbenchAuxiliaryPanelId selectedPanelId;
  final WorkbenchCenterPaneViewData centerPaneViewData;
  final WorkbenchWorkspaceShellViewData viewData;
  final ValueChanged<WorkbenchAuxiliaryPanelId> onPanelSelected;
  final VoidCallback onDismissRequested;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.panel;
    final style = WorkbenchDesktopStyle.of(context);
    final visual = WorkbenchVisualStyle.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.auxiliarySectionColor,
        border: Border(
          top: BorderSide(color: style.auxiliarySectionBorderColor, width: 1),
        ),
      ),
      child: Padding(
        padding: visual.auxiliaryPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        centerPaneViewData.descriptorFor(selectedPanelId).label,
                        style: TextStyle(
                          fontSize: visual.sectionTitleFontSize,
                          height: visual.titleLineHeight,
                          fontWeight: FontWeight.w800,
                          color: surface.foregroundColor,
                        ),
                      ),
                      SizedBox(height: visual.microGap - 2),
                      Text(
                        centerPaneViewData
                            .descriptorFor(selectedPanelId)
                            .description,
                        style: TextStyle(
                          fontSize: visual.captionFontSize,
                          height: visual.bodyLineHeight,
                          fontWeight: FontWeight.w500,
                          color: surface.mutedForegroundColor,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onDismissRequested,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('收起'),
                ),
              ],
            ),
            SizedBox(height: visual.compactGap),
            Wrap(
              spacing: visual.compactGap,
              runSpacing: visual.compactGap,
              children: centerPaneViewData.auxiliaryPanels
                  .map(
                    (panel) => _AuxiliaryPanelChip(
                      panel: panel,
                      selected: panel.panelId == selectedPanelId,
                      onSelected: () => onPanelSelected(panel.panelId),
                    ),
                  )
                  .toList(growable: false),
            ),
            SizedBox(height: visual.compactGap),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: KeyedSubtree(
                  key: ValueKey(selectedPanelId),
                  child: switch (selectedPanelId) {
                    WorkbenchAuxiliaryPanelId.promptPreview =>
                      _PromptPreviewPanel(viewData: viewData),
                    WorkbenchAuxiliaryPanelId.rewritePreview =>
                      _RewritePreviewPanel(viewData: viewData),
                    WorkbenchAuxiliaryPanelId.reviewAnalysis =>
                      _ReviewAnalysisPanel(viewData: viewData),
                    WorkbenchAuxiliaryPanelId.contextSelection =>
                      _ContextSelectionPanel(viewData: viewData),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuxiliaryPanelChip extends StatelessWidget {
  const _AuxiliaryPanelChip({
    required this.panel,
    required this.selected,
    required this.onSelected,
  });

  final WorkbenchCenterAuxiliaryPanelViewData panel;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final optionSurface = context.novelThemeSurfaces.optionTile;
    final visual = WorkbenchVisualStyle.of(context);
    return ChoiceChip(
      label: Text(panel.label),
      selected: selected,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: visual.optionBackground(optionSurface, selected: false),
      selectedColor: optionSurface.highlightBackgroundColor,
      side: BorderSide(
        color: selected
            ? optionSurface.highlightBorderColor
            : optionSurface.borderColor,
        width: optionSurface.borderWidth,
      ),
      labelStyle: TextStyle(
        fontSize: visual.compactLabelFontSize,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        color: optionSurface.foregroundColor,
      ),
      onSelected: (_) => onSelected(),
    );
  }
}

class _PromptPreviewPanel extends StatelessWidget {
  const _PromptPreviewPanel({required this.viewData});

  final WorkbenchWorkspaceShellViewData viewData;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.panel;
    final visual = WorkbenchVisualStyle.of(context);
    return ListView(
      primary: false,
      children: [
        _PanelBlock(
          title: '即将参与的协作基线',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InlineFact(label: '模型', value: viewData.modelLabel),
              _InlineFact(label: '智能体组', value: viewData.agentGroupLabel),
              _InlineFact(label: '主智能体', value: viewData.primaryAgentLabel),
              _InlineFact(label: '工作流', value: viewData.workflowTitle),
              const SizedBox(height: 8),
              Text(
                viewData.workflowDescription,
                style: TextStyle(
                  fontSize: visual.bodyFontSize,
                  height: visual.bodyLineHeight,
                  color: surface.mutedForegroundColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _PanelBlock(
          title: '当前上下文摘要',
          child: Text(
            viewData.contextSummary.trim().isEmpty
                ? '当前没有上下文摘要。'
                : viewData.contextSummary,
            style: TextStyle(
              fontSize: visual.bodyFontSize,
              height: visual.bodyLineHeight,
              color: surface.mutedForegroundColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _RewritePreviewPanel extends StatelessWidget {
  const _RewritePreviewPanel({required this.viewData});

  final WorkbenchWorkspaceShellViewData viewData;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.panel;
    final visual = WorkbenchVisualStyle.of(context);
    return ListView(
      primary: false,
      children: [
        _PanelBlock(
          title: '当前文档切片',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                viewData.activeDocumentDisplayTitle,
                style: TextStyle(
                  fontSize: visual.sectionTitleFontSize,
                  fontWeight: FontWeight.w800,
                  color: surface.foregroundColor,
                ),
              ),
              if (viewData.activeDocumentPath.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  viewData.activeDocumentPath,
                  style: TextStyle(
                    fontSize: visual.compactLabelFontSize,
                    fontWeight: FontWeight.w600,
                    color: surface.mutedForegroundColor,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                viewData.activeDocumentExcerpt.isEmpty
                    ? '当前文档暂无可预览内容。'
                    : viewData.activeDocumentExcerpt,
                style: TextStyle(
                  fontSize: visual.bodyFontSize,
                  height: visual.bodyLineHeight,
                  color: surface.mutedForegroundColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _PanelBlock(
          title: '重写前确认',
          child: Text(
            '先确认当前文档路径、标题和片段，再决定是否继续围绕这段内容重写、续写或局部调整。',
            style: TextStyle(
              fontSize: visual.bodyFontSize,
              height: visual.bodyLineHeight,
              color: surface.mutedForegroundColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewAnalysisPanel extends StatelessWidget {
  const _ReviewAnalysisPanel({required this.viewData});

  final WorkbenchWorkspaceShellViewData viewData;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.panel;
    final visual = WorkbenchVisualStyle.of(context);
    return ListView(
      primary: false,
      children: [
        _PanelBlock(
          title: '当前审稿锚点',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                viewData.activeDocumentDisplayTitle,
                style: TextStyle(
                  fontSize: visual.sectionTitleFontSize,
                  fontWeight: FontWeight.w800,
                  color: surface.foregroundColor,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _StatusChip(label: viewData.generationStatus),
                  _StatusChip(
                    label: viewData.activeDocumentDirty ? '存在未保存修改' : '已保存',
                  ),
                  _StatusChip(label: '候选选项 ${viewData.pendingOptionCount}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _PanelBlock(
          title: '当前处理方式',
          child: Text(
            '当前文档可以直接从工具栏发起审稿；审稿结果与返工任务会回到长任务总站和工作台文件区继续查看。',
            style: TextStyle(
              fontSize: visual.bodyFontSize,
              height: visual.bodyLineHeight,
              color: surface.mutedForegroundColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContextSelectionPanel extends StatelessWidget {
  const _ContextSelectionPanel({required this.viewData});

  final WorkbenchWorkspaceShellViewData viewData;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.panel;
    final visual = WorkbenchVisualStyle.of(context);
    return ListView(
      primary: false,
      children: [
        _PanelBlock(
          title: '当前会话上下文',
          child: Text(
            viewData.contextSummary.trim().isEmpty
                ? '当前没有上下文摘要。'
                : viewData.contextSummary,
            style: TextStyle(
              fontSize: visual.bodyFontSize,
              height: visual.bodyLineHeight,
              color: surface.mutedForegroundColor,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _PanelBlock(
          title: '关联信号',
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _StatusChip(label: '资源 ${viewData.resourceCount}'),
              _StatusChip(label: '子智能体 ${viewData.subAgentRunCount}'),
              _StatusChip(
                label: viewData.projectSubtitle.trim().isEmpty
                    ? '无副标题'
                    : viewData.projectSubtitle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PanelBlock extends StatelessWidget {
  const _PanelBlock({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final optionSurface = context.novelThemeSurfaces.optionTile;
    final visual = WorkbenchVisualStyle.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: optionSurface.highlightBorderColor, width: 2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 2, 4, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: visual.compactLabelFontSize,
                fontWeight: FontWeight.w800,
                color: optionSurface.foregroundColor,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _InlineFact extends StatelessWidget {
  const _InlineFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.panel;
    final visual = WorkbenchVisualStyle.of(context);
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: visual.bodyFontSize,
          height: visual.bodyLineHeight,
          color: surface.foregroundColor,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: surface.foregroundColor,
            ),
          ),
          TextSpan(
            text: value.trim().isEmpty ? '未设置' : value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: surface.mutedForegroundColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final chip = context.novelThemeSurfaces.optionTile;
    final visual = WorkbenchVisualStyle.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: visual.badgeBackground(chip),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: TextStyle(
            fontSize: visual.captionFontSize,
            fontWeight: FontWeight.w700,
            color: chip.foregroundColor,
          ),
        ),
      ),
    );
  }
}
