import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_file_write_tool_executor.dart';
import 'project_tool_path_policy.dart';

class ProjectStructuredMemoryToolExecutor {
  ProjectStructuredMemoryToolExecutor({
    required ProjectFileWriteToolExecutor writeToolExecutor,
    ProjectToolPathPolicy? pathPolicy,
  }) : _writeToolExecutor = writeToolExecutor,
       _pathPolicy = pathPolicy ?? ProjectToolPathPolicy();

  final ProjectFileWriteToolExecutor _writeToolExecutor;
  final ProjectToolPathPolicy _pathPolicy;

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
  ) {
    // 中文注释: 连续性检查报告落到 reviews/<type>/ 目录，正文和问题列表都保持可读 Markdown。
    final title = ValueReaders.stringValue(arguments['title'], '连续性检查');
    final reviewType = ValueReaders.stringValue(
      arguments['review_type'],
      'continuity',
    ).trim().toLowerCase();
    final issues = ValueReaders.objectList(arguments['issues'])
        .map(ValueReaders.mapValue)
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    final suggestions = ValueReaders.stringList(arguments['suggestions']);
    final sourcePaths = ValueReaders.stringList(arguments['source_paths']);
    final buffer = StringBuffer()
      ..writeln('# $title')
      ..writeln()
      ..writeln('- 检查类型：$reviewType');
    final scope = ValueReaders.stringValue(arguments['scope']).trim();
    if (scope.isNotEmpty) {
      buffer.writeln('- 范围：$scope');
    }
    if (sourcePaths.isNotEmpty) {
      buffer.writeln('- 关联文件：${sourcePaths.join('、')}');
    }
    buffer
      ..writeln()
      ..writeln(ValueReaders.stringValue(arguments['summary']).trim());
    if (issues.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## 问题列表');
      for (final issue in issues) {
        buffer
          ..writeln()
          ..writeln(
            '- ${ValueReaders.stringValue(issue['title'], '未命名问题')}'
            '（${ValueReaders.stringValue(issue['severity'], 'unknown')}）',
          );
        final detail = ValueReaders.stringValue(issue['detail']).trim();
        if (detail.isNotEmpty) {
          buffer.writeln('  - 细节：$detail');
        }
        final suggestion = ValueReaders.stringValue(issue['suggestion']).trim();
        if (suggestion.isNotEmpty) {
          buffer.writeln('  - 建议：$suggestion');
        }
      }
    }
    if (suggestions.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## 补充建议');
      for (final suggestion in suggestions) {
        buffer.writeln('- $suggestion');
      }
    }
    return _writeToolExecutor.writeProjectFile(project, <String, Object?>{
      'content_type': 'summary',
      'title': title,
      'relative_path':
          'reviews/$reviewType/${_pathPolicy.safeFileName(title)}.md',
      'content': buffer.toString().trim(),
    });
  }
}
