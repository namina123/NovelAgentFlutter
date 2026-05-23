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
