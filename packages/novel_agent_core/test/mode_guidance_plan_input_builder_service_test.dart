import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ModeGuidancePlanInputBuilderService', () {
    test('builds seed autopilot runtime plan input from ready state', () {
      final transitionService = ModeGuidanceTransitionService();
      final builder = ModeGuidancePlanInputBuilderService();
      var state = transitionService.initialize('seed_autopilot_novel');
      for (final item in const <Map<String, String>>[
        <String, String>{
          'stage': 'seed_scope',
          'field': 'seed_scope',
          'value': '黑暗奇幻权谋，主角准备回到帝都翻案。',
        },
        <String, String>{
          'stage': 'core_promise',
          'field': 'core_promise',
          'value': '高压权谋与连续逆转。',
        },
        <String, String>{
          'stage': 'world_anchor',
          'field': 'world_anchor',
          'value': '帝国靠誓约维持秩序。',
        },
        <String, String>{
          'stage': 'protagonist_drive',
          'field': 'protagonist_drive',
          'value': '复仇与翻案。',
        },
        <String, String>{
          'stage': 'style_target',
          'field': 'style_target',
          'value': '干净利落，偏商业长篇。',
        },
        <String, String>{
          'stage': 'autonomy_guardrails',
          'field': 'autonomy_guardrails',
          'value': '允许智能体先生成总纲、分卷结构和前 12 章章纲，但跨卷大转折需要确认。',
        },
        <String, String>{
          'stage': 'review_ready',
          'field': 'review_ready',
          'value': '已确认以上信息，可以开始生成可恢复长任务链。',
        },
      ]) {
        state = transitionService.answer(
          state,
          stageId: item['stage']!,
          fieldKey: item['field']!,
          value: item['value']!,
        );
      }

      final input = builder.build(state);
      expect(input.isReady, isTrue);
      expect(input.runtimeMode, TaskRuntimeConstants.modeSeedToFullNovel);
      expect(
        ValueReaders.stringValue(input.options['seed_prompt']),
        contains('【核心承诺】高压权谋与连续逆转。'),
      );
      expect(ValueReaders.intValue(input.options['chapter_count']), 12);
      expect(ValueReaders.intValue(input.options['checkpoint_interval']), 4);
      expect(
        ValueReaders.stringList(input.options['persistent_context_paths']),
        contains('styles/seed_autopilot_style.md'),
      );
    });
  });
}
