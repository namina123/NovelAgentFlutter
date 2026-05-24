import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../workbench/presentation/models/resource_entry_view_data.dart';
import '../models/project_collection_snapshot.dart';

typedef ProjectFileReader =
    Future<String?> Function(ProjectDescriptor project, String relativePath);

class ProjectCollectionLoaderService {
  ProjectCollectionLoaderService({
    ReviewReportSummaryService? reviewReportSummaryService,
    PromptTemplateNormalizerService? promptTemplateNormalizerService,
  }) : _reviewReportSummaryService =
           reviewReportSummaryService ?? ReviewReportSummaryService(),
       _promptTemplateNormalizerService =
           promptTemplateNormalizerService ?? PromptTemplateNormalizerService();

  final ReviewReportSummaryService _reviewReportSummaryService;
  final PromptTemplateNormalizerService _promptTemplateNormalizerService;

  Future<ProjectCollectionSnapshot> load({
    required String kind,
    required ProjectDescriptor project,
    required List<ResourceEntryViewData> resourceEntries,
    required ProjectFileReader readFile,
    String selectedEntryId = '',
  }) async {
    // 中文注释: 项目集合加载服务只负责把 tasks/reviews/prompts 目录中的真实文件摘要成统一页面快照。
    final descriptor = _descriptorFor(kind);
    final entries = <JsonMap>[];
    for (final resourceEntry in resourceEntries) {
      if (resourceEntry.isDirectory || !_matchesKind(kind, resourceEntry.id)) {
        continue;
      }
      final content = await readFile(project, resourceEntry.id);
      entries.add(
        _summaryFor(
          kind,
          relativePath: resourceEntry.id,
          content: content ?? '',
        ),
      );
    }
    final resolvedSelectedEntryId = _resolvedSelectedEntryId(
      selectedEntryId,
      entries,
    );
    return ProjectCollectionSnapshot(
      kind: kind,
      title: descriptor['title'] as String,
      description: descriptor['description'] as String,
      entries: entries,
      selectedEntryId: resolvedSelectedEntryId,
    );
  }

  JsonMap _summaryFor(
    String kind, {
    required String relativePath,
    required String content,
  }) {
    switch (kind) {
      case 'reviews':
        return _reviewSummary(relativePath: relativePath, content: content);
      case 'templates':
        return _templateSummary(relativePath: relativePath, content: content);
      case 'tasks':
      default:
        return _taskSummary(relativePath: relativePath, content: content);
    }
  }

  JsonMap _taskSummary({
    required String relativePath,
    required String content,
  }) {
    // 中文注释: 任务摘要优先读取 JSON 字段，没有结构化内容时退回到文件名和原始片段。
    JsonMap task = const <String, Object?>{};
    if (content.trim().startsWith('{')) {
      try {
        task = ValueReaders.mapValue(jsonDecode(content));
      } catch (_) {}
    }
    final title = ValueReaders.stringValue(
      task['title'],
      relativePath.split('/').last,
    );
    return <String, Object?>{
      'id': relativePath,
      'title': title,
      'subtitle': ValueReaders.stringValue(task['task_type'], 'task'),
      'badge': ValueReaders.stringValue(task['status'], 'pending'),
      'description': ValueReaders.stringValue(
        task['goal'],
        ValueReaders.stringValue(task['notes'], _previewText(content)),
      ),
      'relative_path': relativePath,
    };
  }

  JsonMap _reviewSummary({
    required String relativePath,
    required String content,
  }) {
    // 中文注释: 审稿摘要优先读取 JSON 报告，没有 JSON 时用路径和 Markdown 头部信息做轻量展示。
    if (relativePath.toLowerCase().endsWith('.json') &&
        content.trim().startsWith('{')) {
      try {
        final report = ValueReaders.mapValue(jsonDecode(content));
        final summary = _reviewReportSummaryService.reportSummary(report);
        return <String, Object?>{
          'id': relativePath,
          'title': ValueReaders.stringValue(summary['title'], relativePath),
          'subtitle': ValueReaders.stringValue(summary['review_type_label']),
          'badge': '${summary['issue_count'] ?? 0}项',
          'description': ValueReaders.stringValue(
            summary['summary'],
            _previewText(content),
          ),
          'relative_path': relativePath,
        };
      } catch (_) {}
    }
    return <String, Object?>{
      'id': relativePath,
      'title': relativePath.split('/').last,
      'subtitle': _reviewTypeFromPath(relativePath),
      'badge': 'report',
      'description': _previewText(content),
      'relative_path': relativePath,
    };
  }

  JsonMap _templateSummary({
    required String relativePath,
    required String content,
  }) {
    // 中文注释: 模板摘要优先走模板规范化器，确保 scope 和变量集合使用统一口径。
    if (content.trim().startsWith('{')) {
      try {
        final template = _promptTemplateNormalizerService.normalizeTemplate(
          ValueReaders.mapValue(jsonDecode(content)),
        );
        return <String, Object?>{
          'id': relativePath,
          'title': ValueReaders.stringValue(template['name'], relativePath),
          'subtitle': ValueReaders.stringValue(template['scope'], 'project'),
          'badge': '${ValueReaders.stringList(template['variables']).length}变量',
          'description': ValueReaders.stringValue(
            template['description'],
            _previewText(ValueReaders.stringValue(template['content'])),
          ),
          'relative_path': relativePath,
        };
      } catch (_) {}
    }
    return <String, Object?>{
      'id': relativePath,
      'title': relativePath.split('/').last,
      'subtitle': 'template',
      'badge': 'raw',
      'description': _previewText(content),
      'relative_path': relativePath,
    };
  }

  Map<String, Object> _descriptorFor(String kind) {
    switch (kind) {
      case 'reviews':
        return <String, Object>{
          'title': '审稿',
          'description': '浏览项目内审稿报告与相关输出。',
        };
      case 'templates':
        return <String, Object>{'title': '模板', 'description': '浏览项目内提示词模板。'};
      case 'tasks':
      default:
        return <String, Object>{
          'title': '任务',
          'description': '浏览项目内章节任务、长任务和检查点文件。',
        };
    }
  }

  bool _matchesKind(String kind, String relativePath) {
    switch (kind) {
      case 'reviews':
        return relativePath.startsWith('reviews/');
      case 'templates':
        return relativePath.startsWith('prompts/');
      case 'tasks':
      default:
        return relativePath.startsWith('tasks/');
    }
  }

  String _resolvedSelectedEntryId(
    String selectedEntryId,
    List<JsonMap> entries,
  ) {
    for (final entry in entries) {
      if (ValueReaders.stringValue(entry['id']) == selectedEntryId.trim()) {
        return selectedEntryId.trim();
      }
    }
    if (entries.isEmpty) {
      return '';
    }
    return ValueReaders.stringValue(entries.first['id']);
  }

  String _previewText(String value) {
    final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length <= 90) {
      return clean;
    }
    return '${clean.substring(0, 90)}...';
  }

  String _reviewTypeFromPath(String relativePath) {
    final segments = relativePath.split('/');
    if (segments.length >= 2) {
      return segments[1];
    }
    return 'general';
  }
}
