import '../common/json_types.dart';
import '../common/value_readers.dart';

class TextEditPlanService {
  JsonMap applyTextEdit(String original, JsonMap arguments) {
    // 中文注释: 全文编辑规划留在核心层计算，宿主只负责真实文件读写与权限边界。
    final operation = ValueReaders.stringValue(
      arguments['operation'],
      ValueReaders.stringValue(arguments['mode'], 'replace'),
    ).trim().toLowerCase();
    final content = ValueReaders.stringValue(
      arguments['content'],
      ValueReaders.stringValue(arguments['text']),
    );
    final oldText = ValueReaders.stringValue(
      arguments['old_text'],
      ValueReaders.stringValue(
        arguments['oldText'],
        ValueReaders.stringValue(arguments['search']),
      ),
    );
    final pattern = ValueReaders.stringValue(arguments['pattern']).trim();
    final useRegex = ValueReaders.boolValue(arguments['use_regex']);
    final startText = ValueReaders.stringValue(arguments['start_text']);
    final endText = ValueReaders.stringValue(arguments['end_text']);
    var nextText = original;
    var replaceCount = 0;
    switch (operation) {
      case 'append':
        nextText = original + content;
        break;
      case 'prepend':
        nextText = content + original;
        break;
      case 'overwrite':
      case 'write':
        nextText = content;
        break;
      case 'replace':
        if (startText.isNotEmpty || endText.isNotEmpty) {
          return _replaceAnchoredRange(
            original: original,
            content: content,
            startText: startText,
            endText: endText,
            includeStart: ValueReaders.boolValue(arguments['include_start']),
            includeEnd: ValueReaders.boolValue(arguments['include_end']),
            operation: operation,
          );
        }
        if (useRegex || pattern.isNotEmpty) {
          return _replaceWithPattern(
            original: original,
            pattern: pattern.isEmpty ? oldText : pattern,
            replacement: content,
            replaceAll: ValueReaders.boolValue(
              arguments['replace_all'] ?? arguments['replaceAll'],
              true,
            ),
            expectedOccurrences: ValueReaders.intValue(
              arguments['expected_occurrences'] ??
                  arguments['expectedOccurrences'],
              -1,
            ),
            operation: operation,
          );
        }
        if (oldText.isEmpty) {
          return _error('old_text is required for replace.');
        }
        replaceCount = _countOccurrences(original, oldText);
        if (replaceCount <= 0) {
          return _error('old_text not found.');
        }
        final expected = ValueReaders.intValue(
          arguments['expected_occurrences'] ?? arguments['expectedOccurrences'],
          -1,
        );
        if (expected >= 0 && expected != replaceCount) {
          return <String, Object?>{
            ..._error('old_text occurrence count mismatch.'),
            'replace_count': replaceCount,
            'expected_occurrences': expected,
          };
        }
        final replaceAll = ValueReaders.boolValue(
          arguments['replace_all'] ?? arguments['replaceAll'],
          true,
        );
        nextText = replaceAll
            ? original.replaceAll(oldText, content)
            : _replaceFirst(original, oldText, content);
        if (!replaceAll) {
          replaceCount = 1;
        }
        break;
      case 'insert_before':
        return _insertAroundAnchor(
          original: original,
          anchor: oldText,
          content: content,
          afterAnchor: false,
          operation: operation,
        );
      case 'insert_after':
        return _insertAroundAnchor(
          original: original,
          anchor: oldText,
          content: content,
          afterAnchor: true,
          operation: operation,
        );
      case 'delete':
        if (startText.isNotEmpty || endText.isNotEmpty) {
          return _replaceAnchoredRange(
            original: original,
            content: '',
            startText: startText,
            endText: endText,
            includeStart: ValueReaders.boolValue(arguments['include_start']),
            includeEnd: ValueReaders.boolValue(arguments['include_end']),
            operation: operation,
          );
        }
        if (useRegex || pattern.isNotEmpty) {
          return _replaceWithPattern(
            original: original,
            pattern: pattern.isEmpty ? oldText : pattern,
            replacement: '',
            replaceAll: ValueReaders.boolValue(
              arguments['replace_all'] ??
                  arguments['delete_all'] ??
                  arguments['deleteAll'],
              true,
            ),
            expectedOccurrences: -1,
            operation: operation,
          );
        }
        if (oldText.isEmpty) {
          return _error('old_text is required for delete.');
        }
        replaceCount = _countOccurrences(original, oldText);
        if (replaceCount <= 0) {
          return _error('old_text not found.');
        }
        final deleteAll = ValueReaders.boolValue(
          arguments['replace_all'] ??
              arguments['delete_all'] ??
              arguments['deleteAll'],
          true,
        );
        nextText = deleteAll
            ? original.replaceAll(oldText, '')
            : _replaceFirst(original, oldText, '');
        if (!deleteAll) {
          replaceCount = 1;
        }
        break;
      default:
        return _error('Unsupported edit operation.');
    }
    return <String, Object?>{
      'ok': true,
      'content': nextText,
      'content_chars': nextText.length,
      'operation': operation,
      'changed': nextText != original,
      'replace_count': replaceCount,
    };
  }

  JsonMap _replaceWithPattern({
    required String original,
    required String pattern,
    required String replacement,
    required bool replaceAll,
    required int expectedOccurrences,
    required String operation,
  }) {
    // 中文注释: 正则替换集中在这里，避免普通文本替换分支继续堆条件分叉。
    if (pattern.isEmpty) {
      return _error('pattern is required for regex replace/delete.');
    }
    final regex = _tryCompilePattern(pattern);
    if (regex == null) {
      return _error('pattern is not a valid regular expression.');
    }
    final matches = regex.allMatches(original).length;
    if (matches <= 0) {
      return _error('pattern not found.');
    }
    if (expectedOccurrences >= 0 && expectedOccurrences != matches) {
      return <String, Object?>{
        ..._error('pattern occurrence count mismatch.'),
        'replace_count': matches,
        'expected_occurrences': expectedOccurrences,
      };
    }
    final nextText = replaceAll
        ? original.replaceAll(regex, replacement)
        : original.replaceFirst(regex, replacement);
    return <String, Object?>{
      'ok': true,
      'content': nextText,
      'content_chars': nextText.length,
      'operation': operation,
      'changed': nextText != original,
      'replace_count': replaceAll ? matches : 1,
    };
  }

  JsonMap _replaceAnchoredRange({
    required String original,
    required String content,
    required String startText,
    required String endText,
    required bool includeStart,
    required bool includeEnd,
    required String operation,
  }) {
    // 中文注释: 锚点范围替换用于只改中间一段内容，减少模型手写长段 old_text 的脆弱性。
    if (startText.isEmpty && endText.isEmpty) {
      return _error(
        'start_text or end_text is required for anchored range replace.',
      );
    }
    final range = _findAnchorRange(
      original,
      startText: startText,
      endText: endText,
      includeStart: includeStart,
      includeEnd: includeEnd,
    );
    if (range == null) {
      return _error('anchored range not found.');
    }
    final nextText =
        original.substring(0, range.$1) +
        content +
        original.substring(range.$2);
    return <String, Object?>{
      'ok': true,
      'content': nextText,
      'changed': nextText != original,
      'replace_count': 1,
      'operation': operation,
      'content_chars': nextText.length,
    };
  }

  JsonMap _insertAroundAnchor({
    required String original,
    required String anchor,
    required String content,
    required bool afterAnchor,
    required String operation,
  }) {
    // 中文注释: 锚点插入要求明确命中位置，避免悄悄追加到错误地方。
    if (anchor.isEmpty) {
      return _error('old_text is required for anchored insert.');
    }
    final found = original.indexOf(anchor);
    if (found < 0) {
      return _error('old_text anchor not found.');
    }
    final insertAt = afterAnchor ? found + anchor.length : found;
    final nextText =
        original.substring(0, insertAt) +
        content +
        original.substring(insertAt);
    return <String, Object?>{
      'ok': true,
      'content': nextText,
      'changed': nextText != original,
      'replace_count': 0,
      'operation': operation,
      'content_chars': nextText.length,
    };
  }

  JsonMap _error(String message) {
    return <String, Object?>{'ok': false, 'error': message};
  }

  RegExp? _tryCompilePattern(String pattern) {
    // 中文注释: 正则编译失败属于用户输入问题，返回 null 交给上层统一产出可读错误。
    try {
      return RegExp(pattern, multiLine: true);
    } catch (_) {
      return null;
    }
  }

  (int, int)? _findAnchorRange(
    String original, {
    required String startText,
    required String endText,
    required bool includeStart,
    required bool includeEnd,
  }) {
    // 中文注释: 允许只给单边锚点，便于“替换从某处到结尾”这类编辑场景。
    var startIndex = 0;
    var endIndex = original.length;
    if (startText.isNotEmpty) {
      final found = original.indexOf(startText);
      if (found < 0) {
        return null;
      }
      startIndex = includeStart ? found : found + startText.length;
    }
    if (endText.isNotEmpty) {
      final searchStart = startText.isEmpty ? 0 : original.indexOf(startText);
      final found = original.indexOf(
        endText,
        searchStart < 0 ? 0 : searchStart + startText.length,
      );
      if (found < 0) {
        return null;
      }
      endIndex = includeEnd ? found + endText.length : found;
    }
    if (startIndex > endIndex) {
      return null;
    }
    return (startIndex, endIndex);
  }

  int _countOccurrences(String text, String needle) {
    // 中文注释: 精确计数用于替换前安全校验，避免模型误把多处命中当成单处修改。
    if (needle.isEmpty) {
      return 0;
    }
    var count = 0;
    var cursor = 0;
    while (cursor <= text.length) {
      final found = text.indexOf(needle, cursor);
      if (found < 0) {
        break;
      }
      count += 1;
      cursor = found + needle.length;
    }
    return count;
  }

  String _replaceFirst(String text, String needle, String replacement) {
    // 中文注释: 只替换首个命中时，行为要和旧项目 planner 保持一致。
    final found = text.indexOf(needle);
    if (found < 0) {
      return text;
    }
    return text.substring(0, found) +
        replacement +
        text.substring(found + needle.length);
  }
}
