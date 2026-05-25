import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../review/review_task_factory_service.dart';
import '../runtime/runtime_baseline_execution_mode_service.dart';

import 'long_task_chapter_gate_policy_service.dart';

class LongTaskChapterGateReviewTaskFactoryService {
  LongTaskChapterGateReviewTaskFactoryService({
    ReviewTaskFactoryService? reviewTaskFactoryService,
    LongTaskChapterGatePolicyService? chapterGatePolicyService,
    RuntimeBaselineExecutionModeService? runtimeBaselineExecutionModeService,
  }) : _reviewTaskFactoryService =
           reviewTaskFactoryService ?? ReviewTaskFactoryService(),
       _chapterGatePolicyService =
           chapterGatePolicyService ?? const LongTaskChapterGatePolicyService(),
       _runtimeBaselineExecutionModeService =
           runtimeBaselineExecutionModeService ??
           RuntimeBaselineExecutionModeService();

  final ReviewTaskFactoryService _reviewTaskFactoryService;
  final LongTaskChapterGatePolicyService _chapterGatePolicyService;
  final RuntimeBaselineExecutionModeService
  _runtimeBaselineExecutionModeService;

  List<JsonMap> buildReviewTasksForChapter(
    JsonMap chapterTask, {
    JsonMap options = const <String, Object?>{},
    int startingSortOrder = 0,
    String createdAt = '',
  }) {
    // 中文注释: 该工厂只把“章级 gate 需要哪些审稿任务”转成现有审稿任务骨架，不新造另一套审稿系统。
    final policy = _chapterGatePolicyService.chapterGatePolicy(
      chapterTask,
      options: options,
    );
    if (!ValueReaders.boolValue(policy['requires_gate'])) {
      return const <JsonMap>[];
    }
    final outputPaths = ValueReaders.stringList(chapterTask['output_paths']);
    if (outputPaths.isEmpty) {
      return const <JsonMap>[];
    }
    final chapterPath = outputPaths.first;
    final runtimeBaselineId = ValueReaders.stringValue(
      policy['runtime_baseline_id'],
    );
    final taskMode = _runtimeBaselineExecutionModeService.resolveRuntimeMode(
      runtimeBaselineId: runtimeBaselineId,
      runtimeMode: ValueReaders.stringValue(chapterTask['mode']),
    );
    final metadata = ValueReaders.mapValue(chapterTask['metadata']);
    final planId = ValueReaders.stringValue(metadata['plan_id']);
    final sourceTaskId = ValueReaders.stringValue(chapterTask['id']);
    final sourceTaskPath = ValueReaders.stringValue(
      chapterTask['relative_path'],
    );
    final chapterTitle = ValueReaders.stringValue(
      chapterTask['title'],
      chapterPath,
    );
    final persistentContextPaths = ValueReaders.stringList(
      metadata['persistent_context_paths'],
    );
    final reviewTypes = ValueReaders.stringList(policy['review_types']);
    final result = <JsonMap>[];
    final now = createdAt.isEmpty
        ? DateTime.now().toIso8601String()
        : createdAt;
    for (var index = 0; index < reviewTypes.length; index += 1) {
      final reviewType = reviewTypes[index];
      final taskId = [
        if (sourceTaskId.trim().isNotEmpty) sourceTaskId.trim(),
        'gate',
        'review',
        reviewType,
      ].join('_');
      final baseTask = _reviewTaskFactoryService.reviewTaskFromSource(
        <String, Object?>{
          'source_path': chapterPath,
          'review_type': reviewType,
          'mode': taskMode,
          'title': '章级审稿：$chapterTitle',
          'metadata': <String, Object?>{
            'origin': 'chapter_gate_review',
            'runtime_baseline_id': runtimeBaselineId,
            'workflow_mode': taskMode,
            'plan_id': planId,
            'chapter_gate': true,
            'gate_scope': ValueReaders.stringValue(policy['gate_scope']),
            'gate_source_task_id': sourceTaskId,
            'gate_source_task_path': sourceTaskPath,
            'persistent_context_paths': persistentContextPaths,
            'sort_order': startingSortOrder + index,
          },
        },
      );
      final metadata = ValueReaders.mapValue(baseTask['metadata']);
      result.add(<String, Object?>{
        'schema_version': 1,
        'id': taskId,
        'title': ValueReaders.stringValue(baseTask['title'], '章级审稿'),
        'task_type': 'review',
        'mode': taskMode,
        'status': 'queued',
        'chapter': ValueReaders.stringValue(baseTask['chapter']),
        'goal': ValueReaders.stringValue(baseTask['goal']),
        'brief': ValueReaders.stringValue(baseTask['brief']),
        'depends_on': <Object?>[
          if (sourceTaskId.trim().isNotEmpty) sourceTaskId,
        ],
        'source_paths': ValueReaders.stringList(baseTask['source_paths']),
        'output_paths': ValueReaders.stringList(baseTask['output_paths']),
        'metadata': metadata,
        'tool_hint': ValueReaders.stringValue(baseTask['tool_hint']),
        'created_at': now,
        'updated_at': now,
        'history': <Object?>[
          <String, Object?>{
            'status': 'queued',
            'note': 'Chapter gate review task generated.',
            'created_at': now,
          },
        ],
      });
    }
    return result;
  }
}
