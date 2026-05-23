import '../common/json_types.dart';

class FrontmatterMetadataReaderService {
  JsonMap readMetadata(String markdown) {
    // 中文注释: 这里读取标准 YAML frontmatter，给技能包和智能体包提供更稳定的元数据入口。
    final lines = markdown
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    if (lines.isEmpty || lines.first.trim() != '---') {
      return <String, Object?>{};
    }
    var endIndex = -1;
    for (var index = 1; index < lines.length; index++) {
      if (lines[index].trim() == '---') {
        endIndex = index;
        break;
      }
    }
    if (endIndex <= 0) {
      return <String, Object?>{};
    }
    return _parseYamlLines(lines.sublist(1, endIndex));
  }

  String removeMetadataBlock(String markdown) {
    // 中文注释: 去掉 frontmatter 后保留正文，便于技能说明继续按 Markdown 正文解析。
    final lines = markdown
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    if (lines.isEmpty || lines.first.trim() != '---') {
      return markdown.trim();
    }
    for (var index = 1; index < lines.length; index++) {
      if (lines[index].trim() == '---') {
        return lines.sublist(index + 1).join('\n').trim();
      }
    }
    return markdown.trim();
  }

  JsonMap _parseYamlLines(List<String> lines) {
    // 中文注释: 当前只支持技能包需要的轻量 YAML 子集，避免为了少量元数据提前引入更重依赖。
    final result = <String, Object?>{};
    var index = 0;
    while (index < lines.length) {
      final line = lines[index];
      if (line.trim().isEmpty || line.trimLeft().startsWith('#')) {
        index += 1;
        continue;
      }
      final indent = _indentCount(line);
      if (indent != 0) {
        index += 1;
        continue;
      }
      final separator = line.indexOf(':');
      if (separator <= 0) {
        index += 1;
        continue;
      }
      final key = line.substring(0, separator).trim();
      final rawValue = line.substring(separator + 1).trim();
      if (rawValue.isNotEmpty) {
        result[key] = _parseScalar(rawValue);
        index += 1;
        continue;
      }
      final blockStart = index + 1;
      final blockEnd = _blockEnd(lines, blockStart, minIndent: 2);
      final blockLines = lines.sublist(blockStart, blockEnd);
      if (_isListBlock(blockLines, indent: 2)) {
        result[key] = _parseListBlock(blockLines, indent: 2);
      } else {
        result[key] = _parseMapBlock(blockLines, indent: 2);
      }
      index = blockEnd;
    }
    return result;
  }

  Map<String, Object?> _parseMapBlock(
    List<String> lines, {
    required int indent,
  }) {
    // 中文注释: frontmatter 中的资源提示和能力分组会走到这里，当前支持一层嵌套 map 和 list。
    final result = <String, Object?>{};
    var index = 0;
    while (index < lines.length) {
      final line = lines[index];
      if (line.trim().isEmpty) {
        index += 1;
        continue;
      }
      if (_indentCount(line) < indent) {
        index += 1;
        continue;
      }
      final trimmed = line.substring(indent);
      final separator = trimmed.indexOf(':');
      if (separator <= 0) {
        index += 1;
        continue;
      }
      final key = trimmed.substring(0, separator).trim();
      final rawValue = trimmed.substring(separator + 1).trim();
      if (rawValue.isNotEmpty) {
        result[key] = _parseScalar(rawValue);
        index += 1;
        continue;
      }
      final blockStart = index + 1;
      final blockEnd = _blockEnd(lines, blockStart, minIndent: indent + 2);
      final blockLines = lines.sublist(blockStart, blockEnd);
      if (_isListBlock(blockLines, indent: indent + 2)) {
        result[key] = _parseListBlock(blockLines, indent: indent + 2);
      } else {
        result[key] = _parseMapBlock(blockLines, indent: indent + 2);
      }
      index = blockEnd;
    }
    return result;
  }

  List<Object?> _parseListBlock(List<String> lines, {required int indent}) {
    // 中文注释: 列表项允许简单标量，已经足够覆盖 tags、activation_hints 和 capability 列表。
    final result = <Object?>[];
    for (final line in lines) {
      if (line.trim().isEmpty || _indentCount(line) < indent) {
        continue;
      }
      final trimmed = line.substring(indent).trim();
      if (!trimmed.startsWith('- ')) {
        continue;
      }
      result.add(_parseScalar(trimmed.substring(2).trim()));
    }
    return result;
  }

  bool _isListBlock(List<String> lines, {required int indent}) {
    for (final line in lines) {
      if (line.trim().isEmpty) {
        continue;
      }
      if (_indentCount(line) < indent) {
        continue;
      }
      return line.substring(indent).trim().startsWith('- ');
    }
    return false;
  }

  int _blockEnd(List<String> lines, int startIndex, {required int minIndent}) {
    for (var index = startIndex; index < lines.length; index++) {
      final line = lines[index];
      if (line.trim().isEmpty) {
        continue;
      }
      if (_indentCount(line) < minIndent) {
        return index;
      }
    }
    return lines.length;
  }

  Object? _parseScalar(String rawValue) {
    // 中文注释: 标量解析集中处理布尔、数字、引号字符串和单行数组，便于后续 parser 直接复用。
    final trimmed = rawValue.trim();
    if (trimmed == 'true') {
      return true;
    }
    if (trimmed == 'false') {
      return false;
    }
    if (trimmed == 'null') {
      return null;
    }
    if ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
        (trimmed.startsWith("'") && trimmed.endsWith("'"))) {
      return trimmed.substring(1, trimmed.length - 1);
    }
    final intValue = int.tryParse(trimmed);
    if (intValue != null) {
      return intValue;
    }
    final doubleValue = double.tryParse(trimmed);
    if (doubleValue != null) {
      return doubleValue;
    }
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      final body = trimmed.substring(1, trimmed.length - 1).trim();
      if (body.isEmpty) {
        return const <Object?>[];
      }
      return body
          .split(',')
          .map((item) => _parseScalar(item.trim()))
          .toList(growable: false);
    }
    return trimmed;
  }

  int _indentCount(String line) {
    var count = 0;
    while (count < line.length && line[count] == ' ') {
      count += 1;
    }
    return count;
  }
}
