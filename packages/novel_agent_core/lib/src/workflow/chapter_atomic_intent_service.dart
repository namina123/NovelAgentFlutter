import '../common/json_types.dart';
import '../common/value_readers.dart';

class ChapterAtomicIntentService {
  String intentForTask(JsonMap task) {
    // 中文注释: 章节原子任务在组装上下文前先收敛意图，避免 ContextAssembler 误走错误的记忆侧重点。
    switch (ValueReaders.stringValue(task['task_type'], 'chapter')) {
      case 'summary':
        return 'summary';
      case 'revision':
        return 'draft';
      case 'review':
        return 'review';
      case 'planning':
        return 'outline';
      case 'checkpoint':
        return 'review';
      case 'world_update':
        return 'setting';
      default:
        return 'draft';
    }
  }
}
