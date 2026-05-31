import 'creative_rule_stack.dart';
import 'expression_constraint_brief_renderer.dart';

class CreativeRuleBriefRenderer {
  const CreativeRuleBriefRenderer({
    ExpressionConstraintBriefRenderer? expressionConstraintBriefRenderer,
  }) : _expressionConstraintBriefRenderer =
           expressionConstraintBriefRenderer ??
           const ExpressionConstraintBriefRenderer();

  final ExpressionConstraintBriefRenderer _expressionConstraintBriefRenderer;

  String render(CreativeRuleStack stack) {
    // 中文注释: 提示摘要只给任务提示和复盘提示看，强调优先级，不重复铺满全部资产正文。
    if (stack.isEmpty) {
      return '';
    }
    final lines = <String>['优先级：项目创作宪法 > 模式引导 > 表达限制 > 项目风格 > 其他上下文与即时发挥。'];
    final constitution = stack.constitution;
    if (constitution != null && !constitution.isEmpty) {
      lines.add(
        '创作宪法：${constitution.summary.trim().isEmpty ? constitution.title : constitution.summary.trim()}',
      );
    }
    final guidance = stack.modeGuidance;
    if (guidance != null && !guidance.isEmpty) {
      lines.add(
        '模式引导：${guidance.summary.trim().isEmpty ? guidance.title : guidance.summary.trim()}',
      );
    }
    lines.addAll(
      _expressionConstraintBriefRenderer.renderLines(
        stack.expressionConstraints,
      ),
    );
    if (stack.styles.isNotEmpty) {
      lines.add(
        '生效风格：${stack.styles.map((style) => style.displayName).join('、')}',
      );
    }
    return lines.join('\n');
  }
}
