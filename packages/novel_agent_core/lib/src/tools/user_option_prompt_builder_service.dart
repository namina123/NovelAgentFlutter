import '../common/json_types.dart';
import '../common/value_readers.dart';

class UserOptionPromptBuilderService {
  String build(JsonMap option) {
    // 中文注释: 用户点选项后的转述消息在这里统一生成，保证主智能体能把点击当成真实确认继续推进。
    var label = ValueReaders.stringValue(option['label'], '这个选项').trim();
    if (label.isEmpty) {
      label = '这个选项';
    }
    final prompt = ValueReaders.stringValue(option['prompt']).trim();
    final lines = <String>[
      prompt.isNotEmpty ? prompt : '我选择「$label」。',
      '',
      '补充说明：我刚才点击并确认了上一轮选项「$label」。请把这个选择视为已确认的用户决策，继续推进，不要重新让用户选择同一组选项。',
    ];
    final question = ValueReaders.stringValue(
      option['_source_question'],
    ).trim();
    if (question.isNotEmpty) {
      lines.add('上一轮问题：$question');
    }
    final description = ValueReaders.stringValue(option['description']).trim();
    if (description.isNotEmpty) {
      lines.add('所选选项说明：$description');
    }
    final allOptions = _optionsSummary(option['_all_options'], label);
    if (allOptions.isNotEmpty) {
      lines.add('上一轮候选摘要：$allOptions');
    }
    return lines.join('\n').trim();
  }

  String _optionsSummary(Object? rawOptions, String selectedLabel) {
    // 中文注释: 候选摘要用于提醒模型本轮是从哪组可选项里做出的确认，而不是新的开放提问。
    if (rawOptions is! List) {
      return '';
    }
    final parts = <String>[];
    for (final rawOption in rawOptions) {
      final option = ValueReaders.mapValue(rawOption);
      final label = ValueReaders.stringValue(option['label']).trim();
      if (label.isEmpty) {
        continue;
      }
      final description = ValueReaders.stringValue(option['description']).trim();
      final marker = label == selectedLabel ? '已选' : '候选';
      parts.add(
        '$marker：$label${description.isEmpty ? '' : '（$description）'}',
      );
    }
    return parts.join('；');
  }
}
