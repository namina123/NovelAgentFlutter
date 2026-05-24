import '../common/json_types.dart';

class FrontmatterYamlWriterService {
  const FrontmatterYamlWriterService();

  String write(JsonMap metadata) {
    // 中文注释: Frontmatter 输出统一在这里生成，避免各类包渲染器各自手拼 YAML 产生格式漂移。
    final lines = <String>[];
    for (final entry in metadata.entries) {
      _writeValue(lines, entry.key, entry.value, 0);
    }
    return lines.join('\n');
  }

  void _writeValue(List<String> lines, String key, Object? value, int depth) {
    final indent = '  ' * depth;
    if (value is Map<Object?, Object?>) {
      lines.add('$indent$key:');
      for (final nested in value.entries) {
        _writeValue(
          lines,
          nested.key.toString(),
          nested.value,
          depth + 1,
        );
      }
      return;
    }
    if (value is List<Object?>) {
      if (value.isEmpty) {
        lines.add('$indent$key: []');
        return;
      }
      lines.add('$indent$key:');
      for (final item in value) {
        _writeListItem(lines, item, depth + 1);
      }
      return;
    }
    if (value is bool || value is num) {
      lines.add('$indent$key: $value');
      return;
    }
    final text = value?.toString() ?? '';
    if (text.contains('\n')) {
      lines.add('$indent$key: |');
      for (final line in text.split('\n')) {
        lines.add('${'  ' * (depth + 1)}$line');
      }
      return;
    }
    lines.add('$indent$key: ${_quoted(text)}');
  }

  void _writeListItem(List<String> lines, Object? value, int depth) {
    final indent = '  ' * depth;
    if (value is Map<Object?, Object?>) {
      if (value.isEmpty) {
        lines.add('$indent- {}');
        return;
      }
      var first = true;
      for (final entry in value.entries) {
        if (first) {
          final nestedValue = entry.value;
          if (nestedValue is Map<Object?, Object?> || nestedValue is List<Object?>) {
            lines.add('$indent- ${entry.key}:');
            _writeNested(lines, nestedValue, depth + 1);
          } else {
            lines.add('$indent- ${entry.key}: ${_scalarText(nestedValue)}');
          }
          first = false;
          continue;
        }
        _writeValue(lines, entry.key.toString(), entry.value, depth + 1);
      }
      return;
    }
    if (value is List<Object?>) {
      if (value.isEmpty) {
        lines.add('$indent- []');
        return;
      }
      lines.add('$indent-');
      for (final item in value) {
        _writeListItem(lines, item, depth + 1);
      }
      return;
    }
    lines.add('$indent- ${_scalarText(value)}');
  }

  void _writeNested(List<String> lines, Object? value, int depth) {
    if (value is Map<Object?, Object?>) {
      for (final entry in value.entries) {
        _writeValue(lines, entry.key.toString(), entry.value, depth);
      }
      return;
    }
    if (value is List<Object?>) {
      for (final item in value) {
        _writeListItem(lines, item, depth);
      }
    }
  }

  String _scalarText(Object? value) {
    if (value is bool || value is num) {
      return value.toString();
    }
    return _quoted(value?.toString() ?? '');
  }

  String _quoted(String value) {
    final escaped = value.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
    return '"$escaped"';
  }
}
