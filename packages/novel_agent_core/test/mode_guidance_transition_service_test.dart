import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ModeGuidanceTransitionService', () {
    test('seed autopilot mode advances stage by stage', () {
      final service = ModeGuidanceTransitionService();
      var state = service.initialize('seed_autopilot_novel');

      expect(state.modeId, 'seed_autopilot_novel');
      expect(state.currentStageId, 'seed_scope');
      expect(state.isReady, isFalse);

      state = service.answer(
        state,
        stageId: 'seed_scope',
        fieldKey: 'seed_scope',
        value: '只有一句灵感',
        label: '只有一句灵感',
        source: 'option',
      );
      expect(state.currentStageId, 'core_promise');
      expect(state.completedStageIds, contains('seed_scope'));

      state = service.answer(
        state,
        stageId: 'core_promise',
        fieldKey: 'core_promise',
        value: '核心承诺偏向持续升级、阶段突破和成长兑现。',
        label: '升级成长',
        source: 'option',
      );
      state = service.answer(
        state,
        stageId: 'world_anchor',
        fieldKey: 'world_anchor',
        value: '世界拥有明确修炼或成长体系，资源、势力与境界决定长期冲突。',
        label: '修炼体系',
        source: 'option',
      );
      state = service.answer(
        state,
        stageId: 'protagonist_drive',
        fieldKey: 'protagonist_drive',
        value: '主角最初以求生、自保或摆脱困境为第一驱动力。',
        label: '求生破局',
        source: 'option',
      );
      state = service.answer(
        state,
        stageId: 'style_target',
        fieldKey: 'style_target',
        value: '文风追求干净、利落、少废话，冲突推进清晰，段落不过度抒情。',
        label: '干净利落',
        source: 'option',
      );
      state = service.answer(
        state,
        stageId: 'autonomy_guardrails',
        fieldKey: 'autonomy_guardrails',
        value: '除世界观底线、总主线和重大转折外，其余推进默认由智能体托管。',
        label: '低频确认',
        source: 'option',
      );
      state = service.answer(
        state,
        stageId: 'review_ready',
        fieldKey: 'review_ready',
        value: '已确认以上信息，可以开始生成可恢复长任务链。',
        label: '开始托管',
        source: 'option',
      );

      expect(state.isReady, isTrue);
      expect(state.completedStageIds.length, 7);
      expect(state.answers.length, 7);
    });

    test('question builder reports progress and ready state', () {
      final service = ModeGuidanceTransitionService();
      var state = service.initialize('seed_autopilot_novel');

      final firstQuestion = service.buildQuestion(state);
      expect(firstQuestion.stageId, 'seed_scope');
      expect(firstQuestion.progressText, '0/7');
      expect(firstQuestion.isReadyToLaunch, isFalse);

      for (final answer in const <Map<String, String>>[
        <String, String>{'stage': 'seed_scope', 'field': 'seed_scope', 'value': 'A'},
        <String, String>{'stage': 'core_promise', 'field': 'core_promise', 'value': 'B'},
        <String, String>{'stage': 'world_anchor', 'field': 'world_anchor', 'value': 'C'},
        <String, String>{'stage': 'protagonist_drive', 'field': 'protagonist_drive', 'value': 'D'},
        <String, String>{'stage': 'style_target', 'field': 'style_target', 'value': 'E'},
        <String, String>{'stage': 'autonomy_guardrails', 'field': 'autonomy_guardrails', 'value': 'F'},
        <String, String>{'stage': 'review_ready', 'field': 'review_ready', 'value': 'G'},
      ]) {
        state = service.answer(
          state,
          stageId: answer['stage']!,
          fieldKey: answer['field']!,
          value: answer['value']!,
        );
      }

      final readyQuestion = service.buildQuestion(state);
      expect(readyQuestion.isReadyToLaunch, isTrue);
      expect(readyQuestion.progressText, '7/7');
    });
  });
}
