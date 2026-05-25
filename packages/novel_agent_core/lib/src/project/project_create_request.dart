import 'project_storage_strategy.dart';

class ProjectCreateRequest {
  const ProjectCreateRequest({
    required this.title,
    required this.projectTypeId,
    this.storageStrategy = ProjectStorageStrategy.markdownProjectStore,
    this.runtimeBaselineId = '',
  });

  final String title;
  final String projectTypeId;
  final ProjectStorageStrategy storageStrategy;
  final String runtimeBaselineId;

  ProjectCreateRequest copyWith({
    String? title,
    String? projectTypeId,
    ProjectStorageStrategy? storageStrategy,
    String? runtimeBaselineId,
  }) {
    return ProjectCreateRequest(
      title: title ?? this.title,
      projectTypeId: projectTypeId ?? this.projectTypeId,
      storageStrategy: storageStrategy ?? this.storageStrategy,
      runtimeBaselineId: runtimeBaselineId ?? this.runtimeBaselineId,
    );
  }
}
