import 'dart:convert';

import '../common/json_types.dart';
import '../common/value_readers.dart';

class AgentRunCompactorService {
  JsonMap compactToolResultForLlm(
    JsonMap result, {
    int maxTextChars = 1500,
    int maxToolCalls = 8,
  }) {
    // 中文注释: 这里把大结果压缩成下一轮模型还能吃下的摘要，避免把全文和 raw 响应重新灌回上下文。
    final compact = ValueReaders.deepCopyMap(result);
    final textLimit = ValueReaders.stringValue(compact['skill_id']).trim().isNotEmpty
        ? 3200
        : maxTextChars;
    if (ValueReaders.stringValue(compact['interaction_type']).trim() ==
        'agent_tasks') {
      compact['continue_required'] = true;
      if (ValueReaders.stringValue(
        compact['next_instruction'],
      ).trim().isEmpty) {
        compact['next_instruction'] = '任务计划已记录，但这不是最终回答。请继续执行当前步骤。';
      }
    }

    for (final key in const <String>[
      'content',
      'result_markdown',
      'reasoning_content',
      'raw',
      'raw_text',
      'message',
      'instructions',
      'instruction_markdown',
      'reference_content',
    ]) {
      if (!compact.containsKey(key)) {
        continue;
      }
      final value = compact[key];
      if (value is String) {
        compact[key] = _clipText(value, textLimit);
      } else if (value is List || value is Map) {
        compact[key] = _clipText(jsonEncode(value), textLimit);
      }
    }

    final toolCalls = ValueReaders.objectList(compact['tool_calls']);
    if (toolCalls.length > maxToolCalls) {
      compact['tool_calls'] = toolCalls
          .take(maxToolCalls)
          .toList(growable: false);
      compact['tool_calls_omitted'] = toolCalls.length - maxToolCalls;
    }
    return compact;
  }

  String clipResponseSummary(JsonMap response, {int maxChars = 900}) {
    // 中文注释: 最终响应摘要只取正文预览，供记录列表和任务中心轻量展示。
    return _clipText(
      ValueReaders.stringValue(response['result_markdown']).trim(),
      maxChars,
    );
  }

  String _clipText(String value, int maxChars) {
    // 中文注释: 截断时保留可读提示，避免上层把半截 JSON 或正文误当完整结果。
    if (maxChars <= 0) {
      return '';
    }
    if (value.length <= maxChars) {
      return value;
    }
    return '${value.substring(0, maxChars)}\n……（已截断）';
  }
}
