import '../common/json_types.dart';
import '../common/value_readers.dart';

class LongTaskGuidanceAppendService {
  JsonMap appendGuidance(
    List<Object?> queue,
    String text, {
    String kind = 'guidance',
    String scope = 'main_agent',
    String createdAt = '',
    int sequenceId = 0,
  }) {
    // 中文注释: 运行中引导只在队列层追加事件，不直接碰会话消息或宿主状态。
    final cleanText = text.trim();
    final nextQueue = _duplicateQueue(queue);
    if (cleanText.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Guidance text is empty.',
        'queue': nextQueue,
      };
    }

    final cleanKind = _cleanKind(kind);
    final nextSequence = sequenceId > 0 ? sequenceId : nextQueue.length + 1;
    final item = <String, Object?>{
      'id': 'guidance_${nextSequence.toString().padLeft(4, '0')}',
      'sequence': nextSequence,
      'kind': cleanKind,
      'scope': _cleanScope(scope),
      'delivery': cleanKind == 'guidance'
          ? 'before_next_tool_call'
          : 'next_model_turn',
      'text': cleanText,
      'status': 'pending',
      'created_at': createdAt.isEmpty
          ? DateTime.now().toIso8601String()
          : createdAt,
    };
    nextQueue.add(item);
    return <String, Object?>{
      'ok': true,
      'queue': nextQueue,
      'event': item,
      'pending_count': nextQueue.length,
    };
  }

  List<JsonMap> _duplicateQueue(List<Object?> queue) {
    // 中文注释: 引导队列需要与外部引用隔离，避免 UI 修改返回值后污染 record。
    return ValueReaders.mapList(queue).map(ValueReaders.deepCopyMap).toList();
  }

  String _cleanKind(String kind) {
    // 中文注释: 目前只保留 guidance 和 normal_note 两种种类，其他值统一回退。
    final value = kind.trim().toLowerCase();
    if (value == 'normal_note' || value == 'note') {
      return 'normal_note';
    }
    return 'guidance';
  }

  String _cleanScope(String scope) {
    // 中文注释: 运行中引导默认只作用于主智能体，避免误传给子智能体。
    return scope.trim().toLowerCase() == 'sub_agent'
        ? 'sub_agent'
        : 'main_agent';
  }
}
