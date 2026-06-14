import 'project_storage_strategy.dart';

class ProjectTypeTransitionRequest {
  const ProjectTypeTransitionRequest({
    required this.sourceProjectTypeId,
    required this.targetProjectTypeId,
    required this.storageStrategy,
    this.currentRuntimeBaselineId = '',
    this.hasActiveLongTaskRun = false,
  });

  final String sourceProjectTypeId;
  final String targetProjectTypeId;
  final ProjectStorageStrategy storageStrategy;
  final String currentRuntimeBaselineId;
  final bool hasActiveLongTaskRun;
}
