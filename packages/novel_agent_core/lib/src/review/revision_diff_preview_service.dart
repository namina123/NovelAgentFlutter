import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'revision_diff_constants.dart';

class RevisionDiffPreviewService {
  JsonMap buildPair({
    required String targetPath,
    required String backupPath,
    required String beforeText,
    required String afterText,
  }) {
    // 中文注释: 单个 diff 配对只根据前后文本构造摘要，不负责读取文件或保存报告。
    var status = 'changed';
    var note = '';
    var preview = '';
    var changedLineEstimate = 0;
    if (backupPath.trim().isEmpty) {
      status = 'no_baseline';
      note = '没有检测到备份，无法生成可靠修复前后对比。后续应要求模型在修订前创建备份。';
    } else if (beforeText == afterText) {
      status = 'unchanged';
      note = '备份与当前文件一致，未检测到文本变化。';
    } else {
      final diff = diffPreview(beforeText, afterText);
      preview = ValueReaders.stringValue(diff['preview']);
      changedLineEstimate = ValueReaders.intValue(
        diff['changed_line_estimate'],
      );
    }
    return <String, Object?>{
      'target_path': targetPath,
      'backup_path': backupPath,
      'status': status,
      'note': note,
      'before_chars': beforeText.length,
      'after_chars': afterText.length,
      'before_lines': lineCount(beforeText),
      'after_lines': lineCount(afterText),
      'changed_line_estimate': changedLineEstimate,
      'preview': preview,
    };
  }

  JsonMap diffPreview(
    String beforeText,
    String afterText, {
    int maxPreviewChanges = RevisionDiffConstants.maxPreviewChanges,
    int maxLineChars = RevisionDiffConstants.maxLineChars,
  }) {
    // 中文注释: 这里生成轻量 diff 预览，不追求完整 LCS，只保留足够判断修复质量的信号。
    final beforeLines = beforeText.split('\n');
    final afterLines = afterText.split('\n');
    final maxCount = beforeLines.length > afterLines.length
        ? beforeLines.length
        : afterLines.length;
    final preview = <String>[];
    var changed = 0;
    for (var index = 0; index < maxCount; index += 1) {
      final oldLine = index < beforeLines.length ? beforeLines[index] : '';
      final newLine = index < afterLines.length ? afterLines[index] : '';
      if (oldLine == newLine) {
        continue;
      }
      changed += 1;
      if (preview.length >= maxPreviewChanges * 3) {
        continue;
      }
      preview.add('@@ line ${index + 1} @@');
      if (index < beforeLines.length) {
        preview.add('- ${clipLine(oldLine, maxLineChars: maxLineChars)}');
      }
      if (index < afterLines.length) {
        preview.add('+ ${clipLine(newLine, maxLineChars: maxLineChars)}');
      }
    }
    if (changed > maxPreviewChanges) {
      preview.add('... ${changed - maxPreviewChanges} more changed line(s)');
    }
    return <String, Object?>{
      'changed_line_estimate': changed,
      'preview': preview.join('\n'),
    };
  }

  String summaryText(List<Object?> pairs) {
    // 中文注释: diff 状态汇总供任务中心与报告顶部使用，让用户一眼看出风险分布。
    var changed = 0;
    var unchanged = 0;
    var noBaseline = 0;
    for (final raw in pairs) {
      final pair = ValueReaders.mapValue(raw);
      switch (ValueReaders.stringValue(pair['status'])) {
        case 'changed':
          changed += 1;
          break;
        case 'unchanged':
          unchanged += 1;
          break;
        case 'no_baseline':
          noBaseline += 1;
          break;
      }
    }
    return '变更 $changed 个，未变更 $unchanged 个，无备份基线 $noBaseline 个。';
  }

  int lineCount(String text) {
    // 中文注释: 行数统计对空文本按 0 处理，避免报告里把空文件误显示成 1 行。
    if (text.isEmpty) {
      return 0;
    }
    return text.split('\n').length;
  }

  String clipLine(
    String value, {
    int maxLineChars = RevisionDiffConstants.maxLineChars,
  }) {
    // 中文注释: 单行过长会撑坏列表与 Markdown 预览，这里统一做长度裁剪。
    final clean = value.replaceAll('\t', '    ');
    if (clean.length <= maxLineChars) {
      return clean;
    }
    return '${clean.substring(0, maxLineChars)}...';
  }
}
