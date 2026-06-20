import 'package:novel_agent_core/novel_agent_core.dart';

class BookDeconstructionStructuredSourceProjectionService {
  const BookDeconstructionStructuredSourceProjectionService({
    BookDeconstructionTargetPathService? targetPathService,
  }) : _targetPathService =
           targetPathService ?? const BookDeconstructionTargetPathService();

  final BookDeconstructionTargetPathService _targetPathService;

  String targetPath({
    required ProjectStorageStrategy storageStrategy,
  }) {
    return _targetPathService.structuredSourcePath(
      storageStrategy: storageStrategy,
    );
  }

  String render({
    required BookDeconstructionDraftBuildResult buildResult,
  }) {
    final extraction = buildResult.extractionResult;
    final sourceDocument = buildResult.input.sourceDocuments.isEmpty
        ? null
        : buildResult.input.sourceDocuments.first;
    final buffer = StringBuffer()
      ..writeln('---')
      ..writeln('kind: book_deconstruction_structured_source')
      ..writeln('source_title: ${_yamlScalar(extraction.sourceTitle)}')
      ..writeln('extraction_id: ${_yamlScalar(extraction.extractionId)}')
      ..writeln('project_strategy_id: ${_yamlScalar(extraction.projectStrategyId)}')
      ..writeln('mode_id: ${_yamlScalar(extraction.modeId)}')
      ..writeln(
        'source_locator: ${_yamlScalar(sourceDocument?.relativePathHint ?? '')}',
      )
      ..writeln('chapter_outline_count: ${extraction.chapterOutlines.length}')
      ..writeln('character_count: ${extraction.characterProfiles.length}')
      ..writeln('organization_count: ${extraction.organizationProfiles.length}')
      ..writeln('world_rule_count: ${extraction.worldRuleSets.length}')
      ..writeln('---')
      ..writeln()
      ..writeln('# ${extraction.sourceTitle.trim().isEmpty ? '拆书结构化源文' : extraction.sourceTitle.trim()}')
      ..writeln();
    if (extraction.storyOutlineSummary.trim().isNotEmpty) {
      buffer
        ..writeln('## 结构摘要')
        ..writeln()
        ..writeln(extraction.storyOutlineSummary.trim())
        ..writeln();
    }
    if (extraction.chapterOutlines.isNotEmpty) {
      buffer
        ..writeln('## 章节索引')
        ..writeln();
      for (final outline in extraction.chapterOutlines) {
        buffer
          ..writeln('- ${outline.sequence}. ${outline.title}：${outline.summary}')
          ..writeln();
      }
    }
    buffer
      ..writeln('## 规范化正文')
      ..writeln();
    final sourceText = sourceDocument?.content.trim() ?? '';
    buffer.writeln(sourceText.isEmpty ? extraction.storyOutlineSummary.trim() : sourceText);
    return '${buffer.toString().trimRight()}\n';
  }

  String _yamlScalar(String value) {
    final clean = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
    if (clean.isEmpty) {
      return '""';
    }
    final escaped = clean.replaceAll('"', '\\"');
    return '"$escaped"';
  }
}
