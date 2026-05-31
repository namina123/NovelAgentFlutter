import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'chapter_atomic_constants.dart';
import 'chapter_atomic_event_service.dart';
import 'chapter_atomic_step_state_service.dart';

class ChapterAtomicResultRecorderService {
  ChapterAtomicResultRecorderService({
    required ChapterAtomicStepStateService stepStateService,
    required ChapterAtomicEventService eventService,
  }) : _stepStateService = stepStateService,
       _eventService = eventService;

  final ChapterAtomicStepStateService _stepStateService;
  final ChapterAtomicEventService _eventService;

  JsonMap advanceStep(
    JsonMap execution,
    String stepId,
    String nextStatus, {
    String note = '',
    String? updatedAt,
  }) {
    // 中文注释: 手工推进单个步骤时，这里统一更新状态、游标、事件和更新时间。
    if (execution.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Execution package not found.',
      };
    }
    final now = updatedAt ?? DateTime.now().toIso8601String();
    var changed = false;
    final steps = <JsonMap>[];
    for (final rawStep in ValueReaders.objectList(execution['steps'])) {
      final step = ValueReaders.mapValue(rawStep);
      if (step.isEmpty) {
        continue;
      }
      final next = ValueReaders.deepCopyMap(step);
      if (ValueReaders.stringValue(step['id']) == stepId) {
        next['status'] = _stepStateService.normalizeStepStatus(nextStatus);
        next['updated_at'] = now;
        if (note.trim().isNotEmpty) {
          next['note'] = note;
        }
        changed = true;
      }
      steps.add(next);
    }
    if (!changed) {
      return <String, Object?>{'ok': false, 'error': 'Step not found: $stepId'};
    }
    final updated = ValueReaders.deepCopyMap(execution);
    updated['steps'] = _stepStateService.refreshStepCursor(steps);
    updated['events'] = _eventService.appendEvent(
      ValueReaders.objectList(execution['events']),
      'step_${_stepStateService.normalizeStepStatus(nextStatus)}',
      note,
      <String, Object?>{'step_id': stepId},
      createdAt: now,
    );
    updated['updated_at'] = now;
    return <String, Object?>{'ok': true, 'execution': updated};
  }

  JsonMap recordModelResult(
    JsonMap execution,
    JsonMap response,
    List<Object?> outputPaths, {
    String? updatedAt,
  }) {
    // 中文注释: 模型单步返回后，这里只更新执行包状态，不决定如何真实保存到项目文件系统。
    if (execution.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Execution package not found.',
      };
    }
    final now = updatedAt ?? DateTime.now().toIso8601String();
    final updated = ValueReaders.deepCopyMap(execution);
    updated['last_response_id'] = ValueReaders.stringValue(response['id']);
    updated['last_response_summary'] = _clipText(
      ValueReaders.stringValue(
        response['result_markdown'],
        ValueReaders.stringValue(response['error_summary']),
      ),
      1200,
    );
    updated['output_paths'] = _mergeStringLists(
      ValueReaders.objectList(execution['output_paths']),
      outputPaths,
    );
    updated['events'] = _eventService.appendEvent(
      ValueReaders.objectList(execution['events']),
      'model_result',
      '模型单步执行已返回。',
      <String, Object?>{
        'response_id': updated['last_response_id'],
        'output_paths': outputPaths,
      },
      createdAt: now,
    );
    updated['updated_at'] = now;

    final taskType = ValueReaders.stringValue(execution['task_type']);
    if (taskType == 'revision') {
      updated['steps'] = _stepStateService.setStepStatuses(
        ValueReaders.objectList(execution['steps']),
        <String, Object?>{
          'read_target': ChapterAtomicConstants.stepSucceeded,
          'edit_target': _stepStateService.hasEditableOutput(outputPaths)
              ? ChapterAtomicConstants.stepSucceeded
              : ChapterAtomicConstants.stepWaitingUser,
          'review_changes': ChapterAtomicConstants.stepReady,
          'create_backup': _stepStateService.hasBackupOutput(outputPaths)
              ? ChapterAtomicConstants.stepSucceeded
              : ChapterAtomicConstants.stepWaitingUser,
        },
        note: '修订模型已返回，等待用户检查 diff。',
        updatedAt: now,
      );
    } else if (taskType == 'review') {
      updated['steps'] = _stepStateService.setStepStatuses(
        ValueReaders.objectList(execution['steps']),
        <String, Object?>{
          'read_sources': ChapterAtomicConstants.stepSucceeded,
          'run_review': ChapterAtomicConstants.stepSucceeded,
          'save_report': _stepStateService.hasReviewReportOutput(outputPaths)
              ? ChapterAtomicConstants.stepSucceeded
              : ChapterAtomicConstants.stepWaitingUser,
        },
        note: '审稿模型已返回，等待用户查看报告。',
        updatedAt: now,
      );
    } else if (taskType == 'planning') {
      updated['steps'] = _stepStateService.setStepStatuses(
        ValueReaders.objectList(execution['steps']),
        <String, Object?>{
          'read_seed': ChapterAtomicConstants.stepSucceeded,
          'expand_seed_spec': ChapterAtomicConstants.stepSucceeded,
          'save_project_spec': _stepStateService.hasSpecOutput(outputPaths)
              ? ChapterAtomicConstants.stepSucceeded
              : ChapterAtomicConstants.stepWaitingUser,
          'save_outline': _stepStateService.hasOutlineOutput(outputPaths)
              ? ChapterAtomicConstants.stepSucceeded
              : ChapterAtomicConstants.stepWaitingUser,
          'create_followup_tasks': _stepStateService.hasTaskOutput(outputPaths)
              ? ChapterAtomicConstants.stepSucceeded
              : ChapterAtomicConstants.stepSkipped,
          'wait_user_checkpoint': ChapterAtomicConstants.stepReady,
        },
        note: '规划模型已返回，等待用户确认总纲或样章方向。',
        updatedAt: now,
      );
    } else if (outputPaths.isNotEmpty) {
      updated['steps'] = _stepStateService.setStepStatuses(
        ValueReaders.objectList(execution['steps']),
        const <String, Object?>{
          'draft_chapter': ChapterAtomicConstants.stepSucceeded,
          'save_draft': ChapterAtomicConstants.stepSucceeded,
          'summarize_chapter': ChapterAtomicConstants.stepReady,
        },
        note: '模型已返回并产生输出路径。',
        updatedAt: now,
      );
    } else {
      updated['steps'] = _stepStateService.setStepStatuses(
        ValueReaders.objectList(execution['steps']),
        const <String, Object?>{
          'draft_chapter': ChapterAtomicConstants.stepSucceeded,
          'save_draft': ChapterAtomicConstants.stepWaitingUser,
        },
        note: '模型已返回，但未检测到工具写入路径。',
        updatedAt: now,
      );
    }

    return <String, Object?>{'ok': true, 'execution': updated};
  }

  JsonMap recordPostprocessResult(
    JsonMap execution,
    JsonMap response,
    List<Object?> outputPaths,
    List<Object?> toolNames, {
    String? updatedAt,
  }) {
    // 中文注释: 后处理阶段只更新摘要、记忆、审稿等附加步骤，不重新改写正文执行状态。
    if (execution.isEmpty) {
      return <String, Object?>{
        'ok': false,
        'error': 'Execution package not found.',
      };
    }
    final now = updatedAt ?? DateTime.now().toIso8601String();
    final updated = ValueReaders.deepCopyMap(execution);
    updated['last_postprocess_response_id'] = ValueReaders.stringValue(
      response['id'],
    );
    updated['postprocess_output_paths'] = _mergeStringLists(
      ValueReaders.objectList(execution['postprocess_output_paths']),
      outputPaths,
    );
    updated['output_paths'] = _mergeStringLists(
      ValueReaders.objectList(execution['output_paths']),
      outputPaths,
    );
    updated['events'] = _eventService.appendEvent(
      ValueReaders.objectList(execution['events']),
      'postprocess_result',
      '后处理单步已返回。',
      <String, Object?>{
        'response_id': updated['last_postprocess_response_id'],
        'tool_names': ValueReaders.stringList(toolNames),
        'output_paths': outputPaths,
      },
      createdAt: now,
    );

    final stepUpdates = <String, Object?>{};
    final isRevision =
        ValueReaders.stringValue(execution['task_type']) == 'revision';
    final normalizedToolNames = ValueReaders.stringList(toolNames);
    final memoryUpdated =
        normalizedToolNames.contains('update_world_state') ||
        normalizedToolNames.contains('update_character_state') ||
        normalizedToolNames.contains('update_foreshadow_state') ||
        normalizedToolNames.contains('update_timeline_state') ||
        normalizedToolNames.contains('update_relationship_state');
    if (isRevision) {
      stepUpdates['review_changes'] =
          normalizedToolNames.contains('run_continuity_check')
          ? ChapterAtomicConstants.stepSucceeded
          : ChapterAtomicConstants.stepWaitingUser;
    } else {
      if (normalizedToolNames.contains('summarize_context')) {
        stepUpdates['summarize_chapter'] = ChapterAtomicConstants.stepSucceeded;
      }
      if (memoryUpdated) {
        stepUpdates['update_memory'] = ChapterAtomicConstants.stepSucceeded;
      }
      if (normalizedToolNames.contains('run_continuity_check')) {
        stepUpdates['continuity_check'] = ChapterAtomicConstants.stepSucceeded;
      }
    }
    if (stepUpdates.isEmpty) {
      stepUpdates[isRevision ? 'review_changes' : 'summarize_chapter'] =
          ChapterAtomicConstants.stepWaitingUser;
    } else if (!isRevision) {
      if (!memoryUpdated) {
        stepUpdates['update_memory'] = ChapterAtomicConstants.stepSkipped;
      }
      stepUpdates['mark_done'] = ChapterAtomicConstants.stepReady;
    }
    updated['steps'] = _stepStateService.setStepStatuses(
      ValueReaders.objectList(execution['steps']),
      stepUpdates,
      note: '后处理工具已执行。',
      updatedAt: now,
    );
    updated['updated_at'] = now;
    return <String, Object?>{'ok': true, 'execution': updated};
  }

  List<String> mergeStringLists(
    List<Object?> leftValue,
    List<Object?> rightValue,
  ) {
    // 中文注释: 给宿主或其他服务暴露一个可复用的路径去重入口，避免重复实现。
    return _mergeStringLists(leftValue, rightValue);
  }

  List<String> _mergeStringLists(
    List<Object?> leftValue,
    List<Object?> rightValue,
  ) {
    // 中文注释: 输出路径合并统一去重，保证执行包里的路径清单稳定可比较。
    final result = ValueReaders.stringList(leftValue);
    for (final value in ValueReaders.stringList(rightValue)) {
      if (!result.contains(value)) {
        result.add(value);
      }
    }
    return result;
  }

  String _clipText(String value, int maxChars) {
    // 中文注释: 完整长文本在 runs/ 里另存，这里只保留执行包恢复所需的短摘要。
    if (value.length <= maxChars) {
      return value;
    }
    return '${value.substring(0, maxChars)}\n……（已截断）';
  }
}
