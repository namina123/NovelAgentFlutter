import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../project/project_workspace_catalog.dart';
import 'chapter_atomic_constants.dart';

class ChapterAtomicStepStateService {
  List<JsonMap> prepareSteps(List<Object?> rawSteps, {String? updatedAt}) {
    // 中文注释: 执行计划里的准备步骤在生成执行包时就算完成，其余步骤保持待执行状态。
    final now = updatedAt ?? DateTime.now().toIso8601String();
    final steps = <JsonMap>[];
    for (final rawStep in rawSteps) {
      final step = ValueReaders.mapValue(rawStep);
      if (step.isEmpty) {
        continue;
      }
      final prepared = ValueReaders.stringValue(step['id']).trim();
      steps.add(<String, Object?>{
        ...step,
        'status': <String>{'read_task', 'assemble_context'}.contains(prepared)
            ? ChapterAtomicConstants.stepSucceeded
            : ChapterAtomicConstants.stepPending,
        'note': <String>{'read_task', 'assemble_context'}.contains(prepared)
            ? '准备执行包时已完成。'
            : ValueReaders.stringValue(step['note']),
        'updated_at': now,
      });
    }
    return refreshStepCursor(steps);
  }

  List<JsonMap> refreshStepCursor(List<Object?> rawSteps) {
    // 中文注释: 第一个 pending 步骤会自动转成 ready，方便后续调度器直接接手。
    var hasReady = false;
    final steps = <JsonMap>[];
    for (final rawStep in rawSteps) {
      final step = ValueReaders.mapValue(rawStep);
      if (step.isEmpty) {
        continue;
      }
      final next = ValueReaders.deepCopyMap(step);
      final status = ValueReaders.stringValue(
        next['status'],
        ChapterAtomicConstants.stepPending,
      );
      if (!hasReady && status == ChapterAtomicConstants.stepReady) {
        next['cursor'] = true;
        hasReady = true;
      } else if (!hasReady && status == ChapterAtomicConstants.stepPending) {
        next['status'] = ChapterAtomicConstants.stepReady;
        next['cursor'] = true;
        hasReady = true;
      } else {
        next['cursor'] = false;
      }
      steps.add(next);
    }
    return steps;
  }

  String normalizeStepStatus(String status) {
    // 中文注释: 外部写入未知步骤状态时一律收回到 pending，避免恢复逻辑被脏数据打断。
    final clean = status.trim();
    if (ChapterAtomicConstants.validStepStatuses.contains(clean)) {
      return clean;
    }
    return ChapterAtomicConstants.stepPending;
  }

  List<JsonMap> setStepStatuses(
    List<Object?> rawSteps,
    JsonMap updates, {
    required String note,
    String? updatedAt,
  }) {
    // 中文注释: 模型结果和后处理结果都会批量推进步骤状态，这里统一处理并刷新游标。
    final now = updatedAt ?? DateTime.now().toIso8601String();
    final steps = <JsonMap>[];
    for (final rawStep in rawSteps) {
      final step = ValueReaders.mapValue(rawStep);
      if (step.isEmpty) {
        continue;
      }
      final next = ValueReaders.deepCopyMap(step);
      final stepId = ValueReaders.stringValue(step['id']);
      if (updates.containsKey(stepId)) {
        next['status'] = ValueReaders.stringValue(updates[stepId]);
        next['note'] = note;
        next['updated_at'] = now;
        if (ValueReaders.stringValue(next['status']) ==
            ChapterAtomicConstants.stepReady) {
          next['cursor'] = false;
        }
      }
      steps.add(next);
    }
    return refreshStepCursor(steps);
  }

  bool hasEditableOutput(List<Object?> paths) {
    // 中文注释: 只有真正指向项目正文/资料目录的输出才算完成写作，不把报告和追踪文件算进去。
    final allowedRoots = ProjectWorkspaceCatalog.userWorkspaceDirs
        .map((item) => item.path.replaceAll('/', ''))
        .toSet();
    for (final path in ValueReaders.stringList(paths)) {
      final root = path.split('/').first;
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
      if (allowedRoots.contains(root)) {
        return true;
      }
    }
    return false;
  }

  bool hasBackupOutput(List<Object?> paths) {
    // 中文注释: 修订任务单独检查 backups/，让 UI 能准确展示“已备份”步骤。
    return ValueReaders.stringList(
      paths,
    ).any((path) => path.startsWith('backups/'));
  }

  bool hasReviewReportOutput(List<Object?> paths) {
    // 中文注释: 审稿或后处理只有真实写出 reviews/ 报告时，才标记保存成功。
    return ValueReaders.stringList(
      paths,
    ).any((path) => path.startsWith('reviews/'));
  }

  bool hasSpecOutput(List<Object?> paths) {
    // 中文注释: 规划任务通过 specs/ 输出判断项目规格是否已落地。
    return ValueReaders.stringList(
      paths,
    ).any((path) => path.startsWith('specs/'));
  }

  bool hasOutlineOutput(List<Object?> paths) {
    // 中文注释: 规划任务把总纲、卷纲和章纲都视作 outline 类产物。
    return ValueReaders.stringList(paths).any(
      (path) =>
          path.startsWith('outlines/story/') ||
          path.startsWith('outlines/volumes/') ||
          path.startsWith('outlines/chapters/') ||
          path.startsWith('outline/') ||
          path.startsWith('volume_outlines/') ||
          path.startsWith('chapter_outlines/'),
    );
  }

  bool hasTaskOutput(List<Object?> paths) {
    // 中文注释: 这里用于判断规划任务是否补充了后续任务文件。
    return ValueReaders.stringList(
      paths,
    ).any((path) => path.startsWith('tasks/'));
  }
}
