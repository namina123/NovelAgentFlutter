import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('CreativeRuleStackResolverService', () {
    test(
      'resolves constitution, mode guidance, expression constraints and effective styles with stable priority',
      () {
        // 中文注释: 这里验证创作宪法、模式引导、表达限制和风格都会被收束成统一栈，并保持稳定优先级。
        final resolver = CreativeRuleStackResolverService();

        final stack = resolver.resolve(
          projectConstitutionMarkdown: '''
# 项目创作宪法

本书以高压权谋和持续逆转为长期承诺。

## 核心原则

- 重大设定必须前后一致。
- 角色动机不得无因跳变。

## 禁止事项

- 不要临时加入万能设定。

## 自然表达

- 减少模板化排比和空泛总结。
''',
          modeGuidanceState: ModeGuidanceState(
            modeId: 'seed_autopilot_novel',
            projectStrategyId: 'long_task_novel',
            workflowStrategyId: 'resumable_long_task',
            status: ModeGuidanceState.statusReady,
            currentStageId: 'review_ready',
            answers: const <ModeGuidanceAnswer>[
              ModeGuidanceAnswer(
                stageId: 'core_promise',
                fieldKey: 'core_promise',
                label: '核心承诺',
                value: '高压权谋与持续逆转。',
              ),
              ModeGuidanceAnswer(
                stageId: 'autonomy_guardrails',
                fieldKey: 'autonomy_guardrails',
                label: '托管边界',
                value: '总纲和重大转折先确认。',
              ),
              ModeGuidanceAnswer(
                stageId: 'style_target',
                fieldKey: 'style_target',
                label: '风格与边界',
                value: '干净利落，避免AI腔。',
              ),
            ],
            completedStageIds: const <String>['core_promise', 'style_target'],
            createdAt: '2026-05-26T09:00:00Z',
            updatedAt: '2026-05-26T09:10:00Z',
          ),
          expressionConstraintProfiles: const <Object?>[
            <String, Object?>{
              'id': 'de_ai',
              'display_name': '去 AI 风',
              'summary': '降低模板化表达和解释腔。',
              'kind': 'natural_expression',
              'rules': <Object?>['减少工整排比和空心总结。'],
            },
          ],
          projectExpressionConstraintBindings: const <Object?>[
            <String, Object?>{
              'profile_id': 'de_ai',
              'default_for_project': true,
              'target_mode_ids': <Object?>['seed_autopilot_novel'],
              'weight': 120,
            },
          ],
          styleProfiles: const <Object?>[
            <String, Object?>{
              'id': 'style.default',
              'display_name': '默认风格',
              'summary': '旧默认风格。',
              'default_for_project': true,
            },
            <String, Object?>{
              'id': 'style.writer',
              'display_name': '作者风格',
              'summary': '干净利落，强钩子。',
            },
          ],
          projectStyleBindings: const <Object?>[
            <String, Object?>{
              'style_id': 'style.writer',
              'default_for_project': true,
              'target_mode_ids': <Object?>['seed_autopilot_novel'],
              'weight': 120,
            },
          ],
          modeId: 'seed_autopilot_novel',
        );

        expect(stack.constitution, isNotNull);
        expect(stack.constitution!.principles, contains('重大设定必须前后一致。'));
        expect(
          stack.constitution!.naturalExpressionRules,
          contains('减少模板化排比和空泛总结。'),
        );
        expect(stack.modeGuidance, isNotNull);
        expect(stack.modeGuidance!.boundaries, contains('总纲和重大转折先确认。'));
        expect(
          stack.expressionConstraints.map((profile) => profile.id),
          <String>['de_ai'],
        );
        expect(stack.styles.map((style) => style.id), <String>['style.writer']);
      },
    );
  });
}
