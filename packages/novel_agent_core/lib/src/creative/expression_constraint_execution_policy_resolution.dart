import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'expression_constraint_execution_policy.dart';

class ExpressionConstraintExecutionPolicyResolution {
  const ExpressionConstraintExecutionPolicyResolution({
    required this.policy,
    this.applied = false,
    this.runtimeEscalated = false,
    this.technicalTurnExcluded = false,
    this.whyApplied = const <String>[],
    this.whySkipped = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final ExpressionConstraintExecutionPolicy policy;
  final bool applied;
  final bool runtimeEscalated;
  final bool technicalTurnExcluded;
  final List<String> whyApplied;
  final List<String> whySkipped;
  final JsonMap metadata;

  bool get skipped => !applied;

  JsonMap toJson() {
    // 中文注释: resolution 只输出稳定合同和解释字段，供后续 bridge 或 probe 直接消费。
    return <String, Object?>{
      'policy': policy.toJson(),
      'applied': applied,
      'runtime_escalated': runtimeEscalated,
      'technical_turn_excluded': technicalTurnExcluded,
      'why_applied': ValueReaders.deepCopyList(whyApplied.cast<Object?>()),
      'why_skipped': ValueReaders.deepCopyList(whySkipped.cast<Object?>()),
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
