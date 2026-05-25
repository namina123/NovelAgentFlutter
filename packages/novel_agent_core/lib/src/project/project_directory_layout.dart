import 'project_storage_strategy.dart';
import 'workspace_directory_descriptor.dart';

class ProjectDirectoryLayout {
  const ProjectDirectoryLayout({
    required this.storageStrategy,
    required this.primaryContentDirectories,
    required this.readableProjectionDirectories,
    required this.advancedDirectories,
    required this.internalDirectories,
  });

  final ProjectStorageStrategy storageStrategy;
  final List<WorkspaceDirectoryDescriptor> primaryContentDirectories;
  final List<WorkspaceDirectoryDescriptor> readableProjectionDirectories;
  final List<WorkspaceDirectoryDescriptor> advancedDirectories;
  final List<WorkspaceDirectoryDescriptor> internalDirectories;
}
