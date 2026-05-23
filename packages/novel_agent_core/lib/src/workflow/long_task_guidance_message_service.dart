import '../common/json_types.dart';
import '../common/value_readers.dart';

class LongTaskGuidanceMessageService {
  JsonMap injectionMessage(
    List<Object?> deliveredGuidance, {
    JsonMap taskContext = const <String, Object?>{},
  }) {
    // 中文注释: 这里把已投递引导收束成一条可插入主智能体回合的用户消息。
    final guidance = ValueReaders.mapList(deliveredGuidance);
    if (guidance.isEmpty) {
      return <String, Object?>{};
    }

    final lines = <String>[
      '【运行中引导】',
      '用户在当前主智能体流式输出期间补充了以下引导。请在下一次工具调用前重新评估即将执行的动作；如果引导与原计划冲突，优先遵守用户最新意图，并在必要时先解释或提问。',
    ];
    final taskTitle = ValueReaders.stringValue(
      taskContext['task_title'],
      ValueReaders.stringValue(taskContext['title']),
    ).trim();
    if (taskTitle.isNotEmpty) {
      lines.add('当前任务：$taskTitle');
    }
    lines.add('');
    for (var index = 0; index < guidance.length; index += 1) {
      lines.add(
        '${index + 1}. ${ValueReaders.stringValue(guidance[index]['text']).trim()}',
      );
    }
    lines.add('');
    lines.add('注意：这些引导只影响主智能体当前回合，不传递给正在独立运行的子智能体；不要把这段说明原样写入小说正文或项目文件。');
    return <String, Object?>{
      'role': 'user',
      'content': lines.join('\n'),
      'guidance_ids': guidance
          .map((item) => ValueReaders.stringValue(item['id']).trim())
          .where((id) => id.isNotEmpty)
          .toList(growable: false),
      'injection_type': 'stream_guidance',
    };
  }
}
