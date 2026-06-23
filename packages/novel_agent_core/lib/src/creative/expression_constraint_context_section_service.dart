import '../common/json_types.dart';
import 'expression_constraint_kind.dart';
import 'expression_constraint_profile.dart';

class ExpressionConstraintContextSectionService {
  const ExpressionConstraintContextSectionService();

  List<JsonMap> buildSections(List<ExpressionConstraintProfile> constraints) {
    final sections = <JsonMap>[];
    for (var index = 0; index < constraints.length; index++) {
      sections.add(_constraintSection(constraints[index], index: index));
    }
    return sections;
  }

  JsonMap _constraintSection(
    ExpressionConstraintProfile profile, {
    required int index,
  }) {
    final lines = <String>[
      '限制：${profile.displayName}',
      '类型：${_kindLabel(profile.kind)}',
      if (profile.summary.trim().isNotEmpty) '限制摘要：${profile.summary.trim()}',
    ];
    if (profile.rules.isNotEmpty) {
      lines.add('执行规则：');
      for (final item in profile.rules.take(8)) {
        lines.add('- ${item.trim()}');
      }
    }
    if (profile.riskSignals.isNotEmpty) {
      lines.add('风险信号（交付前自查；命中后需要改写或降到明确可接受的极低频率）：');
      // 中文注释: 风险信号与正文表面扫描器（ExpressionConstraintSurfaceRiskScanService）共用同一份
      // 列表——扫描器会用全部信号检查正文。这里必须把全部信号都展示给模型，否则会出现“模型因未被
      // 告知的信号被判定为违反约束”的不一致。信号本身是短词，不做截断也不会明显占用预算。
      for (final item in profile.riskSignals) {
        lines.add('- ${item.trim()}');
      }
    }
    return <String, Object?>{
      'id':
          'creative_expression_constraint_${profile.id.isEmpty ? index + 1 : profile.id}',
      'title': '表达限制规范',
      'priority': 97 - index,
      'pinned': true,
      'creative_layer': 'expression_constraint',
      'content': lines.join('\n'),
    };
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
