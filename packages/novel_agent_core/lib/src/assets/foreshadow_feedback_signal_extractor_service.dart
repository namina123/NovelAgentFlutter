import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../review/chapter_analysis_issue.dart';
import '../review/chapter_analysis_result_normalizer_service.dart';
import '../review/review_report_normalizer_service.dart';
import 'foreshadow_feedback_signal.dart';
import 'foreshadow_status_catalog_service.dart';

class ForeshadowFeedbackSignalExtractorService {
  ForeshadowFeedbackSignalExtractorService({
    ReviewReportNormalizerService? reviewReportNormalizerService,
    ChapterAnalysisResultNormalizerService?
    chapterAnalysisResultNormalizerService,
    ForeshadowStatusCatalogService? statusCatalogService,
  }) : _reviewReportNormalizerService =
           reviewReportNormalizerService ?? ReviewReportNormalizerService(),
       _chapterAnalysisResultNormalizerService =
           chapterAnalysisResultNormalizerService ??
           ChapterAnalysisResultNormalizerService(),
       _statusCatalogService =
           statusCatalogService ?? const ForeshadowStatusCatalogService();

  final ReviewReportNormalizerService _reviewReportNormalizerService;
  final ChapterAnalysisResultNormalizerService
  _chapterAnalysisResultNormalizerService;
  final ForeshadowStatusCatalogService _statusCatalogService;

  List<ForeshadowFeedbackSignal> fromReviewReport(JsonMap report) {
    // 中文注释: review 报告中的相关伏笔 ID 需要被提炼成状态信号，而不是只停留在报告文本里。
    final normalized = _reviewReportNormalizerService.normalizeReport(report);
    final signals = <ForeshadowFeedbackSignal>[];
    for (final issue in ValueReaders.mapList(normalized['issues'])) {
      for (final id in ValueReaders.stringList(
        issue['related_foreshadow_ids'],
      )) {
        signals.add(
          ForeshadowFeedbackSignal(
            foreshadowId: id,
            statusHint: _statusFromText(
              '${ValueReaders.stringValue(issue['title'])}\n'
              '${ValueReaders.stringValue(issue['detail'])}\n'
              '${ValueReaders.stringValue(issue['suggestion'])}',
              fallback: ForeshadowStatusCatalogService.atRisk,
            ),
            note: _note(issue),
            relatedTimelineIds: ValueReaders.stringList(
              issue['related_timeline_ids'],
            ),
            relatedRelationshipIds: ValueReaders.stringList(
              issue['related_relationship_ids'],
            ),
            relatedPaths: _mergePaths(
              ValueReaders.stringList(normalized['source_paths']),
              <String>[ValueReaders.stringValue(issue['source_path'])],
            ),
          ),
        );
      }
    }
    return _deduplicate(signals);
  }

  List<ForeshadowFeedbackSignal> fromAnalysisDocument(JsonMap rawDocument) {
    // 中文注释: 章节分析对象同样允许给伏笔状态反馈，保证“分析 -> 资产”闭环走共享合同。
    final result = _chapterAnalysisResultNormalizerService.normalizeResult(
      rawDocument,
    );
    final signals = <ForeshadowFeedbackSignal>[];
    for (final issue in result.issues) {
      for (final id in issue.relatedForeshadowIds) {
        signals.add(
          ForeshadowFeedbackSignal(
            foreshadowId: id,
            statusHint: _statusFromText(
              '${issue.title}\n${issue.detail}\n${issue.suggestion}',
              fallback: ForeshadowStatusCatalogService.atRisk,
            ),
            note: _joinNonEmpty(<String>[issue.title, issue.suggestion]),
            relatedTimelineIds: issue.relatedTimelineIds,
            relatedRelationshipIds: issue.relatedRelationshipIds,
            relatedPaths: _mergePaths(result.sourcePaths, result.relatedPaths),
          ),
        );
      }
    }
    for (final suggestion in result.suggestions) {
      for (final id in suggestion.issueIds) {
        ChapterAnalysisIssue? issue;
        for (final candidate in result.issues) {
          if (candidate.id == id) {
            issue = candidate;
            break;
          }
        }
        if (issue == null) {
          continue;
        }
        for (final foreshadowId in issue.relatedForeshadowIds) {
          signals.add(
            ForeshadowFeedbackSignal(
              foreshadowId: foreshadowId,
              statusHint: _statusFromText(
                '${suggestion.title}\n${suggestion.summary}',
                fallback: ForeshadowStatusCatalogService.pendingPayoff,
              ),
              note: _joinNonEmpty(<String>[
                suggestion.title,
                suggestion.summary,
              ]),
              relatedTimelineIds: issue.relatedTimelineIds,
              relatedRelationshipIds: issue.relatedRelationshipIds,
              relatedPaths: _mergePaths(
                result.sourcePaths,
                suggestion.outputPaths,
              ),
            ),
          );
        }
      }
    }
    return _deduplicate(signals);
  }

  String _statusFromText(String text, {required String fallback}) {
    final lower = text.toLowerCase();
    if (lower.contains('已回收') ||
        lower.contains('完成回收') ||
        lower.contains('已兑现') ||
        lower.contains('完成兑现')) {
      return ForeshadowStatusCatalogService.resolved;
    }
    if (lower.contains('部分回收')) {
      return ForeshadowStatusCatalogService.partialPayoff;
    }
    if (lower.contains('弃用') || lower.contains('放弃')) {
      return ForeshadowStatusCatalogService.abandoned;
    }
    if (lower.contains('回收') || lower.contains('兑现')) {
      return ForeshadowStatusCatalogService.pendingPayoff;
    }
    return _statusCatalogService.normalize(fallback);
  }

  String _note(JsonMap issue) {
    return _joinNonEmpty(<String>[
      ValueReaders.stringValue(issue['title']),
      ValueReaders.stringValue(issue['suggestion']),
    ]);
  }

  List<String> _mergePaths(List<String> left, List<String> right) {
    final result = <String>[];
    for (final item in <String>[...left, ...right]) {
      final clean = item.trim();
      if (clean.isNotEmpty && !result.contains(clean)) {
        result.add(clean);
      }
    }
    return result;
  }

  String _joinNonEmpty(List<String> values) {
    return values
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .join('；');
  }

  List<ForeshadowFeedbackSignal> _deduplicate(
    List<ForeshadowFeedbackSignal> signals,
  ) {
    final merged = <String, ForeshadowFeedbackSignal>{};
    for (final signal in signals) {
      final previous = merged[signal.foreshadowId];
      if (previous == null) {
        merged[signal.foreshadowId] = signal;
        continue;
      }
      final previousPriority = _statusCatalogService.priority(
        previous.statusHint,
      );
      final nextPriority = _statusCatalogService.priority(signal.statusHint);
      merged[signal.foreshadowId] = previousPriority <= nextPriority
          ? ForeshadowFeedbackSignal(
              foreshadowId: signal.foreshadowId,
              statusHint: previous.statusHint,
              note: _joinNonEmpty(<String>[previous.note, signal.note]),
              relatedTimelineIds: _mergePaths(
                previous.relatedTimelineIds,
                signal.relatedTimelineIds,
              ),
              relatedRelationshipIds: _mergePaths(
                previous.relatedRelationshipIds,
                signal.relatedRelationshipIds,
              ),
              relatedPaths: _mergePaths(
                previous.relatedPaths,
                signal.relatedPaths,
              ),
            )
          : ForeshadowFeedbackSignal(
              foreshadowId: signal.foreshadowId,
              statusHint: signal.statusHint,
              note: _joinNonEmpty(<String>[previous.note, signal.note]),
              relatedTimelineIds: _mergePaths(
                previous.relatedTimelineIds,
                signal.relatedTimelineIds,
              ),
              relatedRelationshipIds: _mergePaths(
                previous.relatedRelationshipIds,
                signal.relatedRelationshipIds,
              ),
              relatedPaths: _mergePaths(
                previous.relatedPaths,
                signal.relatedPaths,
              ),
            );
    }
    return merged.values.toList(growable: false);
  }
}
