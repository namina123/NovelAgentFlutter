import '../common/json_types.dart';

class SessionContextSpecializedSectionService {
  const SessionContextSpecializedSectionService();

  List<JsonMap> buildSections(String sessionContext) {
    final normalized = sessionContext.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) {
      return const <JsonMap>[];
    }
    final result = <JsonMap>[];
    final continuityItems = _continuityItems(normalized);
    if (continuityItems.isNotEmpty) {
      result.add(<String, Object?>{
        'id': 'chapter_continuity_gate',
        'title': '章节承接 Gate',
        'priority': 98,
        'pinned': true,
        'content': _continuityContent(continuityItems),
      });
    }
    final executionGateLines = _executionGateLines(normalized);
    if (executionGateLines.isNotEmpty) {
      result.add(<String, Object?>{
        'id': 'chapter_delivery_gate',
        'title': '正式交付 Gate',
        'priority': 97,
        'pinned': true,
        'content': _deliveryGateContent(executionGateLines),
      });
    }
    return List<JsonMap>.unmodifiable(result);
  }

  List<String> _continuityItems(String normalized) {
    final lines = normalized.split('\n');
    final result = <String>[];
    var inBlock = false;
    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      final trimmed = line.trim();
      if (trimmed == '- continuity_checkpoint:' ||
          trimmed == 'continuity_checkpoint:') {
        inBlock = true;
        continue;
      }
      if (inBlock) {
        if (trimmed.isEmpty) {
          continue;
        }
        if (!rawLine.startsWith(' ') && !trimmed.startsWith('- ')) {
          inBlock = false;
        } else {
          final clean = _stripBulletPrefix(trimmed);
          if (clean.isNotEmpty) {
            _addUnique(result, clean);
          }
          continue;
        }
      }
      if (_looksLikeContinuityLine(trimmed)) {
        _addUnique(result, _stripBulletPrefix(trimmed));
      }
    }
    return List<String>.unmodifiable(result);
  }

  List<String> _executionGateLines(String normalized) {
    final lines = normalized.split('\n');
    final result = <String>[];
    var inBlock = false;
    for (final rawLine in lines) {
      final trimmed = rawLine.trim();
      if (trimmed == '## Execution Constraints') {
        inBlock = true;
        continue;
      }
      if (inBlock) {
        if (trimmed.startsWith('## ')) {
          break;
        }
        if (trimmed.startsWith('- 字数约束：') ||
            trimmed.startsWith('- 正式交付 gate：') ||
            trimmed.startsWith('- 表达限制 gate：')) {
          _addUnique(result, trimmed);
        }
      } else if (trimmed.startsWith('- 字数约束：') ||
          trimmed.startsWith('- 正式交付 gate：')) {
        _addUnique(result, trimmed);
      }
    }
    return List<String>.unmodifiable(result);
  }

  String _continuityContent(List<String> items) {
    final lines = <String>[
      '下面是连续章节的 P0 承接输入，不是一般表达风格建议。',
      '连续章节开篇必须直接承接上一章已落定状态；第一段先推进新的回应、动作或结果，再展开场景。',
      '如果上一章末尾已经完成了寻路、敲门、到达、发问、开门或对视，本章不要再从这些动作前重新起步。',
      ...items.map((item) => '- $item'),
    ];
    return lines.join('\n');
  }

  String _deliveryGateContent(List<String> items) {
    final lines = <String>['以下约束在正式章节交付时按硬 gate 执行，不能只在说明里口头满足。', ...items];
    return lines.join('\n');
  }

  bool _looksLikeContinuityLine(String line) {
    return line.contains('下一章必须直接承接：') ||
        line.contains('上一章已完成，不要重演：') ||
        line.contains('当前落点：') ||
        line.contains('开篇先推进到新情节点');
  }

  String _stripBulletPrefix(String line) {
    var result = line.trim();
    if (result.startsWith('- ')) {
      result = result.substring(2).trimLeft();
    }
    return result.trim();
  }

  void _addUnique(List<String> items, String value) {
    final clean = value.trim();
    if (clean.isNotEmpty && !items.contains(clean)) {
      items.add(clean);
    }
  }
}
