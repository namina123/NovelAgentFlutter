import 'expression_constraint_kind.dart';
import 'expression_constraint_profile.dart';

class ExpressionConstraintBriefRenderer {
  const ExpressionConstraintBriefRenderer();

  List<String> renderLines(List<ExpressionConstraintProfile> constraints) {
    if (constraints.isEmpty) {
      return const <String>[];
    }
    return <String>[
      '表达限制：${constraints.map((profile) => profile.displayName).join('、')}',
      ...constraints.map(_renderConstraintLine),
    ];
  }

  String _renderConstraintLine(ExpressionConstraintProfile profile) {
    final parts = <String>[
      profile.displayName,
      _kindLabel(profile.kind),
      if (profile.summary.trim().isNotEmpty) profile.summary.trim(),
    ];
    return '- ${parts.join(' | ')}';
  }

  String _kindLabel(ExpressionConstraintKind kind) {
    switch (kind) {
      case ExpressionConstraintKind.naturalExpression:
        return '自然表达';
      case ExpressionConstraintKind.narrativeBoundary:
        return '叙事边界';
      case ExpressionConstraintKind.terminologyControl:
        return '术语控制';
      case ExpressionConstraintKind.rhythmControl:
        return '节奏控制';
      case ExpressionConstraintKind.continuityGuard:
        return '连续性护栏';
      case ExpressionConstraintKind.custom:
        return '自定义';
    }
  }
}
