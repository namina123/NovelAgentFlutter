import '../common/json_types.dart';

class ProjectRuntimeProfile {
  const ProjectRuntimeProfile({
    required this.projectType,
    required this.runtimeBaselineId,
    required this.runtimeMode,
    required this.initialRunOptions,
    this.schemaVersion = 1,
  });

  final String projectType;
  final String runtimeBaselineId;
  final String runtimeMode;
  final JsonMap initialRunOptions;
  final int schemaVersion;
}
