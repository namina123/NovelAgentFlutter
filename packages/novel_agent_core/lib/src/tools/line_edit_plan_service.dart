import '../common/json_types.dart';
import '../common/value_readers.dart';

class LineEditPlanService {
  JsonMap applyLineEdit(String original, JsonMap arguments) {
    // 中文注释: 行级复制、剪切和删除在核心计算结果，宿主只负责把结果写回项目目录。
    final operation = ValueReaders.stringValue(
      arguments['operation'],
      ValueReaders.stringValue(arguments['mode']),
    ).trim().toLowerCase();
    if (!const <String>{'copy', 'cut', 'delete'}.contains(operation)) {
      return _error('Unsupported line operation.');
    }
    if (original.isEmpty) {
      return _error('Source file is empty.');
    }
    final lines = original
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    final lineCount = lines.length;
    final startLine = _resolveExistingLineNumber(
      ValueReaders.intValue(
        arguments['start_line'] ?? arguments['startLine'],
        1,
      ),
      lineCount,
    );
    final endLine = _resolveExistingLineNumber(
      ValueReaders.intValue(
        arguments['end_line'] ?? arguments['endLine'],
        startLine,
      ),
      lineCount,
      minValue: startLine,
    );
    final selectedText = lines.sublist(startLine - 1, endLine).join('\n');
    var nextSource = original;
    var sourceChanged = false;
    if (operation == 'cut' || operation == 'delete') {
      final kept = <String>[];
      for (var index = 0; index < lines.length; index++) {
        final lineNo = index + 1;
        if (lineNo < startLine || lineNo > endLine) {
          kept.add(lines[index]);
        }
      }
      nextSource = kept.join('\n');
      sourceChanged = nextSource != original;
    }
    var targetChanged = false;
    var nextTarget = ValueReaders.stringValue(arguments['target_content']);
    if ((operation == 'copy' || operation == 'cut') &&
        arguments.containsKey('target_content')) {
      final targetLine = _resolveInsertionLineNumber(
        ValueReaders.intValue(
          arguments['target_line'] ?? arguments['targetLine'],
          -1,
        ),
        nextTarget,
      );
      nextTarget = _insertTextAtLine(nextTarget, selectedText, targetLine);
      targetChanged =
          nextTarget != ValueReaders.stringValue(arguments['target_content']);
    }
    return <String, Object?>{
      'ok': true,
      'content': nextSource,
      'content_chars': nextSource.length,
      'target_content': nextTarget,
      'target_content_chars': nextTarget.length,
      'operation': operation,
      'line_count': lineCount,
      'selected_start_line': startLine,
      'selected_end_line': endLine,
      'selected_text': selectedText,
      'changed': sourceChanged || targetChanged,
      'source_changed': sourceChanged,
      'target_changed': targetChanged,
    };
  }

  JsonMap _error(String message) {
    return <String, Object?>{'ok': false, 'error': message};
  }

  int _resolveExistingLineNumber(int value, int lineCount, {int minValue = 1}) {
    // 中文注释: 读取现有行时允许负数从尾部反向定位，例如 -1 表示最后一行。
    final normalized = value < 0 ? lineCount + value + 1 : value;
    return _clampLine(normalized, minValue, lineCount);
  }

  int _resolveInsertionLineNumber(int value, String original) {
    // 中文注释: 目标插入位置同样支持负数；-1 视为追加到最后一行之后。
    final lines = original
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    final lineCount = lines.length;
    if (value < 0) {
      return _clampLine(lineCount + value + 2, 1, lineCount + 1);
    }
    return _clampLine(value, 1, lineCount + 1);
  }

  int _clampLine(int value, int minValue, int maxValue) {
    // 中文注释: 行号仍以 1-based 对外暴露，这里统一夹取合法范围。
    if (value < minValue) {
      return minValue;
    }
    if (value > maxValue) {
      return maxValue;
    }
    return value;
  }

  String _insertTextAtLine(String original, String text, int targetLine) {
    // 中文注释: 目标行号为空或越界时追加到末尾，保持和旧项目 planner 一致。
    if (targetLine <= 0) {
      var nextText = original;
      if (nextText.isNotEmpty && !nextText.endsWith('\n')) {
        nextText += '\n';
      }
      return nextText + text;
    }
    final lines = original
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    final normalizedTargetLine = _clampLine(targetLine, 1, lines.length + 1);
    final hasTrailingNewline = original.endsWith('\n');
    final insertIndex =
        hasTrailingNewline && normalizedTargetLine == lines.length + 1
        ? lines.length - 1
        : normalizedTargetLine - 1;
    final insertLines = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .toList(growable: true);
    if (insertLines.isNotEmpty && insertLines.last.isEmpty) {
      insertLines.removeLast();
    }
    lines.insertAll(insertIndex, insertLines);
    return lines.join('\n');
  }
}
