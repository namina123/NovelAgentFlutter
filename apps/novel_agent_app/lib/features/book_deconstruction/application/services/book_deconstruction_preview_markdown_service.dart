import 'package:novel_agent_core/novel_agent_core.dart';

class BookDeconstructionPreviewMarkdownService {
  const BookDeconstructionPreviewMarkdownService();

  String render({
    required BookDeconstructionDraftBuildResult buildResult,
    required Set<String> selectedItemIds,
  }) {
    // 中文注释: 预演确认只输出稳定 Markdown 纪要，供用户回看与后续真实应用链继续复用。
    final extraction = buildResult.extractionResult;
    final plan = buildResult.applicationPlan;
    final selectedItems = plan.items
        .where((item) => selectedItemIds.contains(item.id))
        .toList(growable: false);
    final buffer = StringBuffer()
      ..writeln('# 拆书结构化预演')
      ..writeln()
      ..writeln('- 来源标题：${extraction.sourceTitle}')
      ..writeln('- 结构条目：${plan.items.length}')
      ..writeln('- 已选应用条目：${selectedItems.length}')
      ..writeln();
    if (extraction.notes.trim().isNotEmpty) {
      buffer
        ..writeln('## 操作备注')
        ..writeln()
        ..writeln(extraction.notes.trim())
        ..writeln();
    }
    if (extraction.premises.isNotEmpty) {
      buffer
        ..writeln('## 前提提取')
        ..writeln();
      for (final premise in extraction.premises) {
        buffer
          ..writeln('### ${premise.displayName}')
          ..writeln()
          ..writeln(premise.summary)
          ..writeln();
      }
    }
    if (extraction.storyOutlineSummary.trim().isNotEmpty) {
      buffer
        ..writeln('## 故事总纲提要')
        ..writeln()
        ..writeln(extraction.storyOutlineSummary.trim())
        ..writeln();
    }
    if (extraction.chapterOutlines.isNotEmpty) {
      buffer
        ..writeln('## 章节结构预览')
        ..writeln();
      for (final outline in extraction.chapterOutlines) {
        buffer
          ..writeln(
            '- ${outline.sequence}. ${outline.title}: ${outline.summary}',
          )
          ..writeln();
      }
    }
    buffer
      ..writeln('## 已选应用计划')
      ..writeln();
    for (final item in selectedItems) {
      buffer.writeln(
        '- ${item.displayName} -> ${item.relativePathHint} (${item.action})',
      );
      if (item.summary.trim().isNotEmpty) {
        buffer.writeln('  - ${item.summary.trim()}');
      }
    }
    return buffer.toString().trimRight();
  }
}
