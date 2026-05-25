import 'project_agent_model_override.dart';

class ProjectAgentBinding {
  const ProjectAgentBinding({
    required this.agentId,
    this.displayName = '',
    this.enabled = true,
    this.selectedByDefault = false,
    this.stageIds = const <String>[],
    this.modeIds = const <String>[],
    this.styleBindingIds = const <String>[],
    this.modelOverride,
    this.metadata = const <String, Object?>{},
  });

  final String agentId;
  final String displayName;
  final bool enabled;
  final bool selectedByDefault;
  final List<String> stageIds;
  final List<String> modeIds;
  final List<String> styleBindingIds;
  final ProjectAgentModelOverride? modelOverride;
  final Map<String, Object?> metadata;
}
