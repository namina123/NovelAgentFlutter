import '../common/json_types.dart';
import '../common/value_readers.dart';

class AgentToolPolicyService {
  bool lastToolWasOnlyPlan(List<Object?> executedTools) {
    // 中文注释: 计划型工具不代表任务已完成，这里集中判断避免宿主误把“列待办”当最终产物。
    if (executedTools.isEmpty) {
      return false;
    }
    var sawPlan = false;
    for (final rawTool in executedTools) {
      final tool = ValueReaders.mapValue(rawTool);
      final name = ValueReaders.stringValue(tool['name']).trim();
      if (name == 'set_agent_tasks') {
        sawPlan = true;
        continue;
      }
      if (name == 'final_response' || name == 'tool_round_limit') {
        continue;
      }
      return false;
    }
    return sawPlan;
  }

  JsonMap afterToolRoundDecision(
    JsonMap nextResult, {
    required bool roundHasPlanTool,
    required bool planContinueRetryUsed,
  }) {
    // 中文注释: 如果模型上一轮只更新计划却没有继续执行，这里发出统一“继续干活”指令。
    if (!roundHasPlanTool || planContinueRetryUsed) {
      return <String, Object?>{
        'retry_after_plan': false,
        'continue_instruction': '',
      };
    }
    final content = ValueReaders.stringValue(nextResult['content']).trim();
    final toolCalls = ValueReaders.objectList(nextResult['tool_calls']);
    if (content.isNotEmpty || toolCalls.isNotEmpty) {
      return <String, Object?>{
        'retry_after_plan': false,
        'continue_instruction': '',
      };
    }
    return <String, Object?>{
      'retry_after_plan': true,
      'continue_instruction':
          '刚才只是更新了执行计划，还没有完成用户任务。请不要停在待办列表；现在继续执行当前步骤，必要时调用读取/写入/修改工具，或给出实质回答。',
    };
  }

  JsonMap finalContentPolicy(
    String content, {
    required bool waitingForUserChoice,
    required List<Object?> executedTools,
    required List<Object?> writtenPaths,
  }) {
    // 中文注释: 最终正文为空时，核心统一给出收口策略，避免不同宿主出现不同的空响应体验。
    final cleanContent = content.trim();
    final hasWrittenPaths = writtenPaths.any(
      (path) => ValueReaders.stringValue(path).trim().isNotEmpty,
    );
    if (waitingForUserChoice && cleanContent.isEmpty) {
      return <String, Object?>{
        'mode': 'waiting_for_user_choice',
        'content': '我需要你先选择一个方向。你也可以忽略按钮，直接输入自己的想法。',
        'path_list': writtenPaths,
      };
    }
    if (cleanContent.isEmpty && lastToolWasOnlyPlan(executedTools)) {
      return <String, Object?>{
        'mode': 'only_plan',
        'content':
            '我已经列出执行计划，但还没有产出实质内容。请直接输入“继续”，我会按当前计划推进；如果你愿意，也可以指出优先处理哪一步。',
        'path_list': writtenPaths,
      };
    }
    if (cleanContent.isEmpty && hasWrittenPaths) {
      return <String, Object?>{
        'mode': 'written_only',
        'content': '',
        'path_list': writtenPaths,
      };
    }
    if (cleanContent.isNotEmpty && hasWrittenPaths) {
      return <String, Object?>{
        'mode': 'append_written_paths',
        'content': cleanContent,
        'path_list': writtenPaths,
      };
    }
    return <String, Object?>{
      'mode': 'content',
      'content': cleanContent,
      'path_list': writtenPaths,
    };
  }
}
