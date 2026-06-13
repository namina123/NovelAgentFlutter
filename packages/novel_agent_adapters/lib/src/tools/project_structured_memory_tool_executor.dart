import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_character_path_policy.dart';
import '../storage/project_character_state_update_service.dart';
import '../storage/project_foreshadow_feedback_update_service.dart';
import '../storage/project_foreshadow_state_update_service.dart';
import '../storage/project_relationship_state_update_service.dart';
import '../storage/project_timeline_state_update_service.dart';
import 'project_file_write_tool_executor.dart';
import 'project_tool_path_policy.dart';

class ProjectStructuredMemoryToolExecutor {
  ProjectStructuredMemoryToolExecutor({
    required ProjectToolHostPort hostPort,
    required ProjectFileWriteToolExecutor writeToolExecutor,
    ProjectToolPathPolicy? pathPolicy,
    ProjectCharacterStateUpdateService? characterStateUpdateService,
    ProjectForeshadowStateUpdateService? foreshadowStateUpdateService,
    ProjectTimelineStateUpdateService? timelineStateUpdateService,
    ProjectRelationshipStateUpdateService? relationshipStateUpdateService,
    ProjectForeshadowFeedbackUpdateService? foreshadowFeedbackUpdateService,
    ReviewReportNormalizerService? reviewReportNormalizerService,
    ReviewReportMarkdownRenderer? reviewReportMarkdownRenderer,
  }) : _writeToolExecutor = writeToolExecutor,
       _hostPort = hostPort,
       _pathPolicy = pathPolicy ?? ProjectToolPathPolicy(),
       _characterStateUpdateService =
           characterStateUpdateService ??
           ProjectCharacterStateUpdateService(
             hostPort: hostPort,
             pathPolicy: ProjectCharacterPathPolicy(toolPathPolicy: pathPolicy),
           ),
       _foreshadowStateUpdateService =
           foreshadowStateUpdateService ??
           ProjectForeshadowStateUpdateService(hostPort: hostPort),
       _timelineStateUpdateService =
           timelineStateUpdateService ??
           ProjectTimelineStateUpdateService(hostPort: hostPort),
       _relationshipStateUpdateService =
           relationshipStateUpdateService ??
           ProjectRelationshipStateUpdateService(hostPort: hostPort),
       _foreshadowFeedbackUpdateService =
           foreshadowFeedbackUpdateService ??
           ProjectForeshadowFeedbackUpdateService(hostPort: hostPort),
       _reviewReportNormalizerService =
           reviewReportNormalizerService ?? ReviewReportNormalizerService(),
       _reviewReportMarkdownRenderer =
           reviewReportMarkdownRenderer ?? ReviewReportMarkdownRenderer();

  final ProjectFileWriteToolExecutor _writeToolExecutor;
  final ProjectToolHostPort _hostPort;
  final ProjectToolPathPolicy _pathPolicy;
  final ProjectCharacterStateUpdateService _characterStateUpdateService;
  final ProjectForeshadowStateUpdateService _foreshadowStateUpdateService;
  final ProjectTimelineStateUpdateService _timelineStateUpdateService;
  final ProjectRelationshipStateUpdateService _relationshipStateUpdateService;
  final ProjectForeshadowFeedbackUpdateService _foreshadowFeedbackUpdateService;
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
    // 中文注释: 角色更新现在统一走共享角色状态服务，由它负责主档、latest 状态与历史附录三层写盘。
    return _characterStateUpdateService.updateCharacterState(
      project,
      arguments,
    );
  }

  Future<JsonMap> updateForeshadowState(
    ProjectDescriptor project,
    JsonMap arguments,
  ) {
    // 中文注释: 伏笔更新走独立资产服务，避免继续把伏笔混成世界书或摘要文本。
    return _foreshadowStateUpdateService.updateForeshadowState(
      project,
      arguments,
    );
  }

  Future<JsonMap> updateTimelineState(
    ProjectDescriptor project,
    JsonMap arguments,
  ) {
    // 中文注释: 时间线更新必须进入共享 timeline 资产层，便于后续上下文与图谱共用。
    return _timelineStateUpdateService.updateTimelineState(project, arguments);
  }

  Future<JsonMap> updateRelationshipState(
    ProjectDescriptor project,
    JsonMap arguments,
  ) {
    // 中文注释: 关系更新只做结构化关系资产写盘，不把关系变化塞回角色主档正文里。
    return _relationshipStateUpdateService.updateRelationshipState(
      project,
      arguments,
    );
  }

  Future<JsonMap> summarizeContext(
    ProjectDescriptor project,
    JsonMap arguments,
  ) {
    // 中文注释: 摘要文件采用 Markdown，保证后续上下文读取和人工审阅都方便。
    final rawTitle = ValueReaders.stringValue(arguments['title'], '上下文摘要');
    final title = _normalizedSummaryTitle(rawTitle);
    final scope = ValueReaders.stringValue(arguments['scope']);
    final summary = ValueReaders.stringValue(arguments['summary']);
    return _writeToolExecutor.writeProjectFile(project, <String, Object?>{
      'content_type': 'summary',
      'title': title,
      'relative_path':
          ValueReaders.stringValue(arguments['relative_path']).trim().isEmpty
          ? _defaultSummaryRelativePath(title, fallbackTitle: rawTitle)
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

  String _defaultSummaryRelativePath(
    String title, {
    String fallbackTitle = '上下文摘要',
  }) {
    final safeStem = _pathPolicy.safeFileName(
      title.trim().isEmpty ? fallbackTitle : title,
      fallback: 'summary',
    );
    return 'summaries/$safeStem.summary.md';
  }

  String _normalizedSummaryTitle(String value) {
    var result = value.trim();
    if (result.isEmpty) {
      return result;
    }
    final lowerResult = result.toLowerCase();
    if (lowerResult.endsWith('.summary.md')) {
      result = result.substring(0, result.length - '.summary.md'.length);
    } else if (lowerResult.endsWith('.md')) {
      result = result.substring(0, result.length - '.md'.length);
    }
    while (result.toLowerCase().endsWith('.summary')) {
      result = result.substring(0, result.length - '.summary'.length).trim();
    }
    return result.trim();
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
    final feedbackChangedPaths = await _foreshadowFeedbackUpdateService
        .applyReviewReport(project, report);
    return <String, Object?>{
      'ok': true,
      'relative_path': markdownPath,
      'markdown_path': markdownPath,
      'json_path': jsonPath,
      'review_type': reviewType,
      'source_paths': sourcePaths,
      'changed_paths': <Object?>[
        jsonPath,
        markdownPath,
        ...feedbackChangedPaths,
      ],
      'summary': '已保存审稿报告：$markdownPath',
    };
  }
}
