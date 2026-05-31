import 'expression_constraint_scope.dart';

class ProjectExpressionConstraintBinding {
  const ProjectExpressionConstraintBinding({
    required this.profileId,
    this.id = '',
    this.displayName = '',
    this.enabled = true,
    this.defaultForProject = false,
    this.targetAgentIds = const <String>[],
    this.targetModeIds = const <String>[],
    this.targetStageIds = const <String>[],
    this.weight = 100,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String profileId;
  final String displayName;
  final bool enabled;
  final bool defaultForProject;
  final List<String> targetAgentIds;
  final List<String> targetModeIds;
  final List<String> targetStageIds;
  final int weight;
  final Map<String, Object?> metadata;

  ExpressionConstraintScope get scope => ExpressionConstraintScope(
    agentIds: targetAgentIds,
    modeIds: targetModeIds,
    stageIds: targetStageIds,
  );
}
