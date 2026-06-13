import '../../../project_creation/application/services/project_creation_expression_constraint_defaults_settings_service.dart';

class ProjectCreationExpressionConstraintDefaultsViewData {
  const ProjectCreationExpressionConstraintDefaultsViewData({
    required this.mode,
    required this.fallbackSummary,
    required this.options,
  });

  final ProjectCreationExpressionConstraintDefaultsMode mode;
  final String fallbackSummary;
  final List<ProjectCreationExpressionConstraintOptionViewData> options;

  factory ProjectCreationExpressionConstraintDefaultsViewData.initial() {
    return const ProjectCreationExpressionConstraintDefaultsViewData(
      mode: ProjectCreationExpressionConstraintDefaultsMode.builtinFallback,
      fallbackSummary: '',
      options: <ProjectCreationExpressionConstraintOptionViewData>[],
    );
  }
}

class ProjectCreationExpressionConstraintOptionViewData {
  const ProjectCreationExpressionConstraintOptionViewData({
    required this.id,
    required this.label,
    required this.summary,
    required this.isSelected,
    this.isMissing = false,
  });

  final String id;
  final String label;
  final String summary;
  final bool isSelected;
  final bool isMissing;
}
