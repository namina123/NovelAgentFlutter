import '../common/json_types.dart';
import '../workflow/task_runtime_constants.dart';
import 'chapter_analysis_result.dart';
import 'chapter_analysis_suggestion.dart';
import 'chapter_rewrite_action_kind.dart';
import 'chapter_rewrite_plan.dart';
import 'review_path_policy_service.dart';

class ChapterRewriteTaskFactoryService {
  ChapterRewriteTaskFactoryService({
    ReviewPathPolicyService? reviewPathPolicyService,
  }) : _reviewPathPolicyService =
           reviewPathPolicyService ?? ReviewPathPolicyService();

  final ReviewPathPolicyService _reviewPathPolicyService;

  JsonMap? revisionTaskFromPlan(
    ChapterRewritePlan plan, {
    String analysisPath = '',
  }) {
    // 中文注释: 只建议型计划不直接落成 revision 任务；真正要改文时，再通过整章或局部计划进入任务链。
    if (plan.actionKind == ChapterRewriteActionKind.suggestionsOnly) {
      return null;
    }
    final outputPaths = _editableOutputPaths(plan.outputPaths);
    if (outputPaths.isEmpty) {
      return null;
    }
    final sourcePaths = _mergePaths(
      plan.sourcePaths,
      analysisPath: analysisPath,
    );
    final goal = _goalFromPlan(plan);
    return <String, Object?>{
      'title': plan.title,
      'task_type': 'revision',
      'chapter': plan.chapterPath.isEmpty
          ? outputPaths.first
          : plan.chapterPath,
      'goal': goal,
      'brief': _briefFromPlan(plan),
      'mode': TaskRuntimeConstants.modeSingleChapterAtomic,
      'source_paths': sourcePaths,
      'output_paths': outputPaths,
      'metadata': <String, Object?>{
        'origin': 'chapter_analysis_rewrite_plan',
        'rewrite_plan_id': plan.id,
        'analysis_result_id': plan.analysisResultId,
        'rewrite_action_kind': plan.actionKind,
        'issue_ids': plan.issueIds,
        'suggestion_ids': plan.suggestionIds,
        'target_segments': plan.targetSegments
            .map(
              (segment) => <String, Object?>{
                'id': segment.id,
                'source_path': segment.sourcePath,
                'label': segment.label,
                'start_line': segment.startLine,
                'end_line': segment.endLine,
                'summary': segment.summary,
              },
            )
            .toList(growable: false),
        'created_at': plan.createdAt,
      },
      'tool_hint': _toolHint(plan),
    };
  }

  JsonMap? revisionTaskFromSuggestions(
    ChapterAnalysisResult result,
    List<ChapterAnalysisSuggestion> suggestions, {
    String analysisPath = '',
  }) {
    // 中文注释: 这里把“建议”直接转成可执行任务，补上分析页到任务中心的共享闭环。
    if (suggestions.isEmpty) {
      return null;
    }
    final outputPaths = _editableOutputPaths(
      _suggestionOutputPaths(result, suggestions),
    );
    if (outputPaths.isEmpty) {
      return null;
    }
    final sourcePaths = _mergePaths(
      _suggestionSourcePaths(result, suggestions),
      analysisPath: analysisPath,
    );
    final isPartial = suggestions.any((item) => item.targetSegments.isNotEmpty);
    final lines = <String>[
      isPartial ? '根据所选分析建议，对指定片段执行定向修订。' : '根据所选分析建议，对当前章节执行修订。',
      '优先落实以下建议：',
    ];
    for (final suggestion in suggestions.take(8)) {
      final detail = suggestion.summary.trim();
      lines.add('- ${suggestion.title}${detail.isEmpty ? '' : '：$detail'}');
    }
    return <String, Object?>{
      'title': '${isPartial ? '建议转局部修订' : '建议转修订'}：${result.title}',
      'task_type': 'revision',
      'chapter': result.chapterPath.isEmpty
          ? outputPaths.first
          : result.chapterPath,
      'goal': lines.join('\n'),
      'brief': '${result.title}｜从分析建议直接转任务｜建议数：${suggestions.length}',
      'mode': TaskRuntimeConstants.modeSingleChapterAtomic,
      'source_paths': sourcePaths,
      'output_paths': outputPaths,
      'metadata': <String, Object?>{
        'origin': 'chapter_analysis_suggestions',
        'analysis_result_id': result.id,
        'analysis_type': result.analysisType,
        'suggestion_ids': suggestions
            .map((item) => item.id)
            .toList(growable: false),
        'issue_ids': suggestions
            .expand((item) => item.issueIds)
            .where((item) => item.trim().isNotEmpty)
            .toSet()
            .toList(growable: false),
      },
      'tool_hint': isPartial
          ? '先读取分析结果与目标片段，再对命中范围做精确修改；不要把未命中的段落一起重写。'
          : '先读取分析结果和章节原文，再按建议完成修订；修订时保持既定风格、角色和世界规则稳定。',
    };
  }

  List<String> _editableOutputPaths(List<String> rawPaths) {
    final result = <String>[];
    for (final rawPath in rawPaths) {
      final path = rawPath.trim().replaceAll('\\', '/');
      if (_reviewPathPolicyService.isEditableProjectPath(path) &&
          !result.contains(path)) {
        result.add(path);
      }
    }
    return result;
  }

  List<String> _mergePaths(
    List<String> rawPaths, {
    required String analysisPath,
  }) {
    final result = <String>[];
    for (final rawPath in rawPaths) {
      final clean = rawPath.trim().replaceAll('\\', '/');
      if (clean.isNotEmpty && !result.contains(clean)) {
        result.add(clean);
      }
    }
    final cleanAnalysisPath = analysisPath.trim().replaceAll('\\', '/');
    if (cleanAnalysisPath.isNotEmpty && !result.contains(cleanAnalysisPath)) {
      result.add(cleanAnalysisPath);
    }
    return result;
  }

  String _goalFromPlan(ChapterRewritePlan plan) {
    final lines = <String>[plan.instructions];
    if (plan.preserveNotes.isNotEmpty) {
      lines.add('执行约束：${plan.preserveNotes.join('；')}');
    }
    return lines.join('\n');
  }

  String _briefFromPlan(ChapterRewritePlan plan) {
    final actionLabel =
        plan.actionKind == ChapterRewriteActionKind.rewritePartial
        ? '局部重写'
        : '整章重写';
    return '$actionLabel｜问题数：${plan.issueIds.length}｜建议数：${plan.suggestionIds.length}';
  }

  String _toolHint(ChapterRewritePlan plan) {
    if (plan.actionKind == ChapterRewriteActionKind.rewritePartial) {
      return '先读取计划、分析结果和目标片段，只改命中范围；必要时按行精确替换，并保留前后文连续性。';
    }
    return '先读取计划、分析结果和章节原文，再完成整章修订；必要时先备份，再覆盖输出目标。';
  }

  List<String> _suggestionSourcePaths(
    ChapterAnalysisResult result,
    List<ChapterAnalysisSuggestion> suggestions,
  ) {
    final resultPaths = <String>[...result.sourcePaths];
    for (final suggestion in suggestions) {
      for (final path in suggestion.sourcePaths) {
        final clean = path.trim();
        if (clean.isNotEmpty && !resultPaths.contains(clean)) {
          resultPaths.add(clean);
        }
      }
    }
    return resultPaths;
  }

  List<String> _suggestionOutputPaths(
    ChapterAnalysisResult result,
    List<ChapterAnalysisSuggestion> suggestions,
  ) {
    final resultPaths = <String>[...result.sourcePaths];
    for (final suggestion in suggestions) {
      for (final path in <String>[
        ...suggestion.outputPaths,
        ...suggestion.targetSegments.map((item) => item.sourcePath),
      ]) {
        final clean = path.trim();
        if (clean.isNotEmpty && !resultPaths.contains(clean)) {
          resultPaths.add(clean);
        }
      }
    }
    return resultPaths;
  }
}
