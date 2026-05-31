import 'package:flutter/material.dart';

import '../../../../../app/theme/app_palette.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../../../../../shared/widgets/section_heading.dart';

class TaskCenterDetailPanel extends StatelessWidget {
  const TaskCenterDetailPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.detailBody,
    required this.resumeBriefBody,
    required this.queueSummary,
    required this.schedulerSummary,
    required this.guidanceRevisitBody,
  });

  final String title;
  final String subtitle;
  final String detailBody;
  final String resumeBriefBody;
  final String queueSummary;
  final String schedulerSummary;
  final String guidanceRevisitBody;

  @override
  Widget build(BuildContext context) {
    return PanelSurface(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(title: title, subtitle: subtitle),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                [
                  detailBody.trim(),
                  if (resumeBriefBody.trim().isNotEmpty) '\n\n$resumeBriefBody',
                  if (queueSummary.trim().isNotEmpty)
                    '\n\n## 队列预检\n$queueSummary',
                  if (schedulerSummary.trim().isNotEmpty)
                    '\n\n## 调度摘要\n$schedulerSummary',
                  if (guidanceRevisitBody.trim().isNotEmpty)
                    '\n\n$guidanceRevisitBody',
                ].join(),
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.55,
                  color: AppPalette.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
