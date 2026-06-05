import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_mode_service.dart';
import 'long_task_path_policy_service.dart';
import 'task_runtime_constants.dart';

class LongTaskTransactionContextService {
  LongTaskTransactionContextService({
    required LongTaskModeService modeService,
    required LongTaskPathPolicyService pathPolicyService,
  }) : _modeService = modeService,
       _pathPolicyService = pathPolicyService;

  final LongTaskModeService _modeService;
  final LongTaskPathPolicyService _pathPolicyService;

  String roleForTask(JsonMap task, {String runMode = ''}) {
    // 中文注释: 事务角色标签是提示工程的一部分，只表达“这一轮以什么视角工作”。
    final taskType = ValueReaders.stringValue(task['task_type'], 'chapter');
    final metadata = ValueReaders.mapValue(task['metadata']);
    final mode = _modeService.normalizeMode(
      ValueReaders.stringValue(
        task['mode'],
        runMode.isEmpty
            ? ValueReaders.stringValue(metadata['workflow_mode'])
            : runMode,
      ),
    );
    if (taskType == 'planning') {
      return 'planner';
    }
    if (taskType == 'review') {
      return 'reviewer';
    }
    if (taskType == 'revision') {
      return 'editor';
    }
    if (taskType == 'checkpoint') {
      return 'checkpoint_presenter';
    }
    if (mode == TaskRuntimeConstants.modeSeedToFullNovel &&
        ValueReaders.stringValue(metadata['stage']) == 'sample') {
      return 'sample_writer';
    }
    return 'chapter_writer';
  }

  List<String> commonContextNeeds(JsonMap task) {
    // 中文注释: 上下文读取策略是提示事务的核心，先在这里按任务类型和模式生成共享规则。
    final taskType = ValueReaders.stringValue(task['task_type'], 'chapter');
    final mode = _modeService.normalizeMode(
      ValueReaders.stringValue(task['mode']),
    );
    final metadata = ValueReaders.mapValue(task['metadata']);
    final needs = <String>[];
    _addUnique(needs, '先读取任务 source_paths 中明确列出的文件。');
    final persistentPaths = _pathPolicyService.stringList(
      metadata['persistent_context_paths'],
    );
    if (persistentPaths.isNotEmpty) {
      _addUnique(needs, '把长期约束路径中的风格、世界、角色与模式摘要视为持续硬约束；除非用户明确改动，否则不要自行漂移。');
    }
    _addUnique(
      needs,
      '需要时读取 specs/project_spec.md、styles/、knowledge/ 等只读信息投影和相关人物/世界状态；长期事实仍以结构化 information/continuity 合同为准。',
    );
    if (taskType == 'chapter') {
      _addUnique(needs, '读取 summaries/ 中与本章相邻或最近的章节摘要，避免遗忘前文状态。');
      _addUnique(needs, '优先读取上一章正文或草稿；长篇模式下只取必要窗口，不要把整部作品塞入上下文。');
    }
    if (mode == TaskRuntimeConstants.modeHumanOutlineAiDraft) {
      _addUnique(needs, '用户大纲是硬约束；如果章节要求冲突，先询问或提出选项，不要擅自改大纲。');
    } else if (mode == TaskRuntimeConstants.modeSupervisedChapterQueue) {
      _addUnique(needs, '每次推进少量章节，遇到走向、设定或质量不确定时停在检查点。');
    } else if (mode == TaskRuntimeConstants.modeSeedToFullNovel) {
      _addUnique(needs, '先确认项目规格、总纲和章节任务清单存在且可用；缺失时先补规划，不要硬写正文。');
      if (ValueReaders.stringValue(metadata['stage']) == 'sample') {
        _addUnique(needs, '这是样章验证：重点证明口吻、节奏、入口和世界观展示方式是否成立。');
      }
    }
    return needs;
  }

  List<String> revisionTargets(JsonMap task, List<Object?> outputPaths) {
    // 中文注释: 修订任务只把真正可编辑的目标文件暴露给后处理，不把报告和备份混进去。
    final candidates = _pathPolicyService.mergePaths(
      ValueReaders.stringList(task['output_paths']),
      outputPaths,
    );
    final result = <String>[];
    for (final clean in candidates) {
      final root = clean.split('/').first;
      if (const <String>{
        'reviews',
        'tracking',
        'runs',
        'tasks',
        'backups',
        'exports',
        'sessions',
      }.contains(root)) {
        continue;
      }
      if (!result.contains(clean)) {
        result.add(clean);
      }
    }
    return result;
  }

  String originalReviewPath(JsonMap task) {
    // 中文注释: 修订任务优先从 metadata 找原审稿报告路径，找不到再从 source_paths 兜底。
    final metadata = ValueReaders.mapValue(task['metadata']);
    final path = _pathPolicyService.safeProjectPath(
      ValueReaders.stringValue(metadata['review_report_path']),
    );
    if (path.isNotEmpty) {
      return path;
    }
    for (final source in _pathPolicyService.stringList(task['source_paths'])) {
      if (source.startsWith('reviews/')) {
        return source;
      }
    }
    return '';
  }

  void addUnique(List<String> items, String value) {
    // 中文注释: 给其他事务服务暴露一个统一去重入口，避免重复写字符串集合逻辑。
    _addUnique(items, value);
  }

  void _addUnique(List<String> items, String value) {
    // 中文注释: 这里保持顺序去重，方便提示渲染时按规则优先级展示。
    final clean = value.trim();
    if (clean.isNotEmpty && !items.contains(clean)) {
      items.add(clean);
    }
  }
}
