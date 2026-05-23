import '../common/json_types.dart';
import '../project/project_descriptor.dart';

class ProjectWorkspaceSnapshot {
  const ProjectWorkspaceSnapshot({
    required this.project,
    required this.projectInfo,
    required this.entries,
  });

  final ProjectDescriptor project;
  final JsonMap projectInfo;
  final List<JsonMap> entries;
}
