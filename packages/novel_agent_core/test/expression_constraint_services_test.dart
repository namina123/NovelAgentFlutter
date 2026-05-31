import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectExpressionConstraintBindingResolverService', () {
    test('resolves enabled bindings by scope and weight', () {
      const resolver = ProjectExpressionConstraintBindingResolverService();

      final profileIds = resolver.resolveProfileIds(
        const <ProjectExpressionConstraintBinding>[
          ProjectExpressionConstraintBinding(
            id: 'draft-natural',
            profileId: 'de_ai',
            defaultForProject: true,
            targetModeIds: <String>['draft'],
            weight: 120,
          ),
          ProjectExpressionConstraintBinding(
            id: 'writer-jargon',
            profileId: 'low_jargon_narration',
            targetAgentIds: <String>['writer'],
            weight: 100,
          ),
          ProjectExpressionConstraintBinding(
            id: 'disabled',
            profileId: 'strict_pov_boundary',
            enabled: false,
          ),
        ],
        availableProfiles: const <ExpressionConstraintProfile>[
          ExpressionConstraintProfile(
            id: 'de_ai',
            displayName: '去 AI 风',
            summary: '降低模板化表达和解释腔。',
          ),
          ExpressionConstraintProfile(
            id: 'low_jargon_narration',
            displayName: '降低术语分析腔',
            summary: '压低职业化和空心分析词。',
          ),
          ExpressionConstraintProfile(
            id: 'strict_pov_boundary',
            displayName: '严格 POV 边界',
            summary: '限制未知信息越界。',
          ),
        ],
        agentId: 'writer',
        modeId: 'draft',
      );

      expect(profileIds, <String>['de_ai', 'low_jargon_narration']);
    });
  });

  group('Expression constraint renderers', () {
    const constraints = <ExpressionConstraintProfile>[
      ExpressionConstraintProfile(
        id: 'de_ai',
        displayName: '去 AI 风',
        summary: '降低模板化表达和解释腔。',
        kind: ExpressionConstraintKind.naturalExpression,
        rules: <String>['少用工整排比与空心总结。'],
        riskSignals: <String>['不是……而是……'],
      ),
    ];

    test('brief renderer produces compact summary lines', () {
      const renderer = ExpressionConstraintBriefRenderer();
      final lines = renderer.renderLines(constraints);

      expect(lines.first, '表达限制：去 AI 风');
      expect(lines.last, contains('自然表达'));
      expect(lines.last, contains('降低模板化表达和解释腔。'));
    });

    test('context section service renders structured sections', () {
      const service = ExpressionConstraintContextSectionService();
      final sections = service.buildSections(constraints);

      expect(sections, hasLength(1));
      expect(sections.single['creative_layer'], 'expression_constraint');
      expect(sections.single['content'], contains('执行规则：'));
      expect(sections.single['content'], contains('风险信号：'));
    });
  });
}
