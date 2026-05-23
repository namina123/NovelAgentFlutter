import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_path_policy_service.dart';

class LongTaskRunPathService {
  LongTaskRunPathService({required LongTaskPathPolicyService pathPolicyService})
    : _pathPolicyService = pathPolicyService;

  final LongTaskPathPolicyService _pathPolicyService;

  JsonMap buildPaths(String runId, {String root = 'tracking/long_task_runs'}) {
    // 中文注释: 运行记录路径只是纯字符串约定，让 GUI/CLI/adapter 可以共用同一命名规则。
    final safeRunId = _pathPolicyService.safeId(
      runId,
      fallbackPrefix: 'long_task_run',
    );
    final cleanRoot = _normalizeRoot(root);
    return <String, Object?>{
      'run_id': safeRunId,
      'relative_path': '$cleanRoot/$safeRunId.json',
      'summary_path': '$cleanRoot/$safeRunId.md',
    };
  }

  String taskPathForNewTask(JsonMap task) {
    // 中文注释: 动态新增任务若未带 relative_path，就按任务 id 生成一个稳定路径。
    final relativePath = ValueReaders.stringValue(task['relative_path']).trim();
    if (relativePath.startsWith('tasks/') &&
        relativePath.toLowerCase().endsWith('.json')) {
      return relativePath;
    }
    final taskId = _pathPolicyService.safeId(
      ValueReaders.stringValue(
        task['id'],
        'task_${DateTime.now().microsecondsSinceEpoch}',
      ),
      fallbackPrefix: 'task',
    );
    return 'tasks/$taskId.json';
  }

  String _normalizeRoot(String root) {
    // 中文注释: 根目录统一转成项目相对路径风格，避免宿主各自拼出不同斜杠格式。
    final clean = root.trim().replaceAll('\\', '/');
    return clean.isEmpty ? 'tracking/long_task_runs' : clean;
  }
}
