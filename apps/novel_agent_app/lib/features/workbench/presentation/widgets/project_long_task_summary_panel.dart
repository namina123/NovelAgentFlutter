import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/project_long_task_summary_view_data.dart';

class ProjectLongTaskSummaryPanel extends StatelessWidget {
  const ProjectLongTaskSummaryPanel({
    super.key,
    required this.summary,
    required this.onOpenStationRequested,
  });

  final ProjectLongTaskSummaryViewData summary;
  final VoidCallback onOpenStationRequested;

  @override
  Widget build(BuildContext context) {
    final toolSurface = context.novelThemeSurfaces.toolRow;
    final optionSurface = context.novelThemeSurfaces.optionTile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                summary.summary,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: optionSurface.mutedForegroundColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onOpenStationRequested,
              child: const Text('打开总站'),
            ),
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
              fontSize: 12,
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
                      ? toolSurface.highlightBackgroundColor
                      : optionSurface.backgroundColor,
                  border: Border.all(
                    color: run.requiresAttention
                        ? toolSurface.highlightBorderColor
                        : optionSurface.borderColor,
                    width: optionSurface.borderWidth,
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
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: optionSurface.foregroundColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            run.statusLabel,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: run.requiresAttention
                                  ? toolSurface.highlightForegroundColor
                                  : optionSurface.mutedForegroundColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        run.subtitle,
                        style: TextStyle(
                          fontSize: 11,
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
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: optionSurface.foregroundColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        run.recentActivityLabel,
                        style: TextStyle(
                          fontSize: 10.5,
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

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.optionTile;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: surface.foregroundColor,
        ),
      ),
    );
  }
}
