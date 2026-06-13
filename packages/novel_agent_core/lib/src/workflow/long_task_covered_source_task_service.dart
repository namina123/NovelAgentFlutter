import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'task_runtime_constants.dart';

class LongTaskCoveredSourceTaskService {
  const LongTaskCoveredSourceTaskService();

  JsonMap firstUncoveredTaskByStatus(List<Object?> tasks, String status) {
    for (final rawTask in tasks) {
      final task = ValueReaders.mapValue(rawTask);
      if (ValueReaders.stringValue(task['status']) != status) {
        continue;
      }
      if (isCoveredBySucceededDependent(task, tasks)) {
        continue;
      }
      return task;
    }
    return const <String, Object?>{};
  }

  bool isCoveredBySucceededDependent(JsonMap task, List<Object?> tasks) {
    if (_isObsoletePlannerWaitingUserSidecar(task, tasks)) {
      return true;
    }
    final taskId = ValueReaders.stringValue(task['id']).trim();
    if (taskId.isEmpty) {
      return false;
    }
    for (final rawCandidate in tasks) {
      final candidate = ValueReaders.mapValue(rawCandidate);
      if (ValueReaders.stringValue(candidate['status']) !=
          TaskRuntimeConstants.statusSucceeded) {
        continue;
      }
      if (ValueReaders.stringList(candidate['depends_on']).contains(taskId)) {
        return true;
      }
    }
    return false;
  }

  bool _isObsoletePlannerWaitingUserSidecar(
    JsonMap task,
    List<Object?> tasks,
  ) {
    if (ValueReaders.stringValue(task['status']).trim() !=
        TaskRuntimeConstants.statusWaitingUser) {
      return false;
    }
    if (ValueReaders.stringValue(task['task_type']).trim() != 'agent_task') {
      return false;
    }
    final metadata = ValueReaders.mapValue(task['metadata']);
    if (ValueReaders.stringValue(metadata['generated_by']).trim() !=
        'LongTaskPlanner') {
      return false;
    }
    if (ValueReaders.stringValue(metadata['stage']).trim() != 'planning') {
      return false;
    }
    final planId = ValueReaders.stringValue(metadata['plan_id']).trim();
    if (planId.isEmpty) {
      return false;
    }
    final taskId = ValueReaders.stringValue(task['id']).trim();
    for (final rawCandidate in tasks) {
      final candidate = ValueReaders.mapValue(rawCandidate);
      if (ValueReaders.stringValue(candidate['status']).trim() !=
          TaskRuntimeConstants.statusSucceeded) {
        continue;
      }
      if (ValueReaders.stringValue(
            ValueReaders.mapValue(candidate['metadata'])['plan_id'],
          ).trim() !=
          planId) {
        continue;
      }
      if (taskId.isNotEmpty &&
          ValueReaders.stringValue(candidate['id']).trim() == taskId) {
        continue;
      }
      final candidateType = ValueReaders.stringValue(
        candidate['task_type'],
      ).trim();
      final candidateStage = ValueReaders.stringValue(
        ValueReaders.mapValue(candidate['metadata'])['stage'],
      ).trim();
      if (candidateType == 'checkpoint' ||
          candidateType == 'chapter' ||
          candidateStage == 'checkpoint' ||
          candidateStage == 'sample' ||
          candidateStage == 'series') {
        return true;
      }
    }
    return false;
  }
}
