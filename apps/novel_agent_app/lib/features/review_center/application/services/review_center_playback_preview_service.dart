import 'package:novel_agent_core/novel_agent_core.dart';

class ReviewCenterPlaybackPreviewService {
  const ReviewCenterPlaybackPreviewService();

  String build({
    required ChapterRewritePlan? plan,
    required String sourceBody,
  }) {
    // 中文注释: 这里只做最小回放壳，给用户看“计划瞄准了哪里”和“原文大概长什么样”，不在这轮追求完整 diff。
    if (plan == null) {
      return '';
    }
    final lines = sourceBody.split('\n');
    final buffer = StringBuffer()
      ..writeln('## 计划摘要')
      ..writeln(plan.summary)
      ..writeln()
      ..writeln('## 执行说明')
      ..writeln(plan.instructions.trim().isEmpty ? '暂无执行说明。' : plan.instructions);
    if (plan.targetSegments.isEmpty) {
      final preview = _window(lines, 1, lines.length < 40 ? lines.length : 40);
      if (preview.trim().isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('## 原文预览')
          ..writeln(preview);
      }
      return buffer.toString().trim();
    }
    for (final segment in plan.targetSegments) {
      buffer
        ..writeln()
        ..writeln('## 目标片段：${segment.label.trim().isEmpty ? segment.sourcePath : segment.label}');
      if (segment.startLine > 0 && segment.endLine >= segment.startLine) {
        buffer.writeln('行号：${segment.startLine}-${segment.endLine}');
      }
      final preview = _window(
        lines,
        segment.startLine <= 2 ? 1 : segment.startLine - 2,
        segment.endLine <= 0 ? segment.startLine + 6 : segment.endLine + 2,
      );
      if (preview.trim().isNotEmpty) {
        buffer.writeln(preview);
      }
    }
    return buffer.toString().trim();
  }

  String _window(List<String> lines, int startLine, int endLine) {
    if (lines.isEmpty) {
      return '';
    }
    final safeStart = startLine < 1 ? 1 : startLine;
    final safeEnd = endLine > lines.length ? lines.length : endLine;
    if (safeEnd < safeStart) {
      return '';
    }
    final buffer = StringBuffer();
    for (var index = safeStart; index <= safeEnd; index += 1) {
      buffer.writeln('$index: ${lines[index - 1]}');
    }
    return buffer.toString().trimRight();
  }
}
