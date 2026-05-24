import 'package:novel_agent_core/novel_agent_core.dart';

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
    );
  }

  String fallbackDetailBody(JsonMap loaded) {
    // 中文注释: 报告详情优先展示 Markdown 正文，没有时再退回总结结构。
    final markdownBody = ValueReaders.stringValue(loaded['markdown_body']).trim();
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
      lines..add('')..add(summary);
    }
    return lines.join('\n');
  }

  String _resolvedSelectedEntryId(String selectedEntryId, List<JsonMap> entries) {
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
}
