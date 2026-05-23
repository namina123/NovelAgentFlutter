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
    final startLine = _clampLine(
      ValueReaders.intValue(
        arguments['start_line'] ?? arguments['startLine'],
        1,
      ),
      1,
      lineCount,
    );
    final endLine = _clampLine(
      ValueReaders.intValue(
        arguments['end_line'] ?? arguments['endLine'],
        startLine,
      ),
      startLine,
      lineCount,
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
      final targetLine = ValueReaders.intValue(
        arguments['target_line'] ?? arguments['targetLine'],
        -1,
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
    final insertIndex = _clampLine(targetLine, 1, lines.length + 1) - 1;
    final insertLines = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    lines.insertAll(insertIndex, insertLines);
    return lines.join('\n');
  }
}
