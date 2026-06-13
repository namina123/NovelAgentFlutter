import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/project_long_task_summary_view_data.dart';
import 'workbench_visual_style.dart';

class ProjectLongTaskSummaryPanel extends StatelessWidget {
  const ProjectLongTaskSummaryPanel({
    super.key,
    required this.summary,
    this.onOpenStationRequested,
  });

  final ProjectLongTaskSummaryViewData summary;
  final VoidCallback? onOpenStationRequested;

  @override
  Widget build(BuildContext context) {
    final toolSurface = context.novelThemeSurfaces.toolRow;
    final optionSurface = context.novelThemeSurfaces.optionTile;
    final visual = WorkbenchVisualStyle.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                summary.summary,
                style: TextStyle(
                  fontSize: visual.bodyFontSize,
                  height: visual.bodyLineHeight,
                  fontWeight: FontWeight.w600,
                  color: optionSurface.mutedForegroundColor,
                ),
              ),
            ),
            if (onOpenStationRequested != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onOpenStationRequested,
                child: const Text('打开总站'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _SummaryBadge(label: '总数', value: summary.totalCount),
            _SummaryBadge(label: '运行中', value: summary.activeCount),
            _SummaryBadge(label: '待处理', value: summary.attentionCount),
          ],
        ),
        if (summary.isLoading) ...[
          const SizedBox(height: 10),
          const LinearProgressIndicator(minHeight: 2),
        ] else if (!summary.hasRuns) ...[
          const SizedBox(height: 10),
          Text(
            '当前项目暂无运行实例。',
            style: TextStyle(
              fontSize: visual.bodyFontSize,
              fontWeight: FontWeight.w600,
              color: optionSurface.mutedForegroundColor,
            ),
          ),
        ] else ...[
          const SizedBox(height: 10),
          ...summary.runs.map(
            (run) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: run.requiresAttention
                      ? toolSurface.highlightBackgroundColor.withValues(
                          alpha: 0.34,
                        )
                      : optionSurface.backgroundColor.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    top: BorderSide(
                      color:
                          (run.requiresAttention
                                  ? toolSurface.highlightBorderColor
                                  : optionSurface.borderColor)
                              .withValues(alpha: 0.42),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              run.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: visual.sectionTitleFontSize,
                                fontWeight: FontWeight.w800,
                                color: optionSurface.foregroundColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: run.requiresAttention
                                  ? toolSurface.highlightBackgroundColor
                                        .withValues(alpha: 0.36)
                                  : optionSurface.backgroundColor.withValues(
                                      alpha: 0.22,
                                    ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              run.statusLabel,
                              style: TextStyle(
                                fontSize: visual.metaFontSize,
                                fontWeight: FontWeight.w700,
                                color: run.requiresAttention
                                    ? toolSurface.highlightForegroundColor
                                    : optionSurface.mutedForegroundColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        run.subtitle,
                        style: TextStyle(
                          fontSize: visual.metaFontSize,
                          fontWeight: FontWeight.w600,
                          color: optionSurface.mutedForegroundColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        run.taskLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: visual.bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: optionSurface.foregroundColor,
                        ),
                      ),
                      if (run.attentionCalloutTitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          run.attentionCalloutTitle,
                          style: TextStyle(
                            fontSize: visual.metaFontSize,
                            fontWeight: FontWeight.w700,
                            color: run.requiresAttention
                                ? toolSurface.highlightForegroundColor
                                : optionSurface.foregroundColor,
                          ),
                        ),
                      ],
                      if (run.attentionCalloutSummary.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          run.attentionCalloutSummary,
                          style: TextStyle(
                            fontSize: visual.metaFontSize,
                            height: visual.bodyLineHeight,
                            color: optionSurface.mutedForegroundColor,
                          ),
                        ),
                      ],
                      if (run.diagnosisLabel.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          run.diagnosisLabel,
                          style: TextStyle(
                            fontSize: visual.metaFontSize,
                            fontWeight: FontWeight.w700,
                            color: run.requiresAttention
                                ? toolSurface.highlightForegroundColor
                                : optionSurface.foregroundColor,
                          ),
                        ),
                      ],
                      if (run.diagnosisSummary.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          run.diagnosisSummary,
                          style: TextStyle(
                            fontSize: visual.metaFontSize,
                            height: visual.bodyLineHeight,
                            color: optionSurface.mutedForegroundColor,
                          ),
                        ),
                      ],
                      if (run.nextStepSummary.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          run.nextStepLabel.trim().isEmpty
                              ? run.nextStepSummary
                              : '${run.nextStepLabel}：${run.nextStepSummary}',
                          style: TextStyle(
                            fontSize: visual.metaFontSize,
                            height: visual.bodyLineHeight,
                            fontWeight: FontWeight.w600,
                            color: optionSurface.foregroundColor,
                          ),
                        ),
                      ],
                      ..._buildDetailLines(
                        run,
                        optionSurface,
                        toolSurface,
                        visual,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        run.recentActivityLabel,
                        style: TextStyle(
                          fontSize: visual.metaFontSize,
                          fontWeight: FontWeight.w700,
                          color: optionSurface.mutedForegroundColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

List<Widget> _buildDetailLines(
  ProjectLongTaskRunSummaryViewData run,
  dynamic optionSurface,
  dynamic toolSurface,
  WorkbenchVisualStyle visual,
) {
  final lines = <String>[
    run.reviewSummaryLine,
    run.repairSummaryLine,
    run.checkpointSummaryLine,
    run.pendingSummaryLine,
  ].where((line) => line.trim().isNotEmpty).toList(growable: false);
  return lines
      .map(
        (line) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            line,
            style: TextStyle(
              fontSize: visual.metaFontSize,
              height: visual.bodyLineHeight,
              color: run.requiresAttention
                  ? toolSurface.highlightForegroundColor
                  : optionSurface.mutedForegroundColor,
            ),
          ),
        ),
      )
      .toList(growable: false);
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.optionTile;
    final visual = WorkbenchVisualStyle.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontSize: visual.metaFontSize,
          fontWeight: FontWeight.w700,
          color: surface.foregroundColor,
        ),
      ),
    );
  }
}
