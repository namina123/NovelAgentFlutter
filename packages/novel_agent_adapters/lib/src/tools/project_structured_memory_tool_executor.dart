import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_file_write_tool_executor.dart';
import 'project_tool_path_policy.dart';

class ProjectStructuredMemoryToolExecutor {
  ProjectStructuredMemoryToolExecutor({
    required ProjectToolHostPort hostPort,
    required ProjectFileWriteToolExecutor writeToolExecutor,
    ProjectToolPathPolicy? pathPolicy,
    ReviewReportNormalizerService? reviewReportNormalizerService,
    ReviewReportMarkdownRenderer? reviewReportMarkdownRenderer,
  }) : _writeToolExecutor = writeToolExecutor,
       _hostPort = hostPort,
       _pathPolicy = pathPolicy ?? ProjectToolPathPolicy(),
       _reviewReportNormalizerService =
           reviewReportNormalizerService ?? ReviewReportNormalizerService(),
       _reviewReportMarkdownRenderer =
           reviewReportMarkdownRenderer ?? ReviewReportMarkdownRenderer();

  final ProjectFileWriteToolExecutor _writeToolExecutor;
  final ProjectToolHostPort _hostPort;
  final ProjectToolPathPolicy _pathPolicy;
  final ReviewReportNormalizerService _reviewReportNormalizerService;
  final ReviewReportMarkdownRenderer _reviewReportMarkdownRenderer;

  Future<JsonMap> updateWorldState(
    ProjectDescriptor project,
    JsonMap arguments,
  ) {
    // 中文注释: 世界书条目最终落成 Markdown 文件，便于 GUI/CLI 和未来包结构统一读取。
    final title = ValueReaders.stringValue(arguments['title'], '未命名设定');
    final keywords = ValueReaders.stringList(arguments['keywords']);
    final lines = <String>[
      '# $title',
      '',
      if (ValueReaders.stringValue(arguments['entry_type']).trim().isNotEmpty)
        '- 条目类型：${ValueReaders.stringValue(arguments['entry_type'])}',
      if (keywords.isNotEmpty) '- 关键词：${keywords.join('、')}',
      '',
      ValueReaders.stringValue(arguments['content']),
    ];
    return _writeToolExecutor.writeProjectFile(project, <String, Object?>{
      'content_type': 'setting',
      'title': title,
      'relative_path': 'world/${_pathPolicy.safeFileName(title)}.md',
      'content': lines.join('\n').trim(),
    });
  }

  Future<JsonMap> updateCharacterState(
    ProjectDescriptor project,
    JsonMap arguments,
  ) {
    // 中文注释: 角色状态同样写成标准 Markdown，后续可自然过渡到角色包或更细粒度索引。
    final name = ValueReaders.stringValue(arguments['name'], '未命名角色');
    final content = ValueReaders.stringValue(arguments['content']).trim();
    final lines = <String>[
      '# $name',
      '',
      if (ValueReaders.stringValue(arguments['role']).trim().isNotEmpty)
        '- 角色定位：${ValueReaders.stringValue(arguments['role'])}',
      if (ValueReaders.stringValue(arguments['status']).trim().isNotEmpty)
        '- 当前状态：${ValueReaders.stringValue(arguments['status'])}',
      '',
      if (content.isNotEmpty) content,
    ];
    return _writeToolExecutor.writeProjectFile(project, <String, Object?>{
      'content_type': 'character',
      'title': name,
      'relative_path': 'characters/${_pathPolicy.safeFileName(name)}.md',
      'content': lines.join('\n').trim(),
    });
  }

  Future<JsonMap> summarizeContext(
    ProjectDescriptor project,
    JsonMap arguments,
  ) {
    // 中文注释: 摘要文件采用 Markdown，保证后续上下文读取和人工审阅都方便。
    final title = ValueReaders.stringValue(arguments['title'], '上下文摘要');
    final scope = ValueReaders.stringValue(arguments['scope']);
    final summary = ValueReaders.stringValue(arguments['summary']);
    return _writeToolExecutor.writeProjectFile(project, <String, Object?>{
      'content_type': 'summary',
      'title': title,
      'relative_path':
          ValueReaders.stringValue(arguments['relative_path']).trim().isEmpty
          ? 'summaries/${_pathPolicy.safeFileName(title)}.summary.md'
          : arguments['relative_path'],
      'content': [
        '# $title',
        '',
        if (scope.trim().isNotEmpty) '- 范围：$scope',
        '',
        summary,
      ].join('\n').trim(),
    });
  }

  Future<JsonMap> runContinuityCheck(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 审稿报告同时落 JSON 和 Markdown 兄弟文件，保证报告浏览、修复任务和详情页都能共用。
    final title = ValueReaders.stringValue(arguments['title'], '连续性检查');
    final reviewType = ValueReaders.stringValue(
      arguments['review_type'],
      'continuity',
    ).trim().toLowerCase();
    final createdAt = DateTime.now().toIso8601String();
    final issues = ValueReaders.objectList(arguments['issues'])
        .map(ValueReaders.mapValue)
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    final suggestions = ValueReaders.stringList(arguments['suggestions']);
    final sourcePaths = ValueReaders.stringList(arguments['source_paths']);
    final scope = ValueReaders.stringValue(arguments['scope']).trim();
    var markdownPath = _pathPolicy.cleanRelativePath(
      ValueReaders.stringValue(arguments['relative_path']),
    );
    if (markdownPath.isEmpty) {
      markdownPath =
          'reviews/$reviewType/${_pathPolicy.safeFileName(title)}.md';
    } else if (markdownPath.toLowerCase().endsWith('.json')) {
      markdownPath = '${markdownPath.substring(0, markdownPath.length - 5)}.md';
    } else if (!markdownPath.split('/').last.contains('.')) {
      markdownPath = '$markdownPath.md';
    }
    if (!_pathPolicy.isSafeFilePath(markdownPath)) {
      return <String, Object?>{
        'ok': false,
        'error': 'Unsafe review report path.',
        'relative_path': markdownPath,
      };
    }
    final overwrite = ValueReaders.boolValue(arguments['overwrite']);
    if (!overwrite) {
      markdownPath = await _pathPolicy.uniqueRelativePath(
        hostPort: _hostPort,
        rootPath: project.rootPath,
        relativePath: markdownPath,
      );
    }
    final jsonPath =
        '${markdownPath.substring(0, markdownPath.length - 3)}.json';
    final report = _reviewReportNormalizerService.normalizeReport(<
      String,
      Object?
    >{
      'id':
          'review_${_pathPolicy.safeFileName(title, fallback: 'report')}_${DateTime.now().microsecondsSinceEpoch}',
      'review_type': reviewType,
      'title': title,
      'scope': scope,
      'summary': ValueReaders.stringValue(arguments['summary']).trim(),
      'issues': issues,
      'suggestions': suggestions,
      'source_paths': sourcePaths,
      'related_paths': ValueReaders.stringList(arguments['related_paths']),
      'metadata': <String, Object?>{'origin': 'run_continuity_check'},
      'created_at': createdAt,
      'json_path': jsonPath,
      'markdown_path': markdownPath,
    }, createdAt: createdAt);
    final markdown = _reviewReportMarkdownRenderer.renderMarkdown(report);
    await _hostPort.writeTextFile(
      project.rootPath,
      jsonPath,
      const JsonEncoder.withIndent('  ').convert(report),
    );
    final markdownResult = await _writeToolExecutor
        .writeProjectFile(project, <String, Object?>{
          'content_type': 'summary',
          'title': title,
          'relative_path': markdownPath,
          'content': markdown,
          'overwrite': true,
        });
    if (!ValueReaders.boolValue(markdownResult['ok'])) {
      return markdownResult;
    }
    return <String, Object?>{
      'ok': true,
      'relative_path': markdownPath,
      'markdown_path': markdownPath,
      'json_path': jsonPath,
      'review_type': reviewType,
      'source_paths': sourcePaths,
      'changed_paths': <Object?>[jsonPath, markdownPath],
      'summary': '已保存审稿报告：$markdownPath',
    };
  }
}
