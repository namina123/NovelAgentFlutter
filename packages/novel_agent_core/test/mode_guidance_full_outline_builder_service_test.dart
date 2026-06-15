import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ModeGuidancePlanInputBuilderService full outline consensus', () {
    test('builds human outline runtime plan input from ready state', () {
      final transitionService = ModeGuidanceTransitionService();
      final builder = ModeGuidancePlanInputBuilderService();
      var state = transitionService.initialize('full_outline_consensus');
      for (final item in const <Map<String, String>>[
        <String, String>{
          'stage': 'book_premise',
          'field': 'book_premise',
          'value': '一个衰败帝国边境的私生公主被迫回京争位。',
        },
        <String, String>{
          'stage': 'main_arc',
          'field': 'main_arc',
          'value': '主角要在皇储之争、边军失控和异族南下之间夺回主动权。',
        },
        <String, String>{
          'stage': 'volume_map',
          'field': 'volume_map',
          'value': '第一卷回京入局，第二卷边军反噬，第三卷诸侯裂盟，第四卷王座清算。',
        },
        <String, String>{
          'stage': 'ending_commitment',
          'field': 'ending_commitment',
          'value': '结局必须让主角掌权，但为此付出重大关系代价。',
        },
        <String, String>{
          'stage': 'style_and_boundaries',
          'field': 'style_and_boundaries',
          'value': '文风干净克制，避免无休止抒情和套路打脸。',
        },
        <String, String>{
          'stage': 'consensus_confirm',
          'field': 'consensus_confirm',
          'value': '当前全书共识已经足够，可以开始生成总纲、卷纲和执行队列。',
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
      expect(input.runtimeBaselineId, 'chapter_collaboration_autorun');
      expect(input.runtimeMode, TaskRuntimeConstants.modeHumanOutlineAiDraft);
      expect(
        ValueReaders.stringValue(input.options['runtime_baseline_id']),
        'chapter_collaboration_autorun',
      );
      expect(
        ValueReaders.stringValue(input.options['outline_text']),
        contains('【分卷结构】第一卷回京入局'),
      );
      expect(ValueReaders.intValue(input.options['checkpoint_interval']), 0);
      expect(
        ValueReaders.stringList(input.options['persistent_context_paths']),
        contains('outlines/story/full_outline_consensus_overview.md'),
      );
    });
  });
}
