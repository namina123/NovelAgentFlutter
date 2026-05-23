import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_run_compactor_service.dart';

class SubAgentResultPackageService {
  SubAgentResultPackageService({AgentRunCompactorService? compactorService})
    : _compactorService = compactorService ?? AgentRunCompactorService();

  final AgentRunCompactorService _compactorService;

  String subAgentFinalContent(
    String content, {
    required bool stoppedByToolError,
  }) {
    // 中文注释: 子智能体空回复需要有明确兜底文案，避免主智能体拿到一片空白难以判断。
    final cleanContent = content.trim();
    if (cleanContent.isEmpty && stoppedByToolError) {
      return '子智能体工具执行后未能生成最终回复。';
    }
    return cleanContent;
  }

  JsonMap subAgentSuccessResultPackage({
    required JsonMap package,
    required String task,
    required String content,
    required JsonMap llmResult,
    required List<Object?> executedTools,
  }) {
    // 中文注释: 成功结果返回给主智能体时只保留可合并字段，不把内部状态无限扩散。
    final subSessionId = ValueReaders.stringValue(package['sub_session_id']);
    final resultMarkdown = content.trim();
    return <String, Object?>{
      'ok': true,
      'interaction_type': 'sub_agent_result',
      'strategy': ValueReaders.stringValue(
        package['strategy'],
        'main_with_children',
      ),
      'agent_id': ValueReaders.stringValue(package['agent_id']),
      'agent_name': ValueReaders.stringValue(
        package['agent_name'],
        ValueReaders.stringValue(package['agent_id']),
      ),
      'sub_session_id': subSessionId,
      'continue_session_id': ValueReaders.stringValue(
        package['continue_session_id'],
      ),
      'task': task,
      'result_markdown': resultMarkdown,
      'summary': _compactorService.clipResponseSummary(<String, Object?>{
        'result_markdown': resultMarkdown,
      }),
      'reasoning_content': ValueReaders.stringValue(
        llmResult['reasoning_content'],
      ),
      'tool_calls': ValueReaders.deepCopyList(executedTools),
      'context_policy': ValueReaders.mapValue(package['context_policy']),
      'source_paths': ValueReaders.objectList(package['source_paths']),
      'not_executed': false,
      'sub_session_tag': '<sub_session_id>$subSessionId</sub_session_id>',
    };
  }

  JsonMap subAgentFailureResultPackage({
    required JsonMap package,
    required String errorDetail,
    required List<Object?> executedTools,
    required bool cancelled,
  }) {
    // 中文注释: 失败结果显式标出是否可重试，方便主智能体或宿主继续决定恢复策略。
    var detail = errorDetail.trim();
    if (detail.isEmpty) {
      detail = cancelled
          ? 'Sub-agent run cancelled.'
          : 'Sub-agent model call failed.';
    }
    return <String, Object?>{
      'ok': false,
      'cancelled': cancelled,
      'error': cancelled
          ? 'Sub-agent run cancelled.'
          : 'Sub-agent model call failed: $detail',
      'agent_id': ValueReaders.stringValue(package['agent_id']),
      'agent_name': ValueReaders.stringValue(package['agent_name']),
      'sub_session_id': ValueReaders.stringValue(package['sub_session_id']),
      'continue_session_id': ValueReaders.stringValue(
        package['continue_session_id'],
      ),
      'tool_calls': ValueReaders.deepCopyList(executedTools),
      'retryable': !cancelled,
    };
  }
}
