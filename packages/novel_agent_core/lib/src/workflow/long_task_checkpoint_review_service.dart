import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../creative/expression_constraint_review_projection.dart';
import '../creative/expression_constraint_review_projection_service.dart';
import '../creative/expression_constraint_surface_risk_scan_service.dart';
import 'expression_constraint_supervisor_signal_service.dart';
import 'long_task_checkpoint_drift_signal_service.dart';
import 'writing_execution_constraint_bridge_result.dart';
import 'writing_execution_result.dart';
import 'writing_execution_result_codec_service.dart';
import 'narrative_supervisor_risk_policy_service.dart';
import 'long_task_task_summary_service.dart';
import 'task_runtime_constants.dart';

class LongTaskCheckpointReviewService {
  LongTaskCheckpointReviewService({
    required LongTaskTaskSummaryService taskSummaryService,
    LongTaskCheckpointDriftSignalService? driftSignalService,
    NarrativeSupervisorRiskPolicyService? narrativeSupervisorRiskPolicyService,
    ExpressionConstraintReviewProjectionService?
    expressionConstraintReviewProjectionService,
    ExpressionConstraintSurfaceRiskScanService?
    expressionConstraintSurfaceRiskScanService,
    ExpressionConstraintSupervisorSignalService?
    expressionConstraintSupervisorSignalService,
    WritingExecutionResultCodecService? writingExecutionResultCodecService,
  }) : _taskSummaryService = taskSummaryService,
       _driftSignalService =
           driftSignalService ?? LongTaskCheckpointDriftSignalService(),
       _narrativeSupervisorRiskPolicyService =
           narrativeSupervisorRiskPolicyService ??
           const NarrativeSupervisorRiskPolicyService(),
       _expressionConstraintReviewProjectionService =
           expressionConstraintReviewProjectionService ??
           const ExpressionConstraintReviewProjectionService(),
       _expressionConstraintSurfaceRiskScanService =
           expressionConstraintSurfaceRiskScanService ??
           const ExpressionConstraintSurfaceRiskScanService(),
       _expressionConstraintSupervisorSignalService =
           expressionConstraintSupervisorSignalService ??
           const ExpressionConstraintSupervisorSignalService(),
       _writingExecutionResultCodecService =
           writingExecutionResultCodecService ??
           const WritingExecutionResultCodecService();

  final LongTaskTaskSummaryService _taskSummaryService;
  final LongTaskCheckpointDriftSignalService _driftSignalService;
  final NarrativeSupervisorRiskPolicyService
  _narrativeSupervisorRiskPolicyService;
  final ExpressionConstraintReviewProjectionService
  _expressionConstraintReviewProjectionService;
  final ExpressionConstraintSurfaceRiskScanService
  _expressionConstraintSurfaceRiskScanService;
  final ExpressionConstraintSupervisorSignalService
  _expressionConstraintSupervisorSignalService;
  final WritingExecutionResultCodecService _writingExecutionResultCodecService;

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
    final cleanOutputs = _dedupePaths(outputPaths);
    final expectedOutputs = ValueReaders.stringList(task['output_paths']);
    final chapterLengthEvaluation = ValueReaders.mapValue(
      result['chapter_length_evaluation'],
    );
    final expressionConstraintReview =
        _expressionConstraintSurfaceRiskScanService.merge(
          _expressionConstraintReviewProjectionService
              .buildFromCreativeRuleStack(_creativeRuleStack(execution)),
          ExpressionConstraintReviewProjection.fromJson(
            ValueReaders.mapValue(
              result['expression_constraint_surface_review'],
            ),
          ),
        );
    final executionConstraintBridgeResult = _executionConstraintBridgeResult(
      execution,
    );
    final writingExecutionConstraints = executionConstraintBridgeResult == null
        ? const <String, Object?>{}
        : _expressionConstraintSupervisorSignalService
              .projectionFromBridgeResult(executionConstraintBridgeResult);
    final expressionConstraintSignal = executionConstraintBridgeResult == null
        ? const <String, Object?>{}
        : _expressionConstraintSupervisorSignalService.signalFromBridgeResult(
            bridgeResult: executionConstraintBridgeResult,
            review: expressionConstraintReview,
          );
    final confirmationFocus = _confirmationFocus(
      taskType: taskType,
      stage: stage,
      outputPaths: cleanOutputs,
      chapterLengthEvaluation: chapterLengthEvaluation,
      expressionConstraintReview: expressionConstraintReview,
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
      expressionConstraintReview: expressionConstraintReview,
    );
    final miniRecheckItems = expressionConstraintReview.miniRecheckItems;
    final nextActions = _nextActions(
      taskType: taskType,
      stage: stage,
      mode: mode,
      outputPaths: cleanOutputs,
      result: result,
      chapterLengthEvaluation: chapterLengthEvaluation,
      miniRecheckItems: miniRecheckItems,
      collaborationSignal: _collaborationSignal(result, execution),
    );
    final narrativeSupervisorRisk = _narrativeSupervisorRiskPolicyService
        .assess(
          result: result,
          execution: execution,
          expressionConstraintSignal: expressionConstraintSignal,
        );
    final informationSignal = ValueReaders.mapValue(
      narrativeSupervisorRisk['information'],
    );
    final collaborationSignal = _collaborationSignal(result, execution);
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
      'summary': _summary(
        task,
        cleanOutputs,
        confirmationFocus,
        chapterLengthEvaluation,
        collaborationSignal,
      ),
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
      'expression_constraint_review': expressionConstraintReview.toJson(),
      'writing_execution_constraints': writingExecutionConstraints,
      'expression_constraint_signal': expressionConstraintSignal,
      'mini_recheck_items': miniRecheckItems,
      'next_actions': nextActions,
      'narrative_supervisor_risk': narrativeSupervisorRisk,
      'information_signal': informationSignal,
      'information_summary': ValueReaders.stringValue(
        informationSignal['summary'],
      ),
      'information_changed_paths': ValueReaders.stringList(
        informationSignal['changed_paths'],
      ),
      'collaboration_signal': collaborationSignal,
      'collaboration_summary': ValueReaders.stringValue(
        collaborationSignal['summary'],
      ),
      'expected_output_paths': expectedOutputs,
      'output_paths': cleanOutputs,
      'tool_names': _toolNames(result),
      'changed_paths': ValueReaders.stringList(result['changed_paths']),
      'result_ok': ValueReaders.boolValue(result['ok']),
      'error': ValueReaders.stringValue(result['error']),
      'response_preview': _responsePreview(result),
      'chapter_length_evaluation': chapterLengthEvaluation,
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
    JsonMap chapterLengthEvaluation,
    JsonMap collaborationSignal,
  ) {
    final title = ValueReaders.stringValue(task['title'], '当前任务');
    final outputText = outputPaths.isEmpty
        ? '尚未写出文件'
        : '已产出 ${outputPaths.length} 个关键路径';
    final focusText = confirmationFocus.isEmpty
        ? '建议继续人工确认。'
        : '当前最该确认：${confirmationFocus.first}';
    final lengthText = _chapterLengthSummary(chapterLengthEvaluation);
    final collaborationText = ValueReaders.stringValue(
      collaborationSignal['summary'],
    ).trim();
    return '$title 已结束当前单步，$outputText。$focusText${lengthText.isEmpty ? '' : ' $lengthText'}${collaborationText.isEmpty ? '' : ' $collaborationText'}';
  }

  List<String> _confirmationFocus({
    required String taskType,
    required String stage,
    required List<String> outputPaths,
    required JsonMap chapterLengthEvaluation,
    required ExpressionConstraintReviewProjection expressionConstraintReview,
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
    final lengthFocus = _chapterLengthFocus(chapterLengthEvaluation);
    if (lengthFocus.isNotEmpty) {
      items.add(lengthFocus);
    }
    if (expressionConstraintReview.authenticityPassLevel !=
        ExpressionConstraintReviewProjection.authenticityDisabled) {
      items.add('若进入真实性清理，确认没有把人物声音、题材纹理和必要术语一起洗掉。');
    }
    return items;
  }

  List<String> _driftWatchItems({
    required String taskType,
    required String stage,
    required List<JsonMap> driftSignals,
    required ExpressionConstraintReviewProjection expressionConstraintReview,
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
    for (final item in expressionConstraintReview.continuityWatchItems) {
      if (!items.contains(item)) {
        items.add(item);
      }
    }
    for (final note in expressionConstraintReview.voiceProtectionNotes) {
      if (!items.contains(note)) {
        items.add(note);
      }
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
    required JsonMap chapterLengthEvaluation,
    required List<String> miniRecheckItems,
    required JsonMap collaborationSignal,
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
    items.addAll(_chapterLengthActions(chapterLengthEvaluation));
    final collaborationCategory = ValueReaders.stringValue(
      collaborationSignal['category'],
    ).trim();
    if (collaborationCategory == 'checkpoint_user') {
      items.add('先确认高风险协作冲突的采纳方向，再决定是否继续长任务主链。');
    } else if (collaborationCategory == 'repair') {
      items.add('先处理协作冲突对应的修订项，再继续后续队列。');
    }
    if (miniRecheckItems.isNotEmpty) {
      items.add('若本轮要做真实性/去 AI 修订，结尾再跑一轮 mini recheck，重点复核角色声音与连续性。');
    }
    return items;
  }

  JsonMap _collaborationSignal(JsonMap result, JsonMap execution) {
    final sharedResult = _sharedWritingExecutionResult(result, execution);
    if (sharedResult == null || !sharedResult.collaboration.present) {
      return const <String, Object?>{'present': false};
    }
    final collaboration = sharedResult.collaboration;
    final category = collaboration.userConfirmationConflictCount > 0
        ? 'checkpoint_user'
        : collaboration.repairRequiredConflictCount > 0
        ? 'repair'
        : collaboration.totalConflictCount > 0
        ? 'accept'
        : '';
    return <String, Object?>{
      'present': collaboration.totalConflictCount > 0,
      'category': category,
      'summary': collaboration.conflictSummary.isNotEmpty
          ? collaboration.conflictSummary
          : collaboration.summary,
      'highest_risk': collaboration.highestConflictRisk,
      'total_conflict_count': collaboration.totalConflictCount,
      'auto_resolved_conflict_count': collaboration.autoResolvedConflictCount,
      'repair_required_conflict_count':
          collaboration.repairRequiredConflictCount,
      'user_confirmation_conflict_count':
          collaboration.userConfirmationConflictCount,
      'requires_repair': collaboration.repairRequiredConflictCount > 0,
      'requires_user_confirmation':
          collaboration.userConfirmationConflictCount > 0,
      'conflicts': collaboration.conflicts
          .map((entry) => entry.toJson())
          .cast<Object?>()
          .toList(growable: false),
      'arbitration_results': collaboration.arbitrationResults
          .map((entry) => entry.toJson())
          .cast<Object?>()
          .toList(growable: false),
    };
  }

  WritingExecutionConstraintBridgeResult? _executionConstraintBridgeResult(
    JsonMap execution,
  ) {
    final raw = ValueReaders.mapValue(execution['execution_constraints']);
    if (raw.isEmpty) {
      return null;
    }
    return WritingExecutionConstraintBridgeResult.fromJson(raw);
  }

  WritingExecutionResult? _sharedWritingExecutionResult(
    JsonMap result,
    JsonMap execution,
  ) {
    final direct = ValueReaders.mapValue(result['writing_execution_result']);
    if (direct.isNotEmpty) {
      return _writingExecutionResultCodecService.fromJson(direct);
    }
    final executionShared = ValueReaders.mapValue(
      execution['writing_execution_result'],
    );
    if (executionShared.isNotEmpty) {
      return _writingExecutionResultCodecService.fromJson(executionShared);
    }
    return null;
  }

  JsonMap _creativeRuleStack(JsonMap execution) {
    final contextPack = ValueReaders.mapValue(execution['context_pack']);
    final contextStack = ValueReaders.mapValue(
      contextPack['creative_rule_stack'],
    );
    if (contextStack.isNotEmpty) {
      return contextStack;
    }
    return ValueReaders.mapValue(execution['creative_rule_stack']);
  }

  String _chapterLengthSummary(JsonMap evaluation) {
    final level = ValueReaders.stringValue(evaluation['level']).trim();
    if (level.isEmpty) {
      return '';
    }
    final current = ValueReaders.intValue(evaluation['current_length']);
    final target = ValueReaders.intValue(evaluation['target_length']);
    if (current <= 0 || target <= 0) {
      return '';
    }
    switch (level) {
      case 'balanced':
        return '本章字数分布基本稳定。';
      case 'slightly_off':
        return '本章字数有轻微波动，可记录提醒。';
      case 'needs_rebalance':
        return '本章字数已偏离基准，建议在下一章主动回调分布。';
      case 'severely_off':
        return '本章字数偏离明显，建议把它纳入审稿/返修判断。';
      default:
        return '';
    }
  }

  String _chapterLengthFocus(JsonMap evaluation) {
    final level = ValueReaders.stringValue(evaluation['level']).trim();
    if (level.isEmpty || level == 'balanced') {
      return '';
    }
    final notes = ValueReaders.stringList(evaluation['notes']);
    if (notes.isNotEmpty) {
      return notes.last;
    }
    return '确认当前章节字数是否仍符合项目的章节节奏预期。';
  }

  List<String> _chapterLengthActions(JsonMap evaluation) {
    final action = ValueReaders.stringValue(
      evaluation['recommended_action'],
    ).trim();
    switch (action) {
      case 'adjust_next_chapter':
        return const <String>['下一章优先按章节字数基准回调，避免与前后章节继续拉开差距。'];
      case 'review_or_repair':
        return const <String>[
          '当前章字数偏离已明显，可进入 review / repair 提示，而不是只靠后续章节自然回调。',
        ];
      case 'remind':
        return const <String>['记录本章字数波动提醒，继续观察后续几章的分布。'];
      default:
        return const <String>[];
    }
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

  List<String> _dedupePaths(List<String> paths) {
    final result = <String>[];
    for (final item in paths) {
      if (!result.contains(item)) {
        result.add(item);
      }
    }
    return result;
  }
}
