import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_run_compactor_service.dart';

class AgentToolSummaryService {
  AgentToolSummaryService({AgentRunCompactorService? compactorService})
    : _compactorService = compactorService ?? AgentRunCompactorService();

  final AgentRunCompactorService _compactorService;

  JsonMap toolExecutionSummary(
    JsonMap call,
    JsonMap result,
    String displayText,
  ) {
    // 中文注释: 工具执行摘要供运行记录和消息回放复用，因此只保留稳定的审计字段。
    return <String, Object?>{
      'name': ValueReaders.stringValue(call['name']),
      'reason': '模型请求执行工具。',
      'status': ValueReaders.boolValue(result['ok']) ? 'ok' : 'failed',
      'display_text': displayText,
      'result': _compactorService.compactToolResultForLlm(result),
    };
  }

  JsonMap failureToolSummary(
    String name,
    String reason,
    String detail,
    JsonMap result,
  ) {
    // 中文注释: 失败摘要统一在这里包装，避免宿主各处手写不同字段名。
    final cleanName = name.trim().isEmpty ? 'final_response' : name.trim();
    final cleanReason = reason.trim();
    final cleanDetail = detail.trim();
    return <String, Object?>{
      'name': cleanName,
      'reason': cleanReason,
      'status': 'failed',
      'display_text': cleanDetail.isEmpty
          ? cleanReason
          : '$cleanReason：$cleanDetail',
      'result': ValueReaders.deepCopyMap(result),
    };
  }

  JsonMap toolRoundLimitSummary(int maxRounds) {
    // 中文注释: 工具轮次上限是运行时保护规则，这里生成统一失败描述供 UI 和 CLI 直接展示。
    return <String, Object?>{
      'name': 'tool_round_limit',
      'reason': '模型连续请求工具过多。',
      'status': 'failed',
      'display_text': '工具调用轮次已达到上限（$maxRounds 轮），已停止继续执行。',
      'result': <String, Object?>{
        'ok': false,
        'error': 'Tool round limit reached.',
      },
    };
  }
}
