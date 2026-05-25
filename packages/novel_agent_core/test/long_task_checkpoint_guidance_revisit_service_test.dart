import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskCheckpointGuidanceRevisitService', () {
    test('builds focused revisit package from risky drift signals', () {
      final transitionService = ModeGuidanceTransitionService();
      var state = transitionService.initialize('seed_autopilot_novel');
      for (final item in const <Map<String, String>>[
        <String, String>{
          'stage': 'seed_scope',
          'field': 'seed_scope',
          'value': '黑暗奇幻长篇',
          'label': '黑暗奇幻长篇',
        },
        <String, String>{
          'stage': 'world_anchor',
          'field': 'world_anchor',
          'value': '誓约体系不可被真正伪造，违约会反噬。',
          'label': '誓约体系',
        },
        <String, String>{
          'stage': 'protagonist_drive',
          'field': 'protagonist_drive',
          'value': '主角要翻案复仇，并夺回北境话语权。',
          'label': '翻案复仇',
        },
        <String, String>{
          'stage': 'style_target',
          'field': 'style_target',
          'value': '干净利落，减少说明腔。',
          'label': '干净利落',
        },
      ]) {
        state = transitionService.answer(
          state,
          stageId: item['stage']!,
          fieldKey: item['field']!,
          value: item['value']!,
          label: item['label']!,
          source: 'option',
        );
      }

      final service = LongTaskCheckpointGuidanceRevisitService();
      final result = service.buildPackage(
        checkpointReview: const <String, Object?>{
          'mode': 'seed_autopilot_novel',
          'persistent_context_paths': <Object?>[
            'tracking/modes/seed_autopilot_novel/guidance.md',
          ],
          'drift_signals': <Object?>[
            <String, Object?>{
              'domain': 'style',
              'severity': 'high',
              'title': '文风漂移',
              'note': '文风出现飘移迹象。',
            },
            <String, Object?>{
              'domain': 'world',
              'severity': 'medium',
              'title': '世界规则漂移',
              'note': '世界规则描述变松。',
            },
          ],
        },
        state: state,
      );

      expect(ValueReaders.boolValue(result['ok']), isTrue);
      expect(
        ValueReaders.stringList(result['focus_domains']),
        containsAll(<String>['style', 'world']),
      );
      expect(
        ValueReaders.mapList(
          result['items'],
        ).any((item) => ValueReaders.stringValue(item['domain']) == 'style'),
        isTrue,
      );
      expect(
        ValueReaders.mapList(result['items']).any(
          (item) =>
              ValueReaders.stringValue(item['path']) ==
              'tracking/modes/seed_autopilot_novel/guidance.md',
        ),
        isTrue,
      );
    });
  });
}
