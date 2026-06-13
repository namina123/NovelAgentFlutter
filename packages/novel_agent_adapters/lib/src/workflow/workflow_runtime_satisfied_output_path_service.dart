import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_task_repository.dart';

class WorkflowRuntimeSatisfiedOutputPathService {
  WorkflowRuntimeSatisfiedOutputPathService({
    required ProjectTaskRepository taskRepository,
  }) : _taskRepository = taskRepository;

  final ProjectTaskRepository _taskRepository;

  Future<List<String>> mergeSatisfiedOutputPaths({
    required ProjectDescriptor project,
    required JsonMap task,
    required List<String> outputPaths,
    JsonMap executionRecord = const <String, Object?>{},
  }) async {
    final merged = _mergePaths(
      outputPaths,
      ValueReaders.stringList(executionRecord['output_paths']),
    );
    final satisfied = await _existingPlanningOutputs(
      project: project,
      task: task,
      knownOutputPaths: merged,
    );
    return _mergePaths(merged, satisfied);
  }

  Future<List<String>> _existingPlanningOutputs({
    required ProjectDescriptor project,
    required JsonMap task,
    required List<String> knownOutputPaths,
  }) async {
    if (!_canReuseExistingPlanningOutputs(task)) {
      return const <String>[];
    }
    final expected = _normalizePaths(
      ValueReaders.stringList(task['output_paths']),
    );
    if (expected.isEmpty) {
      return const <String>[];
    }
    final known = _normalizePaths(knownOutputPaths).toSet();
    final satisfied = <String>[];
    for (final path in expected) {
      if (known.contains(path)) {
        continue;
      }
      final existing = await _taskRepository.readTextFile(project, path);
      if ((existing ?? '').trim().isEmpty) {
        continue;
      }
      satisfied.add(path);
    }
    return List<String>.unmodifiable(satisfied);
  }

  bool _canReuseExistingPlanningOutputs(JsonMap task) {
    final metadata = ValueReaders.mapValue(task['metadata']);
    if (ValueReaders.stringValue(metadata['stage']).trim() != 'planning') {
      return false;
    }
    if (ValueReaders.stringValue(task['task_type']).trim() != 'planning') {
      return false;
    }
    if (ValueReaders.stringValue(metadata['plan_id']).trim().isNotEmpty ||
        ValueReaders.stringValue(
          metadata['runtime_baseline_id'],
        ).trim().isNotEmpty) {
      return true;
    }
    final generatedBy = ValueReaders.stringValue(
      metadata['generated_by'],
    ).trim();
    return generatedBy == 'LongTaskPlanner' ||
        generatedBy == 'LongTaskRevision';
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

  List<String> _normalizePaths(List<String> paths) {
    final result = <String>[];
    for (final raw in paths) {
      final normalized = raw.trim().replaceAll('\\', '/');
      if (normalized.isEmpty || result.contains(normalized)) {
        continue;
      }
      result.add(normalized);
    }
    return result;
  }
}
