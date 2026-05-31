import '../common/json_types.dart';

class ChapterLengthRecord {
  const ChapterLengthRecord({
    required this.length,
    required this.sortOrder,
    this.taskId = '',
    this.title = '',
    this.relativePath = '',
  });

  final int length;
  final int sortOrder;
  final String taskId;
  final String title;
  final String relativePath;

  JsonMap toJson() {
    // 中文注释: 长度记录是纯统计样本，不承担项目真相，只服务于分布评估。
    return <String, Object?>{
      'length': length,
      'sort_order': sortOrder,
      'task_id': taskId,
      'title': title,
      'relative_path': relativePath,
    };
  }
}
