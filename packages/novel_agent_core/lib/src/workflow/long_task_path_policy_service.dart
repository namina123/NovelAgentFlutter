import '../common/value_readers.dart';

class LongTaskPathPolicyService {
  List<String> stringList(Object? rawValue, {bool unique = true}) {
    // 中文注释: 长任务里路径字符串统一转成项目相对路径风格，并在需要时去重。
    final result = <String>[];
    for (final rawItem in ValueReaders.objectList(rawValue)) {
      final text = ValueReaders.stringValue(
        rawItem,
      ).trim().replaceAll('\\', '/');
      if (text.isEmpty) {
        continue;
      }
      if (!unique || !result.contains(text)) {
        result.add(text);
      }
    }
    return result;
  }

  String joinStrings(List<Object?> items, String separator) {
    // 中文注释: 提示事务里大量需要把路径和规则渲染成短串，这里集中处理空值和 trim。
    final parts = <String>[];
    for (final item in items) {
      final text = ValueReaders.stringValue(item).trim();
      if (text.isNotEmpty) {
        parts.add(text);
      }
    }
    return parts.join(separator);
  }

  String safeId(String value, {String fallbackPrefix = 'item'}) {
    // 中文注释: 长任务计划 id、run id 和章节文件名共用同一套安全字符规则。
    var result = value.trim();
    for (final token in const <String>[
      '\\',
      '/',
      ':',
      '*',
      '?',
      '"',
      '<',
      '>',
      '|',
      '\n',
      '\r',
      '\t',
      ' ',
    ]) {
      result = result.replaceAll(token, '_');
    }
    if (result.isEmpty) {
      result = fallbackPrefix;
    }
    if (result.length > 96) {
      result = result.substring(0, 96);
    }
    return result;
  }

  String safeProjectPath(String path) {
    // 中文注释: 事务层只接受项目内相对路径，拒绝绝对路径和越级路径。
    var clean = path.trim().replaceAll('\\', '/');
    while (clean.startsWith('/')) {
      clean = clean.substring(1);
    }
    if (clean.contains('..') || clean.contains(':')) {
      return '';
    }
    return clean;
  }

  List<String> mergePaths(List<Object?> left, List<Object?> right) {
    // 中文注释: 路径合并只保留安全、非空、去重后的相对路径。
    final result = <String>[];
    for (final source in <List<Object?>>[left, right]) {
      for (final rawPath in source) {
        final path = safeProjectPath(ValueReaders.stringValue(rawPath));
        if (path.isNotEmpty && !result.contains(path)) {
          result.add(path);
        }
      }
    }
    return result;
  }
}
