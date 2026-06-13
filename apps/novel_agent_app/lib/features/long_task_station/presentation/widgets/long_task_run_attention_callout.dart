import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../contracts/long_task_station_action_handler.dart';
import '../models/long_task_station_view_data.dart';

class LongTaskRunAttentionCallout extends StatelessWidget {
  const LongTaskRunAttentionCallout({
    super.key,
    required this.run,
    required this.actionHandler,
  });

  final LongTaskRunDetailViewData run;
  final LongTaskStationActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    if (!run.requiresManualAttention &&
        run.pendingUserAction == null &&
        run.preferredRecentOutput == null &&
        run.latestRepairTask == null &&
        run.latestReviewReport == null &&
        run.blockerActionHint.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final surface = context.novelThemeSurfaces.toolRow;
    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface.highlightBackgroundColor,
        border: Border.all(
          color: surface.highlightBorderColor,
          width: surface.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            run.attentionCalloutTitle.trim().isEmpty
                ? (run.pendingUserAction != null
                      ? '当前运行停在待确认节点。'
                      : run.requiresManualAttention
                      ? '当前运行停在待处理节点。'
                      : '这里有一条建议操作链。')
                : run.attentionCalloutTitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: surface.highlightForegroundColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            run.attentionCalloutSummary.trim().isEmpty
                ? _fallbackSummaryText()
                : run.attentionCalloutSummary,
            style: TextStyle(
              fontSize: 12,
              height: 1.55,
              fontWeight: FontWeight.w600,
              color: surface.highlightForegroundColor,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (run.canResume)
                FilledButton.tonal(
                  onPressed: () =>
                      actionHandler.onLongTaskStationResumeRequested(run.id),
                  child: Text(run.resumeActionLabel),
                ),
              if (run.pendingUserAction != null &&
                  run.pendingUserAction!.relativePath.trim().isNotEmpty)
                OutlinedButton(
                  onPressed: () =>
                      actionHandler.onLongTaskStationResourceRequested(
                        run.id,
                        run.pendingUserAction!.relativePath,
                      ),
                  child: Text(run.pendingUserActionLabel),
                ),
              if (run.preferredRecentOutput != null &&
                  run.preferredRecentOutput!.relativePath.trim().isNotEmpty)
                OutlinedButton(
                  onPressed: () =>
                      actionHandler.onLongTaskStationResourceRequested(
                        run.id,
                        run.preferredRecentOutput!.relativePath,
                      ),
                  child: const Text('查看最近产物'),
                ),
              if (run.latestRepairTask != null)
                OutlinedButton(
                  onPressed: () =>
                      actionHandler.onLongTaskStationResourceRequested(
                        run.id,
                        run.latestRepairTask!.relativePath,
                      ),
                  child: Text(run.latestRepairTask!.actionLabel),
                ),
              if (run.latestReviewReport != null)
                OutlinedButton(
                  onPressed: () =>
                      actionHandler.onLongTaskStationResourceRequested(
                        run.id,
                        run.latestReviewReport!.relativePath,
                      ),
                  child: Text(run.latestReviewReport!.actionLabel),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _fallbackSummaryText() {
    final segments = <String>[];
    if (run.blockerNote.trim().isNotEmpty && run.blockerNote != '当前没有明显阻塞。') {
      segments.add(run.blockerNote.trim());
    }
    if (run.blockerActionHint.trim().isNotEmpty) {
      segments.add(run.blockerActionHint.trim());
    }
    if (segments.isEmpty) {
      if (run.requiresManualAttention) {
        return '当前运行需要先处理后再继续。';
      }
      if (run.pendingUserAction != null) {
        return '当前运行在等待你先处理当前确认。';
      }
      return '可以从这里继续查看当前运行状态。';
    }
    return segments.join(' ');
  }
}
