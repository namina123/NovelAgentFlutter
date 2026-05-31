import '../common/json_types.dart';
import 'expression_constraint_context_section_service.dart';
import 'creative_rule_stack.dart';
import 'mode_guidance.dart';
import 'project_constitution.dart';
import '../assets/style_profile.dart';

class CreativeRuleContextSectionService {
  const CreativeRuleContextSectionService({
    ExpressionConstraintContextSectionService?
    expressionConstraintContextSectionService,
  }) : _expressionConstraintContextSectionService =
           expressionConstraintContextSectionService ??
           const ExpressionConstraintContextSectionService();

  final ExpressionConstraintContextSectionService
  _expressionConstraintContextSectionService;

  List<JsonMap> buildSections(CreativeRuleStack stack) {
    // 中文注释: 创作约束栈在这里转成正式上下文片段，保证宪法、引导和风格始终以稳定顺序进入模型。
    if (stack.isEmpty) {
      return const <JsonMap>[];
    }
    final sections = <JsonMap>[];
    if (stack.constitution != null && !stack.constitution!.isEmpty) {
      sections.add(_constitutionSection(stack.constitution!));
    }
    if (stack.modeGuidance != null && !stack.modeGuidance!.isEmpty) {
      sections.add(_modeGuidanceSection(stack.modeGuidance!));
    }
    sections.addAll(
      _expressionConstraintContextSectionService.buildSections(
        stack.expressionConstraints,
      ),
    );
    for (var index = 0; index < stack.styles.length; index++) {
      sections.add(_styleSection(stack.styles[index], index: index));
    }
    return sections;
  }

  JsonMap _constitutionSection(ProjectConstitution constitution) {
    final lines = <String>[
      '宪法标题：${constitution.title}',
      if (constitution.summary.trim().isNotEmpty)
        '核心摘要：${constitution.summary.trim()}',
    ];
    if (constitution.principles.isNotEmpty) {
      lines.add('必须遵守：');
      for (final item in constitution.principles) {
        lines.add('- ${item.trim()}');
      }
    }
    if (constitution.prohibitions.isNotEmpty) {
      lines.add('绝不做：');
      for (final item in constitution.prohibitions) {
        lines.add('- ${item.trim()}');
      }
    }
    if (constitution.naturalExpressionRules.isNotEmpty) {
      lines.add('自然表达约束：');
      for (final item in constitution.naturalExpressionRules) {
        lines.add('- ${item.trim()}');
      }
    }
    return <String, Object?>{
      'id': 'creative_constitution',
      'title': '项目创作宪法',
      'priority': 99,
      'pinned': true,
      'creative_layer': 'constitution',
      if (constitution.sourcePath.trim().isNotEmpty)
        'source': constitution.sourcePath.trim(),
      'content': lines.join('\n'),
    };
  }

  JsonMap _modeGuidanceSection(ModeGuidance guidance) {
    final lines = <String>[
      '模式：${guidance.title}',
      if (guidance.summary.trim().isNotEmpty) '当前收束：${guidance.summary.trim()}',
      if (guidance.currentStageTitle.trim().isNotEmpty)
        '当前阶段：${guidance.currentStageTitle.trim()}',
    ];
    if (guidance.confirmedFacts.isNotEmpty) {
      lines.add('已确认事实：');
      for (final item in guidance.confirmedFacts.take(8)) {
        lines.add('- ${item.trim()}');
      }
    }
    if (guidance.boundaries.isNotEmpty) {
      lines.add('模式边界：');
      for (final item in guidance.boundaries.take(6)) {
        lines.add('- ${item.trim()}');
      }
    }
    return <String, Object?>{
      'id': 'creative_mode_guidance_${guidance.modeId}',
      'title': '模式引导约束',
      'priority': 98,
      'pinned': true,
      'creative_layer': 'mode_guidance',
      if (guidance.sourcePath.trim().isNotEmpty)
        'source': guidance.sourcePath.trim(),
      'content': lines.join('\n'),
    };
  }

  JsonMap _styleSection(StyleProfile style, {required int index}) {
    final lines = <String>[
      '风格：${style.displayName}',
      if (style.summary.trim().isNotEmpty) '风格摘要：${style.summary.trim()}',
      if (style.tone.trim().isNotEmpty) '语气：${style.tone.trim()}',
      if (style.genre.trim().isNotEmpty) '适配题材：${style.genre.trim()}',
      if (style.audience.trim().isNotEmpty) '目标读者：${style.audience.trim()}',
    ];
    if (style.guardrails.isNotEmpty) {
      lines.add('风格护栏：');
      for (final item in style.guardrails.take(8)) {
        lines.add('- ${item.trim()}');
      }
    }
    return <String, Object?>{
      'id': 'creative_style_${style.id.isEmpty ? index + 1 : style.id}',
      'title': '项目风格规范',
      'priority': 92 - index,
      'pinned': true,
      'creative_layer': 'style',
      if (style.sourcePath.trim().isNotEmpty) 'source': style.sourcePath.trim(),
      'content': lines.join('\n'),
    };
  }
}
