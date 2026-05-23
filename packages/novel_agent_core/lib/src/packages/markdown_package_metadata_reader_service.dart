import 'dart:convert';

import '../common/json_types.dart';
import '../common/value_readers.dart';

class MarkdownPackageMetadataReaderService {
  JsonMap readMetadata(
    String markdown, {
    required List<String> acceptedFenceLabels,
  }) {
    // 中文注释: Markdown 包的结构化元数据统一从第一个受支持代码块读取，避免每个解析器各自猜格式。
    final match = RegExp(
      r'^\s*```([^\n`]*)\n([\s\S]*?)\n```',
      multiLine: false,
    ).firstMatch(markdown);
    if (match == null) {
      return <String, Object?>{};
    }
    final rawLabel = match.group(1)?.trim().toLowerCase() ?? '';
    final accepted = acceptedFenceLabels
        .map((item) => item.toLowerCase())
        .toSet();
    if (!accepted.contains(rawLabel) && rawLabel != 'json') {
      return <String, Object?>{};
    }
    final rawBody = match.group(2)?.trim() ?? '';
    try {
      return ValueReaders.mapValue(jsonDecode(rawBody));
    } catch (_) {
      return <String, Object?>{};
    }
  }

  String removeMetadataBlock(
    String markdown, {
    required List<String> acceptedFenceLabels,
  }) {
    // 中文注释: 解析出元数据后，把首个元数据代码块剥离，剩余正文交给说明或 system prompt 字段承载。
    final match = RegExp(
      r'^\s*```([^\n`]*)\n([\s\S]*?)\n```',
      multiLine: false,
    ).firstMatch(markdown);
    if (match == null) {
      return markdown.trim();
    }
    final rawLabel = match.group(1)?.trim().toLowerCase() ?? '';
    final accepted = acceptedFenceLabels
        .map((item) => item.toLowerCase())
        .toSet();
    if (!accepted.contains(rawLabel) && rawLabel != 'json') {
      return markdown.trim();
    }
    final remaining = markdown.substring(match.end).trim();
    return remaining;
  }

  String readFirstHeading(String markdown) {
    // 中文注释: 没有显式元数据时，标题回退到首个一级标题，方便最小 Markdown 包也能被识别。
    for (final line in markdown.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('# ')) {
        return trimmed.substring(2).trim();
      }
    }
    return '';
  }
}
