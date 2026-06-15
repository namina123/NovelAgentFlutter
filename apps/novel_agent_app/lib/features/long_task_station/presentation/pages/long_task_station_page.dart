import 'package:flutter/material.dart';

import '../../../../shared/theme/novel_theme_context.dart';
import '../../../../shared/widgets/panel_surface.dart';
import '../../../../shared/widgets/workspace_page_scaffold.dart';
import '../../../../shared/widgets/workspace_pane_layout.dart';
import '../../application/controllers/long_task_station_controller.dart';
import '../widgets/long_task_run_detail_panel.dart';
import '../widgets/long_task_run_list_panel.dart';
import '../widgets/long_task_station_toolbar.dart';

class LongTaskStationPage extends StatefulWidget {
  const LongTaskStationPage({
    super.key,
    required this.controller,
    required this.onBackRequested,
  });

  final LongTaskStationController controller;
  final VoidCallback onBackRequested;

  @override
  State<LongTaskStationPage> createState() => _LongTaskStationPageState();
}

class _LongTaskStationPageState extends State<LongTaskStationPage> {
  @override
  void initState() {
    super.initState();
    if (!widget.controller.isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.initialize();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final viewData = widget.controller.viewData;
        return WorkspacePageScaffold(
          header: LongTaskStationToolbar(
            title: viewData.title,
            description: viewData.description,
            supervisorStatusLabel: viewData.supervisorStatusLabel,
            onBackRequested: widget.onBackRequested,
            onTaskCenterRequested:
                widget.controller.onLongTaskStationTaskCenterRequested,
            onRefreshRequested:
                widget.controller.onLongTaskStationRefreshRequested,
          ),
          headerBottom: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ScopeChip(label: viewData.scopeLabel),
              _SummaryChip(label: '总数', value: viewData.totalCount),
              _SummaryChip(label: '运行中', value: viewData.activeCount),
              _SummaryChip(label: '已暂停', value: viewData.pausedCount),
              _SummaryChip(label: '待处理', value: viewData.attentionCount),
              FilterChip(
                label: Text(viewData.currentProjectFilterLabel),
                selected: viewData.isCurrentProjectFilterActive,
                onSelected: viewData.canFilterToCurrentProject
                    ? widget
                          .controller
                          .onLongTaskStationCurrentProjectFilterToggled
                    : null,
              ),
            ],
          ),
          statusText: viewData.statusMessage,
          isLoading: viewData.isLoading,
          body: WorkspacePaneLayout(
            breakpoint: 900,
            leadingPaneWidth: 320,
            leadingCompactHeight: 260,
            leadingPane: PanelSurface(
              showBorder: true,
              padding: EdgeInsets.zero,
              child: LongTaskRunListPanel(
                entries: viewData.runs,
                onRunSelected: widget.controller.onLongTaskStationRunSelected,
              ),
            ),
            mainPane: PanelSurface(
              showBorder: true,
              padding: EdgeInsets.zero,
              child: LongTaskRunDetailPanel(
                detail: viewData.selectedRun,
                actionHandler: widget.controller,
                pendingResearchActionHandler: widget.controller,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.optionTile;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: surface.backgroundColor,
        border: Border.all(
          color: surface.borderColor,
          width: surface.borderWidth,
        ),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: surface.foregroundColor,
        ),
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.optionTile;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: surface.backgroundColor,
        border: Border.all(
          color: surface.borderColor,
          width: surface.borderWidth,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: surface.foregroundColor,
        ),
      ),
    );
  }
}
