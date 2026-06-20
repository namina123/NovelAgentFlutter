import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'book_deconstruction_smart_import_rules.dart';

class BookDeconstructionSmartImportRuleDocumentService {
  const BookDeconstructionSmartImportRuleDocumentService();

  BookDeconstructionSmartImportRules? parse(String content) {
    final normalized = content.trim();
    if (normalized.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(normalized);
      if (decoded is Map<String, Object?>) {
        return _fromMap(decoded);
      }
    } catch (_) {
      // 中文注释: 宽松解析放到下面，优先兼容模型把 JSON 包在代码块里的返回形式。
    }
    final extracted = _extractJsonObject(normalized);
    if (extracted.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(extracted);
      if (decoded is Map<String, Object?>) {
        return _fromMap(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String encode(BookDeconstructionSmartImportRules rules) {
    final document = <String, Object?>{
      'selected_source_paths': rules.selectedSourcePaths,
      'chapter_heading_patterns': rules.chapterHeadingPatterns,
      'drop_line_contains': rules.dropLineContains,
      'drop_line_patterns': rules.dropLinePatterns,
      'collapse_blank_lines': rules.collapseBlankLines,
      'insert_blank_line_between_sources': rules.insertBlankLineBetweenSources,
      'trim_trailing_whitespace': rules.trimTrailingWhitespace,
    };
    return const JsonEncoder.withIndent('  ').convert(document);
  }

  BookDeconstructionSmartImportRules _fromMap(Map<String, Object?> value) {
    return BookDeconstructionSmartImportRules(
      selectedSourcePaths: _cleanList(value['selected_source_paths']),
      chapterHeadingPatterns: _cleanList(value['chapter_heading_patterns']),
      dropLineContains: _cleanList(value['drop_line_contains']),
      dropLinePatterns: _cleanList(value['drop_line_patterns']),
      collapseBlankLines: _readBool(value['collapse_blank_lines'], true),
      insertBlankLineBetweenSources: _readBool(
        value['insert_blank_line_between_sources'],
        true,
      ),
      trimTrailingWhitespace: _readBool(
        value['trim_trailing_whitespace'],
        true,
      ),
    );
  }

  List<String> _cleanList(Object? value) {
    return ValueReaders.stringList(value)
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  bool _readBool(Object? value, bool fallback) {
    if (value == null) {
      return fallback;
    }
    return ValueReaders.boolValue(value, fallback);
  }

  String _extractJsonObject(String text) {
    final fenced = RegExp(
      r'```(?:json)?\s*([\s\S]*?)```',
      caseSensitive: false,
    ).firstMatch(text);
    if (fenced != null) {
      final candidate = fenced.group(1)?.trim() ?? '';
      if (candidate.startsWith('{') && candidate.endsWith('}')) {
        return candidate;
      }
    }
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) {
      return '';
    }
    return text.substring(start, end + 1).trim();
  }
}
