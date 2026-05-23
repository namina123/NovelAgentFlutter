import 'project_entry_view_data.dart';
import 'project_type_option_view_data.dart';

enum ProjectLauncherMode { open, create }

class ProjectLauncherViewData {
  const ProjectLauncherViewData({
    required this.mode,
    required this.projectsRootPath,
    required this.entries,
    required this.status,
    required this.projectTypeOptions,
    required this.selectedProjectTypeId,
  });

  final ProjectLauncherMode mode;
  final String projectsRootPath;
  final List<ProjectEntryViewData> entries;
  final String status;
  final List<ProjectTypeOptionViewData> projectTypeOptions;
  final String selectedProjectTypeId;
}
