import '../common/json_types.dart';
import '../common/value_readers.dart';

class AgentToolRoundStateService {
  JsonMap toolRoundState(List<Object?> toolCalls) {
    // 中文注释: 这里统一汇总一轮工具调用状态，宿主无需再到处扫描工具名判断语义。
    final toolNames = <String>[];
    var hasPlanTool = false;
    var toolCount = 0;
    for (final rawCall in toolCalls) {
      final call = ValueReaders.mapValue(rawCall);
      final name = ValueReaders.stringValue(call['name']).trim();
      if (name.isEmpty) {
        continue;
      }
      toolNames.add(name);
      toolCount += 1;
      if (name == 'set_agent_tasks') {
        hasPlanTool = true;
      }
    }
    return <String, Object?>{
      'tool_count': toolCount,
      'has_tool_calls': toolCount > 0,
      'has_plan_tool': hasPlanTool,
      'tool_names': toolNames,
    };
  }
}
