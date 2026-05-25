import 'chapter_analysis_issue.dart';
import 'chapter_analysis_result.dart';
import 'chapter_analysis_suggestion.dart';
import 'chapter_analysis_target_segment.dart';
import 'chapter_rewrite_action_kind.dart';
import 'chapter_rewrite_plan.dart';

class ChapterRewritePlanBuilderService {
  const ChapterRewritePlanBuilderService();

  ChapterRewritePlan buildFullChapterPlan(
    ChapterAnalysisResult result, {
    String generatedId = '',
    String createdAt = '',
    List<String> selectedIssueIds = const <String>[],
    List<String> selectedSuggestionIds = const <String>[],
  }) {
    return _buildPlan(
      result,
      actionKind: ChapterRewriteActionKind.rewriteFull,
      generatedId: generatedId,
      createdAt: createdAt,
      selectedIssueIds: selectedIssueIds,
      selectedSuggestionIds: selectedSuggestionIds,
      targetSegments: const <ChapterAnalysisTargetSegment>[],
    );
  }

  ChapterRewritePlan buildPartialRewritePlan(
    ChapterAnalysisResult result, {
    required List<ChapterAnalysisTargetSegment> targetSegments,
    String generatedId = '',
    String createdAt = '',
    List<String> selectedIssueIds = const <String>[],
    List<String> selectedSuggestionIds = const <String>[],
  }) {
    return _buildPlan(
      result,
      actionKind: ChapterRewriteActionKind.rewritePartial,
      generatedId: generatedId,
      createdAt: createdAt,
      selectedIssueIds: selectedIssueIds,
      selectedSuggestionIds: selectedSuggestionIds,
      targetSegments: targetSegments,
    );
  }

  ChapterRewritePlan buildSuggestionsOnlyPlan(
    ChapterAnalysisResult result, {
    String generatedId = '',
    String createdAt = '',
    List<String> selectedIssueIds = const <String>[],
    List<String> selectedSuggestionIds = const <String>[],
  }) {
    return _buildPlan(
      result,
      actionKind: ChapterRewriteActionKind.suggestionsOnly,
      generatedId: generatedId,
      createdAt: createdAt,
      selectedIssueIds: selectedIssueIds,
      selectedSuggestionIds: selectedSuggestionIds,
      targetSegments: const <ChapterAnalysisTargetSegment>[],
    );
  }

  ChapterRewritePlan _buildPlan(
    ChapterAnalysisResult result, {
    required String actionKind,
    required String generatedId,
    required String createdAt,
    required List<String> selectedIssueIds,
    required List<String> selectedSuggestionIds,
    required List<ChapterAnalysisTargetSegment> targetSegments,
  }) {
    // 中文注释: 重写计划只表达“怎么执行”，不替代任务本身；这样整章、局部、只建议三条路径才能共用同一入口。
    final issues = _selectedIssues(result.issues, selectedIssueIds);
    final suggestions = _selectedSuggestions(
      result.suggestions,
      selectedSuggestionIds,
    );
    final planId = generatedId.trim().isEmpty
        ? 'rewrite_plan_${result.id}'
        : generatedId.trim();
    final effectiveTargetSegments =
        actionKind == ChapterRewriteActionKind.rewritePartial
        ? _mergeTargetSegments(targetSegments, suggestions)
        : const <ChapterAnalysisTargetSegment>[];
    final outputPaths = actionKind == ChapterRewriteActionKind.suggestionsOnly
        ? const <String>[]
        : _outputPaths(
            result,
            suggestions,
            targetSegments: effectiveTargetSegments,
          );
    return ChapterRewritePlan(
      id: planId,
      analysisResultId: result.id,
      actionKind: actionKind,
      title: _title(result, actionKind: actionKind),
      chapterPath: result.chapterPath,
      summary: _summary(result, issues: issues, suggestions: suggestions),
      instructions: _instructions(
        result,
        actionKind: actionKind,
        issues: issues,
        suggestions: suggestions,
        targetSegments: effectiveTargetSegments,
      ),
      sourcePaths: _sourcePaths(result, suggestions),
      outputPaths: outputPaths,
      issueIds: issues.map((item) => item.id).toList(growable: false),
      suggestionIds: suggestions.map((item) => item.id).toList(growable: false),
      targetSegments: effectiveTargetSegments,
      preserveNotes: _preserveNotes(result, actionKind: actionKind),
      createdAt: createdAt.trim(),
      metadata: <String, Object?>{
        'analysis_type': result.analysisType,
        'issue_count': issues.length,
        'suggestion_count': suggestions.length,
      },
    );
  }

  List<ChapterAnalysisIssue> _selectedIssues(
    List<ChapterAnalysisIssue> issues,
    List<String> selectedIssueIds,
  ) {
    if (selectedIssueIds.isEmpty) {
      return issues;
    }
    return issues
        .where((issue) => selectedIssueIds.contains(issue.id))
        .toList(growable: false);
  }

  List<ChapterAnalysisSuggestion> _selectedSuggestions(
    List<ChapterAnalysisSuggestion> suggestions,
    List<String> selectedSuggestionIds,
  ) {
    if (selectedSuggestionIds.isEmpty) {
      return suggestions;
    }
    return suggestions
        .where((suggestion) => selectedSuggestionIds.contains(suggestion.id))
        .toList(growable: false);
  }

  List<ChapterAnalysisTargetSegment> _mergeTargetSegments(
    List<ChapterAnalysisTargetSegment> targetSegments,
    List<ChapterAnalysisSuggestion> suggestions,
  ) {
    final result = <ChapterAnalysisTargetSegment>[...targetSegments];
    for (final suggestion in suggestions) {
      for (final segment in suggestion.targetSegments) {
        if (!result.any((item) => item.id == segment.id)) {
          result.add(segment);
        }
      }
    }
    return result;
  }

  List<String> _sourcePaths(
    ChapterAnalysisResult result,
    List<ChapterAnalysisSuggestion> suggestions,
  ) {
    final resultPaths = <String>[...result.sourcePaths];
    for (final suggestion in suggestions) {
      for (final path in suggestion.sourcePaths) {
        if (path.trim().isNotEmpty && !resultPaths.contains(path)) {
          resultPaths.add(path);
        }
      }
    }
    return resultPaths;
  }

  List<String> _outputPaths(
    ChapterAnalysisResult result,
    List<ChapterAnalysisSuggestion> suggestions, {
    required List<ChapterAnalysisTargetSegment> targetSegments,
  }) {
    final resultPaths = <String>[];
    for (final path in result.sourcePaths) {
      if (path.trim().isNotEmpty && !resultPaths.contains(path)) {
        resultPaths.add(path);
      }
    }
    for (final suggestion in suggestions) {
      for (final path in suggestion.outputPaths) {
        if (path.trim().isNotEmpty && !resultPaths.contains(path)) {
          resultPaths.add(path);
        }
      }
    }
    for (final segment in targetSegments) {
      if (segment.sourcePath.trim().isNotEmpty &&
          !resultPaths.contains(segment.sourcePath)) {
        resultPaths.add(segment.sourcePath);
      }
    }
    return resultPaths;
  }

  String _title(ChapterAnalysisResult result, {required String actionKind}) {
    switch (actionKind) {
      case ChapterRewriteActionKind.rewriteFull:
        return '整章重写：${result.title}';
      case ChapterRewriteActionKind.rewritePartial:
        return '局部重写：${result.title}';
      default:
        return '仅输出建议：${result.title}';
    }
  }

  String _summary(
    ChapterAnalysisResult result, {
    required List<ChapterAnalysisIssue> issues,
    required List<ChapterAnalysisSuggestion> suggestions,
  }) {
    final issueCount = issues.length;
    final suggestionCount = suggestions.length;
    return '${result.title}｜问题数：$issueCount｜建议数：$suggestionCount';
  }

  String _instructions(
    ChapterAnalysisResult result, {
    required String actionKind,
    required List<ChapterAnalysisIssue> issues,
    required List<ChapterAnalysisSuggestion> suggestions,
    required List<ChapterAnalysisTargetSegment> targetSegments,
  }) {
    final lines = <String>[];
    switch (actionKind) {
      case ChapterRewriteActionKind.rewriteFull:
        lines.add('基于章节分析结果，对整章进行重写，保留原章节意图、世界规则与角色连续性。');
        break;
      case ChapterRewriteActionKind.rewritePartial:
        lines.add('基于章节分析结果，只重写指定片段，未命中的段落保持原意与结构稳定。');
        break;
      default:
        lines.add('当前阶段只整理建议，不直接执行重写。');
        break;
    }
    if (result.summary.trim().isNotEmpty) {
      lines.add('分析总结：${result.summary.trim()}');
    }
    if (result.overallAssessment.trim().isNotEmpty) {
      lines.add('整体判断：${result.overallAssessment.trim()}');
    }
    if (issues.isNotEmpty) {
      lines.add('优先处理问题：');
      for (final issue in issues.take(6)) {
        final detail = issue.suggestion.trim().isEmpty
            ? issue.summary
            : issue.suggestion;
        lines.add('- ${issue.title}${detail.trim().isEmpty ? '' : '：$detail'}');
      }
    }
    if (suggestions.isNotEmpty) {
      lines.add('建议动作：');
      for (final suggestion in suggestions.take(6)) {
        final detail = suggestion.summary.trim();
        lines.add('- ${suggestion.title}${detail.isEmpty ? '' : '：$detail'}');
      }
    }
    if (targetSegments.isNotEmpty) {
      lines.add('目标片段：');
      for (final segment in targetSegments) {
        final rangeText =
            segment.startLine > 0 && segment.endLine >= segment.startLine
            ? '（第 ${segment.startLine}-${segment.endLine} 行）'
            : '';
        lines.add(
          '- ${segment.label.trim().isEmpty ? segment.sourcePath : segment.label}$rangeText',
        );
      }
    }
    return lines.join('\n');
  }

  List<String> _preserveNotes(
    ChapterAnalysisResult result, {
    required String actionKind,
  }) {
    final notes = <String>['保持项目既定风格，不把修复写成另一种声音。', '保持角色动机、关系和世界规则连续。'];
    if (actionKind == ChapterRewriteActionKind.rewritePartial) {
      notes.add('未命中的片段不要无意义改写。');
    }
    if (result.relatedPaths.isNotEmpty) {
      notes.add('必要时参考关联资料：${result.relatedPaths.join('、')}');
    }
    return notes;
  }
}
