import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ExpressionConstraintScope', () {
    test('treats an empty scope as global', () {
      const scope = ExpressionConstraintScope();

      expect(scope.isGlobal, isTrue);
    });

    test('treats targeted fields as scoped', () {
      const scope = ExpressionConstraintScope(
        projectTypeIds: <String>['long_novel'],
        modeIds: <String>['draft'],
      );

      expect(scope.isGlobal, isFalse);
      expect(scope.projectTypeIds, <String>['long_novel']);
      expect(scope.modeIds, <String>['draft']);
    });
  });

  group('ExpressionConstraintProfile', () {
    test('keeps reusable preset contract data', () {
      const profile = ExpressionConstraintProfile(
        id: 'low_jargon_narration',
        displayName: '降低术语分析腔',
        summary: '压低职业化、抽象化、方案化叙述。',
        kind: ExpressionConstraintKind.terminologyControl,
        rules: <String>['能转成动作、后果或对话时，不优先保留抽象分析词。'],
        riskSignals: <String>['底层逻辑', '闭环', '机制'],
        recommendedScope: ExpressionConstraintScope(
          projectTypeIds: <String>['novel'],
        ),
        metadata: <String, Object?>{'builtin': true},
      );

      expect(profile.id, 'low_jargon_narration');
      expect(profile.kind, ExpressionConstraintKind.terminologyControl);
      expect(profile.rules, hasLength(1));
      expect(profile.riskSignals, contains('闭环'));
      expect(profile.recommendedScope.projectTypeIds, <String>['novel']);
      expect(profile.metadata['builtin'], isTrue);
    });

    test('treats de_ai as a normal built-in preset id', () {
      const profile = ExpressionConstraintProfile(
        id: 'de_ai',
        displayName: '去 AI 风',
        summary: '降低模板化表达和解释腔。',
        kind: ExpressionConstraintKind.naturalExpression,
      );

      expect(profile.id, 'de_ai');
      expect(profile.kind, ExpressionConstraintKind.naturalExpression);
      expect(profile.recommendedScope.isGlobal, isTrue);
    });
  });

  group('ProjectExpressionConstraintBinding', () {
    test('mirrors project binding scope and priority semantics', () {
      const binding = ProjectExpressionConstraintBinding(
        id: 'writer-de-ai',
        profileId: 'de_ai',
        displayName: '作者正文去 AI 风',
        defaultForProject: true,
        targetAgentIds: <String>['writer'],
        targetModeIds: <String>['draft'],
        targetStageIds: <String>['chapter_write'],
        weight: 120,
        metadata: <String, Object?>{'source': 'project'},
      );

      expect(binding.profileId, 'de_ai');
      expect(binding.defaultForProject, isTrue);
      expect(binding.scope.isGlobal, isFalse);
      expect(binding.scope.agentIds, <String>['writer']);
      expect(binding.scope.modeIds, <String>['draft']);
      expect(binding.scope.stageIds, <String>['chapter_write']);
      expect(binding.weight, 120);
      expect(binding.metadata['source'], 'project');
    });

    test('defaults to enabled global binding when no targets are set', () {
      const binding = ProjectExpressionConstraintBinding(
        profileId: 'strict_pov_boundary',
      );

      expect(binding.enabled, isTrue);
      expect(binding.scope.isGlobal, isTrue);
      expect(binding.weight, 100);
    });
  });
}
