import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_entry_view_data.dart';
import 'project_creation_phase.dart';
import 'project_deconstruction_followup_option_view_data.dart';
import 'project_knowledge_base_branch_option_view_data.dart';
import 'project_runtime_baseline_option_view_data.dart';
import 'project_storage_strategy_option_view_data.dart';
import 'project_type_option_view_data.dart';

enum ProjectLauncherMode { guard, create }

class ProjectLauncherViewData {
  const ProjectLauncherViewData({
    required this.mode,
    required this.title,
    required this.description,
    required this.projectsRootPath,
    required this.entries,
    required this.status,
    required this.draftTitle,
    required this.projectTypeOptions,
    required this.selectedProjectTypeId,
    required this.storageStrategyOptions,
    required this.selectedStorageStrategyId,
    required this.creationPhase,
    required this.knowledgeBaseBranchOptions,
    required this.selectedKnowledgeBaseBranchId,
    required this.bookDeconstructionFollowupOptions,
    required this.selectedBookDeconstructionFollowupRouteId,
    required this.runtimeBaselineOptions,
    required this.selectedRuntimeBaselineId,
    required this.selectedProjectTypeRequiresRuntimeBaseline,
    required this.continuityInput,
    required this.canDismiss,
    required this.allowOpenExisting,
  });

  final ProjectLauncherMode mode;
  final String title;
  final String description;
  final String projectsRootPath;
  final List<ProjectEntryViewData> entries;
  final String status;
  final String draftTitle;
  final List<ProjectTypeOptionViewData> projectTypeOptions;
  final String selectedProjectTypeId;
  final List<ProjectStorageStrategyOptionViewData> storageStrategyOptions;
  final String selectedStorageStrategyId;
  final ProjectCreationPhase creationPhase;
  final List<ProjectKnowledgeBaseBranchOptionViewData>
  knowledgeBaseBranchOptions;
  final String selectedKnowledgeBaseBranchId;
  final List<ProjectDeconstructionFollowupOptionViewData>
  bookDeconstructionFollowupOptions;
  final String selectedBookDeconstructionFollowupRouteId;
  final List<ProjectRuntimeBaselineOptionViewData> runtimeBaselineOptions;
  final String selectedRuntimeBaselineId;
  final bool selectedProjectTypeRequiresRuntimeBaseline;
  final ProjectContinuityInputProfile continuityInput;
  final bool canDismiss;
  final bool allowOpenExisting;
}
