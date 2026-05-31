import '../project/project_trait_set.dart';

class AgentAvailabilityContext {
  const AgentAvailabilityContext({
    required this.projectTypeId,
    required this.projectTraits,
    this.modeId = '',
    this.stageId = '',
  });

  final String projectTypeId;
  final ProjectTraitSet projectTraits;
  final String modeId;
  final String stageId;
}
