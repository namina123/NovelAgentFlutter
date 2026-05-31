import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_chapter_gate_disposition_service.dart';
import 'task_runtime_constants.dart';

class LongTaskChapterGatePolicyService {
  const LongTaskChapterGatePolicyService({
    LongTaskChapterGateDispositionService? dispositionService,
  }) : _dispositionService =
           dispositionService ?? const LongTaskChapterGateDispositionService();

  final LongTaskChapterGateDispositionService _dispositionService;

  String runtimeBaselineIdForTask(
    JsonMap task, {
    JsonMap options = const <String, Object?>{},
  }) {
    final explicit = ValueReaders.stringValue(options['runtime_baseline_id']);
    if (explicit.trim().isNotEmpty) {
      return explicit.trim();
    }
    final metadata = ValueReaders.mapValue(task['metadata']);
    return ValueReaders.stringValue(metadata['runtime_baseline_id']).trim();
  }

  JsonMap chapterGatePolicy(
    JsonMap task, {
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 章级 gate 规则只描述“要不要审稿、审完如何放行”，不直接创建任务也不触碰持久化。
    final runtimeBaselineId = runtimeBaselineIdForTask(task, options: options);
    final taskType = ValueReaders.stringValue(task['task_type'], 'chapter');
    if (runtimeBaselineId != 'chapter_collaboration_autorun' ||
        taskType != 'chapter') {
      return const <String, Object?>{
        'runtime_baseline_id': '',
        'requires_gate': false,
        'auto_advance_after_gate': false,
        'review_types': <Object?>[],
        'advisory_focuses': <Object?>[],
        'auto_create_review_tasks': false,
        'auto_create_repair_task': false,
      };
    }
    return const <String, Object?>{
      'runtime_baseline_id': 'chapter_collaboration_autorun',
      'requires_gate': true,
      'auto_advance_after_gate': true,
      'blocks_next_chapter_until_gate_passed': true,
      'auto_create_review_tasks': true,
      'auto_create_repair_task': true,
      'review_types': <Object?>['general'],
      'advisory_focuses': <Object?>['continuity', 'plot', 'style'],
      'gate_scope': 'chapter',
      'gate_label': '逐章审稿闸门',
      'description': '每章正文完成后先进入结构化审稿；若报告指出问题，则先走返工链，通过后再自动推进下一章。',
    };
  }

  bool requiresChapterGate(
    JsonMap task, {
    JsonMap options = const <String, Object?>{},
  }) {
    return ValueReaders.boolValue(
      chapterGatePolicy(task, options: options)['requires_gate'],
    );
  }

  JsonMap reviewOutcomeDecision(
    JsonMap reviewReport, {
    String runtimeBaselineId = '',
  }) {
    // 中文注释: 这里把审稿结果翻译成 gate 决策，后续 adapters 只需要按合同决定是否物化修复任务。
    return _dispositionService.resolve(
      reviewReport,
      runtimeBaselineId: runtimeBaselineId,
    );
  }

  String statusAfterReviewOutcome(JsonMap decision, String defaultStatus) {
    // 中文注释: 章级 gate 只在明确阻塞用户或人工介入时拦下当前 review 任务，其他情况沿用默认完成策略。
    final disposition = ValueReaders.stringValue(
      decision['disposition'],
    ).trim();
    if (disposition == 'blocked_wait_user' ||
        disposition == 'manual_attention') {
      return TaskRuntimeConstants.statusWaitingUser;
    }
    return defaultStatus;
  }
}
