import '../common/json_types.dart';
import '../common/value_readers.dart';

class LongTaskTaskSummaryService {
  JsonMap taskSummary(JsonMap task) {
    // 中文注释: 长任务运行记录只保留任务摘要快照，避免把完整任务对象反复复制进 record。
    final metadata = ValueReaders.mapValue(task['metadata']);
    return <String, Object?>{
      'id': ValueReaders.stringValue(task['id']),
      'title': ValueReaders.stringValue(task['title']),
      'task_type': ValueReaders.stringValue(task['task_type']),
      'mode': ValueReaders.stringValue(task['mode']),
      'status': ValueReaders.stringValue(task['status']),
      'depends_on': ValueReaders.stringList(task['depends_on']),
      'output_paths': ValueReaders.stringList(task['output_paths']),
      'sort_order': ValueReaders.intValue(metadata['sort_order']),
      'relative_path': ValueReaders.stringValue(task['relative_path']),
    };
  }
}
