import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_checkpoint_drift_signal_service.dart';
import 'long_task_task_summary_service.dart';
import 'task_runtime_constants.dart';

class LongTaskCheckpointReviewService {
  LongTaskCheckpointReviewService({
    required LongTaskTaskSummaryService taskSummaryService,
    LongTaskCheckpointDriftSignalService? driftSignalService,
  }) : _taskSummaryService = taskSummaryService,
       _driftSignalService =
           driftSignalService ?? LongTaskCheckpointDriftSignalService();

  final LongTaskTaskSummaryService _taskSummaryService;
  final LongTaskCheckpointDriftSignalService _driftSignalService;

  JsonMap buildReview({
    required JsonMap task,
    required JsonMap result,
    required List<JsonMap> memorySections,
    List<String> outputPaths = const <String>[],
    JsonMap execution = const <String, Object?>{},
    String createdAt = '',
  }) {
    // 中文注释: 该服务把当前单步结果压成“给人复盘、给系统继续判断”的检查点合同，不触碰存储。
    final taskSummary = _taskSummaryService.taskSummary(task);
    final metadata = ValueReaders.mapValue(task['metadata']);
    final mode = ValueReaders.stringValue(
      task['mode'],
      ValueReaders.stringValue(taskSummary['mode']),
    );
    final taskType = ValueReaders.stringValue(
      task['task_type'],
      ValueReaders.stringValue(taskSummary['task_type']),
    );
    final stage = ValueReaders.stringValue(metadata['stage']);
    final cleanOutputs = _mergePaths(
      ValueReaders.stringList(task['output_paths']),
      outputPaths,
    );
    final confirmationFocus = _confirmationFocus(
      taskType: taskType,
      stage: stage,
      outputPaths: cleanOutputs,
    );
    final driftSignals = _driftSignalService.buildSignals(
      taskType: taskType,
      stage: stage,
      memorySections: memorySections,
      outputPaths: cleanOutputs,
    );
    final driftWatchItems = _driftWatchItems(
      taskType: taskType,
      stage: stage,
      driftSignals: driftSignals,
    );
    final nextActions = _nextActions(
      taskType: taskType,
      stage: stage,
      mode: mode,
      outputPaths: cleanOutputs,
      result: result,
    );
    final now = createdAt.isEmpty
        ? DateTime.now().toIso8601String()
        : createdAt;
    return <String, Object?>{
      'schema_version': 1,
      'kind': 'long_task_checkpoint_review',
      'id':
          'checkpoint_review_${ValueReaders.stringValue(task['id'], 'task')}_${DateTime.now().microsecondsSinceEpoch}',
      'task': taskSummary,
      'mode': mode,
      'task_type': taskType,
      'stage': stage,
      'summary': _summary(task, cleanOutputs, confirmationFocus),
      'persistent_context_paths': ValueReaders.stringList(
        metadata['persistent_context_paths'],
      ),
      'memory_section_titles': memorySections
          .map((section) => ValueReaders.stringValue(section['title']))
          .where((title) => title.trim().isNotEmpty)
          .toList(growable: false),
      'confirmation_focus': confirmationFocus,
      'drift_signals': driftSignals,
      'drift_watch_items': driftWatchItems,
      'next_actions': nextActions,
      'output_paths': cleanOutputs,
      'tool_names': _toolNames(result),
      'changed_paths': ValueReaders.stringList(result['changed_paths']),
      'result_ok': ValueReaders.boolValue(result['ok']),
      'error': ValueReaders.stringValue(result['error']),
      'response_preview': _responsePreview(result),
      'context_pack_summary': ValueReaders.stringValue(
        ValueReaders.mapValue(result['response'])['context_pack_summary'],
        ValueReaders.stringValue(execution['context_pack_summary']),
      ),
      'created_at': now,
    };
  }

  String _summary(
    JsonMap task,
    List<String> outputPaths,
    List<String> confirmationFocus,
  ) {
    final title = ValueReaders.stringValue(task['title'], '当前任务');
    final outputText = outputPaths.isEmpty
        ? '尚未写出文件'
        : '已产出 ${outputPaths.length} 个关键路径';
    final focusText = confirmationFocus.isEmpty
        ? '建议继续人工确认。'
        : '当前最该确认：${confirmationFocus.first}';
    return '$title 已结束当前单步，$outputText。$focusText';
  }

  List<String> _confirmationFocus({
    required String taskType,
    required String stage,
    required List<String> outputPaths,
  }) {
    final items = <String>[];
    if (taskType == 'planning') {
      items.add('规划是否已经真正落成总纲、规格或章纲文件，而不是停留在讨论。');
      items.add('当前规划是否足够支撑下一阶段执行，不足处是否已显式转成任务。');
    } else if (taskType == 'chapter') {
      items.add('本轮产出的正文或样章是否保持了既定口吻、节奏和冲突推进。');
      items.add('新内容是否和既有世界规则、角色动机、前文状态保持一致。');
      if (stage == 'sample') {
        items.add('样章入口是否成立，是否能证明题材钩子和叙事方式可持续。');
      }
    } else if (taskType == 'checkpoint') {
      items.add('是否可以确认当前节点完成，并放行后续队列继续推进。');
    } else {
      items.add('这一单步的结果是否满足当前任务目标。');
    }
    if (outputPaths.isEmpty) {
      items.add('如果没有实际产物文件，需要判断是否应继续补写还是退回规划。');
    }
    return items;
  }

  List<String> _driftWatchItems({
    required String taskType,
    required String stage,
    required List<JsonMap> driftSignals,
  }) {
    final items = <String>[];
    for (final signal in driftSignals) {
      final note = ValueReaders.stringValue(signal['note']).trim();
      if (note.isNotEmpty && !items.contains(note)) {
        items.add(note);
      }
    }
    if (taskType == 'planning') {
      items.add('检查规划是否擅自扩大承诺，或把未确认脑洞写成硬设定。');
    }
    if (taskType == 'chapter' && stage == 'sample') {
      items.add('样章阶段重点防止世界观灌输过重或叙事入口失衡。');
    }
    if (items.isEmpty) {
      items.add('检查当前结果是否偏离长期约束与任务目标。');
    }
    return items;
  }

  List<String> _nextActions({
    required String taskType,
    required String stage,
    required String mode,
    required List<String> outputPaths,
    required JsonMap result,
  }) {
    final items = <String>[];
    if (!ValueReaders.boolValue(result['ok'])) {
      items.add('先处理当前错误，再决定是否重试本任务。');
      return items;
    }
    if (taskType == 'planning') {
      items.add('优先检查总纲、规格和章纲文件，再决定是否放行样章或正文任务。');
    } else if (taskType == 'chapter' && stage == 'sample') {
      items.add('样章通过后，确认是否继续正文队列或先修订风格与大纲。');
    } else if (taskType == 'chapter') {
      items.add('确认本章结果后，可继续下一章或进入后处理 / 连续性检查。');
    } else if (taskType == 'checkpoint') {
      items.add('确认当前检查点后，可继续后续队列或插入修订 / 额外规划任务。');
    }
    if (mode == TaskRuntimeConstants.modeSeedToFullNovel) {
      items.add('继续推进时仍需把模式摘要、风格、世界和角色锚点视为硬约束。');
    }
    if (outputPaths.isNotEmpty) {
      items.add('先审阅本轮实际写出的文件，再决定是否标记任务完成。');
    }
    return items;
  }

  String _responsePreview(JsonMap result) {
    final response = ValueReaders.mapValue(result['response']);
    final content = ValueReaders.stringValue(response['content']).trim();
    if (content.isEmpty) {
      return '';
    }
    if (content.length <= 280) {
      return content;
    }
    return '${content.substring(0, 280)}...';
  }

  List<String> _toolNames(JsonMap result) {
    final tools = <String>[];
    for (final rawTool in ValueReaders.objectList(result['executed_tools'])) {
      final tool = ValueReaders.mapValue(rawTool);
      final name = ValueReaders.stringValue(tool['name']).trim();
      if (name.isNotEmpty && !tools.contains(name)) {
        tools.add(name);
      }
    }
    final responseTools = ValueReaders.objectList(
      ValueReaders.mapValue(result['response'])['tool_calls'],
    );
    for (final rawTool in responseTools) {
      final tool = ValueReaders.mapValue(rawTool);
      final name = ValueReaders.stringValue(tool['name']).trim();
      if (name.isNotEmpty && !tools.contains(name)) {
        tools.add(name);
      }
    }
    return tools;
  }

  List<String> _mergePaths(List<String> left, List<String> right) {
    final result = <String>[...left];
    for (final item in right) {
      if (!result.contains(item)) {
        result.add(item);
      }
    }
    return result;
  }
}
