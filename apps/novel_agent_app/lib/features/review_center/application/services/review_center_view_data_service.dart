import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/review_center_analysis_state.dart';
import '../../presentation/models/review_center_view_data.dart';

class ReviewCenterViewDataService {
  const ReviewCenterViewDataService();

  ReviewCenterViewData build({
    required List<JsonMap> entries,
    required List<JsonMap> reviewTypeDefinitions,
    required String selectedEntryId,
    required String detailBody,
    required String reviewTypeFilter,
    required String scopeFilter,
    required String sourceFilter,
    required ReviewCenterAnalysisState analysisState,
    String status = '',
  }) {
    // 中文注释: 审稿页把原始报告摘要转换成稳定的展示模型，避免控制器手写列表徽标和筛选回显。
    final resolvedSelectedEntryId = _resolvedSelectedEntryId(
      selectedEntryId,
      entries,
    );
    return ReviewCenterViewData(
      title: '审稿报告',
      description: '浏览当前项目的连续性、文风、剧情与综合检查报告，并从报告生成修复任务。',
      status: status,
      entries: entries
          .map(
            (entry) => ReviewCenterEntryViewData(
              id: ValueReaders.stringValue(
                entry['markdown_path'],
                ValueReaders.stringValue(entry['relative_path']),
              ),
              title: ValueReaders.stringValue(entry['title'], '未命名报告'),
              subtitle: _entrySubtitle(entry),
              badge: _badgeText(entry),
              relativePath: ValueReaders.stringValue(
                entry['markdown_path'],
                ValueReaders.stringValue(entry['relative_path']),
              ),
              isSelected:
                  ValueReaders.stringValue(
                    entry['markdown_path'],
                    ValueReaders.stringValue(entry['relative_path']),
                  ) ==
                  resolvedSelectedEntryId,
            ),
          )
          .toList(growable: false),
      selectedEntryId: resolvedSelectedEntryId,
      detailBody: detailBody,
      reviewTypes: reviewTypeDefinitions
          .map(
            (item) => ReviewTypeOptionViewData(
              id: ValueReaders.stringValue(item['id']),
              label: ValueReaders.stringValue(item['name']),
            ),
          )
          .toList(growable: false),
      initialReviewTypeFilter: reviewTypeFilter,
      initialScopeFilter: scopeFilter,
      initialSourceFilter: sourceFilter,
      analysis: _analysisViewData(analysisState),
    );
  }

  String fallbackDetailBody(JsonMap loaded) {
    // 中文注释: 报告详情优先展示 Markdown 正文，没有时再退回总结结构。
    final markdownBody = ValueReaders.stringValue(
      loaded['markdown_body'],
    ).trim();
    if (markdownBody.isNotEmpty) {
      return markdownBody;
    }
    final report = ValueReaders.mapValue(loaded['report']);
    if (report.isEmpty) {
      return '';
    }
    final lines = <String>[
      '# ${ValueReaders.stringValue(report['title'], '未命名报告')}',
      '',
      '- 类型：${ValueReaders.stringValue(report['review_type'], 'general')}',
    ];
    final scope = ValueReaders.stringValue(report['scope']).trim();
    if (scope.isNotEmpty) {
      lines.add('- 范围：$scope');
    }
    final summary = ValueReaders.stringValue(report['summary']).trim();
    if (summary.isNotEmpty) {
      lines
        ..add('')
        ..add(summary);
    }
    return lines.join('\n');
  }

  ReviewCenterAnalysisViewData _analysisViewData(
    ReviewCenterAnalysisState analysisState,
  ) {
    final result = analysisState.analysisResult;
    if (result == null) {
      return ReviewCenterAnalysisViewData.empty();
    }
    return ReviewCenterAnalysisViewData(
      title: result.title,
      summary: result.summary,
      overallAssessment: result.overallAssessment,
      analysisTypeLabel: _analysisTypeLabel(result.analysisType),
      issueCountLabel: '问题 ${result.issues.length} / 建议 ${result.suggestions.length}',
      rewriteActions: <ReviewCenterRewriteActionViewData>[
        ReviewCenterRewriteActionViewData(
          id: ChapterRewriteActionKind.rewriteFull,
          label: '整章重写',
          description: '基于当前分析结论生成整章 revision 任务。',
          isSelected:
              analysisState.rewriteMode == ChapterRewriteActionKind.rewriteFull,
        ),
        ReviewCenterRewriteActionViewData(
          id: ChapterRewriteActionKind.rewritePartial,
          label: '局部重写',
          description: '只针对命中的片段范围生成 revision 任务。',
          isSelected:
              analysisState.rewriteMode ==
              ChapterRewriteActionKind.rewritePartial,
        ),
        ReviewCenterRewriteActionViewData(
          id: ChapterRewriteActionKind.suggestionsOnly,
          label: '只生成建议',
          description: '只整理建议与执行说明，不直接创建任务。',
          isSelected:
              analysisState.rewriteMode ==
              ChapterRewriteActionKind.suggestionsOnly,
        ),
      ],
      issues: result.issues
          .map(
            (issue) => ReviewCenterIssueViewData(
              id: issue.id,
              title: issue.title,
              severityLabel: _severityLabel(issue.severity),
              summary: issue.summary.isEmpty ? issue.detail : issue.summary,
              suggestion: issue.suggestion,
              rangeLabel: _rangeLabel(
                issue.sourcePath,
                issue.startLine,
                issue.endLine,
              ),
            ),
          )
          .toList(growable: false),
      suggestions: result.suggestions
          .map(
            (suggestion) => ReviewCenterSuggestionViewData(
              id: suggestion.id,
              title: suggestion.title,
              summary: suggestion.summary,
              actionKindLabel: _actionKindLabel(suggestion.actionKind),
              isSelected:
                  analysisState.selectedSuggestionIds.contains(suggestion.id),
              segmentCountLabel: suggestion.targetSegments.isEmpty
                  ? ''
                  : '片段 ${suggestion.targetSegments.length}',
            ),
          )
          .toList(growable: false),
      segments: result.suggestions
          .expand((suggestion) => suggestion.targetSegments)
          .map(
            (segment) => ReviewCenterSegmentViewData(
              id: segment.id,
              label: segment.label.trim().isEmpty
                  ? segment.sourcePath
                  : segment.label,
              rangeLabel: _rangeLabel(
                segment.sourcePath,
                segment.startLine,
                segment.endLine,
              ),
              sourcePath: segment.sourcePath,
              isSelected: analysisState.selectedSegmentIds.contains(segment.id),
            ),
          )
          .toList(growable: false),
      plan: _planViewData(
        analysisState.currentPlan,
        analysisState.rewriteMode,
      ),
      playback: ReviewCenterPlaybackViewData(
        title: '回放预览',
        sourcePath: analysisState.playbackSourcePath,
        body: analysisState.playbackBody,
      ),
    );
  }

  ReviewCenterPlanViewData _planViewData(
    ChapterRewritePlan? plan,
    String rewriteMode,
  ) {
    if (plan == null) {
      return ReviewCenterPlanViewData(
        title: '重写计划',
        summary: '',
        instructions: '',
        actionLabel: _actionKindLabel(rewriteMode),
        outputPaths: const <String>[],
        canCreateTask: rewriteMode != ChapterRewriteActionKind.suggestionsOnly,
        confirmButtonLabel: rewriteMode == ChapterRewriteActionKind.suggestionsOnly
            ? '生成建议'
            : '创建修订任务',
      );
    }
    final canCreateTask =
        plan.actionKind != ChapterRewriteActionKind.suggestionsOnly &&
        (plan.actionKind != ChapterRewriteActionKind.rewritePartial ||
            plan.targetSegments.isNotEmpty);
    return ReviewCenterPlanViewData(
      title: plan.title,
      summary: plan.summary,
      instructions: plan.instructions,
      actionLabel: _actionKindLabel(plan.actionKind),
      outputPaths: plan.outputPaths,
      canCreateTask: canCreateTask,
      confirmButtonLabel:
          plan.actionKind == ChapterRewriteActionKind.suggestionsOnly
          ? '生成建议'
          : '创建修订任务',
    );
  }

  String _resolvedSelectedEntryId(
    String selectedEntryId,
    List<JsonMap> entries,
  ) {
    for (final entry in entries) {
      final path = ValueReaders.stringValue(
        entry['markdown_path'],
        ValueReaders.stringValue(entry['relative_path']),
      );
      if (path == selectedEntryId) {
        return selectedEntryId;
      }
    }
    if (entries.isEmpty) {
      return '';
    }
    return ValueReaders.stringValue(
      entries.first['markdown_path'],
      ValueReaders.stringValue(entries.first['relative_path']),
    );
  }

  String _entrySubtitle(JsonMap entry) {
    final parts = <String>[
      ValueReaders.stringValue(
        entry['review_type_label'],
        ValueReaders.stringValue(entry['review_type'], '综合检查'),
      ),
    ];
    final scope = ValueReaders.stringValue(entry['scope']).trim();
    if (scope.isNotEmpty) {
      parts.add(scope);
    }
    final sources = ValueReaders.stringList(entry['source_paths']);
    if (sources.isNotEmpty) {
      parts.add(sources.first);
    }
    return parts.join('｜');
  }

  String _badgeText(JsonMap entry) {
    final issueCount = entry['issue_count'];
    if (issueCount is num) {
      return '${issueCount.toInt()}项';
    }
    final value = ValueReaders.stringValue(issueCount).trim();
    if (value.isNotEmpty) {
      return value;
    }
    return '报告';
  }

  String _analysisTypeLabel(String reviewType) {
    switch (reviewType) {
      case ReviewTypeConstants.continuity:
        return '连续性分析';
      case ReviewTypeConstants.style:
        return '文风分析';
      case ReviewTypeConstants.plot:
        return '剧情分析';
      default:
        return '综合分析';
    }
  }

  String _actionKindLabel(String actionKind) {
    switch (actionKind) {
      case ChapterRewriteActionKind.rewriteFull:
        return '整章重写';
      case ChapterRewriteActionKind.rewritePartial:
        return '局部重写';
      default:
        return '只生成建议';
    }
  }

  String _severityLabel(String severity) {
    switch (severity) {
      case 'critical':
        return '严重';
      case 'high':
        return '高';
      case 'medium':
        return '中';
      case 'low':
        return '低';
      default:
        return '一般';
    }
  }

  String _rangeLabel(String sourcePath, int startLine, int endLine) {
    final pathLabel = sourcePath.trim();
    if (startLine > 0 && endLine >= startLine) {
      return pathLabel.isEmpty
          ? '第 $startLine-$endLine 行'
          : '$pathLabel｜第 $startLine-$endLine 行';
    }
    return pathLabel;
  }
}
