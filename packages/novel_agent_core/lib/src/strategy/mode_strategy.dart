import 'autonomy_policy.dart';
import 'checkpoint_policy.dart';

class ModeStrategy {
  const ModeStrategy({
    required this.id,
    required this.projectStrategyId,
    required this.workflowStrategyId,
    required this.title,
    required this.description,
    required this.defaultAutonomyPolicy,
    required this.defaultCheckpointPolicy,
  });

  final String id;
  final String projectStrategyId;
  final String workflowStrategyId;
  final String title;
  final String description;
  final AutonomyPolicy defaultAutonomyPolicy;
  final CheckpointPolicy defaultCheckpointPolicy;
}
