import '../common/json_types.dart';
import '../common/value_readers.dart';

class AgentResponsePackageService {
  JsonMap runResponsePackage({
    required JsonMap agent,
    required JsonMap provider,
    required String intent,
    required String content,
    required JsonMap llmResult,
    required List<Object?> executedTools,
    required JsonMap contextPack,
    required int totalToolCalls,
    required bool waitingForUserChoice,
    required String runId,
    required String createdAt,
  }) {
    // 中文注释: 主智能体运行结果在这里统一包装，方便 GUI/CLI 共用同一份响应字段协议。
    final agentId = ValueReaders.stringValue(agent['id'], 'default_generalist');
    final agentName = ValueReaders.stringValue(agent['name'], '综合创作智能体');
    return <String, Object?>{
      'id': runId,
      'agent_id': agentId,
      'agent_name': agentName,
      'provider': ValueReaders.deepCopyMap(provider),
      'intent': intent,
      'thought_summary': '真实模型已返回。内容类型判断：$intent。工具调用数：$totalToolCalls。',
      'result_markdown': content.trim(),
      'reasoning_content': ValueReaders.stringValue(
        llmResult['reasoning_content'],
      ),
      'chapter_markdown': '',
      'tool_calls': ValueReaders.deepCopyList(executedTools),
      'sub_agent_calls': <Object?>[],
      'waiting_for_user_choice': waitingForUserChoice,
      'context_pack_id': ValueReaders.stringValue(contextPack['id']),
      'context_pack_summary': ValueReaders.stringValue(contextPack['summary']),
      'prompt_preview_markdown': ValueReaders.stringValue(
        contextPack['prompt_preview_markdown'],
      ),
      'created_at': createdAt,
    };
  }

  JsonMap errorResponsePackage({
    required JsonMap agent,
    required JsonMap provider,
    required String summary,
    required String detail,
    required String intent,
    required String responseId,
    required String createdAt,
  }) {
    // 中文注释: 错误响应也走同一出口，保证上层总能拿到稳定的 agent/provider 基本信息。
    return <String, Object?>{
      'id': responseId,
      'agent_id': ValueReaders.stringValue(agent['id'], 'default_generalist'),
      'agent_name': ValueReaders.stringValue(agent['name'], '综合创作智能体'),
      'provider': ValueReaders.deepCopyMap(provider),
      'intent': intent,
      'is_error': true,
      'error_summary': summary,
      'error_detail': detail,
      'thought_summary': '',
      'result_markdown': '',
      'reasoning_content': '',
      'chapter_markdown': '',
      'tool_calls': <Object?>[],
      'sub_agent_calls': <Object?>[],
      'created_at': createdAt,
    };
  }
}
