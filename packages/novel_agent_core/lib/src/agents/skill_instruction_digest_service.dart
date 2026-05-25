import '../common/json_types.dart';
import '../common/value_readers.dart';

class SkillInstructionDigestService {
  const SkillInstructionDigestService();

  String buildDigest(JsonMap skill, {int maxChars = 2400}) {
    // 中文注释: 默认只返回技能执行摘要，避免整份超长技能正文直接塞满上下文。
    final lines = <String>[
      '技能名称：${ValueReaders.stringValue(skill["name"], ValueReaders.stringValue(skill["id"]))}',
      '用途：${ValueReaders.stringValue(skill["description"])}',
    ];
    _appendList(lines, '适用时机', skill['activation_hints'], limit: 4);
    _appendList(lines, '输入', skill['inputs'], limit: 4);
    _appendList(lines, '输出', skill['outputs'], limit: 4);
    _appendList(lines, '必需能力', skill['required_capabilities'], limit: 4);
    _appendList(lines, '可选能力', skill['optional_capabilities'], limit: 4);
    final preferredOutput = ValueReaders.stringValue(
      skill['preferred_output'],
    ).trim();
    if (preferredOutput.isNotEmpty) {
      lines.add('优先输出：$preferredOutput');
    }
    final executionHints = _extractExecutionHints(
      ValueReaders.stringValue(skill['instruction_markdown']),
    );
    if (executionHints.isNotEmpty) {
      lines
        ..add('执行摘要：')
        ..add(executionHints);
    }
    final joined = lines.join('\n');
    if (joined.length <= maxChars) {
      return joined;
    }
    return '${joined.substring(0, maxChars - 3)}...';
  }

  void _appendList(
    List<String> lines,
    String label,
    Object? rawValue, {
    required int limit,
  }) {
    final items = ValueReaders.stringList(rawValue)
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(limit)
        .toList(growable: false);
    if (items.isNotEmpty) {
      lines.add('$label：${items.join('；')}');
    }
  }

  String _extractExecutionHints(String markdown) {
    // 中文注释: 这里只抓技能正文里最靠前、最像执行指南的若干行，不做重型语义解析。
    final normalized = markdown.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    final kept = <String>[];
    var bulletCount = 0;
    for (final line in lines) {
      final text = line.trim();
      if (text.isEmpty || text.startsWith('# ')) {
        continue;
      }
      if (text.startsWith('## ') &&
          (text.contains('Overview') ||
              text.contains('When to Use') ||
              text.contains('Hard Rules') ||
              text.contains('Execution') ||
              text.contains('Workflow') ||
              text.contains('Compatibility'))) {
        kept.add(text.replaceFirst('## ', ''));
        continue;
      }
      if (text.startsWith('- ') || RegExp(r'^\d+\.\s').hasMatch(text)) {
        kept.add(text);
        bulletCount += 1;
        if (bulletCount >= 8) {
          break;
        }
        continue;
      }
      if (kept.length < 5) {
        kept.add(text);
      }
    }
    return kept.join('\n').trim();
  }
}
