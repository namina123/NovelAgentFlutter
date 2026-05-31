import 'package:flutter/material.dart';

import '../../../../shared/widgets/action_button.dart';
import '../../../../shared/widgets/section_heading.dart';
import '../contracts/review_center_action_handler.dart';
import '../models/review_center_view_data.dart';

class ReviewCenterAnalysisPanel extends StatelessWidget {
  const ReviewCenterAnalysisPanel({
    super.key,
    required this.analysis,
    required this.actionHandler,
  });

  final ReviewCenterAnalysisViewData analysis;
  final ReviewCenterActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(
          title: analysis.title,
          subtitle: analysis.analysisTypeLabel.isEmpty
              ? '尚未生成分析结果'
              : '${analysis.analysisTypeLabel}｜${analysis.issueCountLabel}',
        ),
        const SizedBox(height: 10),
        if (analysis.summary.trim().isNotEmpty)
          Text(analysis.summary, style: Theme.of(context).textTheme.bodyMedium),
        if (analysis.overallAssessment.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            analysis.overallAssessment,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: analysis.rewriteActions
              .map(
                (item) => ChoiceChip(
                  label: Text(item.label),
                  selected: item.isSelected,
                  onSelected: (_) =>
                      actionHandler.onReviewCenterRewriteModeSelected(item.id),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            ActionButton(
              label: '生成计划',
              compact: true,
              onPressed: actionHandler.onReviewCenterPlanRequested,
            ),
            const SizedBox(width: 8),
            ActionButton(
              label: analysis.plan.confirmButtonLabel,
              compact: true,
              tone: analysis.plan.canCreateTask
                  ? ActionButtonTone.warm
                  : ActionButtonTone.neutral,
              onPressed: actionHandler.onReviewCenterMaterializeRewriteRequested,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              if (analysis.issues.isNotEmpty) ...[
                const _PanelHeading('问题'),
                ...analysis.issues.map(
                  (issue) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(issue.title),
                    subtitle: Text(
                      [
                        issue.severityLabel,
                        issue.rangeLabel,
                        issue.summary,
                        issue.suggestion,
                      ].where((item) => item.trim().isNotEmpty).join('｜'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const _PanelHeading('建议'),
              ...analysis.suggestions.map(
                (suggestion) => CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: suggestion.isSelected,
                  onChanged: (value) => actionHandler.onReviewCenterSuggestionToggled(
                    suggestion.id,
                    value ?? false,
                  ),
                  title: Text(suggestion.title),
                  subtitle: Text(
                    [
                      suggestion.actionKindLabel,
                      suggestion.segmentCountLabel,
                      suggestion.summary,
                    ].where((item) => item.trim().isNotEmpty).join('｜'),
                  ),
                ),
              ),
              if (analysis.segments.isNotEmpty) ...[
                const SizedBox(height: 8),
                const _PanelHeading('局部片段'),
                ...analysis.segments.map(
                  (segment) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: segment.isSelected,
                    onChanged: (value) => actionHandler.onReviewCenterSegmentToggled(
                      segment.id,
                      value ?? false,
                    ),
                    title: Text(segment.label),
                    subtitle: Text(segment.rangeLabel),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              const _PanelHeading('计划'),
              Text(
                analysis.plan.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (analysis.plan.summary.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(analysis.plan.summary),
              ],
              if (analysis.plan.instructions.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                SelectableText(
                  analysis.plan.instructions,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (analysis.plan.outputPaths.isNotEmpty) ...[
                const SizedBox(height: 6),
                ...analysis.plan.outputPaths.map(
                  (path) => Text(path, style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
              if (analysis.playback.body.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                const _PanelHeading('回放预览'),
                if (analysis.playback.sourcePath.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      analysis.playback.sourcePath,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                SelectableText(
                  analysis.playback.body,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PanelHeading extends StatelessWidget {
  const _PanelHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
