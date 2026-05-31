import 'expression_constraint_kind.dart';
import 'expression_constraint_scope.dart';

class ExpressionConstraintProfile {
  const ExpressionConstraintProfile({
    required this.id,
    required this.displayName,
    required this.summary,
    this.kind = ExpressionConstraintKind.custom,
    this.rules = const <String>[],
    this.riskSignals = const <String>[],
    this.recommendedScope = const ExpressionConstraintScope(),
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String displayName;
  final String summary;
  final ExpressionConstraintKind kind;
  final List<String> rules;
  final List<String> riskSignals;
  final ExpressionConstraintScope recommendedScope;
  final Map<String, Object?> metadata;
}
