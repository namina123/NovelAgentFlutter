import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_planning_artifact_path_service.dart';

class LongTaskSampleReadinessService {
  static const String readinessCheckpointFlag = 'sample_readiness_checkpoint';
  static const String requiredArtifactPathsField = 'required_artifact_paths';
  static const String optionalArtifactPathsField = 'optional_artifact_paths';
  static const String requiresInformationConfirmationField =
      'requires_information_confirmation';
  static const String requiresStyleConfirmationField =
      'requires_style_confirmation';
  static const String requiresOutlineConfirmationField =
      'requires_outline_confirmation';

  const LongTaskSampleReadinessService({
    LongTaskPlanningArtifactPathService? planningArtifactPathService,
  }) : _planningArtifactPathService =
           planningArtifactPathService ??
           const LongTaskPlanningArtifactPathService();

  final LongTaskPlanningArtifactPathService _planningArtifactPathService;

  bool isSampleTask(JsonMap task) {
    return ValueReaders.stringValue(task['task_type']).trim() == 'chapter' &&
        ValueReaders.stringValue(
              ValueReaders.mapValue(task['metadata'])['stage'],
            ).trim().toLowerCase() ==
            'sample';
  }

  bool isReadinessCheckpoint(JsonMap task) {
    return ValueReaders.stringValue(task['task_type']).trim() == 'checkpoint' &&
        ValueReaders.boolValue(
          ValueReaders.mapValue(task['metadata'])[readinessCheckpointFlag],
        );
  }

  List<String> requiredPlanningArtifactPaths() {
    return _planningArtifactPathService.sampleReadinessRequiredPaths();
  }

  List<String> optionalPlanningArtifactPaths() {
    return _planningArtifactPathService.sampleReadinessOptionalPaths();
  }

  JsonMap readinessMetadata() {
    return <String, Object?>{
      readinessCheckpointFlag: true,
      requiredArtifactPathsField: requiredPlanningArtifactPaths(),
      optionalArtifactPathsField: optionalPlanningArtifactPaths(),
      requiresInformationConfirmationField: true,
      requiresStyleConfirmationField: true,
      requiresOutlineConfirmationField: true,
    };
  }

  bool hasSatisfiedReadinessCheckpoint(
    JsonMap sampleTask,
    List<JsonMap> tasks,
  ) {
    if (!isSampleTask(sampleTask)) {
      return true;
    }
    final dependencies = ValueReaders.stringList(
      sampleTask['depends_on'],
    ).toSet();
    if (dependencies.isEmpty) {
      return false;
    }
    for (final task in tasks) {
      final taskId = ValueReaders.stringValue(task['id']).trim();
      if (!dependencies.contains(taskId) || !isReadinessCheckpoint(task)) {
        continue;
      }
      if (ValueReaders.stringValue(task['status']).trim() == 'succeeded') {
        return true;
      }
    }
    return false;
  }
}
