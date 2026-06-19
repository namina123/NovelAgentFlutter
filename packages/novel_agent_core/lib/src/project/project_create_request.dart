import 'project_storage_strategy.dart';

class ProjectCreateRequest {
  const ProjectCreateRequest({
    required this.title,
    required this.projectTypeId,
    this.storageStrategy = ProjectStorageStrategy.markdownProjectStore,
    this.projectBranchId = '',
    this.runtimeBaselineId = '',
  });

  final String title;
  final String projectTypeId;
  final ProjectStorageStrategy storageStrategy;
  final String projectBranchId;
  final String runtimeBaselineId;

  ProjectCreateRequest copyWith({
    String? title,
    String? projectTypeId,
    ProjectStorageStrategy? storageStrategy,
    String? projectBranchId,
    String? runtimeBaselineId,
  }) {
    return ProjectCreateRequest(
      title: title ?? this.title,
      projectTypeId: projectTypeId ?? this.projectTypeId,
      storageStrategy: storageStrategy ?? this.storageStrategy,
      projectBranchId: projectBranchId ?? this.projectBranchId,
      runtimeBaselineId: runtimeBaselineId ?? this.runtimeBaselineId,
    );
  }
}
