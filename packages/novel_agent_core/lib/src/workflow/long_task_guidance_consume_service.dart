import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_guidance_message_service.dart';

class LongTaskGuidanceConsumeService {
  LongTaskGuidanceConsumeService({
    required LongTaskGuidanceMessageService messageService,
  }) : _messageService = messageService;

  final LongTaskGuidanceMessageService _messageService;

  JsonMap consumeGuidance(
    List<Object?> queue, {
    String scope = 'main_agent',
    String trigger = 'before_next_tool_call',
    String createdAt = '',
    JsonMap taskContext = const <String, Object?>{},
  }) {
    // 中文注释: 消费逻辑只标记本轮可投递的引导，不负责真正把消息塞进宿主会话。
    final nextQueue = ValueReaders.mapList(
      queue,
    ).map(ValueReaders.deepCopyMap).toList(growable: true);
    final delivered = <JsonMap>[];
    final cleanScope = _cleanScope(scope);
    final beforeTool = trigger.trim().toLowerCase() == 'before_next_tool_call';
    final deliveredAt = createdAt.isEmpty
        ? DateTime.now().toIso8601String()
        : createdAt;
    for (var index = 0; index < nextQueue.length; index += 1) {
      final item = nextQueue[index];
      if (!beforeTool || !_deliverableBeforeTool(item, cleanScope)) {
        continue;
      }
      item['status'] = 'delivered';
      item['delivered_at'] = deliveredAt;
      item['delivered_trigger'] = 'before_next_tool_call';
      delivered.add(ValueReaders.deepCopyMap(item));
    }
    return <String, Object?>{
      'ok': true,
      'queue': nextQueue,
      'delivered_guidance': delivered,
      'has_guidance': delivered.isNotEmpty,
      'message': _messageService.injectionMessage(
        delivered,
        taskContext: taskContext,
      ),
    };
  }

  bool _deliverableBeforeTool(JsonMap item, String scope) {
    // 中文注释: 只有主智能体待投递 guidance 会在下次工具调用前注入。
    return ValueReaders.stringValue(item['status'], 'pending') == 'pending' &&
        ValueReaders.stringValue(item['kind'], 'guidance') == 'guidance' &&
        ValueReaders.stringValue(item['scope'], 'main_agent') == scope &&
        scope == 'main_agent';
  }

  String _cleanScope(String scope) {
    // 中文注释: consume 与 append 保持同一套 scope 规范化语义。
    return scope.trim().toLowerCase() == 'sub_agent'
        ? 'sub_agent'
        : 'main_agent';
  }
}
