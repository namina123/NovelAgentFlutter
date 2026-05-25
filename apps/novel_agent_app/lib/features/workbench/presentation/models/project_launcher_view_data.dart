import 'project_entry_view_data.dart';
import 'project_creation_phase.dart';
import 'project_runtime_baseline_option_view_data.dart';
import 'project_storage_strategy_option_view_data.dart';
import 'project_type_option_view_data.dart';

enum ProjectLauncherMode { open, create }

class ProjectLauncherViewData {
  const ProjectLauncherViewData({
    required this.mode,
    required this.projectsRootPath,
    required this.entries,
    required this.status,
    required this.draftTitle,
    required this.projectTypeOptions,
    required this.selectedProjectTypeId,
    required this.storageStrategyOptions,
    required this.selectedStorageStrategyId,
    required this.creationPhase,
    required this.runtimeBaselineOptions,
    required this.selectedRuntimeBaselineId,
    required this.selectedProjectTypeRequiresRuntimeBaseline,
    required this.canDismiss,
    required this.allowOpenExisting,
  });

  final ProjectLauncherMode mode;
  final String projectsRootPath;
  final List<ProjectEntryViewData> entries;
  final String status;
  final String draftTitle;
  final List<ProjectTypeOptionViewData> projectTypeOptions;
  final String selectedProjectTypeId;
  final List<ProjectStorageStrategyOptionViewData> storageStrategyOptions;
  final String selectedStorageStrategyId;
  final ProjectCreationPhase creationPhase;
  final List<ProjectRuntimeBaselineOptionViewData> runtimeBaselineOptions;
  final String selectedRuntimeBaselineId;
  final bool selectedProjectTypeRequiresRuntimeBaseline;
  final bool canDismiss;
  final bool allowOpenExisting;
}
