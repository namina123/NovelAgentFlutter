import 'project_create_request.dart';
import 'project_creation_next_step.dart';
import 'project_runtime_baseline_definition.dart';
import 'project_type_definition.dart';

class ProjectCreationPlan {
  const ProjectCreationPlan({
    required this.request,
    required this.projectTypeDefinition,
    required this.runtimeBaselineOptions,
    required this.nextStep,
  });

  final ProjectCreateRequest request;
  final ProjectTypeDefinition projectTypeDefinition;
  final List<ProjectRuntimeBaselineDefinition> runtimeBaselineOptions;
  final ProjectCreationNextStep nextStep;

  bool get canCreate => nextStep == ProjectCreationNextStep.readyToCreate;
}
