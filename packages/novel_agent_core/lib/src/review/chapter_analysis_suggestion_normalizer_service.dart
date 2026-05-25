import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'chapter_analysis_suggestion.dart';
import 'chapter_analysis_target_segment.dart';
import 'chapter_rewrite_action_kind.dart';

class ChapterAnalysisSuggestionNormalizerService {
  const ChapterAnalysisSuggestionNormalizerService();

  List<ChapterAnalysisSuggestion> normalizeSuggestions(
    Object? rawSuggestions, {
    String suggestionIdPrefix = 'suggestion',
    List<String> fallbackSourcePaths = const <String>[],
    List<String> fallbackOutputPaths = const <String>[],
  }) {
    // 中文注释: 建议对象负责承接“分析后可执行动作”，这里把字符串建议和结构化建议统一压成正式领域对象。
    final result = <ChapterAnalysisSuggestion>[];
    final rawList = ValueReaders.objectList(rawSuggestions);
    for (var index = 0; index < rawList.length; index += 1) {
      final rawSuggestion = rawList[index];
      final suggestion = rawSuggestion is Map
          ? ValueReaders.mapValue(rawSuggestion)
          : <String, Object?>{'title': rawSuggestion, 'summary': rawSuggestion};
      final title = ValueReaders.stringValue(
        suggestion['title'],
        ValueReaders.stringValue(suggestion['name']),
      ).trim();
      final summary = ValueReaders.stringValue(
        suggestion['summary'],
        ValueReaders.stringValue(suggestion['detail']),
      ).trim();
      if (title.isEmpty && summary.isEmpty) {
        continue;
      }
      final targetSegments = _targetSegments(
        suggestion['target_segments'],
        suggestionIdPrefix: suggestionIdPrefix,
        suggestionIndex: index,
      );
      final sourcePaths = _paths(
        suggestion['source_paths'],
        fallbackValues: fallbackSourcePaths,
      );
      final outputPaths = _paths(
        suggestion['output_paths'],
        fallbackValues: targetSegments.isEmpty
            ? fallbackOutputPaths
            : _segmentPaths(targetSegments),
      );
      final actionKind = _actionKind(
        suggestion,
        targetSegments: targetSegments,
        outputPaths: outputPaths,
      );
      result.add(
        ChapterAnalysisSuggestion(
          id: _suggestionId(suggestion, suggestionIdPrefix, index),
          title: title.isEmpty ? summary : title,
          actionKind: actionKind,
          summary: summary,
          priorityRank: ValueReaders.intValue(
            suggestion['priority_rank'],
            index + 1,
          ),
          sourcePaths: sourcePaths,
          outputPaths: outputPaths,
          issueIds: ValueReaders.stringList(suggestion['issue_ids']),
          promptHints: ValueReaders.stringList(suggestion['prompt_hints']),
          targetSegments: targetSegments,
          metadata: ValueReaders.deepCopyMap(
            ValueReaders.mapValue(suggestion['metadata']),
          ),
        ),
      );
    }
    result.sort((left, right) {
      final rankCompare = left.priorityRank.compareTo(right.priorityRank);
      if (rankCompare != 0) {
        return rankCompare;
      }
      return left.title.compareTo(right.title);
    });
    return result;
  }

  JsonMap toDocument(ChapterAnalysisSuggestion suggestion) {
    return <String, Object?>{
      'id': suggestion.id,
      'title': suggestion.title,
      'action_kind': suggestion.actionKind,
      'summary': suggestion.summary,
      'priority_rank': suggestion.priorityRank,
      'source_paths': suggestion.sourcePaths,
      'output_paths': suggestion.outputPaths,
      'issue_ids': suggestion.issueIds,
      'prompt_hints': suggestion.promptHints,
      'target_segments': suggestion.targetSegments
          .map(_targetSegmentDocument)
          .toList(growable: false),
      'metadata': ValueReaders.deepCopyMap(suggestion.metadata),
    };
  }

  List<ChapterAnalysisTargetSegment> _targetSegments(
    Object? rawSegments, {
    required String suggestionIdPrefix,
    required int suggestionIndex,
  }) {
    final result = <ChapterAnalysisTargetSegment>[];
    final rawList = ValueReaders.objectList(rawSegments);
    for (var index = 0; index < rawList.length; index += 1) {
      final segment = ValueReaders.mapValue(rawList[index]);
      final sourcePath = ValueReaders.stringValue(
        segment['source_path'],
      ).trim();
      if (sourcePath.isEmpty) {
        continue;
      }
      result.add(
        ChapterAnalysisTargetSegment(
          id: ValueReaders.stringValue(
            segment['id'],
            '${suggestionIdPrefix}_${suggestionIndex + 1}_segment_${index + 1}',
          ).trim(),
          sourcePath: sourcePath,
          label: ValueReaders.stringValue(segment['label']).trim(),
          startLine: ValueReaders.intValue(
            segment['start_line'],
            ValueReaders.intValue(segment['line_start']),
          ),
          endLine: ValueReaders.intValue(
            segment['end_line'],
            ValueReaders.intValue(segment['line_end']),
          ),
          summary: ValueReaders.stringValue(segment['summary']).trim(),
          metadata: ValueReaders.deepCopyMap(
            ValueReaders.mapValue(segment['metadata']),
          ),
        ),
      );
    }
    return result;
  }

  JsonMap _targetSegmentDocument(ChapterAnalysisTargetSegment segment) {
    return <String, Object?>{
      'id': segment.id,
      'source_path': segment.sourcePath,
      'label': segment.label,
      'start_line': segment.startLine,
      'end_line': segment.endLine,
      'summary': segment.summary,
      'metadata': ValueReaders.deepCopyMap(segment.metadata),
    };
  }

  List<String> _paths(
    Object? rawPaths, {
    List<String> fallbackValues = const <String>[],
  }) {
    final result = <String>[];
    for (final rawPath in <String>[
      ...ValueReaders.stringList(rawPaths),
      ...fallbackValues,
    ]) {
      final clean = rawPath.trim().replaceAll('\\', '/');
      if (clean.isNotEmpty && !result.contains(clean)) {
        result.add(clean);
      }
    }
    return result;
  }

  List<String> _segmentPaths(
    List<ChapterAnalysisTargetSegment> targetSegments,
  ) {
    final result = <String>[];
    for (final segment in targetSegments) {
      final path = segment.sourcePath.trim();
      if (path.isNotEmpty && !result.contains(path)) {
        result.add(path);
      }
    }
    return result;
  }

  String _actionKind(
    JsonMap suggestion, {
    required List<ChapterAnalysisTargetSegment> targetSegments,
    required List<String> outputPaths,
  }) {
    final explicitActionKind = ValueReaders.stringValue(
      suggestion['action_kind'],
      ValueReaders.stringValue(suggestion['rewrite_scope']),
    );
    if (explicitActionKind.trim().isNotEmpty) {
      return ChapterRewriteActionKind.normalize(explicitActionKind);
    }
    if (targetSegments.isNotEmpty) {
      return ChapterRewriteActionKind.rewritePartial;
    }
    if (outputPaths.isNotEmpty) {
      return ChapterRewriteActionKind.rewriteFull;
    }
    return ChapterRewriteActionKind.suggestionsOnly;
  }

  String _suggestionId(
    JsonMap suggestion,
    String suggestionIdPrefix,
    int index,
  ) {
    final explicitId = ValueReaders.stringValue(suggestion['id']).trim();
    if (explicitId.isNotEmpty) {
      return explicitId;
    }
    return '${suggestionIdPrefix}_${index + 1}';
  }
}
