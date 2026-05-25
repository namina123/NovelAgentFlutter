import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ModeGuidanceAssetBundleBuilderService', () {
    test('builds structured assets for seed autopilot mode', () {
      final transitionService = ModeGuidanceTransitionService();
      const builder = ModeGuidanceAssetBundleBuilderService();
      var state = transitionService.initialize('seed_autopilot_novel');
      for (final item in const <Map<String, String>>[
        <String, String>{
          'stage': 'core_promise',
          'field': 'core_promise',
          'value': '高压权谋与连续逆转。',
        },
        <String, String>{
          'stage': 'world_anchor',
          'field': 'world_anchor',
          'value': '帝国靠誓约维持秩序。高位者违约会遭受反噬。',
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
          'value': '跨卷大转折需要确认。',
        },
      ]) {
        state = transitionService.answer(
          state,
          stageId: item['stage']!,
          fieldKey: item['field']!,
          value: item['value']!,
        );
      }

      final bundle = builder.build(state);
      expect(bundle.styleProfiles, hasLength(1));
      expect(bundle.worldRuleSets, hasLength(1));
      expect(bundle.entityIdentities, hasLength(1));
      expect(bundle.styleProfiles.single.guardrails, contains('高压权谋与连续逆转。'));
      expect(bundle.worldRuleSets.single.rules, hasLength(2));
      expect(bundle.entityIdentities.single.kind, 'character');
      expect(
        bundle.markdownPathFor(bundle.styleProfiles.single.id),
        'styles/seed_autopilot_style.md',
      );
    });

    test(
      'builds reusable style and story focus assets for full outline mode',
      () {
        final transitionService = ModeGuidanceTransitionService();
        const builder = ModeGuidanceAssetBundleBuilderService();
        var state = transitionService.initialize('full_outline_consensus');
        for (final item in const <Map<String, String>>[
          <String, String>{
            'stage': 'book_premise',
            'field': 'book_premise',
            'value': '失势公主回京争位。',
          },
          <String, String>{
            'stage': 'main_arc',
            'field': 'main_arc',
            'value': '她要在皇储之争和边军失控之间建立联盟。',
          },
          <String, String>{
            'stage': 'style_and_boundaries',
            'field': 'style_and_boundaries',
            'value': '文风要克制、干净、偏商业长篇。',
          },
        ]) {
          state = transitionService.answer(
            state,
            stageId: item['stage']!,
            fieldKey: item['field']!,
            value: item['value']!,
          );
        }

        final bundle = builder.build(state);
        expect(bundle.styleProfiles, hasLength(1));
        expect(bundle.entityIdentities, hasLength(1));
        expect(bundle.worldRuleSets, isEmpty);
        expect(bundle.entityIdentities.single.displayName, '主角焦点');
      },
    );
  });
}
