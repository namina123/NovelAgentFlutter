import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_tool_message_service.dart';
import 'agent_tool_round_state_service.dart';
import 'agent_tool_summary_service.dart';

class AgentLoopContractService {
  AgentLoopContractService({
    AgentToolRoundStateService? roundStateService,
    AgentToolMessageService? toolMessageService,
    AgentToolSummaryService? toolSummaryService,
  }) : _roundStateService = roundStateService ?? AgentToolRoundStateService(),
       _toolMessageService = toolMessageService ?? AgentToolMessageService(),
       _toolSummaryService = toolSummaryService ?? AgentToolSummaryService();

  final AgentToolRoundStateService _roundStateService;
  final AgentToolMessageService _toolMessageService;
  final AgentToolSummaryService _toolSummaryService;

  JsonMap loopStepContract(
    JsonMap llmResult,
    List<Object?> toolCalls, {
    required int roundIndex,
    required int maxRounds,
    required bool waitingForUserChoice,
    required bool stoppedByToolError,
  }) {
    // 中文注释: 运行主循环的下一步动作由核心统一决定，这样 GUI 和 CLI 可以共享同一套合同。
    final contract = <String, Object?>{
      'ok': true,
      'round_index': roundIndex,
      'max_rounds': maxRounds,
    };
    if (ValueReaders.boolValue(llmResult['cancelled'])) {
      return <String, Object?>{
        ...contract,
        'action': 'cancel',
        'reason': 'llm_cancelled',
      };
    }
    if (!ValueReaders.boolValue(llmResult['ok'], true)) {
      return <String, Object?>{
        ...contract,
        'action': 'error',
        'reason': 'llm_error',
      };
    }
    if (waitingForUserChoice) {
      return <String, Object?>{
        ...contract,
        'action': 'wait_user',
        'reason': 'waiting_for_user_choice',
      };
    }
    if (stoppedByToolError) {
      return <String, Object?>{
        ...contract,
        'action': 'stop_error',
        'reason': 'tool_error',
      };
    }
    if (toolCalls.isEmpty) {
      return <String, Object?>{
        ...contract,
        'action': 'final_response',
        'reason': 'no_tool_calls',
      };
    }
    if (maxRounds >= 0 && roundIndex >= maxRounds) {
      return <String, Object?>{
        ...contract,
        'action': 'tool_round_limit',
        'reason': 'max_rounds_reached',
        'limit_summary': _toolSummaryService.toolRoundLimitSummary(maxRounds),
      };
    }
    return <String, Object?>{
      ...contract,
      'action': 'execute_tools',
      'reason': 'model_requested_tools',
      'round_state': _roundStateService.toolRoundState(toolCalls),
      'assistant_message': _toolMessageService.assistantToolCallMessage(
        llmResult,
        toolCalls,
      ),
      'tool_calls': ValueReaders.deepCopyList(toolCalls),
    };
  }
}
