import 'autonomy_policy.dart';
import 'checkpoint_policy.dart';
import 'mode_stage_definition.dart';

class ModeDefinition {
  const ModeDefinition({
    required this.id,
    required this.projectStrategyId,
    required this.workflowStrategyId,
    required this.title,
    required this.description,
    required this.defaultAutonomyPolicy,
    required this.defaultCheckpointPolicy,
    this.stages = const <ModeStageDefinition>[],
  });

  final String id;
  final String projectStrategyId;
  final String workflowStrategyId;
  final String title;
  final String description;
  final AutonomyPolicy defaultAutonomyPolicy;
  final CheckpointPolicy defaultCheckpointPolicy;
  final List<ModeStageDefinition> stages;
}
