import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_json_document_service.dart';
import 'project_task_repository.dart';

class ProjectReviewReportService {
  ProjectReviewReportService({
    required ProjectWorkspacePort workspacePort,
    required ProjectTaskRepository taskRepository,
    ProjectJsonDocumentService? jsonDocumentService,
    ReviewReportNormalizerService? reportNormalizerService,
    ReviewReportSummaryService? summaryService,
    ReviewTaskFactoryService? taskFactoryService,
    ReviewTypeCatalogService? reviewTypeCatalogService,
    ReviewPathPolicyService? pathPolicyService,
  }) : _workspacePort = workspacePort,
       _taskRepository = taskRepository,
       _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(workspacePort: workspacePort),
       _reportNormalizerService =
           reportNormalizerService ?? ReviewReportNormalizerService(),
       _summaryService = summaryService ?? ReviewReportSummaryService(),
       _taskFactoryService = taskFactoryService ?? ReviewTaskFactoryService(),
       _reviewTypeCatalogService =
           reviewTypeCatalogService ?? ReviewTypeCatalogService(),
       _pathPolicyService = pathPolicyService ?? ReviewPathPolicyService();

  final ProjectWorkspacePort _workspacePort;
  final ProjectTaskRepository _taskRepository;
  final ProjectJsonDocumentService _jsonDocumentService;
  final ReviewReportNormalizerService _reportNormalizerService;
  final ReviewReportSummaryService _summaryService;
  final ReviewTaskFactoryService _taskFactoryService;
  final ReviewTypeCatalogService _reviewTypeCatalogService;
  final ReviewPathPolicyService _pathPolicyService;

  List<JsonMap> listReviewTypeDefs() {
    // 中文注释: 审稿类型定义直接复用 core 目录，保证 GUI/CLI 展示口径一致。
    return _reviewTypeCatalogService.reviewTypeDefs();
  }

  Future<List<JsonMap>> listReports(
    ProjectDescriptor project, {
    JsonMap filters = const <String, Object?>{},
    int limit = 20,
  }) async {
    // 中文注释: 报告列表优先读取 reviews/ 下的结构化 JSON，没有 JSON 也兼容只落 Markdown 的旧产物。
    final entries = await _workspacePort.listEntries(project.rootPath);
    final result = <JsonMap>[];
    final seenMarkdownPaths = <String>{};
    for (final entry in entries) {
      final relativePath = ValueReaders.stringValue(entry['relative_path']);
      final isDir = ValueReaders.boolValue(entry['is_dir']);
      if (isDir || !relativePath.startsWith('reviews/')) {
        continue;
      }
      if (relativePath.toLowerCase().endsWith('.json')) {
        final report = await _jsonDocumentService.readJsonMap(
          project.rootPath,
          relativePath,
        );
        if (report.isEmpty) {
          continue;
        }
        final normalized = _reportNormalizerService.normalizeReport(report)
          ..['json_path'] = relativePath
          ..['markdown_path'] = _markdownPathFor(relativePath);
        if (!_matchesFilters(normalized, filters)) {
          continue;
        }
        result.add(_summaryFromReport(normalized));
        seenMarkdownPaths.add(_markdownPathFor(relativePath));
        continue;
      }
      if (relativePath.toLowerCase().endsWith('.md')) {
        if (seenMarkdownPaths.contains(relativePath)) {
          continue;
        }
        final content = await _workspacePort.readTextFile(
          project.rootPath,
          relativePath,
        );
        if (content == null || content.trim().isEmpty) {
          continue;
        }
        final summary = _summaryFromMarkdown(relativePath, content);
        if (!_matchesFilters(summary, filters)) {
          continue;
        }
        result.add(summary);
      }
    }
    result.sort((left, right) {
      final leftUpdated = ValueReaders.stringValue(
        left['updated_at'],
        ValueReaders.stringValue(left['created_at']),
      );
      final rightUpdated = ValueReaders.stringValue(
        right['updated_at'],
        ValueReaders.stringValue(right['created_at']),
      );
      return rightUpdated.compareTo(leftUpdated);
    });
    if (result.length <= limit) {
      return result;
    }
    return result.take(limit).toList(growable: false);
  }

  Future<JsonMap> loadReport(
    ProjectDescriptor project,
    String markdownOrJsonPath,
  ) async {
    // 中文注释: 读取详情时优先拿 JSON 正文；如果只有 Markdown，也返回可直接展示的正文内容。
    final cleanPath = markdownOrJsonPath.trim().replaceAll('\\', '/');
    final jsonPath = cleanPath.toLowerCase().endsWith('.json')
        ? _pathPolicyService.reviewJsonPath(cleanPath)
        : _pathPolicyService.reviewJsonPath(cleanPath);
    if (jsonPath.isNotEmpty) {
      final report = await _jsonDocumentService.readJsonMap(
        project.rootPath,
        jsonPath,
      );
      if (report.isNotEmpty) {
        final normalized = _reportNormalizerService.normalizeReport(report);
        final markdownPath = _markdownPathFor(jsonPath);
        final markdownBody =
            await _workspacePort.readTextFile(project.rootPath, markdownPath) ??
            '';
        return <String, Object?>{
          'ok': true,
          'report': normalized,
          'json_path': jsonPath,
          'markdown_path': markdownPath,
          'markdown_body': markdownBody,
        };
      }
    }
    final markdownPath = cleanPath.toLowerCase().endsWith('.md') ? cleanPath : '';
    if (markdownPath.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Review report not found.',
        'report': <String, Object?>{},
      };
    }
    final markdownBody = await _workspacePort.readTextFile(
      project.rootPath,
      markdownPath,
    );
    if (markdownBody == null || markdownBody.trim().isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Review report not found.',
        'report': <String, Object?>{},
      };
    }
    final synthetic = _syntheticReportFromMarkdown(markdownPath, markdownBody);
    return <String, Object?>{
      'ok': true,
      'report': synthetic,
      'json_path': '',
      'markdown_path': markdownPath,
      'markdown_body': markdownBody,
    };
  }

  Future<JsonMap> createReviewRepairTask(
    ProjectDescriptor project,
    String markdownOrJsonPath,
  ) async {
    // 中文注释: 审稿修复任务创建保持只写任务文件，不在这里直接触发模型执行。
    final loaded = await loadReport(project, markdownOrJsonPath);
    if (!ValueReaders.boolValue(loaded['ok'])) {
      return <String, Object?>{
        'ok': false,
        'error': ValueReaders.stringValue(
          loaded['error'],
          'Review report not found.',
        ),
      };
    }
    final task = _taskFactoryService.repairTaskFromReport(
      ValueReaders.mapValue(loaded['report']),
      reportPath: ValueReaders.stringValue(loaded['markdown_path']),
    );
    final saved = await _taskRepository.saveTask(project, task);
    return <String, Object?>{
      'ok': true,
      'relative_path': ValueReaders.stringValue(saved['relative_path']),
      'task': saved,
      'review_report_path': ValueReaders.stringValue(loaded['markdown_path']),
      'task_arguments': task,
    };
  }

  Future<JsonMap> createReviewTask(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 一键审稿任务只把规则层给出的任务骨架落盘，后续执行仍交给任务中心。
    final task = _taskFactoryService.reviewTaskFromSource(arguments);
    final saved = await _taskRepository.saveTask(project, task);
    return <String, Object?>{
      'ok': true,
      'relative_path': ValueReaders.stringValue(saved['relative_path']),
      'task': saved,
      'task_arguments': task,
    };
  }

  JsonMap _summaryFromReport(JsonMap report) {
    // 中文注释: JSON 报告摘要统一经 core 服务生成，再补上项目内路径定位。
    final summary = _summaryService.reportSummary(report);
    return <String, Object?>{
      ...summary,
      'markdown_path': ValueReaders.stringValue(report['markdown_path']),
      'json_path': ValueReaders.stringValue(report['json_path']),
      'relative_path': ValueReaders.stringValue(
        report['markdown_path'],
        ValueReaders.stringValue(report['json_path']),
      ),
      'scope': ValueReaders.stringValue(report['scope']),
      'source_paths': ValueReaders.stringList(report['source_paths']),
      'updated_at': ValueReaders.stringValue(
        report['updated_at'],
        ValueReaders.stringValue(report['created_at']),
      ),
      'created_at': ValueReaders.stringValue(report['created_at']),
    };
  }

  JsonMap _summaryFromMarkdown(String relativePath, String body) {
    // 中文注释: Markdown 摘要提供旧产物兜底展示，至少让报告浏览、筛选和打开都可用。
    final title = _extractMarkdownTitle(relativePath, body);
    final reviewType = _reviewTypeFromPath(relativePath);
    return <String, Object?>{
      'id': _safeIdFromPath(relativePath),
      'title': title,
      'summary': _previewText(body),
      'review_type': reviewType,
      'review_type_label': _reviewTypeCatalogService.reviewTypeLabel(reviewType),
      'issue_count': _markdownIssueCount(body),
      'scope': _extractMarkdownBullet(body, '范围'),
      'markdown_path': relativePath,
      'json_path': '',
      'relative_path': relativePath,
      'updated_at': '',
      'created_at': '',
    };
  }

  JsonMap _syntheticReportFromMarkdown(String relativePath, String body) {
    // 中文注释: 没有 JSON 的旧报告仍然转成最小结构化对象，便于修复任务和详情面板统一消费。
    final reviewType = _reviewTypeFromPath(relativePath);
    return <String, Object?>{
      'id': _safeIdFromPath(relativePath),
      'title': _extractMarkdownTitle(relativePath, body),
      'review_type': reviewType,
      'scope': _extractMarkdownBullet(body, '范围'),
      'summary': _previewText(body),
      'issues': <Object?>[],
      'source_paths': ValueReaders.stringList(
        _extractMarkdownBullet(body, '关联文件').split('、'),
      ),
      'suggestions': <Object?>[],
      'markdown_path': relativePath,
    };
  }

  bool _matchesFilters(JsonMap summary, JsonMap filters) {
    // 中文注释: 报告筛选只覆盖旧项目已有的类型、范围和来源路径，避免 GUI/CLI 各自复制规则。
    final reviewType = ValueReaders.stringValue(filters['review_type']).trim();
    if (reviewType.isNotEmpty &&
        ValueReaders.stringValue(summary['review_type']) != reviewType) {
      return false;
    }
    final scope = ValueReaders.stringValue(filters['scope']).trim();
    if (scope.isNotEmpty) {
      final summaryScope = ValueReaders.stringValue(summary['scope']);
      if (!summaryScope.contains(scope)) {
        return false;
      }
    }
    final sourcePath = ValueReaders.stringValue(
      filters['source_path'],
      ValueReaders.stringValue(filters['relative_path']),
    ).trim();
    if (sourcePath.isNotEmpty) {
      final sources = ValueReaders.stringList(summary['source_paths']).join(' ');
      final markdownPath = ValueReaders.stringValue(summary['markdown_path']);
      if (!sources.contains(sourcePath) && !markdownPath.contains(sourcePath)) {
        return false;
      }
    }
    return true;
  }

  String _markdownPathFor(String jsonPath) {
    // 中文注释: JSON 报告与 Markdown 报告保持同名兄弟文件，路径转换集中在这里。
    if (!jsonPath.toLowerCase().endsWith('.json')) {
      return jsonPath;
    }
    return '${jsonPath.substring(0, jsonPath.length - 5)}md';
  }

  String _extractMarkdownTitle(String relativePath, String body) {
    // 中文注释: Markdown 标题优先取一级标题，没有则回退文件名。
    for (final line in body.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('# ')) {
        return trimmed.substring(2).trim();
      }
    }
    return relativePath.split('/').last;
  }

  String _reviewTypeFromPath(String relativePath) {
    // 中文注释: reviews/<type>/... 的目录结构直接决定审稿类型。
    final segments = relativePath.split('/');
    if (segments.length >= 2) {
      return _reviewTypeCatalogService.normalizeReviewType(segments[1]);
    }
    return ReviewTypeConstants.general;
  }

  int _markdownIssueCount(String body) {
    // 中文注释: 旧 Markdown 报告没有结构化问题数组时，用列表项数量给一个近似值。
    var count = 0;
    for (final line in body.split('\n')) {
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('- ') && trimmed.contains('（')) {
        count += 1;
      }
    }
    return count;
  }

  String _extractMarkdownBullet(String body, String label) {
    // 中文注释: 报告头部常见的 “- 范围：” 一类字段在这里统一提取。
    for (final line in body.split('\n')) {
      final trimmed = line.trim();
      final prefix = '- $label：';
      if (trimmed.startsWith(prefix)) {
        return trimmed.substring(prefix.length).trim();
      }
    }
    return '';
  }

  String _previewText(String body) {
    // 中文注释: 摘要只保留可扫读前几句，避免列表页一次塞整份报告。
    final clean = body
        .replaceAll(RegExp(r'[#>*`-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.length <= 160) {
      return clean;
    }
    return '${clean.substring(0, 160)}...';
  }

  String _safeIdFromPath(String path) {
    // 中文注释: 报告路径到 id 的映射只用于浏览场景，不影响真实项目文件名。
    return path.replaceAll('/', '__').replaceAll('.', '_');
  }
}
