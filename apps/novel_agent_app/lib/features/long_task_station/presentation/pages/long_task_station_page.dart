import 'package:flutter/material.dart';

import '../../../../app/layout/adaptive_page_frame.dart';
import '../../../../shared/widgets/panel_surface.dart';
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
        return AdaptivePageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LongTaskStationToolbar(
                title: viewData.title,
                description: viewData.description,
                supervisorStatusLabel: viewData.supervisorStatusLabel,
                onBackRequested: widget.onBackRequested,
                onRefreshRequested:
                    widget.controller.onLongTaskStationRefreshRequested,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SummaryChip(label: '总数', value: viewData.totalCount),
                  _SummaryChip(label: '运行中', value: viewData.activeCount),
                  _SummaryChip(label: '已暂停', value: viewData.pausedCount),
                  _SummaryChip(label: '待处理', value: viewData.attentionCount),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                viewData.statusMessage,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 900;
                    if (isNarrow) {
                      return Column(
                        children: [
                          Expanded(
                            child: PanelSurface(
                              showBorder: true,
                              padding: EdgeInsets.zero,
                              child: LongTaskRunListPanel(
                                entries: viewData.runs,
                                onRunSelected: widget
                                    .controller
                                    .onLongTaskStationRunSelected,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: PanelSurface(
                              showBorder: true,
                              padding: EdgeInsets.zero,
                              child: LongTaskRunDetailPanel(
                                detail: viewData.selectedRun,
                                actionHandler: widget.controller,
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        SizedBox(
                          width: 320,
                          child: PanelSurface(
                            showBorder: true,
                            padding: EdgeInsets.zero,
                            child: LongTaskRunListPanel(
                              entries: viewData.runs,
                              onRunSelected: widget
                                  .controller
                                  .onLongTaskStationRunSelected,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PanelSurface(
                            showBorder: true,
                            padding: EdgeInsets.zero,
                            child: LongTaskRunDetailPanel(
                              detail: viewData.selectedRun,
                              actionHandler: widget.controller,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (viewData.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
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
    return Chip(label: Text('$label $value'));
  }
}
