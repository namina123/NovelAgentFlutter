import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'review_path_policy_service.dart';
import 'review_report_normalizer_service.dart';
import 'review_type_catalog_service.dart';

class ReviewTaskFactoryService {
  ReviewTaskFactoryService({
    ReviewReportNormalizerService? normalizerService,
    ReviewPathPolicyService? pathPolicyService,
    ReviewTypeCatalogService? typeCatalogService,
  }) : _normalizerService =
           normalizerService ?? ReviewReportNormalizerService(),
       _pathPolicyService = pathPolicyService ?? ReviewPathPolicyService(),
       _typeCatalogService = typeCatalogService ?? ReviewTypeCatalogService();

  final ReviewReportNormalizerService _normalizerService;
  final ReviewPathPolicyService _pathPolicyService;
  final ReviewTypeCatalogService _typeCatalogService;

  JsonMap repairTaskFromReport(JsonMap report, {String reportPath = ''}) {
    // 中文注释: 这里把审稿报告转换成 revision 任务参数，不直接写文件，让宿主决定何时执行。
    final normalized = _normalizerService.normalizeReport(report);
    final editPaths = _pathPolicyService.editableSourcePaths(normalized);
    final contextPaths = _pathPolicyService.mergeStringArrays(
      editPaths,
      _pathPolicyService.reviewReferencePaths(normalized, reportPath),
    );
    return <String, Object?>{
      'title':
          '修复审稿问题：${ValueReaders.stringValue(normalized['title'], '审稿报告')}',
      'task_type': 'revision',
      'chapter': ValueReaders.stringValue(normalized['scope']),
      'goal': _repairGoal(normalized),
      'brief': _repairBrief(normalized),
      'mode': 'single_chapter_atomic',
      'source_paths': contextPaths,
      'output_paths': editPaths,
      'metadata': <String, Object?>{
        'origin': 'review_report',
        'review_report_path': reportPath.trim(),
        'review_type': ValueReaders.stringValue(normalized['review_type']),
        'review_id': ValueReaders.stringValue(normalized['id']),
        'issue_count': ValueReaders.objectList(normalized['issues']).length,
      },
      'tool_hint': '先读取审稿报告和来源文件，按问题逐条修订；覆盖或精确替换前创建备份，修订后保存新的检查报告。',
    };
  }

  JsonMap reviewTaskFromSource(JsonMap arguments) {
    // 中文注释: 一键审稿任务只创建任务骨架，不替宿主直接发起模型调用。
    final sourcePath = ValueReaders.stringValue(
      arguments['source_path'],
      ValueReaders.stringValue(arguments['relative_path']),
    ).trim().replaceAll('\\', '/');
    final reviewType = _typeCatalogService.normalizeReviewType(
      ValueReaders.stringValue(arguments['review_type']),
    );
    var title = ValueReaders.stringValue(arguments['title']).trim();
    if (title.isEmpty) {
      final fileName = sourcePath.split('/').last;
      final baseName = fileName.endsWith('.md') || fileName.endsWith('.json')
          ? fileName.substring(0, fileName.lastIndexOf('.'))
          : fileName;
      title = '${_typeCatalogService.reviewTypeLabel(reviewType)}：$baseName';
    }
    return <String, Object?>{
      'title': title,
      'task_type': 'review',
      'chapter': sourcePath,
      'goal': _typeCatalogService.reviewGoal(reviewType),
      'brief':
          '读取来源文件并保存${_typeCatalogService.reviewTypeLabel(reviewType)}报告；不要修改原文。',
      'mode': 'single_chapter_atomic',
      'source_paths': <String>[sourcePath],
      'output_paths': <Object?>[],
      'metadata': <String, Object?>{
        'origin': 'one_click_review',
        'review_type': reviewType,
        'source_path': sourcePath,
      },
      'tool_hint':
          '先 read_project_file 读取来源，再调用 run_continuity_check 保存审稿报告到 reviews/。',
    };
  }

  String _repairGoal(JsonMap report) {
    // 中文注释: 修复目标把总结、问题和建议压成执行说明，供 revision 任务直接复用。
    final lines = <String>['根据审稿报告修复原文问题，保持原章节意图、设定连续性和用户既定风格。'];
    final summary = ValueReaders.stringValue(report['summary']).trim();
    if (summary.isNotEmpty) {
      lines.add('报告总结：$summary');
    }
    final issues = ValueReaders.mapList(report['issues']);
    if (issues.isNotEmpty) {
      lines.add('优先修复问题：');
      for (final issue in issues.take(8)) {
        var line = '- ${ValueReaders.stringValue(issue['title'], '问题').trim()}';
        final suggestion = ValueReaders.stringValue(issue['suggestion']).trim();
        if (suggestion.isNotEmpty) {
          line += '；建议：$suggestion';
        }
        lines.add(line);
      }
    }
    final suggestions = ValueReaders.stringList(report['suggestions']);
    if (suggestions.isNotEmpty) {
      lines.add('综合建议：${suggestions.join('；')}');
    }
    return lines.join('\n');
  }

  String _repairBrief(JsonMap report) {
    // 中文注释: 列表短说明要让用户立刻知道这份修复任务来自什么报告、问题有多少。
    return '${_typeCatalogService.reviewTypeLabel(ValueReaders.stringValue(report['review_type']))}'
        '｜范围：${ValueReaders.stringValue(report['scope'], '当前范围')}'
        '｜问题数：${ValueReaders.objectList(report['issues']).length}'
        '。修复时优先读取报告与来源文件，必要时创建备份。';
  }
}
